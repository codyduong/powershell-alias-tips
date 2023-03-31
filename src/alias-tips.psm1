param(
  [bool]$Debug
)

# $PSConsoleHostReadLineDef = if ($funcInfo = Get-Command PSConsoleHostReadLine -ErrorAction SilentlyContinue) { $funcInfo.Definition }

. $PSScriptRoot\tips.ps1

# TODO PREVENT OVERWRITE OF EXISTING PSCONSOLEHOSTREADLINE
$script:DefaultPSConsoleHostReadlineDef = {
  ## Get the execution status of the last accepted user input.
  ## This needs to be done as the first thing because any script run will flush $?.
  $lastRunStatus = $?
  Microsoft.PowerShell.Core\Set-StrictMode -Off
  [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus)
}

$exportModuleMemberParams = @{
  Function = @(
    'PSConsoleHostReadLine',
    'Find-AliasTips'
  )
  Variable = @()
}

Export-ModuleMember @exportModuleMemberParams