#!/usr/bin/env pwsh
# Take all the PowerShell module content in ../src and package it as a NuPkg.
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $PackageVersionNuGet,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $PackageVersionMajorMinorPatchBuild,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $PackageVersionPrereleaseTag,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ReleaseNotes,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Commitish
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

[string] $ds = [System.IO.Path]::DirectorySeparatorChar
[string[]] $authors = @(
    "Pwshrc Maintainers"
)
[string] $companyName = "Pwshrc Maintainers"
[string] $repositoryGitUrl = (git remote get-url origin)
[string] $PackageId = $repositoryGitUrl.Split("/")[-1].Split(".")[0]
[string] $projectUrl = $repositoryGitUrl.Replace(".git", "")
[string] $readmeFileName = "README.md"
[string] $licenseFilePath = "${PSScriptRoot}${ds}..${ds}LICENSE.txt"
[string] $licenseFileName = [System.IO.Path]::GetFileName($licenseFilePath)
[string] $packageIconUrl = "https://en.gravatar.com/userimage/238766323/a23519bf4769d01f4e880ce1a538785f.jpeg?size=256"
[bool] $PSEdition_Desktop = $true
[bool] $PSEdition_Core = $true


. "${PSScriptRoot}${ds}lib${ds}Get-PackageDescription.ps1"
[string] $packageDescription = Get-PackageDescription

. "${PSScriptRoot}${ds}lib${ds}Get-ModuleExports.ps1"
[hashtable] $moduleExports = Get-ModuleExports -Psm1Path "${PSScriptRoot}${ds}..${ds}src${ds}${PackageId}.psm1"

. "${PSScriptRoot}${ds}lib${ds}Get-PackageTags.ps1"
[string[]] $packageTagsConstrained = Get-PackageTags -PackageId $PackageId
[string[]] $packageTagsExtended = Get-PackageTags -PackageId $PackageId -PSGalleryExtended -ModuleExports $moduleExports -PSEdition_Desktop:$PSEdition_Desktop -PSEdition_Core:$PSEdition_Core

. "${PSScriptRoot}${ds}lib${ds}Get-PackageCopyright.ps1"
[string] $packageCopyright = Get-PackageCopyright -LicenseFilePath $licenseFilePath

. "${PSScriptRoot}${ds}lib${ds}Get-PackageGuid.ps1"
[string] $packageGuid = Get-PackageGuid

. "${PSScriptRoot}${ds}lib${ds}New-ModuleManifestCustomized.ps1"
[System.IO.FileInfo] $moduleManifest = New-ModuleManifestCustomized `
    -PackageId $PackageId `
    -CompanyName $companyName `
    -Authors $authors `
    -GitRepositoryUrl $repositoryGitUrl `
    -Commitish $Commitish `
    -ProjectUrl $projectUrl `
    -LicenseFileName $licenseFileName `
    -ReadmeFileName $readmeFileName `
    -PackageIconUrl $packageIconUrl `
    -PackageDescription $packageDescription `
    -PackageCopyright $packageCopyright `
    -PackageTags $packageTagsConstrained `
    -ReleaseNotes $ReleaseNotes `
    -PackageVersionMajorMinorPatchBuild $PackageVersionMajorMinorPatchBuild `
    -PackageVersionPrereleaseTag $PackageVersionPrereleaseTag `
    -PackageGuid $packageGuid `
    -PSEdition_Desktop:$PSEdition_Desktop `
    -PSEdition_Core:$PSEdition_Core

. "${PSScriptRoot}${ds}lib${ds}New-TemporaryProjectFile.ps1"
[System.IO.FileInfo] $projectFile = New-TemporaryProjectFile `
    -PackageId $PackageId `
    -PackageVersion $PackageVersionNuGet `
    -CompanyName $companyName `
    -Authors $authors `
    -GitRepositoryUrl $repositoryGitUrl `
    -Commitish $Commitish `
    -ProjectUrl $projectUrl `
    -LicenseFileName $licenseFileName `
    -ReadmeFileName $readmeFileName `
    -PackageIconUrl $packageIconUrl `
    -PackageDescription $packageDescription `
    -PackageCopyright $packageCopyright `
    -PackageTags $packageTagsExtended `
    -ReleaseNotes $ReleaseNotes `
    -ModuleManifest $moduleManifest
try {
    dotnet pack -c Release -o "${PSScriptRoot}${ds}..${ds}out" $projectFile.FullName
}
finally {
    Remove-Item -LiteralPath $projectFile.FullName -Force
}