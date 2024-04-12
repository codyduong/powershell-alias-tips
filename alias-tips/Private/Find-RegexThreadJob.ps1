function Find-RegexThreadJob {
  if ($null -ne $script:AliasTipsProxyFunctionRegex -and $null -ne $script:AliasTipsProxyFunctionRegexNoArgs) {
    return
  }

  $existingJob = Get-Job -Name "FindAliasTipsJob" -ErrorAction SilentlyContinue | Select-Object -Last 1
  if ($null -ne $existingJob) {
    $existingJob = Wait-Job -Job $existingJob
  }
  else {
    $job = Start-RegexThreadJob

    $existingJob = Wait-Job -Job $job
  }
  $result = Receive-Job -Job $existingJob -Wait -AutoRemoveJob

  # this is a regex to find all commands, not just aliases/functions
  $script:AliasTipsProxyFunctionRegex, $script:AliasTipsProxyFunctionRegexNoArgs = $result
}