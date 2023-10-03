#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest



<#
.SYNOPSIS
    Adds a path entry to the environment variable `PATH` at the given environment variable scope.
.PARAMETER Process
    Adds the path entry to the environment variable `PATH` at the Process-level environment variable scope.
.PARAMETER User
    Adds the path entry to the environment variable `PATH` at the User-level environment variable scope.
    If running on Windows and the current session is not elevated, causes an exception to be thrown.
.PARAMETER Machine
    Adds the path entry to the environment variable `PATH` at the Machine-level environment variable scope.
    If running on Windows and the current session is not elevated, causes an exception to be thrown.
.PARAMETER Scope
    The scope at which to add the entry to the `PATH` environment variable.
    If running on Windows and the current session is not elevated, values other than 'Process' cause an exception to be thrown.
.PARAMETER Value
    The path entry to add to the `PATH` environment variable.
.PARAMETER Prepend
    If specified, the path entry will be prepended to the `PATH` environment variable rather than appended.
.EXAMPLE
    Add-EnvPathItem -Process "C:\Program Files\MyApp"
.COMPONENT
    env
#>
function Add-EnvPathItem() {
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

        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Value,

        [Parameter(Mandatory=$false, Position=2)]
        [switch] $Prepend
    )

    $new_args = $PSBoundParameters + @{Name="PATH"}
    Add-EnvVarPathItem @new_args
}
