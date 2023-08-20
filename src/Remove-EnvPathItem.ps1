#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


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
