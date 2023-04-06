. $PSScriptRoot\Command.ps1
. $PSScriptRoot\Alias.ps1

function script:SeperateCommand {
  param(
    [Parameter(Mandatory)][string]$Line
  )

  if ($Line -match "(?<cmd>.*)(?<sep>;|(\|\|)|(&&))(?<rest>.*)") {
    if ($Debug) { Write-Host "Splitting line into $($matches['cmd']), $($matches['sep']), and $($matches['rest'])" }
    $LeftHalf = Find-Alias($matches['cmd'])
    $RightHalf = SeperateCommand $($matches['rest'])

    # If the left half isn't found restore the left half
    if (-not $LeftHalf) { $LeftHalf = $matches['cmd'] | Format-CleanCommand }
    # If the right half isn't found restore the right half
    if (-not $RightHalf) { $RightHalf = $matches['rest'] | Format-CleanCommand }
    
    $CompleteAlias = $($LeftHalf + "$(If ($matches['sep'] -eq ';') {''} else {' '})$($matches['sep']) " + $RightHalf) | Format-CleanCommand
    # only return the alias if it is different from the line
    if ($CompleteAlias -ne $($Line | Format-CleanCommand)) {
      return $CompleteAlias
    }
  }
  else {
    return Find-Alias($Line)
  }
}

function PSConsoleHostReadLine {
  ## Get the execution status of the last accepted user input.
  ## This needs to be done as the first thing because any script run will flush $?.
  $lastRunStatus = $?

  ($Line = [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus))

  # split line into multiple commands if possible
  $alias = SeperateCommand $Line

  if ($alias -and -not $AliasTipsThreadJob -and $AliasHash.Length -gt 0) {
    # Only react to non-blank lines.
    $tip = "Alias tip: $alias"
    $host.UI.SupportsVirtualTerminal ? "`e[033m$tip`e[m" : $tip | Out-Host
  }
}

$script:AliasHash = @{}

if ($Debug) { Write-Host $AliasHash }

# Attempts to find an alias
function Find-Alias {
  param(
    [Parameter(Mandatory)][string]$Command
  )

  # If we can find the alias quickly, do so
  $Alias = $AliasHash[$Command.Trim()]
  if ($Alias) {
    return $Alias
  }

  # TODO check if it is an alias, expand it back out to check if there is a better alias
  
  $Regex = Get-CommandMatcher $Command
  if ($Regex -eq "") {
    return ""
  }
  $SimpleSubRegex ="$([Regex]::Escape($($Command | Format-CleanCommand).Split(" ")[0]))[^`$`n]*\`$"
  
  $Aliases = @("")
  if ($Debug) { Write-Host "`n$Regex`n`n$SimpleSubRegex`n" }

  # Create a new AliasHash with evaluated expression
  $AliasHashEvaluated = $AliasHash.Clone()
  $AliasHash.GetEnumerator() | ForEach-Object {
    if ($_.key -match $Regex) {
      $Aliases += $_.key
    }

    # Substitute commands using ExecutionContext if possible
    # Check if we have anything that has a $(...)
    if ($_.key -match $SimpleSubRegex) {
      $NewKey = Format-CommandAST($_.value)
      if ($NewKey -and $($NewKey -replace '\$args','') -match $Regex) {
        $Aliases += $($NewKey -replace '\$args','').Trim()
        $AliasHashEvaluated[$NewKey] = $_.value
      }
    }
  }
  Clear-AliasTipsInternalASTResults

  if ($Debug) { Write-Host $($Aliases -Join ",") }
  # Use the longest candiate
  $AliasCandidate = ($Aliases | Sort-Object -Descending -Property Length)[0]
  $Alias = ""
  if ($AliasCandidate) {
    $Remaining = "$($Command)"
    $CleanAlias = "$($AliasCandidate)" | Format-CleanCommand
    $AttemptSplit = $CleanAlias -split " "

    $AttemptSplit | ForEach-Object {
      [Regex]$Pattern = [Regex]::Escape("$_")
      $Remaining = $Pattern.replace($Remaining, "", 1)
    }

    if (-not $Remaining) {
      $Alias = ($AliasHashEvaluated[$AliasCandidate]) | Format-CleanCommand
    }
    if ($AliasHashEvaluated[$AliasCandidate + ' $args']) {
      # TODO: Sometimes superflous args aren't at the end... Fix this.
      $Alias = ($AliasHashEvaluated[$AliasCandidate + ' $args'] + $Remaining) | Format-CleanCommand
    }
    if ($Alias -ne $Command) {
      return $Alias
    }
  }
}

function Find-AliasTips {
  $CommandsPattern = Get-CommandsPattern

  $global:AliasTipsProxyFunctionRegex = $CommandsPattern | Get-ProxyFunctionRegex 
  $global:AliasTipsProxyFunctionRegexNoArgs = $CommandsPattern | Get-ProxyFunctionRegexNoArgs

  $script:AliasHash = Get-AliasHash
}

function Start-FindAliasTips {
  if (-not $script:AliasTipsThreadJob) {
    $script:AliasTipsThreadJob = Start-ThreadJob -Name 'Find-AliasTips' -StreamingHost $Host {
      param(
        [Parameter(Mandatory, Position=0)][string]$GetCommandsPattern
      )
      return $(& $([scriptblock]::Create($GetCommandsPattern)))
    } -ThrottleLimit 1 -Arg $(Get-Item -Path Function:\Get-CommandsPattern | Select-Object -ExpandProperty 'Definition')
    $JobResults = $AliasTipsThreadJob | Receive-Job -Wait
    if (-not $Debug) {
      Remove-Job -Name 'Find-AliasTips'
    }
    $global:AliasTipsProxyFunctionRegex = $JobResults | Get-ProxyFunctionRegex
    $global:AliasTipsProxyFunctionRegexNoArgs = $JobResults | Get-ProxyFunctionRegexNoArgs
    $script:AliasHash = Get-AliasHash
    $script:AliasTipsThreadJob = $false
  }
}

if ($LoadAliasOnImport) {
  if ($SynchronousLoad) {
    Find-AliasTips
  } else {
    Start-FindAliasTips
  }
}
