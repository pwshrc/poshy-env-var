#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


BeforeDiscovery {
    . "$PSScriptRoot/Common.ps1"
}

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
            $actualEnvironmentVariables = GetAllEnvironmentVariablesInScope -Scope $expectedEnvironmentVariableScope -Hashtable
            $actualEnvironmentVariables | Should -BeHashtableEqualTo $originalEnvironmentVariables -KeyComparer (GetPlatformEnvVarNameStringComparer)
        }
        function Assert-EnvironmentVariableWasSet {
            param(
                [ValidateNotNullOrEmpty()]
                [string] $Name,

                [AllowNull()][AllowEmptyString()]
                [object] $Value
            )
            $expectedEnvironmentVariables = $originalEnvironmentVariables.Clone()
            $expectedEnvironmentVariables[$Name] = $Value
            $actualEnvironmentVariables = GetAllEnvironmentVariablesInScope -Scope $expectedEnvironmentVariableScope -Hashtable
            $actualEnvironmentVariables | Should -BeHashtableEqualTo $expectedEnvironmentVariables -KeyComparer (GetPlatformEnvVarNameStringComparer)
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

                                Assert-EnvironmentVariableWasSet -Name $attemptedEnvironmentVariableName -Value $attemptedEnvironmentVariableValue
                            }
                        }

                        Context "environment variable already existed" {
                            BeforeEach {
                                $originalEnvironmentVariableValue = "baz"+[System.Guid]::NewGuid().ToString()
                                Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableName -Value $originalEnvironmentVariableValue
                            }

                            It "updates the environment variable" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariableWasSet -Name $attemptedEnvironmentVariableName -Value $attemptedEnvironmentVariableValue
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

                                    Assert-EnvironmentVariableWasSet -Name $originalEnvironmentVariableName -Value $attemptedEnvironmentVariableValue
                                }
                            }

                            Context "platform environment variable names are case-sensitive" -Skip:($IsWindows) {
                                It "creates a new environment variable, and doesn't change the original" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariableWasSet -Name $originalEnvironmentVariableName -Value $attemptedEnvironmentVariableValue
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
