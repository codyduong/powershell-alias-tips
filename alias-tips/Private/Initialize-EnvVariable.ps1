function Initialize-EnvVariable {
  param (
    [string]$VariableName,
    [string]$DefaultValue
  )

  $Var = Get-EnvVariable $VariableName
  $Var = if ($null -ne $Var) { $Var } else { $DefaultValue }
  Set-UnsetEnvVariable $VariableName $Var
  $Var
}