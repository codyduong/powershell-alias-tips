$AliasTipsHashFile = Initialize-EnvVariable "ALIASTIPS_HASH_PATH" "$([System.IO.Path]::Combine("$HOME", '.alias_tips.hash'))"
Initialize-EnvVariable "ALIASTIPS_DISABLE" $false

$AliasTipsHash = @{}
$AliasTipsHashEvaluated = @{}
$script:AliasTipsProxyFunctionRegex, $script:AliasTipsProxyFunctionRegexNoArgs = $null, $null