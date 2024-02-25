#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function GetPlatformEnvVarNameStringComparer {
    [OutputType([System.Collections.Generic.IEqualityComparer[string]])]
    param(
    )
    if ($IsWindows) {
        return [System.StringComparer]::OrdinalIgnoreCase
    } else {
        return [System.StringComparer]::Ordinal
    }
}
