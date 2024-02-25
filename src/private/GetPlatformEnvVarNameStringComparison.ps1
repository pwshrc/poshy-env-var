#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function GetPlatformEnvVarNameStringComparison {
    [OutputType([System.StringComparison])]
    param(
    )
    if ($IsWindows) {
        return [System.StringComparison]::OrdinalIgnoreCase
    } else {
        return [System.StringComparison]::Ordinal
    }
}
