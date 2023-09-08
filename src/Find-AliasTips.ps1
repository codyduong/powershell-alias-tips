. $PSScriptRoot\Command.ps1


# The regular expression here is roughly follows this pattern:
#
# <begin anchor><whitespace>*<command>(<whitespace><parameter>)*<whitespace>+<$args><whitespace>*<end anchor>
#
# The delimiters inside the parameter list and between some of the elements are non-newline whitespace characters ([^\S\r\n]).
# In those instances, newlines are only allowed if they preceded by a non-newline whitespace character.
#
# Begin anchor (^|[;`n])
# Whitespace   (\s*)
# Any Command  (?<cmd>)
# Parameters   (?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)
# $args Anchor (([^\S\r\n]|[^\S\r\n]``\r?\n)+\`$args)
# Whitespace   (\s|``\r?\n)*
# End Anchor   ($|[|;`n])
function script:Get-ProxyFunctionRegex {
  param (
    [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)][string]${CommandPattern}
  )

  "(^|[;`n])(\s*)(?<cmd>($CommandPattern))(?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)(([^\S\r\n]|[^\S\r\n]``\r?\n)+\`$args)(\s|``\r?\n)*($|[|;`n])"
}


function script:Get-ProxyFunctionRegexNoArgs {
  param (
    [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)][string]${CommandPattern}
  )

  "(^|[;`n])(\s*)(?<cmd>($CommandPattern))(?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)(\s|``\r?\n)*($|[|;`n])"
}


# Return a hashtable of possible aliases
function script:Get-Aliases {
  $Hash = @{}

  # generate aliases for commands aliases via function
  $proxyAliases = Get-Item -Path Function:\
  foreach ($alias in $proxyAliases) {
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
    $hash[$aliasDef + ' $args'] = $aliasName
  }

  return $hash
}


function Find-AliasTips {
  $CommandsPattern = Get-CommandsPattern

  $global:AliasTipsProxyFunctionRegex = $CommandsPattern | Get-ProxyFunctionRegex 
  $global:AliasTipsProxyFunctionRegexNoArgs = $CommandsPattern | Get-ProxyFunctionRegexNoArgs

  $AliasTipsHash = Get-Aliases
  $Value = $($AliasTipsHash.GetEnumerator() | ForEach-Object {
    if ($_.Key.Length -ne 0) {
      # Replaces \ with \\
      "$($_.Key -replace "\\", "\\")|$($_.Value -replace "\\", "\\")"
    }
  })
  Set-Content -Path $AliasTipsHashFile -Value $Value
}
