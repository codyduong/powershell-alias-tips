function Format-Command {
  param(
    [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)][string]${Command}
  )

  return ($Command -replace '`\r?\n', ' ' -replace '\s+', ' ').Trim()
}