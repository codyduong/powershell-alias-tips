# Store the original PSConsoleHostReadLine function when importing the module
$script:AliasTipsOriginalPSConsoleHostReadLine = Get-Item Function:\PSConsoleHostReadLine -ErrorAction SilentlyContinue

function PSConsoleHostReadLine {
  ## Get the execution status of the last accepted user input.
  ## This needs to be done as the first thing because any script run will flush $?.
  $lastRunStatus = $?

  ($Line = [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus))

  if ([System.Environment]::GetEnvironmentVariable("ALIASTIPS_DISABLE") -eq [string]$true) {
    return
  }

  # split line into multiple commands if possible
  $alias = Find-Alias $Line

  if (-not [string]::IsNullOrEmpty($alias) -and ($alias | Format-Command) -ne ($Line | Format-Command)) {
    $tip = (Initialize-EnvVariable "ALIASTIPS_MSG" "Alias tip: {0}") -f $alias
    $vtTip = (Initialize-EnvVariable "ALIASTIPS_MSG_VT" "`e[033mAlias tip: {0}`e[m") -f $alias
    if ($tip -eq "") {
      Write-Warning "Error formatting ALIASTIPS_MSG"
    }
    if ($vtTip -eq "") {
      Write-Warning "Error formatting ALIASTIPS_MSG_VT"
    }
    $host.UI.SupportsVirtualTerminal ? $vtTip : $tip | Out-Host
  }
}

$DEFAULT_PSConsoleHostReadLine = {
  [System.Diagnostics.DebuggerHidden()]
  param()

  ## Get the execution status of the last accepted user input.
  ## This needs to be done as the first thing because any script run will flush $?.
  $lastRunStatus = $?
  Microsoft.PowerShell.Core\Set-StrictMode -Off
  [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus)
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  if ($null -eq $script:AliasTipsOriginalPSConsoleHostReadLine) {
    $script:AliasTipsOriginalPSConsoleHostReadLine = $DEFAULT_PSConsoleHostReadLine
  }
  $toFixStr = "Set-Item Function:\PSConsoleHostReadLine -Value `$AliasTipsOriginalPSConsoleHostReadLine"
  @"
`e[1;31mRemoved module alias-tips!`e[m `e[36mTo restore your PSReadline, run:`e[m
$toFixStr
`e[36mIt has been copied into your clipboard for your convenience`e[m
"@ | Out-Host
  Set-Clipboard -Value $toFixStr
  # TODO is there a way to restore this automagically??
  Set-Item Function:\PSConsoleHostReadLine -Value $script:AliasTipsOriginalPSConsoleHostReadLine -Force
}
