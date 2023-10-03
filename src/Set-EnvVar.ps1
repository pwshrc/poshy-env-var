#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Sets the value of the specified environment variable at the given environment variable scope.
.PARAMETER Process
    Sets the value of the environment variable at the Process-level environment variable scope.
.PARAMETER User
    Sets the value of the environment variable at the User-level environment variable scope.
    If running on Windows and the current session is not elevated, causes an exception to be thrown.
.PARAMETER Machine
    Sets the value of the environment variable at the Machine-level environment variable scope.
    If running on Windows and the current session is not elevated, causes an exception to be thrown.
.PARAMETER Scope
    The scope of the environment variable to set.
    If running on Windows and the current session is not elevated, values other than 'Process' cause an exception to be thrown.
.PARAMETER Name
    The name of the environment variable to set.
.PARAMETER Value
    The value to set for the environment variable.
.PARAMETER KVP
    A key-value pair whose key is the name of the environment variable to set and whose value is the value to set for the environment variable.
.PARAMETER Entry
    A dictionary entry whose key is the name of the environment variable to set and whose value is the value to set for the environment variable.
.PARAMETER Environment
    A hashtable whose keys are the names of the environment variables to set and whose values are the values to set for the environment variables.
.PARAMETER SkipOverwrite
    If specified, environment variables that already exist will not be overwritten.
.EXAMPLE
    Set-EnvVar -Process -Name "MYAPP_HOME" -Value "C:\Program Files\MyApp"
.EXAMPLE
    Set-EnvVar -Process -SkipOverwrite -Environment @{MYAPP_HOME="C:\Program Files\MyApp"; MYAPP_DATA="C:\ProgramData\MyApp"}
.COMPONENT
    env
#>
function Set-EnvVar() {
    [CmdletBinding(DefaultParameterSetName = "ProcessScopeNAV")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNAV", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeKVP", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeDE", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeHashtable", Position=0)]
        [switch] $Machine,

        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeNAV", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeKVP", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeDE", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeHashtable", Position=0)]
        [switch] $Process,

        [Parameter(Mandatory=$true, ParameterSetName="UserScopeNAV", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeKVP", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeDE", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeHashtable", Position=0)]
        [switch] $User,

        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNAV", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueKVP", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueDE", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueHashtable", Position=0)]
        [System.EnvironmentVariableTarget] $Scope,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNAV", Position=1, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeNAV", Position=1, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeNAV", Position=1, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNAV", Position=1, ValueFromPipelineByPropertyName=$true)]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Name,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNAV", Position=2, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeNAV", Position=2, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeNAV", Position=2, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNAV", Position=2, ValueFromPipelineByPropertyName=$true)]
        [object] $Value,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeKVP", Position=1, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeKVP", Position=1, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeKVP", Position=1, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueKVP", Position=1, ValueFromPipeline=$true)]
        [ValidateCount(1, [int]::MaxValue)]
        [System.Collections.Generic.KeyValuePair[string, object]] $KVP,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeDE", Position=1, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeDE", Position=1, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeDE", Position=1, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueDE", Position=1, ValueFromPipeline=$true)]
        [System.Collections.DictionaryEntry] $Entry,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeHashtable", Position=1, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeHashtable", Position=1, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeHashtable", Position=1, ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueHashtable", Position=1, ValueFromPipeline=$true)]
        [hashtable] $Environment,

        [Parameter(Mandatory=$false, Position=3)]
        [switch] $SkipOverwrite
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
                throw "Elevated session required for updating environment variables with scope '$Scope'"
            }
        }

        if ($KVP) {
            $Name = $KVP.Key
            $Value = $KVP.Value
        }

        if ($Entry) {
            $Name = $Entry.Name
            $Value = $Entry.Value
        }

        if ($Value -is [bool]) {
            $Value = $Value.ToString().ToLower()
        }
    }
    Process {
        if ($Environment -is [hashtable]) {
            for ($i = 0; $i -lt $Environment.Count; $i++) {
                $Name = $Environment.Keys[$i]
                $Value = $Environment.Values[$i]
                Set-EnvVar -Name $Name -Value $Value -Scope $Scope -SkipOverwrite:$SkipOverwrite
            }
            return
        }

        if ($SkipOverwrite -and [System.Environment]::GetEnvironmentVariable($Name, $Scope)) {
            return
        }

        if ($null -eq $Value) {
            Remove-EnvVar -Scope $Scope -Name $Name
        } else {
            [System.Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
        }
    }
}
