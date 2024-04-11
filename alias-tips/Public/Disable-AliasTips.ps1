function Disable-AliasTips {
  <#
  .SYNOPSIS

  Disables alias-tips

  .DESCRIPTION

  Disables alias-tips by setting $env:ALIASTIPS_DISABLE to $true

  .INPUTS
  
  None. This function does not accept any input.

  .OUTPUTS
  
  None. This function does not accept any input.

  .EXAMPLE

  PS> Disable-AliasTips

  #>
  [System.Environment]::SetEnvironmentVariable("ALIASTIPS_DISABLE", $true)
}
