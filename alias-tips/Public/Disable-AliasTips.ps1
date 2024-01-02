function Disable-AliasTips {
  [System.Environment]::SetEnvironmentVariable("ALIASTIPS_DISABLE", $true)
}
