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

$Version = $(Import-PowerShellDataFile (Join-Path $PSScriptRoot "..\alias-tips\alias-tips.psd1")).ModuleVersion
$Path = if ([string]::IsNullOrEmpty($Path)) { Join-Path $PSScriptRoot "..\Output\alias-tips\$Version" } else { $Path }
$NuGetApiKey = if ([string]::IsNullOrEmpty($NuGetApiKey)) { "$(Get-Content -Path .env)" -replace ".*=" } else { $NuGetApiKey }
[void]$PSBoundParameters.Remove('Publish')
# Remove-Item $Path -Include ** -Recurse -ErrorAction SilentlyContinue
# New-Item -Path $Path -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
# Copy-Item src/** -Destination $Path -Include **
Remove-Item (Join-Path $Path ".\en-US") -Include ** -Recurse -ErrorAction SilentlyContinue
Publish-Module -Path $Path -NuGetApiKey $NuGetApiKey -Verbose -WhatIf:$(-not $Publish) @PSBoundParameters