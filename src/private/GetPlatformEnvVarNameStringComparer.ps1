#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function GetPlatformEnvVarNameStringComparer {
    [OutputType([System.Collections.Generic.IEqualityComparer[string]])]
    param(
    )
    if ($IsWindows) {
        [System.StringComparer]::OrdinalIgnoreCase | Write-Output
    } else {
        [System.StringComparer]::Ordinal | Write-Output
    }
}
