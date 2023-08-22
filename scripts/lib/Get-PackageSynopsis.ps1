#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Get-PackageSynopsis {
    param(
        [switch] $ForGitHubRepoDescription
    )

    [string] $synopsisFilePath = "${PSScriptRoot}${ds}..${ds}..${ds}.info${ds}synopsis.txt"
    if (-not (Test-Path -Path $synopsisFilePath -ErrorAction SilentlyContinue)) {
        Write-Error "The file '${synopsisFilePath}' does not exist."
        return
    }
    [string] $synopsis = (Get-Content -Raw -Path $synopsisFilePath -Encoding UTF8).Trim()
    if ([string]::IsNullOrEmpty($synopsis)) {
        Write-Error "The file '${synopsisFilePath}' is empty."
        return
    }

    if ($ForGitHubRepoDescription) {
        $synopsis = ($synopsis -replace "`r?`n", " ") -replace "\s+", " "
    }


    return $synopsis
}
