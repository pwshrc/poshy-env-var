#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $NUGET_KEY,

    [switch] $WhatIf
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


$ds = [System.IO.Path]::DirectorySeparatorChar
[System.IO.FileInfo[]] $psgallery_nupkg = Get-ChildItem -Path "${PSScriptRoot}${ds}..${ds}out" -Filter "*.nupkg" -Recurse -File -Force -ErrorAction SilentlyContinue
if (-not $psgallery_nupkg) {
    throw "No NuGet packages were found in '${PSScriptRoot}${ds}..${ds}out'."
}
if ($psgallery_nupkg.Count -gt 1) {
    throw "Multiple NuGet packages were found in '${PSScriptRoot}${ds}..${ds}out'. Did you forget to clean?"
}
[string] $package_expanded = "${PSScriptRoot}${ds}..${ds}out${ds}$($psgallery_nupkg[0].BaseName)"
if (Test-Path $package_expanded -ErrorAction SilentlyContinue) {
    throw "The directory '${package_expanded}' already exists. Did you forget to clean?"
}
Expand-Archive -Path $psgallery_nupkg[0].FullName -DestinationPath $package_expanded -Force | Out-Null
[System.IO.FileInfo] $psd1 = Get-ChildItem -Path $package_expanded -Filter "*.psd1" -Recurse -File -Force | Out-Null
[hashtable] $psd1_data = Import-PowerShellDataFile -Path $psd1[0].FullName
Move-Item -Path $package_expanded -Destination $psd1.BaseName -Force | Out-Null


Publish-Module `
    -Path $psd1.BaseName `
    -NuGetApiKey $NUGET_KEY `
    -ReleaseNotes $psd1_data.PrivateData.PSData.ReleaseNotes `
    -Tags $psd1_data.PrivateData.PSData.Tags `
    -LicenseUri $psd1_data.PrivateData.PSData.LicenseUri `
    -IconUri $psd1_data.PrivateData.PSData.IconUri `
    -ProjectUri $psd1_data.PrivateData.PSData.ProjectUri `
    -WhatIf:$WhatIf
