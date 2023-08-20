#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Get-PackageGuid {
    [string] $GuidFilePath = "${PSScriptRoot}${ds}..${ds}..${ds}.info${ds}guid.txt"
    if (-not (Test-Path -Path $GuidFilePath -ErrorAction SilentlyContinue)) {
        throw "The file '${GuidFilePath}' does not exist."
    }
    [string] $guid = (Get-Content -Path $GuidFilePath -Raw).Trim()
    if ([string]::IsNullOrEmpty($guid)) {
        throw "The file '${GuidFilePath}' is empty."
    }
    return $guid
}
