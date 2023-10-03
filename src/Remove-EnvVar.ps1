#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Removes the specified environment variable at the given environment variable scope.
.PARAMETER Process
    Removes the specified environment variable at the Process-level environment variable scope.
.PARAMETER User
    Removes the specified environment variable at the User-level environment variable scope.
    If running on Windows and the current session is not elevated, causes an exception to be thrown.
.PARAMETER Machine
    Removes the specified environment variable at the Machine-level environment variable scope.
    If running on Windows and the current session is not elevated, causes an exception to be thrown.
.PARAMETER Scope
    The scope of the environment variable to remove.
    If running on Windows and the current session is not elevated, values other than 'Process' cause an exception to be thrown.
.PARAMETER Name
    The exact name of the environment variable to remove.
.PARAMETER NameLike
    The name of the environment variable to remove, using a wildcard pattern match.
.PARAMETER NameMatch
    The name of the environment variable to remove, using a regular expression match.
.EXAMPLE
    Remove-EnvVar -Process -NameLike "MYAPP_*"
.COMPONENT
    env
#>
function Remove-EnvVar() {
    [CmdletBinding(DefaultParameterSetName = "ProcessScopeSpecificName")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeSpecificName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNameLike", Position=0)]
        [switch] $Machine,

        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeSpecificName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeNameLike", Position=0)]
        [switch] $Process,

        [Parameter(Mandatory=$true, ParameterSetName="UserScopeSpecificName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeNameLike", Position=0)]
        [switch] $User,

        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueSpecificName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNameLike", Position=0)]
        [System.EnvironmentVariableTarget] $Scope,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeSpecificName", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeSpecificName", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeSpecificName", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueSpecificName", Position=1)]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Name,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNameLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeNameLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeNameLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNameLike", Position=1)]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $NameLike
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
    }
    Process {
        if ($Scope -ne [System.EnvironmentVariableTarget]::Process) {
            throw [System.NotSupportedException]::new("Removal of only Process-scoped environment variables is supported at this time.")
        }

        if ($Name) {
            Remove-Item Env:$Name
        } elseif ($NameLike) {
            Get-ChildItem Env:$NameLike | Remove-Item
        } else {
            throw [System.InvalidOperationException]::new("Either Name or NameLike must be specified.")
        }
    }
}
