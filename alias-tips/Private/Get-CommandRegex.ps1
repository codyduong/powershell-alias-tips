# this naming convention is confusing. This returns a regex to find a command (singular)
function Get-CommandRegex {
  param(
    [Parameter(Mandatory, ValueFromPipeline = $true)][string]${Command},
    [Parameter()][switch]${Simple}
  )

  if ($Simple) {
    $CleanCommand = $Command | Format-Command
    return "(" + ([Regex]::Escape($CleanCommand) -split " " -join "|") + ")"
  }

  # The parse is a bit naive...
  if ($Command -match $AliasTipsProxyFunctionRegexNoArgs) {
    # Clean up the command by removing extra delimiting whitespace and backtick preceding newlines
    $CommandString = ("$($matches['cmd'].TrimStart())") | Format-Command

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