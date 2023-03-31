. $PSScriptRoot\Command.ps1
. $PSScriptRoot\Alias.ps1

function script:SeperateCommand() {
  param(
    [Parameter(Mandatory)][string]$Line
  )

  if ($Line -match "(?<cmd>.*)(?<sep>;|(\|\|)|(&&))(?<rest>.*)") {
    if ($Debug) { Write-Host "Splliting line into $($matches['cmd']), $($matches['sep']), and $($matches['rest'])" }
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

$script:AliasHash

if ($Debug) { Write-Host $AliasHash }

# Attempts to find an alias
function Find-Alias() {
  param(
    [Parameter(Mandatory)][string]$Command
  )

  # If we can find the alias quickly, do so
  $Alias = $AliasHash[$Command.Trim()]
  if ($Alias) {
    return $Alias
  }
  
  $Regex = Get-CommandMatcher $Command
  if ($Regex -eq "") {
    return ""
  }
  
  $Aliases = @("")
  if ($Debug) { Write-Host $Regex }
  $AliasHash.GetEnumerator() | ForEach-Object {
    if ($_.key -match $Regex) {
      $Aliases += $_.key
    }
  }

  if ($Debug) { Write-Host $Aliases }
  # Use the longest candiate
  $Alias = ($Aliases | Sort-Object -Descending -Property Length)[0]
  if ($Alias) {
    $Remaining = "$($Command)"
    $CleanAlias = "$($Alias)" | Format-CleanCommand
    $AttemptSplit = $CleanAlias -split " "

    $AttemptSplit | ForEach-Object {
      [Regex]$Pattern = [Regex]::Escape("$_")
      $Remaining = $Pattern.replace($Remaining, "", 1)
    }

    $Alias = ($AliasHash[$Alias] + $Remaining) | Format-CleanCommand
    if ($Remaining -and $AliasHash[$Alias + ' $args']) {
      $Alias = ($AliasHash[$Alias + ' $args'] + $Remaining) | Format-CleanCommand
    }
    if ($Alias -ne $Command) {
      return $Alias
    }
  }
}

function Find-AliasTips() {
  $CommandsPattern = Get-CommandsPattern

  # THANKS TO csc027 for the original code https://github.com/csc027
  # Taken from: https://github.com/dahlbyk/posh-git/blob/ad8278e90ad8180c18e336676e490d921615e506/src/GitTabExpansion.ps1#L73-L87
  #
  # The regular expression here is roughly follows this pattern:
  #
  # <begin anchor><whitespace>*<command>(<whitespace><parameter>)*<whitespace>+<$args><whitespace>*<end anchor>
  #
  # The delimiters inside the parameter list and between some of the elements are non-newline whitespace characters ([^\S\r\n]).
  # In those instances, newlines are only allowed if they preceded by a non-newline whitespace character.
  #
  # Begin anchor (^|[;`n])
  # Whitespace   (\s*)
  # Any Command  (?<cmd>)
  # Parameters   (?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)
  # $args Anchor (([^\S\r\n]|[^\S\r\n]``\r?\n)+\`$args)
  # Whitespace   (\s|``\r?\n)*
  # End Anchor   ($|[|;`n])
  $global:AliasTipsProxyFunctionRegex = $CommandsPattern | Get-ProxyFunctionRegex 
  $global:AliasTipsProxyFunctionRegexNoArgs = $CommandsPattern | Get-ProxyFunctionRegexNoArgs

  $script:AliasHash = Get-AliasHash
}

function Start-FindAliasTips() {
  if (-not $script:AliasTipsThreadJob) {
    $script:AliasTipsThreadJob = Start-ThreadJob -Name 'Find-AliasTips' -StreamingHost $Host {
      return $(Get-CommandsPattern)
    } -ThrottleLimit 1
    $JobResults = $AliasTipsThreadJob | Receive-Job
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
