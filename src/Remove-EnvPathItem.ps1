#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


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
    Remove-EnvPathItem -Process -Name "PATH" -ValueLike "C:\Program Files\*"
.COMPONENT
    env
#>
function Remove-EnvPathItem() {
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
        [string] $Value,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeForValueLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeForValueLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeForValueLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueForValueLike", Position=1)]
        [string] $ValueLike,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeForValueMatch", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeForValueMatch", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeForValueMatch", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueForValueMatch", Position=1)]
        [string] $ValueMatch
    )

    $new_args = $PSBoundParameters + @{Name="PATH"}
    Remove-EnvVarPathItem @new_args
}
