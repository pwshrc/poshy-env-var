#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


. "$PSScriptRoot/Common.ps1"

Describe "cmdlet Set-EnvVar" {
    BeforeDiscovery {
        Get-ChildItem -Path "$PSScriptRoot/../src/private/*.ps1" | ForEach-Object {
            . $_.FullName
        }
        $expectedEnvironmentVariableScope = [System.EnvironmentVariableTarget]::Process
    }

    BeforeAll {
        Get-ChildItem -Path "$PSScriptRoot/../src/private/*.ps1" | ForEach-Object {
            . $_.FullName
        }
        $expectedEnvironmentVariableScope = [System.EnvironmentVariableTarget]::Process
    }

    BeforeEach {
        . "$PSScriptRoot/../src/Set-EnvVar.ps1"
        $originalEnvironmentVariables = GetAllEnvironmentVariablesInScope -Scope $expectedEnvironmentVariableScope -Hashtable
        function Set-EnvironmentVariableWithProvenance {
            [CmdletBinding()]
            param(
                [ValidateNotNullOrEmpty()]
                [string] $Name,

                [AllowNull()][AllowEmptyString()]
                [object] $Value
            )
            SetEnvironmentVariableInScope -Scope $expectedEnvironmentVariableScope -Name $Name -Value $Value
            $originalEnvironmentVariables[$Name] = $Value
        }
        function Assert-EnvironmentVariablesAllUnchanged {
            $expectedEnvironmentVariables = $originalEnvironmentVariables.Clone()
            $actualEnvironmentVariables = GetAllEnvironmentVariablesInScope -Scope $expectedEnvironmentVariableScope -Hashtable

            $expectedEnvironmentVariables.Keys | ForEach-Object {
                $actualEnvironmentVariables.ContainsKey($_) | Should -Be $true -Because "environment variable named '$_' is expected to still exist"
                $actualEnvironmentVariables[$_] | Should -Be $expectedEnvironmentVariables[$_] -Because "environment variable named '$_' is expected to be unchanged"
            }
            $actualEnvironmentVariables | Enumerate-DictionaryEntry | ForEach-Object {
                $expectedEnvironmentVariables.ContainsKey($_.Key) | Should -Be $true -Because "environment variable named '$($_.Key)' should not have been created"
            }
        }
        function Assert-EnvironmentVariableWasSet {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory=$true, ParameterSetName='Default')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_NameCasedDifferently')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_NameCasedDifferently_WithNoOtherChanges')]
                # [Parameter(Mandatory=$true, ParameterSetName='NameCasedDifferently')]
                # [Parameter(Mandatory=$true, ParameterSetName='NameCasedDifferently_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='NameCasingUnchanged')]
                [Parameter(Mandatory=$true, ParameterSetName='NameCasingUnchanged_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='WithNoOtherChanges')]
                [ValidateNotNullOrEmpty()]
                [string] $Name,

                [Parameter(Mandatory=$true, ParameterSetName='Default')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_NameCasedDifferently')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_NameCasedDifferently_WithNoOtherChanges')]
                # [Parameter(Mandatory=$true, ParameterSetName='NameCasedDifferently')]
                # [Parameter(Mandatory=$true, ParameterSetName='NameCasedDifferently_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='NameCasingUnchanged')]
                [Parameter(Mandatory=$true, ParameterSetName='NameCasingUnchanged_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='WithNoOtherChanges')]
                [AllowNull()][AllowEmptyString()]
                [object] $Value,

                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_NameCasedDifferently')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_NameCasedDifferently_WithNoOtherChanges')]
                [switch] $NewlyCreated,

                # [Parameter(Mandatory=$true, ParameterSetName='NameCasedDifferently')]
                # [Parameter(Mandatory=$true, ParameterSetName='NameCasedDifferently_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_NameCasedDifferently')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_NameCasedDifferently_WithNoOtherChanges')]
                [switch] $NameCasedDifferently,

                [Parameter(Mandatory=$true, ParameterSetName='NameCasingUnchanged')]
                [Parameter(Mandatory=$true, ParameterSetName='NameCasingUnchanged_WithNoOtherChanges')]
                [switch] $NameCasingUnchanged,

                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='NewlyCreated_NameCasedDifferently_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='NameCasedDifferently_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='NameCasingUnchanged_WithNoOtherChanges')]
                [Parameter(Mandatory=$true, ParameterSetName='WithNoOtherChanges')]
                [switch] $WithNoOtherChanges
            )
            $actualEnvironmentVariables = GetAllEnvironmentVariablesInScope -Scope $expectedEnvironmentVariableScope -Hashtable
            if ($NewlyCreated) {
                $actualEnvironmentVariables.ContainsKey($Name) | Should -Be $true -Because "environment variable named '$Name' should have been created"
            } else {
                $actualEnvironmentVariables.ContainsKey($Name) | Should -Be $true -Because "environment variable named '$Name' should still exist"
            }
            $actualEnvironmentVariables[$Name] | Should -Be $Value -Because "environment variable named '$Name' is expected to have specific value"
            if ($NewlyCreated) {
                $originalEnvironmentVariables.ContainsKey($Name) | Should -Be $false -Because "environment variable named '$Name' should not have existed before"
            } else {
                $originalEnvironmentVariables.ContainsKey($Name) | Should -Be $true -Because "environment variable named '$Name' should have existed before"
            }
            if (-not $NewlyCreated) {
                if ($NameCasedDifferently) {
                    $exactOriginalName = $originalEnvironmentVariables.Keys | Where-Object { $_ -ieq $Name } | Select-Object -First 1
                    $exactOriginalName | Should -Not -BeNullOrEmpty -Because "environment variable named '$Name' should have been found in originalEnvironmentVariables"
                    $exactCurrentName = $actualEnvironmentVariables.Keys | Where-Object { $_ -ieq $Name } | Select-Object -First 1
                    $exactCurrentName | Should -Not -BeNullOrEmpty -Because "environment variable named '$Name' should have been found in actualEnvironmentVariables"
                    $exactCurrentName | Should -Not -BeExactly $exactOriginalName -Because "environment variable named '$Name' should have had a name casing change"
                } elseif ($NameCasingUnchanged) {
                    $exactOriginalName = $originalEnvironmentVariables.Keys | Where-Object { $_ -ieq $Name } | Select-Object -First 1
                    $exactOriginalName | Should -Not -BeNullOrEmpty -Because "environment variable named '$Name' should have been found in originalEnvironmentVariables"
                    $exactCurrentName = $actualEnvironmentVariables.Keys | Where-Object { $_ -ieq $Name } | Select-Object -First 1
                    $exactCurrentName | Should -Not -BeNullOrEmpty -Because "environment variable named '$Name' should have been found in actualEnvironmentVariables"
                    $exactCurrentName | Should -BeExactly $exactOriginalName -Because "environment variable named '$Name' should not have had a name casing change"
                }
            } elseif ($NewlyCreated -and $NameCasedDifferently) {
                $originalEnvironmentVariables.Keys | Where-Object { $_ -ieq $Name } | Should -BeNullOrEmpty -Because "environment variable named '$Name' should not have existed before"
            }
            if ($WithNoOtherChanges) {
                $expectedEnvironmentVariables = $originalEnvironmentVariables.Clone()
                $expectedEnvironmentVariables[$Name] = $Value
                $expectedEnvironmentVariables | Enumerate-DictionaryEntry | ForEach-Object {
                    $actualEnvironmentVariables.ContainsKey($_.Key) | Should -Be $true -Because "environment variable named '$($_.Key)' should still exist"
                    $actualEnvironmentVariables[$_.Key] | Should -Be $_.Value -Because "environment variable named '$($_.Key)' should be unchanged"
                }
                $actualEnvironmentVariables | Enumerate-DictionaryEntry | ForEach-Object {
                    $expectedEnvironmentVariables.ContainsKey($_.Key) | Should -Be $true -Because "environment variable named '$($_.Key)' should not have been created"
                }
            }
        }
    }

    Context "when invoked" {
        Context "without pipeline input" {
            Context "scoped to Process" {
                BeforeEach {
                    $sutInvocationArgs = [hashtable]@{
                        $expectedEnvironmentVariableScope.ToString() = $true
                    }
                }

                Context "no other parameters" {
                    It "errs" {
                        { Set-EnvVar @sutInvocationArgs } | Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
                        Assert-EnvironmentVariablesAllUnchanged
                    }

                    # We don't test for 'ErrorAction set to SilentlyContinue' because it doesn't suppress ParameterBindingException.

                    # Context "ErrorAction set to SilentlyContinue" {
                    #     BeforeEach {
                    #         $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                    #     }

                    #     It "does nothing" {
                    #         { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw
                    #         Assert-EnvironmentVariablesAllUnchanged
                    #     }

                    #     It "returns nothing" {
                    #         $result = Set-EnvVar @sutInvocationArgs
                    #         $result | Should -BeNullOrEmpty
                    #     }
                    # }
                }

                Context "Name parameter has single value" {
                    BeforeEach {
                        $attemptedEnvironmentVariableName = "foo" + [System.Guid]::NewGuid().ToString()
                        $sutInvocationArgs.Name = $attemptedEnvironmentVariableName
                    }

                    Context "missing Value parameter" { # e.g. "no other parameters"
                        It "errs" {
                            { Set-EnvVar @sutInvocationArgs } | Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
                            Assert-EnvironmentVariablesAllUnchanged
                        }

                        # We don't test for 'ErrorAction set to SilentlyContinue' because it doesn't suppress ParameterBindingException.
                    }

                    Context "Value parameter is valid" {
                        BeforeEach {
                            $attemptedEnvironmentVariableValue = "bar" + [System.Guid]::NewGuid().ToString()
                            $sutInvocationArgs.Value = $attemptedEnvironmentVariableValue
                        }

                        Context "environment variable didn't already exist" {
                            It "creates the environment variable" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariableWasSet -Name $attemptedEnvironmentVariableName -Value $attemptedEnvironmentVariableValue -NewlyCreated -WithNoOtherChanges
                            }
                        }

                        Context "environment variable already existed" {
                            BeforeEach {
                                $originalEnvironmentVariableValue = "baz"+[System.Guid]::NewGuid().ToString()
                                Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableName -Value $originalEnvironmentVariableValue
                            }

                            It "updates the environment variable" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariableWasSet -Name $attemptedEnvironmentVariableName -Value $attemptedEnvironmentVariableValue -WithNoOtherChanges
                            }
                        }

                        Context "environment variable already existed, name cased differently" {
                            BeforeEach {
                                $originalEnvironmentVariableName = $attemptedEnvironmentVariableName.ToUpper()
                                $originalEnvironmentVariableValue = "baz"+[System.Guid]::NewGuid().ToString()
                                Set-EnvironmentVariableWithProvenance -Name $originalEnvironmentVariableName -Value $originalEnvironmentVariableValue
                            }

                            Context "platform environment variable names are case-insensitive" -Skip:(-not $IsWindows) {
                                It "updates the environment variable's value, but doesn't change its name" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariableWasSet -Name $attemptedEnvironmentVariableName -Value $attemptedEnvironmentVariableValue -NameCasingUnchanged -WithNoOtherChanges
                                }
                            }

                            Context "platform environment variable names are case-sensitive" -Skip:($IsWindows) {
                                It "creates a new environment variable, and doesn't change the original" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariableWasSet -Name $attemptedEnvironmentVariableName -Value $attemptedEnvironmentVariableValue -NameCasedDifferently -NewlyCreated -WithNoOtherChanges
                                }
                            }
                        }
                    }

                    # TODO:
                    # Context "Value parameter is `$null" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variable already existed, name cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variable didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }

                    # TODO:
                    # Context "Value parameter is empty string" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variable already existed, name cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variable didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }
                }

                Context "Name parameter has multiple values" {
                    # TODO:
                    # Context "missing Value parameter" {
                        # TODO:
                        # It …

                        # TODO:
                        # Context "ErrorAction set to SilentlyContinue" {
                        # }
                    # }

                    # TODO:
                    # Context "Value parameter is valid" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variable already existed, name cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variable didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }

                    # TODO:
                    # Context "Value parameter is `$null" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variable already existed, name cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variable didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }

                    # TODO:
                    # Context "Value parameter is empty string" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variable already existed, name cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variable didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }
                }

                Context "KVP parameter" {
                    # TODO:
                    # Context "Value property is valid" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variable already existed, name cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variable didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }

                    # TODO:
                    # Context "Value property is `$null" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variable already existed, name cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variable didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }

                    # TODO:
                    # Context "Value property is empty string" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variable already existed, name cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variable didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }
                }

                Context "Entry parameter" {
                    # TODO:
                    # Context "Value property is valid" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variable already existed, name cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variable didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }

                    # TODO:
                    # Context "Value property is `$null" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variable already existed, name cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variable didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }

                    # TODO:
                    # Context "Value property is empty string" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variable already existed, name cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variable didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }
                }

                Context "Environment parameter" {
                    # TODO:
                    # Context "Value properties all valid" {
                        # TODO:
                        # Context "environment variable already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variables already existed, names cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variables didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }

                    # TODO:
                    # Context "Value properties are `$null" {
                        # TODO:
                        # Context "environment variables already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variables already existed, names cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variables didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }

                    # TODO:
                    # Context "Value properties are empty strings" {
                        # TODO:
                        # Context "environment variables already existed" {
                            # TODO:
                            # It …
                        # }

                        # TODO:
                        # Context "environment variables already existed, names cased differently" {
                            # TODO:
                            # Context "platform env var names are case-insensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "platform env var names are case-sensitive" { # conditionally skip
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "environment variables didn't already exist" {
                            # TODO:
                            # It …
                        # }
                    # }
                }
            }
        }

        Context "with pipeline input" {
            Context "scoped to Process" {
                BeforeEach {
                    $sutInvocationArgs = [hashtable]@{
                        $expectedEnvironmentVariableScope.ToString() = $true
                    }
                }

                Context "pipeline is X" {
                    BeforeEach {
                        $sutInvocationPipelineInput = [string]::Empty # pipeline is X
                    }

                    Context "no other parameters" {
                        It "TODO" {
                            # TODO
                        }
                    }

                    # Context "*, ErrorAction set to SilentlyContinue" {
                    # }
                }

                # Context "pipeline is *" {
                # }
            }
        }
    }
}
