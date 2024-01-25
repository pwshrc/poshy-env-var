#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


Get-ChildItem -Path "$PSScriptRoot/private/*.ps1" | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -Path "$PSScriptRoot/*.ps1" | ForEach-Object {
    . $_.FullName
    Export-ModuleMember -Function $_.BaseName
}
