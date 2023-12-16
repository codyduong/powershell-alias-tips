function Set-UnsetEnvVariable {
  param (
    [string]$VariableName,
    [string]$Value
  )

  # Check if the environment variable is already set
  if (-not [System.Environment]::GetEnvironmentVariable($VariableName)) {
    # Set the environment variable
    [System.Environment]::SetEnvironmentVariable($VariableName, $Value)
  }
}