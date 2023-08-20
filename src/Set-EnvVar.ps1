#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# Sets an environment variable, requiring explicit specification of scope.
# Can accept pipeline of objects with properties `Name` and `Value`.
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
