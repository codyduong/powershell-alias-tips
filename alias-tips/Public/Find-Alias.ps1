# Attempts to find an alias
function Find-Alias {
  param(
    [Parameter(ValueFromPipeline=$true)]
    [string]$Command
  )

  process {
    if ($AliasTipsHash -and $AliasTipsHash.Count -eq 0) {
      $AliasTipsHash = ConvertFrom-StringData -StringData $([System.IO.File]::ReadAllText($AliasTipsHashFile)) -Delimiter "|"
    }
  
    # If we can find the alias quickly, do so
    $Alias = $AliasTipsHash[$Command.Trim()]
    if ($Alias) {
      Write-Verbose "Quickly found alias inside of AliasTipsHash"
      return $Alias
    }
  
    # TODO check if it is an alias, expand it back out to check if there is a better alias
  
    # We failed to find the alias in the hash, instead get the executed command, and attempt to generate a regex for it.
    $Regex = Get-CommandRegex $Command
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
        $Aliases += $_.key
      }
  
      # Substitute commands using ExecutionContext if possible
      # Check if we have anything that has a $(...)
      if ($_.key -match $SimpleSubRegex -and ([boolean](Initialize-EnvVariable "ALIASTIPS_FUNCTION_INTROSPECTION" $false)) -eq $true) {
        $NewKey = Format-CommandFromExecutionContext($_.value)
        if (-not [string]::IsNullOrEmpty($NewKey) -and $($NewKey -replace '\$args', '') -match $Regex) {
          $Aliases += $($NewKey -replace '\$args', '').Trim()
          $AliasTipsHashEvaluated[$NewKey] = $_.value
        }
      }
    }
    Clear-AliasTipsInternalASTResults
  
    Write-Verbose $($Aliases -Join ",")
    # Use the longest candiate
    $AliasCandidate = ($Aliases | Sort-Object -Descending -Property Length)[0]
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
