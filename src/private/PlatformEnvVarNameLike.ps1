#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function PlatformEnvVarNameLike {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $envVarName,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $wildcardPattern
    )
    if ($IsWindows) {
        $envVarName -ilike $wildcardPattern
    } else {
        $envVarName -clike $wildcardPattern
    }
}
