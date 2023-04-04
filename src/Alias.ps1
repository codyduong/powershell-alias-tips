. $PSScriptRoot\Command.ps1

# Return a naive hashtable of possible aliases
function Get-AliasHash() {
  $Hash = @{}

  # generate aliases for commands aliases via function
  $proxyAliases = Get-Item -Path Function:\
  foreach($alias in $proxyAliases) {
    $f = Get-Item -Path Function:\$alias
    $ProxyName = $f | Select-Object -ExpandProperty 'Name'
    $ProxyDef = $f | Select-Object -ExpandProperty 'Definition'
    # validate there is a command
    if ($ProxyDef -match $AliasTipsProxyFunctionRegex) {
      $CleanedCommand = ("$($matches['cmd'].TrimStart()) $($matches['params'])") | Format-CleanCommand
      if ($ProxyDef -match '\$args') {
        $Hash[$CleanedCommand + ' $args'] = $ProxyName
      }

      # quick alias
      $Hash[$CleanedCommand] = $ProxyName
    }
  }

  Get-Alias | ForEach-Object {
    $aliasName = $_ | Select-Object -ExpandProperty 'Name'
    $aliasDef = $($_ | Select-Object -ExpandProperty 'Definition') | Format-CleanCommand
    $hash[$aliasDef] = $aliasName
  }

  return $hash
}
