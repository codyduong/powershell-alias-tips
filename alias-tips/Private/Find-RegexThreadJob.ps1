function Find-RegexThreadJob {
  if ($null -ne $global:AliasTipsProxyFunctionRegex -and $null -ne $global:AliasTipsProxyFunctionRegexNoArgs) {
    return
  }

  $existingJob = Get-Job -Name "FindAliasTipsJob"
  if ($null -ne $existingJob) {
    $existingJob = Wait-Job -Job $existingJob
  }
  else {
    $job = Start-RegexThreadJob

    $existingJob = Wait-Job -Job $job
  }
  $result = Receive-Job -Job $existingJob -Wait -AutoRemoveJob

  $global:AliasTipsProxyFunctionRegex, $global:AliasTipsProxyFunctionRegexNoArgs = $result
}