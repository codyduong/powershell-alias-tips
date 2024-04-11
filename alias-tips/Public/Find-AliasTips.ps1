function Find-AliasTips {
  <#
  .SYNOPSIS

  Finds alias-tips for the current shell context.

  .DESCRIPTION

  Finds alias-tips for the current shell context. This command should be run everytime aliases 
  are updated or changed. It caches the expensive operation to a pipe delimited file in the 
  `$env:AliasTipsHashFile` location. By default this location is at `$HOME/.alias_tips.hash`.

  .EXAMPLE

  PS> Find-AliasTips

  #>
  $AliasTipsHash = Get-Aliases
  $Value = $($AliasTipsHash.GetEnumerator() | ForEach-Object {
      if ($_.Key.Length -ne 0) {
        # Replaces \ with \\
        "$($_.Key -replace "\\", "\\")|$($_.Value -replace "\\", "\\")"
      }
    })

  Set-Content -Path $AliasTipsHashFile -Value $Value
}
