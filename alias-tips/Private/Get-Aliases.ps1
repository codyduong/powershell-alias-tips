# Return a hashtable of possible aliases
function Get-Aliases {
  $Hash = @{}

  # generate aliases for commands aliases created via native PowerShell functions
  $proxyAliases = Get-Item -Path Function:\
  foreach ($alias in $proxyAliases) {
    $f = Get-Item -Path Function:\$alias
    $ProxyName = $f | Select-Object -ExpandProperty 'Name'
    $ProxyDef = $f | Select-Object -ExpandProperty 'Definition'
    # validate there is a command
    if ($ProxyDef -match $AliasTipsProxyFunctionRegex) {
      $CleanedCommand = ("$($matches['cmd'].TrimStart()) $($matches['params'])") | Format-Command
      if ($ProxyDef -match '\$args') {
        $Hash[$CleanedCommand + ' $args'] = $ProxyName
      }

      # quick alias
      $Hash[$CleanedCommand] = $ProxyName
    }
  }

  # generate aliases configured from the `Set-Alias` command
  Get-Alias | ForEach-Object {
    $aliasName = $_ | Select-Object -ExpandProperty 'Name'
    $aliasDef = $($_ | Select-Object -ExpandProperty 'Definition') | Format-Command
    $hash[$aliasDef] = $aliasName
    $hash[$aliasDef + ' $args'] = $aliasName
  }

  return $hash
}
