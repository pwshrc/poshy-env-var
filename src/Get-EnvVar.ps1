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
    [CmdletBinding(DefaultParameterSetName = "ProcessScopeAnyName")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeAnyName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeSpecificName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNameLike", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeNameMatch", Position=0)]
        [ValidateScript({ $IsWindows }, ErrorMessage="The Machine scope is not supported on non-Windows platforms.")]
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
        [ValidateScript({ $IsWindows }, ErrorMessage="The User scope is not supported on non-Windows platforms.")]
        [switch] $User,

        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueAnyName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueSpecificName", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNameLike", Position=0)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueNameMatch", Position=0)]
        [ValidateScript({ ($_ -eq [System.EnvironmentVariableTarget]::Process) -or $IsWindows }, ErrorMessage="Only the Process scope is supported on non-Windows platforms.")]
        [System.EnvironmentVariableTarget] $Scope,

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeSpecificName", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeSpecificName", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeSpecificName", Position=1)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueSpecificName", Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

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

        [Parameter(Mandatory=$false, ParameterSetName="MachineScopeAnyName")]
        [Parameter(Mandatory=$false, ParameterSetName="MachineScopeSpecificName")]
        [Parameter(Mandatory=$false, ParameterSetName="MachineScopeNameLike")]
        [Parameter(Mandatory=$false, ParameterSetName="MachineScopeNameMatch")]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeAnyName")]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeSpecificName")]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeNameLike")]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeNameMatch")]
        [Parameter(Mandatory=$false, ParameterSetName="UserScopeAnyName")]
        [Parameter(Mandatory=$false, ParameterSetName="UserScopeSpecificName")]
        [Parameter(Mandatory=$false, ParameterSetName="UserScopeNameLike")]
        [Parameter(Mandatory=$false, ParameterSetName="UserScopeNameMatch")]
        [Parameter(Mandatory=$false, ParameterSetName="ScopeValueAnyName")]
        [Parameter(Mandatory=$false, ParameterSetName="ScopeValueSpecificName")]
        [Parameter(Mandatory=$false, ParameterSetName="ScopeValueNameLike")]
        [Parameter(Mandatory=$false, ParameterSetName="ScopeValueNameMatch")]
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

        if ($null -ne $Name) {
            $expectsSingleMultiplicitousReturnType = $false
        } else {
            $expectsSingleMultiplicitousReturnType = $true
        }
        $allEnvVariablesForScope = [System.Environment]::GetEnvironmentVariables($Scope)
        if ($IsWindows) {
            $resultsBuilder = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::OrdinalIgnoreCase)
        } else {
            $resultsBuilder = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
        }
    }
    Process {
        $sourceDescriptor = " "
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $Name = $PSItem
        }
        if ($Name -is [string]) {
            $Name = [string[]]@(, $Name)
        }
        if (($Name -isnot [string]) -and ($Name -is [System.Collections.IEnumerable])) {
            foreach ($envVariableName in $Name) {
                if (-not [string]::IsNullOrWhiteSpace($sourceDescriptor)) {
                    $sourceDescriptor = " or "
                }
                $sourceDescriptor += "named '$envVariableName'"
                [string] $valueFound = $allEnvVariablesForScope[$envVariableName]
                if (-not [string]::IsNullOrEmpty($valueFound)) {
                    $resultsBuilder.Add($envVariableName, $valueFound)
                }
            }
        } elseif (-not [string]::IsNullOrEmpty($NameLike)) {
            $sourceDescriptor = " matching wildcard pattern '$NameLike'"
            foreach ($envVariableName in $allEnvVariablesForScope.Keys) {
                if ($envVariableName -like $NameLike) {
                    $resultsBuilder.Add($envVariableName, $allEnvVariablesForScope[$envVariableName])
                }
            }
        } elseif (-not [string]::IsNullOrEmpty($NameMatch)) {
            $sourceDescriptor = " matching regular expression pattern '$NameMatch'"
            foreach ($envVariableName in $allEnvVariablesForScope.Keys) {
                if ($envVariableName -match $NameMatch) {
                    $resultsBuilder.Add($envVariableName, $allEnvVariablesForScope[$envVariableName])
                }
            }
        } else {
            foreach ($envVariableName in $allEnvVariablesForScope.Keys) {
                $resultsBuilder.Add($envVariableName, $allEnvVariablesForScope[$envVariableName])
            }
        }

        if (-not $PSCmdlet.MyInvocation.ExpectingInput) {
            $resultsBuilder = $resultsBuilder.AsReadOnly()
            if ($expectsSingleMultiplicitousReturnType -and $resultsBuilder.Count -gt 0) {
                if (-not $ValueOnly) {
                    Write-Output ($resultsBuilder)
                } else {
                    Write-Output ($resultsBuilder.Values)
                }
            } elseif ($resultsBuilder.Count -gt 0) {
                if (-not $ValueOnly) {
                    $resultsEnumerator = $resultsBuilder.GetEnumerator()
                    while ($resultsEnumerator.MoveNext()) {
                        Write-Output ($resultsEnumerator.Current)
                    }
                } else {
                    $resultsBuilder.Values | ForEach-Object { Write-Output $_ }
                }
            } else {
                Write-Error "Get-EnvVar: No environment variable found in scope '$Scope'${sourceDescriptor}."
            }
        }
    }
    End {
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $resultsBuilder = $resultsBuilder.AsReadOnly()
            if ($expectsSingleMultiplicitousReturnType -and $resultsBuilder.Count -gt 0) {
                if (-not $ValueOnly) {
                    Write-Output ($resultsBuilder)
                } else {
                    Write-Output ($resultsBuilder.Values)
                }
            } elseif ($resultsBuilder.Count -gt 0) {
                if (-not $ValueOnly) {
                    $resultsBuilder | ForEach-Object { Write-Output $_ }
                } else {
                    $resultsBuilder.Values | ForEach-Object { Write-Output $_ }
                }
            } else {
                Write-Error "Get-EnvVar: No environment variable found in scope '$Scope'${sourceDescriptor}."
            }
        }
    }
}
