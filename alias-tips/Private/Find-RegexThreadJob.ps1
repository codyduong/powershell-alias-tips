function Find-RegexThreadJob {
  if ($null -ne $global:AliasTipsProxyFunctionRegex -and $null -ne $global:AliasTipsProxyFunctionRegexNoArgs) {
    return
  }

  $existingJob = Get-Job -Name "FindAliasTipsJob" -State Running -ErrorAction SilentlyContinue
  if ($null -ne $existingJob) {
    Wait-Job -Job $existingJob
  }
  else {
    $job = Start-RegexThreadJob

    Wait-Job -Job $job
  }
  
  $result = Receive-Job -Name "FindAliasTipsJob" -Wait -AutoRemoveJob

  $global:AliasTipsProxyFunctionRegex, $global:AliasTipsProxyFunctionRegexNoArgs = $result
}