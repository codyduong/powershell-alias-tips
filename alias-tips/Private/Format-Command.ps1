function Format-Command {
  param(
    [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)][string]${Command}
  )

  process {
    if ([string]::IsNullOrEmpty($Command)) {
      return $Command
    }

    $tokens = @()
    [void][System.Management.Automation.Language.Parser]::ParseInput($Command, [ref]$tokens, [ref]$null)

    return ($tokens.Text -join " " -replace '\s*\r?\n\s*', ' ').Trim()
  }
}
