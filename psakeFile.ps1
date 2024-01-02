properties {
  # Build settings
  $PSBPreference.Build.CompileModule = $true
  # $PSBPreference.Build.CopyDirectories = @('Data')
  $PSBPreference.Build.CompileHeader = @'
using namespace System.Management.Automation
using namespace System.Collections.ObjectModel
'@

  # Test settings
  $PSBPreference.Test.ImportModule = $true
  $PSBPreference.Test.OutputFile = [IO.Path]::Combine($PSBPreference.Build.OutDir, 'testResults.xml')
  $PSBPreference.Test.ScriptAnalysis.SettingsPath = [IO.Path]::Combine($PSBPreference.Test.RootDir, 'ScriptAnalyzerSettings.psd1')

  if ($galleryApiKey) {
    $PSBPreference.Publish.PSRepositoryApiKey = $galleryApiKey.GetNetworkCredential().password
  } 
}

task default -depends Test

task Pester -FromModule PowerShellBuild -Version '0.6.1' -preaction { Remove-Module alias-tips -ErrorAction SilentlyContinue }
