function Get-CommandRegex {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory, ValueFromPipeline = $true)]
      [string]${Command},

      [Parameter()]
      [switch]${Simple}
  )

  process {
      if ($Simple) {
          $CleanCommand = $Command | Format-Command
          return "(" + ([Regex]::Escape($CleanCommand) -split " " -join "|") + ")"
      }

      # The parse is a bit naive...
      if ($Command -match $AliasTipsProxyFunctionRegexNoArgs) {
          # Clean up the command by removing extra delimiting whitespace and backtick preceding newlines
          $CommandString = ("$($matches['cmd'].TrimStart())") | Format-Command

          if ([string]::IsNullOrEmpty($CommandString)) {
            return ""
          }

          $ReqParams = $($matches['params']) -split " "
          $ReqParamRegex = "(" + ($ReqParams.ForEach({
                  "$([Regex]::Escape($_.Trim()))(\s|``\r?\n)*"
              }) -join '|') + ")*"

          # Enable sensitive case (?-i)
          # Begin anchor      (^|[;`n])
          # Whitespace        (\s*)
          # Any Command       (?<cmd>$CommandString)
          # Whitespace        (\s|``\r?\n)*
          # Req Parameters    (?<params>$ReqParamRegex)
          # Whitespace        (\s|``\r?\n)*
          # End Anchor        ($|[|;`n])
          $Regex = "(?-i)(^|[;`n])(\s*)(?<cmd>$CommandString)(\s|``\r?\n)*(?<params>$ReqParamRegex)(\s|``\r?\n)*($|[|;`n])"

          return $Regex
      }
  }
}
