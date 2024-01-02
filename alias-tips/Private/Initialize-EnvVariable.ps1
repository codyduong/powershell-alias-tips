function Initialize-EnvVariable {
  param (
    [Parameter(Mandatory = $true, Position = 0)][string]$VariableName,
    [Parameter(Position = 1)][string]$DefaultValue
  )

  $Var = Get-EnvVariable $VariableName
  $Var = if ($null -ne $Var) { $Var } else { $DefaultValue }
  Set-UnsetEnvVariable $VariableName $Var
  $Var
}
