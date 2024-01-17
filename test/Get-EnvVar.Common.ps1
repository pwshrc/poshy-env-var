#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function TestCanSetEnvironmentVariablesInScope {
    param(
        [Parameter()]
        [System.EnvironmentVariableTarget] $scope
    )
    try {
        $envVarName = "foo" + [System.Guid]::NewGuid().ToString()
        $envVarValue = [System.Guid]::NewGuid().ToString()
        [System.Environment]::SetEnvironmentVariable($envVarName, $envVarValue, $scope)
        try {
            $actual = [System.Environment]::GetEnvironmentVariable($envVarName, $scope)
            $actual | Should -Be $envVarValue
        } finally {
            [System.Environment]::SetEnvironmentVariable($envVarName, $null, $scope)
        }
        $true
    } catch {
        $false
    }
}
