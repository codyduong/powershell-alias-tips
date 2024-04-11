function Enable-AliasTips {
  <#
  .SYNOPSIS

  Enables alias-tips

  .DESCRIPTION

  Enables alias-tips by setting $env:ALIASTIPS_DISABLE to $false

  .INPUTS
  
  None. This function does not accept any input.

  .OUTPUTS
  
  None. This function does not accept any input.

  .EXAMPLE

  PS> Enable-AliasTips

  #>

  [System.Environment]::SetEnvironmentVariable("ALIASTIPS_DISABLE", $false)
}
