#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Get-PackageDescription {
    [string] $descriptionFilePath = "${PSScriptRoot}${ds}..${ds}..${ds}.info${ds}description.txt"
    if (-not (Test-Path -Path $descriptionFilePath -ErrorAction SilentlyContinue)) {
        throw "The file '${descriptionFilePath}' does not exist."
    }
    [string] $description = Get-Content -Raw -Path $descriptionFilePath -Encoding utf8
    if ([string]::IsNullOrEmpty($description)) {
        throw "The file '${descriptionFilePath}' is empty."
    }
    return $description
}
