# Store the original PSConsoleHostReadLine function when importing the module
$global:AliasTipsOriginalPSConsoleHostReadLine = $function:PSConsoleHostReadLine

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

Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action {
  $function:PSConsoleHostReadLine = $global:AliasTipsOriginalPSConsoleHostReadLine
}
