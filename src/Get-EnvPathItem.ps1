#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Gets the path entries of the environment variable `PATH` at the given environment variable scope.
.PARAMETER Process
    Gets the path entries of the environment variable `PATH` at the Process-level environment variable scope.
.PARAMETER User
    Gets the path entries of the environment variable `PATH` at the User-level environment variable scope.
.PARAMETER Machine
    Gets the path entries of the environment variable `PATH` at the Machine-level environment variable scope.
.PARAMETER Scope
    The scope of the environment variable from which the path entries will be retrieved.
.OUTPUTS
    string
.COMPONENT
    env
#>
function Get-EnvPathItem() {
    [CmdletBinding(DefaultParameterSetName = "ProcessScopeForValue")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeForValue", Position=0)]
        [switch] $Machine,

        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeForValue", Position=0)]
        [switch] $Process,

        [Parameter(Mandatory=$true, ParameterSetName="UserScopeForValue", Position=0)]
        [switch] $User,

        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueForValue", Position=0)]
        [System.EnvironmentVariableTarget] $Scope
    )

    $new_args = $PSBoundParameters + @{Name="PATH"}
    Get-EnvVarPathItem @new_args
}
