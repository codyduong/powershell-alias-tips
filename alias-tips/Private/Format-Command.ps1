function Format-Command {
  param(
    [Parameter(Position = 0, ValueFromPipeline = $true)][string]${Command}
  )

  process {
    if ([string]::IsNullOrEmpty($Command)) {
      return $Command
    }

    return ($Command -replace '`\r?\n', ' ' -replace '\s+', ' ').Trim()
  }
}
