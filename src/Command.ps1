function Get-CommandsPattern() {
  (Get-Command * | ForEach-Object {
    $CommandUnsafe = $_ | Select-Object -ExpandProperty 'Name'
    $Command = [Regex]::Escape($CommandUnsafe)
    # check if it has a file extensions
    if ($CommandUnsafe -match "(?<cmd>[^.\s]+)\.(?<ext>[^.\s]+)$") {
      $CommandWithoutExtension = [Regex]::Escape($matches['cmd'])
      return $Command, $CommandWithoutExtension
    } else {
      return $Command
    }
  }) -Join '|'
}

$global:AliasTipCommandsPattern = Get-CommandsPattern

# THANKS TO csc027 for the original code https://github.com/csc027
# Taken from: https://github.com/dahlbyk/posh-git/blob/ad8278e90ad8180c18e336676e490d921615e506/src/GitTabExpansion.ps1#L73-L87
#
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
$ProxyFunctionRegex = "(^|[;`n])(\s*)(?<cmd>($AliasTipCommandsPattern))(?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)(([^\S\r\n]|[^\S\r\n]``\r?\n)+\`$args)(\s|``\r?\n)*($|[|;`n])"
$ProxyFunctionRegexNoArgs = "(^|[;`n])(\s*)(?<cmd>($AliasTipCommandsPattern))(?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)(\s|``\r?\n)*($|[|;`n])"

function Format-CleanCommand() {
  param(
    [Parameter(Mandatory, ValueFromPipeline = $true)][string]${Command}
  )

  return ($Command -replace '`\r?\n', ' ' -replace '\s+', ' ').Trim()
}

# Returns a regex to match with
function Get-CommandMatcher() {
  param(
    [Parameter(Mandatory, ValueFromPipeline = $true)][string]${Command},
    [Parameter()][switch]${Simple}
  )

  if ($Simple) {
    $CleanCommand = $Command | Format-CleanCommand
    return "(" + ([Regex]::Escape($CleanCommand) -split " " -join "|") + ")"
  }

  # The parse is a bit naive...
  if ($Command -match $ProxyFunctionRegexNoArgs) {
    # Clean up the command by removing extra delimiting whitespace and backtick preceding newlines
    $CommandString = ("$($matches['cmd'].TrimStart())") | Format-CleanCommand

    $ReqParams = $($matches['params']) -split " "
    # $ReqParamLength = $ReqParams.Count
    $ReqParamRegex = "(" + ($ReqParams.ForEach({
          "$([Regex]::Escape($_.Trim()))(\s|``\r?\n)*"
        }) -join '|') + ")*"

    # Enable sensitive case (?-i)
    # Begin anchor      (^|[;`n])
    # Whitespace        (\s*)
    # Any Command       (?<cmd>$CommandString)
    # Whitespace        (\s|``\r?\n)*
    # Req Parameters    (?<params>$ReqParamRegex)
    # Req Param Length  {$ReqParamLength,}
    # Whitespace        (\s|``\r?\n)*
    # End Anchor        ($|[|;`n])
    #$Regex = "(^|[;`n])(\s*)(?<cmd>$CommandString)(?<params>$ReqParamRegex{$ReqParamLength,})(\s|``\r?\n)*($|[|;`n])"
    $Regex = "(?-i)(^|[;`n])(\s*)(?<cmd>$CommandString)(\s|``\r?\n)*(?<params>$ReqParamRegex)(\s|``\r?\n)*($|[|;`n])"

    return $Regex
  }

  return ""
}
