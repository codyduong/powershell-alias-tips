function Start-RegexThreadJob {
  $existingJob = Get-Job -Name "FindAliasTipsJob" -ErrorAction SilentlyContinue | Select-Object -Last 1
  if ($null -ne $existingJob) {
    $existingJob = Wait-Job -Job $existingJob
  }

  return Start-ThreadJob -Name "FindAliasTipsJob" -ScriptBlock {
    function Get-CommandsRegex {
      (Get-Command * | ForEach-Object {
        $CommandUnsafe = $_ | Select-Object -ExpandProperty 'Name'
        $Command = [Regex]::Escape($CommandUnsafe)
        # check if it has a file extensions
        if ($CommandUnsafe -match "(?<cmd>[^.\s]+)\.(?<ext>[^.\s]+)$") {
          $CommandWithoutExtension = [Regex]::Escape($matches['cmd'])
          return $Command, $CommandWithoutExtension
        }
        else {
          return $Command
        }
      }) -Join '|'
    }

    # The regular expression here roughly follows this pattern:
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
    function Get-ProxyFunctionRegexes {
      param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)][regex]${CommandPattern}
      )

      process {
        [regex]"(^|[;`n])(\s*)(?<cmd>($CommandPattern))(?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)(([^\S\r\n]|[^\S\r\n]``\r?\n)+\`$args)(\s|``\r?\n)*($|[|;`n])",
        [regex]"(^|[;`n])(\s*)(?<cmd>($CommandPattern))(?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)(\s|``\r?\n)*($|[|;`n])"
      }
    }

    Get-CommandsRegex | Get-ProxyFunctionRegexes
  }
}

Start-RegexThreadJob | Out-Null