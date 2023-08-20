#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# Gets matching environment variables, requires explicit specification of scope.
# Outputs one or more objects with properties `Name` and `Value`.
function Get-EnvVar() {
    [CmdletBinding(DefaultParameterSetName = "ProcessScopeSpecificName")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeAnyName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeSpecificName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNameLike", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNameMatch", Position=0)]
        [switch] $Machine,

        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeAnyName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeSpecificName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeNameLike", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeNameMatch", Position=0)]
        [switch] $Process,

        [Parameter(Mandatory=$true, ParameterSetName="UserScopeAnyName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeSpecificName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeNameLike", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeNameMatch", Position=0)]
        [switch] $User,

        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueAnyName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueSpecificName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNameLike", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNameMatch", Position=0)]
        [System.EnvironmentVariableTarget] $Scope,

        [Parameter(Mandatory=$false, ParameterSetName="MachineScopeSpecificName", Position=1)]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeSpecificName", Position=1)]
        [Parameter(Mandatory=$false, ParameterSetName="UserScopeSpecificName", Position=1)]
        [Parameter(Mandatory=$false, ParameterSetName="ScopeValueSpecificName", Position=1)]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Name = $null,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNameLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeNameLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeNameLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNameLike", Position=1)]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $NameLike,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNameMatch", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeNameMatch", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeNameMatch", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNameMatch", Position=1)]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $NameMatch,

        [Parameter(Mandatory=$false, Position=2)]
        [switch] $Value
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
        if ($Name) {
            [string] $valueFound = [System.Environment]::GetEnvironmentVariable($Name, $Scope)
            if ($null -eq $valueFound) {
                if ($Value -and $Value.IsPresent) {
                    Write-Output $null
                } else {
                    # Intentionally left blank.
                }
            } else {
                if ($Value -and $Value.IsPresent) {
                    Write-Output $valueFound
                } else {
                    [System.Collections.DictionaryEntry] $de = [System.Collections.DictionaryEntry]::new($Name, $valueFound)
                    Write-Output $de
                }
            }
        } else {
            [System.Collections.DictionaryEntry[]] $allEnvItems = Get-ChildItem Env:
            foreach ($de in $allEnvItems) {
                if ($NameLike -and ($de.Name -notlike $NameLike)) {
                    continue
                }
                if ($NameMatch -and ($de.Name -notmatch $NameMatch)) {
                    continue
                }
                if ($null -eq [System.Environment]::GetEnvironmentVariable($de.Name, $Scope)) {
                    continue
                } else {
                    if ($Value) {
                        Write-Output $de.Value
                    } else {
                        Write-Output $de
                    }
                }
            }
        }
    }
}
