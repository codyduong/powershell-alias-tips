# param(
#   [bool]$AliasTipsDebug = 0
# )
# TODO READ FROM CONFIG/ENV VARIABLES

$AliasTipsHashFile = [System.IO.Path]::Combine("$HOME", '.alias_tips.hash')
$AliasTipsHash = @{}
$AliasTipsHashEvaluated = @{}

if ($AliasTipsDebug) { Write-Host $AliasTipsHash.Count }
