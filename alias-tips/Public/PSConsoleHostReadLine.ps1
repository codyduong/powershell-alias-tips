# Store the original PSConsoleHostReadLine function when importing the module
$global:AliasTipsOriginalPSConsoleHostReadLine = $function:PSConsoleHostReadLine

function PSConsoleHostReadLine {
  ## Get the execution status of the last accepted user input.
  ## This needs to be done as the first thing because any script run will flush $?.
  $lastRunStatus = $? 

  ($Line = [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus))

  # split line into multiple commands if possible
  $alias = Split-Command $Line

  if ($alias) {
    $tip = (Initialize-EnvVariable "ALIASTIPS_MESSAGE" "Alias tip: {0}") -f $alias
    $vtTip = (Initialize-EnvVariable "ALIASTIPS_TEMPLATE" "`e[033m{0}`e[m") -f $tip
    if ($tip -eq "") {
      Write-Warning "Error formatting ALIASTIPS_MESSAGE"
    }
    if ($vtTip -eq "") {
      Write-Warning "Error formatting ALIASTIPS_TEMPLATE"
    }
    $host.UI.SupportsVirtualTerminal ? $vtTip : $tip | Out-Host
  }
}

Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action {
  $function:PSConsoleHostReadLine = $global:AliasTipsOriginalPSConsoleHostReadLine
}
