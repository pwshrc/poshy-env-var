#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Gets the names and values of environment variables at a given environment variable scope.
.PARAMETER Process
    Restricts the results to environment variables at the Process-level environment variable scope.
.PARAMETER User
    Restricts the results to environment variables at the User-level environment variable scope.
.PARAMETER Machine
    Restricts the results to environment variables at the Machine-level environment variable scope.
.PARAMETER Scope
    Restricts the results to environment variables at the specified environment variable scope.
.PARAMETER Name
    Restricts the results to environment variables with the exact specified name.
.PARAMETER NameLike
    Restricts the results to environment variables with names that match the specified wildcard pattern.
.PARAMETER NameMatch
    Restricts the results to environment variables with names that match the specified regular expression pattern.
.PARAMETER ValueOnly
    Indicates that this cmdlet gets only the value of the variable(s).
.EXAMPLE
    Get-EnvVar -Process -Name "PATH"
.OUTPUTS
    System.Collections.DictionaryEntry
    string
.COMPONENT
    env
#>
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
        [ValidateNotNullOrEmpty()]
        [string] $Name = $null,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNameLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeNameLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeNameLike", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNameLike", Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $NameLike,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNameMatch", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeNameMatch", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeNameMatch", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNameMatch", Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $NameMatch,

        [Parameter(Mandatory=$false, Position=2)]
        [Alias("Value")]
        [switch] $ValueOnly
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
                if ($ValueOnly -and $ValueOnly.IsPresent) {
                    Write-Output $null
                } else {
                    # Intentionally left blank.
                }
            } else {
                if ($ValueOnly -and $ValueOnly.IsPresent) {
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
                    if ($ValueOnly) {
                        Write-Output $de.Value
                    } else {
                        Write-Output $de
                    }
                }
            }
        }
    }
}
