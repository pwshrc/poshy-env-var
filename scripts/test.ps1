#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'UseSrc')]
    [switch] $UseSrc,

    [Parameter(Mandatory = $true, ParameterSetName = 'UsePackageExport')]
    [switch] $UsePackageExport,

    [switch] $NoFail
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


if (-not (Get-Command Invoke-Pester -ErrorAction SilentlyContinue)) {
    throw "Invoke-Pester not found. Please install the PowerShell module 'Pester'."
}

[string] $newPsmodulePathEntry = $null
if ($UsePackageExport) {
    $ds = [System.IO.Path]::DirectorySeparatorChar
    [System.IO.FileInfo[]] $psgallery_nupkg = @(Get-ChildItem -Path "${PSScriptRoot}${ds}..${ds}out" -Filter "*.nupkg" -Recurse -File -Force)
    if (-not $psgallery_nupkg) {
        throw "No NuGet packages were found in '${PSScriptRoot}${ds}..${ds}out'."
    }
    [string] $package_expanded = "${PSScriptRoot}${ds}..${ds}out${ds}$($psgallery_nupkg[0].BaseName)"
    Expand-Archive -Path $psgallery_nupkg[0].FullName -DestinationPath $package_expanded -Force | Out-Null
    $newPsmodulePathEntry = $package_expanded
} else {
    $newPsmodulePathEntry = "${PSScriptRoot}${ds}..${ds}src"
}
[string] $moduleName = Get-ChildItem -Path $newPsmodulePathEntry -Filter *.psm1 -Recurse -File -Force | Select-Object -First 1 -ExpandProperty BaseName
New-Item -Path Variable:"Global:SubjectModuleName" -Value $moduleName -Force | Out-Null

$pesterConfig = New-PesterConfiguration @{
    Run = @{
        Path = "$PSScriptRoot/../test"
        Throw = (-not $NoFail)
        PassThru = $true
    }
    TestResult = @{
        Enabled = $true
        OutputPath = "$PSScriptRoot/../out/test-results.xml"
        OutputFormat = "NUnit3"
    }
    CodeCoverage = @{
        Enabled = $true
        OutputPath = "$PSScriptRoot/../out/test-coverage.xml"
        OutputFormat = "JaCoCo"
        Path = $newPsmodulePathEntry
        RecursePaths = $true
    }
}

$ps = [System.IO.Path]::PathSeparator
$Env:PSModulePath = "${newPsmodulePathEntry}${ps}$Env:PSModulePath"
try {
    Invoke-Pester -Configuration $pesterConfig
} finally {
    $Env:PSModulePath = $Env:PSModulePath.Replace("${newPsmodulePathEntry}${ps}", "")
    Remove-Item -Path Variable:"Global:SubjectModuleName" -Force -ErrorAction SilentlyContinue
}
