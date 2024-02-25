#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Sets the value of the specified environment variable, optionally at the given environment variable scope.
.PARAMETER Process
    Sets the value of the environment variable at the Process-level environment variable scope.
.PARAMETER User
    Sets the value of the environment variable at the User-level environment variable scope.
    Not supported on non-Windows platforms.
.PARAMETER Machine
    Sets the value of the environment variable at the Machine-level environment variable scope.
    Not supported on non-Windows platforms.
.PARAMETER Scope
    The scope of the environment variable to set.
    Values other than 'Process' (the default) are not supported on non-Windows platforms.
.PARAMETER Name
    The name of the environment variable to set.
.PARAMETER Value
    The value to set for the environment variable.
    A value of $null will remove the respective environment variable.
.PARAMETER KVP
    A key-value pair whose key and value are the environment variable to set.
    A value of $null will remove the respective environment variable.
.PARAMETER Entry
    A dictionary entry whose key and value are the environment variable to set.
    A value of $null will remove the respective environment variable.
.PARAMETER Environment
    A hashtable whose keys and values are the the environment variables to set.
    Values of $null will remove the respective environment variables.
.EXAMPLE
    Set-EnvVar -Process -Name "MYAPP_HOME" -Value "C:\Program Files\MyApp"
.EXAMPLE
    Set-EnvVar -Process -Environment @{MYAPP_HOME="C:\Program Files\MyApp"; MYAPP_DATA="C:\ProgramData\MyApp"}
.COMPONENT
    env
#>
function Set-EnvVar() {
    [CmdletBinding(DefaultParameterSetName = "ProcessScopeVAName")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeVAName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeKVP", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeDE", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeHashtable", Position=0)]
        [ValidateScript({ $IsWindows }, ErrorMessage="The Machine scope is not supported on non-Windows platforms.")]
        [switch] $Machine,

        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeVAName", Position=0)]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeKVP", Position=0)]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeDE", Position=0)]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeHashtable", Position=0)]
        [switch] $Process,

        [Parameter(Mandatory=$true, ParameterSetName="UserScopeVAName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeKVP", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeDE", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeHashtable", Position=0)]
        [ValidateScript({ $IsWindows }, ErrorMessage="The User scope is not supported on non-Windows platforms.")]
        [switch] $User,

        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueVAName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueKVP", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueDE", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueHashtable", Position=0)]
        [ValidateScript({ ($_ -eq [System.EnvironmentVariableTarget]::Process) -or $IsWindows }, ErrorMessage="Only the Process scope is supported on non-Windows platforms.")]
        [System.EnvironmentVariableTarget] $Scope,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeVAName", Position=1, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeVAName", Position=1, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeVAName", Position=1, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueVAName", Position=1, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("Key")]
        [string] $Name,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeVAName", Position=2, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeVAName", Position=2, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeVAName", Position=2, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueVAName", Position=2, ValueFromPipelineByPropertyName=$true)]
        [AllowNull()]
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
        [hashtable] $Environment
    )
    Begin {
        if ($Machine) {
            $Scope = [System.EnvironmentVariableTarget]::Machine
        } elseif ($User) {
            $Scope = [System.EnvironmentVariableTarget]::User
        } elseif ($Process) {
            $Scope = [System.EnvironmentVariableTarget]::Process
        }
        if (-not (Get-Variable -Name "Scope" -ErrorAction SilentlyContinue)) {
            $Scope = [System.EnvironmentVariableTarget]::Process
        }
        if (-not [System.EnvironmentVariableTarget]::IsDefined($Scope)) {
            throw "Unrecognized EnvironmentVariableTarget '$Scope'"
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
                SetEnvironmentVariableInScope -Name $Name -Value $Value -Scope $Scope
            }
            return
        }


        SetEnvironmentVariableInScope -Name $Name -Value $Value -Scope $Scope
    }
}
