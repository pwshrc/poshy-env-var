#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function TestCanSetEnvironmentVariablesInScope {
    param(
        [Parameter()]
        [System.EnvironmentVariableTarget] $scope
    )
    if (($scope -ne [System.EnvironmentVariableTarget]::Process) -and (-not $IsWindows)) {
        $false
    } else {
        try {
            [string] $envVarName = "foo" + [System.Guid]::NewGuid().ToString()
            [string] $envVarValue = [System.Guid]::NewGuid().ToString()
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
}

function RemoveBlankEnvironmentVariablesInProcessScope {
    . "$PSScriptRoot/../src/private/GetAllEnvironmentVariableKeysInScope.ps1"

    $scope = [System.EnvironmentVariableTarget]::Process
    (GetAllEnvironmentVariableKeysInScope $scope) | ForEach-Object {
        if ([string]::IsNullOrWhiteSpace([System.Environment]::GetEnvironmentVariable($_, $scope))) {
            [System.Environment]::SetEnvironmentVariable($_, $null, $scope)
        }
    }
}

RemoveBlankEnvironmentVariablesInProcessScope
