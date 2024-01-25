#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function GetAllEnvironmentVariableKeysInScope {
    param(
        [Parameter()]
        [System.EnvironmentVariableTarget] $scope
    )
    [System.Environment]::GetEnvironmentVariables($scope).Keys
}
