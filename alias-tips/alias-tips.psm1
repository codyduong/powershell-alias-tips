$AliasTipsHashFile = Initialize-EnvVariable "ALIASTIPS_HASH_PATH" [System.IO.Path]::Combine("$HOME", '.alias_tips.hash')

$AliasTipsHash = @{}
$AliasTipsHashEvaluated = @{}
