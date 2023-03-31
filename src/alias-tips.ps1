. $PSScriptRoot\Command.ps1
. $PSScriptRoot\QuickAlias.ps1

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
    
    $CompleteAlias = $LeftHalf + "$(If ($matches['sep'] == ';') {''} else {' '})$($matches['sep']) " + $RightHalf
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

  if ($alias) {
    # Only react to non-blank lines.
    $tip = "Alias tip: $alias"
    $host.UI.SupportsVirtualTerminal ? "`e[033m$tip`e[m" : $tip | Out-Host
  }
}

# Todo start a thread job
$script:AliasHash = Get-AliasHash

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
  $script:AliasHash = Get-AliasHash
  $global:AliasTipCommandsPattern = Get-CommandsPattern
}
