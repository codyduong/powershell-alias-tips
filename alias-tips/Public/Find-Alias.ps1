# Attempts to find an alias for a command string (ie. can consist of chained or nested aliases)
function Find-Alias {
  param(
    [Parameter(Mandatory)][string]$Line
  )

  $tokens = @()
  $ast = [System.Management.Automation.Language.Parser]::ParseInput($Line, [ref]$tokens, [ref]$null)

  $fastAlias = Find-AliasCommand ($tokens.Text -join " ")

  if (-not [string]::IsNullOrEmpty($fastAlias)) {
    Write-Verbose "Found alias without resorting to parsing"
    return $fastAlias
  }

  $queue = [System.Collections.ArrayList]::new()
  $extents = @(0, 0)
  $offset = 0
  $aliased = $ast.ToString()

  foreach ($token in $tokens) {
    $kind = $token.Kind
    # Write-Host ($kind, "'$($token.Text)'" , $token.Extent.StartOffset, $token.Extent.EndOffset)
    if ('Generic', 'Identifier', 'HereStringLiteral', 'Parameter', 'StringLiteral' -contains $kind) {
      if ($queue.Count -eq 0) {
        $queue += $token.Text
        $extents = @($token.Extent.StartOffset, $token.Extent.EndOffset)
      }
      else {
        $queue[-1] = "$($queue[-1]) $($token.Text)"
        $extents = @($extents[0], $token.Extent.EndOffset)
      }
    }
    else {
      # When we finish the current token back-alias it
      if ($queue.Count -gt 0) {
        $alias = Find-AliasCommand $queue[-1]
        if (-not [string]::IsNullOrEmpty($alias)) {
          $saved = $queue[-1].Length - $alias.Length
          $newleft = $extents[0] + $offset
          $newright = $extents[1] + $offset
          $aliased = "$(if ($newLeft -le 0) {''} else {$aliased.Substring(0, $newLeft)})$alias$(if ($newright -ge $aliased.Length) {''} else {$aliased.Substring($newright)})"
          $offset -= $saved
        }
      }

      # Reset the queue
      $queue = [System.Collections.ArrayList]::new()
      $extents = @(0, 0)

      if ('HereStringExpandable', 'StringExpandable' -contains $kind) {
        $ntokens = $token.NestedTokens
        if ($ntokens.Length -eq 0) {
          continue
        }
        $nqueue = [System.Collections.ArrayList]::new()
        $nextents = @(0, 0)
        foreach ($ntoken in $ntokens) {
          $nkind = $ntoken.Kind
          # Write-Host ("`t", $nkind, "'$($ntoken.Text)'" , $ntoken.Extent.StartOffset, $ntoken.Extent.Endoffset)
          if ('Generic', 'Identifier', 'HereStringLiteral', 'Parameter', 'StringLiteral' -contains $nkind) {
            if ($nqueue.Count -eq 0) {
              $nqueue += $ntoken.Text
              $nextents = @($ntoken.Extent.StartOffset, $ntoken.Extent.EndOffset)
            }
            else {
              $nqueue[-1] = "$($nqueue[-1]) $($ntoken.Text)"
              $nextents = @($nextents[0], $ntoken.Extent.EndOffset)
            }
          }
          else {
            # When we finish the current token back-alias it
            if ($nqueue.Count -gt 0) {
              $alias = Find-AliasCommand $nqueue[-1]
              if (-not [string]::IsNullOrEmpty($alias)) {
                $saved = $nqueue[-1].Length - $alias.Length
                $newleft = $nextents[0] + $offset
                $newright = $nextents[1] + $offset
                $aliased = "$(if ($newLeft -le 0) {''} else {$aliased.Substring(0, $newLeft)})$alias$(if ($newright -ge $aliased.Length) {''} else {$aliased.Substring($newright)})"
                $offset -= $saved
              }
            }

            # Reset the queue
            $nqueue = [System.Collections.ArrayList]::new()
            $nextents = @(0, 0)
          }
        }
      }
    }
  }

  $aliased.Trim()
}
