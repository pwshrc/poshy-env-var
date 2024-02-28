#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Gets the names and values of environment variables, optionally filtered by scope and/or name.
.PARAMETER Process
    Retrieves the environment variables from the current process, which is the default scope.
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
    System.Collections.Hashtable
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

        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeAnyName", Position=0)]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeSpecificName", Position=0)]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeNameLike", Position=0)]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeNameMatch", Position=0)]
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

        [Parameter(Mandatory=$true, ParameterSetName="MachineScopeSpecificName", Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ProcessScopeSpecificName", Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="UserScopeSpecificName", Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true, ParameterSetName="ScopeValueSpecificName", Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Name,

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
        if ($Machine) {
            $Scope = [System.EnvironmentVariableTarget]::Machine
        } elseif ($User) {
            $Scope = [System.EnvironmentVariableTarget]::User
        } elseif ($Process) {
            $Scope = [System.EnvironmentVariableTarget]::Process
        }
        if (-not (Get-Variable -Name "Scope" -ValueOnly -ErrorAction SilentlyContinue)) {
            $Scope = [System.EnvironmentVariableTarget]::Process
        }
        if (-not [System.EnvironmentVariableTarget]::IsDefined($Scope)) {
            throw "Unrecognized EnvironmentVariableTarget '$Scope'"
        }

        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $expectsSingleMultiplicitousReturnType = $false
        } elseif ($null -ne $Name) {
            $expectsSingleMultiplicitousReturnType = @(, $Name).Count -gt 1
        } else {
            $expectsSingleMultiplicitousReturnType = $true
        }
        $allEnvVariablesForScope = GetAllEnvironmentVariablesInScope -Scope $Scope -Raw

        $emptyResultsAllowable = $false
        if ($NameLike -or $NameMatch) {
            $emptyResultsAllowable = $true
        } elseif ($allEnvVariablesForScope.PSBase.Count -eq 0) {
            Write-Information ("Get-EnvVar: There are no environment variables in scope '$Scope'.")
        }

        $caseSensitivityDescriptor = [string]::Empty
        if ($IsWindows) {
            $platformEnvVarNameComparer = [System.StringComparer]::OrdinalIgnoreCase
            $caseSensitivityDescriptor = "(with the host's case-insensitive comparison semantics)"
        } else {
            $platformEnvVarNameComparer = [System.StringComparer]::Ordinal
            $caseSensitivityDescriptor = "(with the host's case-sensitive comparison semantics)"
        }

        $resultsBuilder = [System.Collections.Specialized.OrderedDictionary]::new($platformEnvVarNameComparer)
        function AccumulateResultItem {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory=$true, Position=0)]
                [ValidateNotNullOrEmpty()]
                [string] $envVarName,

                [Parameter(Mandatory=$true, Position=1)]
                [AllowNull()]
                [AllowEmptyString()]
                [object] $envVarValue
            )
            Process {
                # We still need to _count_ the number of results even when we are streaming them out, so that we can detect < 1 and > 1 results.
                $resultsBuilder.Add($envVarName, $envVarValue)
                if (-not $expectsSingleMultiplicitousReturnType) {
                    # Stream out the results as they come in.
                    if (-not $ValueOnly) {
                        [System.Collections.DictionaryEntry] $resultItem = [System.Collections.DictionaryEntry]::new($envVarName, $envVarValue)
                        $resultItem | Write-Output
                    } else {
                        Write-Output $envVarValue
                    }
                }
            }
        }
        $sourceDescriptor = " "
        function ReleaseAccumulatedResults {
            if ($null -eq $resultsBuilder) {
                throw [System.InvalidOperationException]::new("Get-EnvVar: ReleaseAccumulatedResults: `$resultsBuilder is `$null.")
            }
            try {
                if ($resultsBuilder.Count -eq 0) {
                    if (-not $emptyResultsAllowable) {
                        Write-Error ("Get-EnvVar: No environment variable found in scope '$Scope'"+($sourceDescriptor.TrimEnd())+".")
                    } else {
                        # Someone might be interested in this, even though they invoked us with "search" semantics (NameLike or NameMatch, any cardinality).
                        Write-Debug ("Get-EnvVar: No environment variable found in scope '$Scope'"+($sourceDescriptor.TrimEnd())+".")
                    }
                }
                if (-not $expectsSingleMultiplicitousReturnType) {
                    # We don't need to write any results, we already streamed out the results as they came in.
                    return
                } elseif ($resultsBuilder.Count -gt 0) {
                    $resultsBuilder = $resultsBuilder.AsReadOnly()
                    if (-not $ValueOnly) {
                        # This doesn't use `-NoEnumerate` because from this code path we want to strip the single-element array in which PowerShell has wrapped this cmdlet's results.
                        Write-Output $resultsBuilder
                    } else {
                        Write-Output $resultsBuilder.Values -NoEnumerate
                    }
                }
            } finally {
                if ((-not $expectsSingleMultiplicitousReturnType) -and (-not $resultsBuilder.PSBase.IsFixedSize)) {
                    # If we haven't returned the results builder (or its Keys or Values) to the caller, we clear it to help the GC.
                    $resultsBuilder.Clear()
                }
                $resultsBuilder = $null
            }
        }
    }
    Process {
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
                $sourceDescriptor += " named '$envVariableName' $caseSensitivityDescriptor"
                if (-not $allEnvVariablesForScope.ContainsKey($envVariableName)) {
                    Write-Error ("Get-EnvVar: No environment variable named '$envVariableName' found in scope '$Scope'"+($sourceDescriptor.TrimEnd())+".")
                } else {
                    [object] $valueFound = $allEnvVariablesForScope[$envVariableName]
                    AccumulateResultItem $envVariableName $valueFound
                }
            }
        } elseif (-not [string]::IsNullOrEmpty($NameLike)) {
            $sourceDescriptor = " matching wildcard pattern '$NameLike' $caseSensitivityDescriptor"
            $allEnvVariablesForScope | Where-DictionaryEntry {
                PlatformEnvVarNameLike $_.Key $NameLike
            } | ForEach-Object {
                AccumulateResultItem $_.Key $_.Value
            }
        } elseif (-not [string]::IsNullOrEmpty($NameMatch)) {
            $sourceDescriptor = " matching regular expression pattern '$NameMatch' $caseSensitivityDescriptor"
            $allEnvVariablesForScope | Where-DictionaryEntry {
                PlatformEnvVarNameMatch $_.Key $NameMatch
            } | ForEach-Object {
                AccumulateResultItem $_.Key $_.Value
            }
        } else {
            $allEnvVariablesForScope | Enumerate-DictionaryEntry | ForEach-Object {
                AccumulateResultItem $_.Key $_.Value
            }
        }
    }
    End {
        ReleaseAccumulatedResults
    }
}
