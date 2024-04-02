function Find-Alias {
  <#
  .SYNOPSIS

  Finds an alias for a command string.

  .DESCRIPTION

  Finds an alias for a command string. Returns the original line if no aliases are found.

  .PARAMETER Line

  Specifies the line to find an alias for.

  .INPUTS

  [System.String](https://docs.microsoft.com/en-us/dotnet/api/system.string)

  .OUTPUTS

  [System.String](https://docs.microsoft.com/en-us/dotnet/api/system.string)

  .EXAMPLE

  PS> Find-Alias "git checkout master"
  Outputs the alias for 'git checkout master', if it exists. Otherwise it returns the original string.

  .EXAMPLE

  PS> "git status" | Find-Alias
  Outputs the alias for 'git status', if it exists. Otherwise it returns the original string.

  #>
  param(
    [Parameter(Mandatory, ValueFromPipeline = $true)]
    [string]$Line
  )

  process {
    if ($AliasTipsHash -and $AliasTipsHash.Count -eq 0) {
      $AliasTipsHash = ConvertFrom-StringData -StringData $([System.IO.File]::ReadAllText($AliasTipsHashFile)) -Delimiter "|"
    }

    $tokens = @()
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Line, [ref]$tokens, [ref]$null)

    $fastAlias = Find-AliasCommand ($tokens.Text -join " ")

    # fastAlias is not appreciably faster but is definetly less stable, disable for now?
    # if (-not [string]::IsNullOrEmpty($fastAlias)) {
    #   Write-Verbose "Found alias without resorting to parsing"
    #   return $fastAlias
    # }

    $queue = [System.Collections.ArrayList]::new()
    $extents = @(0, 0)
    $offset = 0
    $aliased = $ast.ToString()

    foreach ($token in $tokens) {
      $kind = $token.Kind
      Write-Verbose "$(($kind, "'$($token.Text)'" , $token.Extent.StartOffset, $token.Extent.EndOffset))"
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
}
