#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


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
