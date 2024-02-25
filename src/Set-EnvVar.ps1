#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Sets the value of the specified environment variable(s), optionally at the given environment variable scope.
.PARAMETER Process
    Sets the value of the environment variable(s) at the Process-level environment variable scope.
.PARAMETER User
    Sets the value of the environment variable(s) at the User-level environment variable scope.
    Not supported on non-Windows platforms.
.PARAMETER Machine
    Sets the value of the environment variable(s) at the Machine-level environment variable scope.
    Not supported on non-Windows platforms.
.PARAMETER Scope
    The scope of the environment variable(s) to set.
    Values other than 'Process' (the default) are not supported on non-Windows platforms.
.PARAMETER Name
    The name(s) of the environment variable(s) to set.
.PARAMETER Value
    The value to set for the environment variable(s).
    A value of $null will remove the respective environment variable.
.PARAMETER KVP
    A key-value pair whose key and value are the environment variable to set.
    A value of $null will remove the respective environment variable.
.PARAMETER Entry
    A dictionary entry whose key and value are the environment variable to set.
    A value of $null will remove the respective environment variable.
.PARAMETER Environment
    A hashtable whose keys and values are the environment variables to set.
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
        [string[]] $Name,

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
        [System.Collections.IDictionary] $Environment,

        [Parameter(Mandatory=$false, ParameterSetName="MachineScopeVAName")]
        [Parameter(Mandatory=$false, ParameterSetName="MachineScopeKVP")]
        [Parameter(Mandatory=$false, ParameterSetName="MachineScopeDE")]
        [Parameter(Mandatory=$false, ParameterSetName="MachineScopeHashtable")]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeVAName")]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeKVP")]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeDE")]
        [Parameter(Mandatory=$false, ParameterSetName="ProcessScopeHashtable")]
        [Parameter(Mandatory=$false, ParameterSetName="UserScopeVAName")]
        [Parameter(Mandatory=$false, ParameterSetName="UserScopeKVP")]
        [Parameter(Mandatory=$false, ParameterSetName="UserScopeDE")]
        [Parameter(Mandatory=$false, ParameterSetName="UserScopeHashtable")]
        [Parameter(Mandatory=$false, ParameterSetName="ScopeValueVAName")]
        [Parameter(Mandatory=$false, ParameterSetName="ScopeValueKVP")]
        [Parameter(Mandatory=$false, ParameterSetName="ScopeValueDE")]
        [Parameter(Mandatory=$false, ParameterSetName="ScopeValueHashtable")]
        [switch] $PassThru
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

        [System.StringComparison] $platformEnvVarNameComparison = GetPlatformEnvVarNameStringComparison
        function ExecuteWrite {
            [CmdletBinding()]
            [OutputType([bool])]
            param(
                [Parameter(Mandatory=$true, Position=0)]
                [ValidateNotNullOrEmpty()]
                [string] $envVarName,

                [Parameter(Mandatory=$true, Position=1)]
                [AllowNull()]
                [AllowEmptyString()]
                [object] $envVarValue
            )
            if (($null -ne $envVarValue) -and ([string]::Empty -eq $envVarValue)) {
                throw [System.NotSupportedException]::new("Setting an environment variable to an empty string is not currently supported. To remove an environment variable, set its value to `$null.")
            }
            if ($platformEnvVarNameComparison -eq [System.StringComparison]::OrdinalIgnoreCase) {
                [Nullable[System.Collections.DictionaryEntry]] $extant = Get-EnvVar -Scope $scope -Name $envVarName -ErrorAction SilentlyContinue
                if ($extant) {
                    $envVarName = $extant.Key
                }
            }
            return (SetEnvironmentVariableInScope -Name $envVarName -Value $envVarValue -Scope $Scope) && $true
        }
        if ($KVP) {
            # It's a simple write, go ahead and do it right here.
            if (ExecuteWrite -envVarName $KVP.Key -envVarValue $KVP.Value) {
                if ($PassThru) {
                    $KVP | Write-Output
                }
            }
        } elseif ($Entry) {
            # It's a simple write, go ahead and do it right here.
            if (ExecuteWrite -envVarName $Entry.Name -envVarValue $Entry.Value) {
                if ($PassThru) {
                    $Entry | Write-Output
                }
            }
        } elseif ($Name) {
            if ($Name.Count -gt 1) {
                # *Not* a simple write. We'll gear up for doing it later, in the Process block.
                if ($PassThru) {
                    [System.Collections.Generic.IEqualityComparer[string]] $platformEnvVarNameComparer = GetPlatformEnvVarNameStringComparer
                    $resultsBuilder = [System.Collections.Specialized.OrderedDictionary]::new($platformEnvVarNameComparer)
                }
            } else {
                # It's a simple write, go ahead and do it right here.
                if (ExecuteWrite -envVarName @($Name)[0] -envVarValue $Value) {
                    if ($PassThru) {
                        [System.Collections.DictionaryEntry]::new(@($Name)[0], $Value) | Write-Output
                    }
                }
            }
        }
        elseif ($Environment) {
            # *Not* a simple write. We'll gear up for doing it later, in the Process block.
            if ($PassThru) {
                [System.Collections.Generic.IEqualityComparer[string]] $platformEnvVarNameComparer = GetPlatformEnvVarNameStringComparer
                $resultsBuilder = [System.Collections.Specialized.OrderedDictionary]::new($platformEnvVarNameComparer)
            }
        } else {
            throw [System.NotImplementedException]::new("ParameterSet '$($PSCmdlet.ParameterSetName)' is not implemented.")
        }
    }
    Process {
        if ($Environment -or ($Name.Count -gt 1)) {
            try {
                if ($Environment) {
                    $Environment | Enumerate-DictionaryEntry | ForEach-Object {
                        if (ExecuteWrite -envVarName $_.Key -envVarValue $_.Value) {
                            if ($PassThru) {
                                $resultsBuilder.Add($_.Key, $_.Value)
                            }
                        }
                    }
                } else { # $Name.Count -gt 1
                    $Name | ForEach-Object {
                        if (ExecuteWrite -envVarName $_ -envVarValue $Value) {
                            if ($PassThru) {
                                $resultsBuilder.Add($_, $Value)
                            }
                        }
                    }
                }
            } finally {
                if ($PassThru -and ($resultsBuilder.PSBase.Count -gt 0)) {
                    $resultsBuilder.AsReadOnly() | Write-Output
                    $resultsBuilder = $null
                }
            }
        } else {
            # There's nothing to do in this case, we already did the simple writes in the Begin block.
        }
    }
}
