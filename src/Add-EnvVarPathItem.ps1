#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Adds a path entry to the specified PATH-style environment variable at the given environment variable scope.
.PARAMETER Machine
    Adds the path entry to the environment variable at the Machine-level environment variable scope.
    If running on Windows and the current session is not elevated, causes an exception to be thrown.
.PARAMETER User
    Adds the path entry to the environment variable at the User-level environment variable scope.
    If running on Windows and the current session is not elevated, causes an exception to be thrown.
.PARAMETER Process
    Adds the path entry to the environment variable at the Process-level environment variable scope.
.PARAMETER Scope
    The scope of the environment variable to which the path entry will be added.
    If running on Windows and the current session is not elevated, values other than 'Process' cause an exception to be thrown.
.PARAMETER Name
    The name of the environment variable to which the path entry will be added.
.PARAMETER Value
    The path entry to add to the environment variable.
.PARAMETER Prepend
    If specified, the path entry will be prepended to the environment variable rather than appended.
.EXAMPLE
    Add-EnvVarPathItem -Process -Name "PATH" -Value "C:\Program Files\MyApp"
.EXAMPLE
    Add-EnvVarPathItem -Process -NAME "PSModulePath" -Value "C:\Program Files\MyApp\Modules" -Prepend
.COMPONENT
    env
#>
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
