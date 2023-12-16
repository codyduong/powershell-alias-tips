function Get-EnvVariable {
  param (
      [string]$VariableName
  )

  [System.Environment]::GetEnvironmentVariable($VariableName)
}
