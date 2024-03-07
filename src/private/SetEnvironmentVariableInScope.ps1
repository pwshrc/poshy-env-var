#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function SetEnvironmentVariableInScope {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $name,

        [Parameter(Mandatory=$true, Position=1)]
        [AllowNull()]
        [AllowEmptyString()]
        [object] $value,

        [Parameter(Mandatory=$true, Position=2)]
        [System.EnvironmentVariableTarget] $scope
    )
    if (($null -ne $value) -and ([string]::Empty -eq $value)) {
        Write-Error "Setting an environment variable to an empty string is not currently supported. To remove an environment variable, set it to `$null."
    } else {
        [System.Environment]::SetEnvironmentVariable($name, $value, $scope)
    }
}
