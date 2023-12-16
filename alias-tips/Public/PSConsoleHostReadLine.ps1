# Store the original PSConsoleHostReadLine function when importing the module
$global:AliasTipsOriginalPSConsoleHostReadLine = $function:PSConsoleHostReadLine

function PSConsoleHostReadLine {
  ## Get the execution status of the last accepted user input.
  ## This needs to be done as the first thing because any script run will flush $?.
  $lastRunStatus = $?

  ($Line = [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus))

  # split line into multiple commands if possible
  $alias = Split-Command $Line

  if ($alias -and -not $AliasTipsThreadJob -and $AliasTipsHash.Length -gt 0) {
    # Only react to non-blank lines.
    $tip = "Alias tip: $alias"
    $host.UI.SupportsVirtualTerminal ? "`e[033m$tip`e[m" : $tip | Out-Host
  }
}

Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action {
  $function:PSConsoleHostReadLine = $global:AliasTipsOriginalPSConsoleHostReadLine
}