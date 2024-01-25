#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function PlatformEnvVarNameMatch {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $envVarName,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $regexPattern
    )
    if ($IsWindows) {
        $envVarName -imatch $regexPattern
    } else {
        $envVarName -cmatch $regexPattern
    }
}
