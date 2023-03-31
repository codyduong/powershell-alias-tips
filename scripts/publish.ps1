[CmdletBinding(
  DefaultParameterSetName='ModuleNameParameterSet', 
  SupportsShouldProcess=$true, 
  ConfirmImpact='Medium', 
  PositionalBinding=$false, 
  HelpUri='https://go.microsoft.com/fwlink/?LinkID=398575')
]
param(
    [Parameter(ParameterSetName='ModuleNameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Name},

    [Parameter(ParameterSetName='ModulePathParameterSet', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [Parameter(ParameterSetName='ModuleNameParameterSet')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${RequiredVersion},

    [string]
    ${NuGetApiKey},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Repository},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [ValidateSet('2.0')]
    [version]
    ${FormatVersion},

    [string[]]
    ${ReleaseNotes},

    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Tags},

    [ValidateNotNullOrEmpty()]
    [uri]
    ${LicenseUri},

    [ValidateNotNullOrEmpty()]
    [uri]
    ${IconUri},

    [ValidateNotNullOrEmpty()]
    [uri]
    ${ProjectUri},

    [Parameter(ParameterSetName='ModuleNameParameterSet')]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Exclude},

    [switch]
    ${Force},

    [Parameter(ParameterSetName='ModuleNameParameterSet')]
    [switch]
    ${AllowPrerelease},

    [switch]
    ${SkipAutomaticTags},

    [Parameter()][switch]$Publish
)

$Name = if ([string]::IsNullOrEmpty($Name)) { 'alias-tips' } else { $Name }
$NuGetApiKey = if ([string]::IsNullOrEmpty($NuGetApiKey)) { "$(Get-Content -Path .env)" -replace ".*=" } else { $NuGetApiKey }

Copy-Item src/** -Destination $Name -Include **
if ($Publish -ne $true) {
  Publish-Module -Name $Name -NuGetApiKey $NuGetApiKey -WhatIf @PSBoundParameters
} else {
  Publish-Module -Name $Name -NuGetApiKey $NuGetApiKey @PSBoundParameters
}