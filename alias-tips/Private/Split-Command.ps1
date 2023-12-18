function Split-Command {
  param(
    [Parameter(Mandatory)][string]$Line
  )

  $tokens = @()
  [void][System.Management.Automation.Language.Parser]::ParseInput($Line, [ref]$tokens, [ref]$null)

  $queue = [System.Collections.ArrayList]::new()
  $aliased = ""

  foreach ($token in $tokens) {
    $kind = $token.Kind
    if ('Generic', 'StringLiteralToken', 'Generic', 'Identifier' -contains $kind) {
      if ($queue.Count -gt 0) {
        $queue[-1] = "$($queue[-1]) $($token.Text)"
      }
      else {
        $queue += $token.Text
      }
    }
    else {
      # When we finish the current token back-alias it
      if ($queue.Count -gt 0) {
        $alias = Find-Alias $queue[-1]
        Write-Warning $queue[-1]
        $aliased += if ([string]::IsNullOrEmpty($alias)) { $token.Text } else { $alias }
      }
      # TODO: Whitespace preservation? Might require a custom tokenizer
      if ('AtCurly', 'AtParen', 'DollarParen', 'LBracket', 'LCurly', 'LParen' -contains $kind) {
        $aliased += " $($token.Text)"
      } elseif ('RBracket', 'RCurly', 'RParen' -contains $kind) {
        $aliased += "$($token.Text) "
      } else {
        $aliased += " $($token.Text) "
      }

      $queue += ""
    }
  }

  $aliased
}
