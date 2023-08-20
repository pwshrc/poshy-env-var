#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Add-EnvVarPathItem() {
    [CmdletBinding(DefaultParameterSetName = "ProcessScopeForValue")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeForValue", Position=0)]
        [switch] $Machine,

        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeForValue", Position=0)]
        [switch] $Process,

        [Parameter(Mandatory=$true, ParameterSetName="UserScopeForValue", Position=0)]
        [switch] $User,

        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueForValue", Position=0)]
        [System.EnvironmentVariableTarget] $Scope,

        [Parameter(Mandatory=$true, Position=1)]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=2, ValueFromPipeline=$true)]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Value,

        [Parameter(Mandatory=$false, Position=3)]
        [switch] $Prepend
    )
    Begin {
        if ($Machine -and $Machine.IsPresent) {
            $Scope = [System.EnvironmentVariableTarget]::Machine
        } elseif ($Process -and $Process.IsPresent) {
            $Scope = [System.EnvironmentVariableTarget]::Process
        } elseif ($User -and $User.IsPresent) {
            $Scope = [System.EnvironmentVariableTarget]::User
        }

        if (-not [System.EnvironmentVariableTarget]::IsDefined($Scope)) {
            throw "Unrecognized EnvironmentVariableTarget '$Scope'"
        }

        if ($IsWindows -and ($Scope -ne [System.EnvironmentVariableTarget]::Process)) {
            [bool] $isElevated = Test-Elevation
            if (-not $isElevated) {
                throw "Elevated session required for EnvironmentVariableTarget '$Scope'"
            }
        }
    }
    Process {
        [string] $extantPath = Get-EnvVar -Scope $Scope -Name $Name -Value
        [string[]] $pathItems = $extantPath -split [System.IO.Path]::PathSeparator

        $pathItems = $pathItems | Where-Object { $_ -ne $Value }
        if ($Prepend -and $Prepend.IsPresent) {
            $pathItems = @(,$Value) + $pathItems
        } else {
            $pathItems = $pathItems + @(,$Value)
        }

        [string] $newPathValue = $pathItems -join [System.IO.Path]::PathSeparator
        Set-EnvVar -Scope $Scope -Name $Name -Value $newPathValue
    }
}
