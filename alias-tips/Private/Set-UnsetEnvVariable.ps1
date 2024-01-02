function Set-UnsetEnvVariable {
  [CmdletBinding(SupportsShouldProcess=$true)]
  param (
    [string]$VariableName,
    [string]$Value
  )

  # Check if the environment variable is already set
  if (-not [System.Environment]::GetEnvironmentVariable($VariableName)) {
    # Set the environment variable
    if($PSCmdlet.ShouldProcess($VariableName)){
      [System.Environment]::SetEnvironmentVariable($VariableName, $Value)
    }
  }
}
