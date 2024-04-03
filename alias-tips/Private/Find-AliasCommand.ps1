# Attempts to find an alias for a singular command
function Find-AliasCommand {
  param(
    [Parameter(Mandatory, ValueFromPipeline = $true)]
    [string]$Command
  )

  begin {
    if ($AliasTipsHash -and $AliasTipsHash.Count -eq 0) {
      $AliasTipsHash = ConvertFrom-StringData -StringData $([System.IO.File]::ReadAllText($AliasTipsHashFile)) -Delimiter "|"
    }
  }

  process {
    # If we can find the alias quickly, do so
    $Alias = $AliasTipsHash[$Command.Trim()]
    if (-not [string]::IsNullOrEmpty($Alias)) {
      Write-Verbose "Quickly found alias inside of AliasTipsHash"
      return $Alias | Format-Command
    }

    # TODO check if it is an alias, expand it back out to check if there is a better alias

    # We failed to find the alias in the hash, instead get the executed command, and attempt to generate a regex for it.

    # First we need to ensure we have generated required regexes
    Find-RegexThreadJob
    # Generate a regex that searches through our alias hash, and checks if it matches as an alias for our command
    $Regex = Get-CommandRegex $Command
    # Write-Host $Regex
    if ([string]::IsNullOrEmpty($Regex)) {
      return ""
    }
    $SimpleSubRegex = "$([Regex]::Escape($($Command | Format-Command).Split(" ")[0]))[^`$`n]*\`$"

    $Aliases = @("")
    Write-Verbose "`n$Regex`n`n$SimpleSubRegex`n"

    # Create a new AliasHash with evaluated expression
    $AliasTipsHashEvaluated = $AliasTipsHash.Clone()
    $AliasTipsHash.GetEnumerator() | ForEach-Object {
      # Only reasonably evaluate any commands that match the one we are searching for
      if ($_.key -match $Regex) {
        $Aliases += ,($_.Key, $_.Value)
      }

      # Substitute commands using ExecutionContext if possible
      # Check if we have anything that has a $(...)
      if ($_.key -match $SimpleSubRegex -and ((Initialize-EnvVariable "ALIASTIPS_FUNCTION_INTROSPECTION" $false) -eq $true)) {
        $NewKey = Format-CommandFromExecutionContext($_.value)
        if (-not [string]::IsNullOrEmpty($NewKey) -and $($NewKey -replace '\$args', '') -match $Regex) {
          $Aliases += ,($($NewKey -replace '\$args', '').Trim(), $_.Value)
          $AliasTipsHashEvaluated[$NewKey] = $_.value
        }
      }
    }
    Clear-AliasTipsInternalASTResults

    # Sort by which alias removes the most, then if they both shorten by same amount, choose the shorter alias
    $Aliases = @(@($Aliases 
      | Where-Object { $null -ne $_[0] -and $null -ne $_[1] })
      | Sort-Object -Property @{Expression = { - ($_[0]).Length } }, @{Expression = { ($_[1]).Length} })
    # foreach ($pair in $Aliases) {
    #   Write-Host "($($pair[0]), $($pair[1]))"
    # }
    # Use the longest candiate, if tied use shorter alias 
    # -- TODO? this is my opinionated way since it results in most coverage (one long alias is better than two combined shorter aliases), 
    $AliasCandidate = ($Aliases)[0][0]
    Write-Verbose "Alias Candidate Chosen: $AliasCandidate"
    $Alias = ""
    if (-not [string]::IsNullOrEmpty($AliasCandidate)) {
      $Remaining = "$($Command)"
      $CleanAlias = "$($AliasCandidate)" | Format-Command
      $AttemptSplit = $CleanAlias -split " "

      $AttemptSplit | ForEach-Object {
        [Regex]$Pattern = [Regex]::Escape("$_")
        $Remaining = $Pattern.replace($Remaining, "", 1)
      }

      if (-not $Remaining) {
        $Alias = ($AliasTipsHashEvaluated[$AliasCandidate]) | Format-Command
      }
      if ($AliasTipsHashEvaluated[$AliasCandidate + ' $args']) {
        # TODO: Sometimes superflous args aren't at the end... Fix this.
        $Alias = ($AliasTipsHashEvaluated[$AliasCandidate + ' $args'] + $Remaining) | Format-Command
      }
      if ($Alias -ne $Command) {
        return $Alias
      }
    }
  }
}
