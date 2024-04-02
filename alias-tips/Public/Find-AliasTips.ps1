function Find-AliasTips {
  $AliasTipsHash = Get-Aliases
  $Value = $($AliasTipsHash.GetEnumerator() | ForEach-Object {
      if ($_.Key.Length -ne 0) {
        # Replaces \ with \\
        "$($_.Key -replace "\\", "\\")|$($_.Value -replace "\\", "\\")"
      }
    })

  Set-Content -Path $AliasTipsHashFile -Value $Value
}
