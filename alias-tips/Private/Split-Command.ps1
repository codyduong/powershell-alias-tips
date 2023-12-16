
function Split-Command {
  param(
    [Parameter(Mandatory)][string]$Line
  )

  if ($Line -match "(?<cmd>.*)(?<sep>;|(\|\|)|(\|)|(&&))(?<rest>.*)") {
    if ($AliasTipsDebug) { Write-Host "Splitting line into $($matches['cmd']), $($matches['sep']), and $($matches['rest'])" }
    $LeftHalf = Find-Alias($matches['cmd'])
    $RightHalf = Split-Command $($matches['rest'])

    # If the left half isn't found restore the left half
    if (-not $LeftHalf) { $LeftHalf = $matches['cmd'] | Format-Command }
    # If the right half isn't found restore the right half
    if (-not $RightHalf) { $RightHalf = $matches['rest'] | Format-Command }

    $CompleteAlias = $($LeftHalf + "$(If ($matches['sep'] -eq ';') {''} else {' '})$($matches['sep']) " + $RightHalf) | Format-Command
    # only return the alias if it is different from the line
    if ($CompleteAlias -ne $($Line | Format-Command)) {
      return $CompleteAlias
    }
  }
  else {
    return Find-Alias($Line)
  }
}