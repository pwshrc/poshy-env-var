#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
#Requires -Modules @{ ModuleName = "poshy-lucidity"; RequiredVersion = "0.4.1" }


<#
.SYNOPSIS
    Removes the specified path entry from the specified PATH-style environment variable at the given environment variable scope.
.PARAMETER Process
    Removes the specified path entry from the environment variable at the Process-level environment variable scope.
.PARAMETER User
    Removes the specified path entry from the environment variable at the User-level environment variable scope.
    If running on Windows and the current session is not elevated, causes an exception to be thrown.
.PARAMETER Machine
    Removes the specified path entry from the environment variable at the Machine-level environment variable scope.
    If running on Windows and the current session is not elevated, causes an exception to be thrown.
.PARAMETER Scope
    The scope of the environment variable from which the path entry will be removed.
    If running on Windows and the current session is not elevated, values other than 'Process' cause an exception to be thrown.
.PARAMETER Name
    The name of the environment variable from which the path entry will be removed.
.PARAMETER Value
    The exact path entry to remove from the environment variable.
.PARAMETER ValueLike
    The path entry to remove from the environment variable, using a wildcard pattern match.
.PARAMETER ValueMatch
    The path entry to remove from the environment variable, using a regular expression match.
.EXAMPLE
    Remove-EnvVarPathItem -Process -Name "PATH" -ValueLike "C:\Program Files\*"
.COMPONENT
    env
#>
function Remove-EnvVarPathItem() {
    [CmdletBinding(DefaultParameterSetName = "ProcessScopeForValue")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeForValue", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeForValueLike", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeForValueMatch", Position=0)]
        [switch] $Machine,

        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeForValue", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeForValueLike", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeForValueMatch", Position=0)]
        [switch] $Process,

        [Parameter(Mandatory=$true, ParameterSetName="UserScopeForValue", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeForValueLike", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeForValueMatch", Position=0)]
        [switch] $User,

        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueForValue", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueForValueLike", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueForValueMatch", Position=0)]
        [System.EnvironmentVariableTarget] $Scope,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeForValue", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeForValue", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeForValue", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueForValue", Position=1)]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Name,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeForValue", Position=2, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeForValue", Position=2, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeForValue", Position=2, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueForValue", Position=2, ValueFromPipeline=$true)]
        [string] $Value,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeForValueLike", Position=2, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeForValueLike", Position=2, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeForValueLike", Position=2, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueForValueLike", Position=2, ValueFromPipeline=$true)]
        [string] $ValueLike,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeForValueMatch", Position=2, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeForValueMatch", Position=2, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeForValueMatch", Position=2, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueForValueMatch", Position=2, ValueFromPipeline=$true)]
        [string] $ValueMatch
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

        if ($Value) {
            $pathItems = $pathItems | Where-Object { $_ -ne $Value }
        } elseif ($ValueLike) {
            $pathItems = $pathItems | Where-Object { $_ -notlike $ValueLike }
        } elseif ($ValueMatch) {
            $pathItems = $pathItems | Where-Object { $_ -notmatch $ValueMatch }
        }

        [string] $newPathValue = $pathItems -join [System.IO.Path]::PathSeparator
        Set-EnvVar -Scope $Scope -Name $Name -Value $newPathValue
    }
}
