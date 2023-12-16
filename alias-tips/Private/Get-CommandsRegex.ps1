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