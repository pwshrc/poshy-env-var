#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


BeforeDiscovery {
    . "$PSScriptRoot/Common.ps1"
}

Describe "cmdlet Get-EnvVar" -Skip:(-not (TestCanSetEnvironmentVariablesInScope ([System.EnvironmentVariableTarget]::Machine))) {
    BeforeDiscovery {
        Get-ChildItem -Path "$PSScriptRoot/../src/private/*.ps1" | ForEach-Object {
            . $_.FullName
        }
        $expectedEnvironmentVariableScope = [System.EnvironmentVariableTarget]::Machine
    }

    BeforeAll {
        Get-ChildItem -Path "$PSScriptRoot/../src/private/*.ps1" | ForEach-Object {
            . $_.FullName
        }
        $expectedEnvironmentVariableScope = [System.EnvironmentVariableTarget]::Machine
    }

    BeforeEach {
        . "$PSScriptRoot/../src/Get-EnvVar.ps1"
    }

    Context "when invoked" {
        Context "without pipeline input" {
            Context "scoped to Machine" {
                BeforeEach {
                    $sutInvocationArgs = [hashtable]@{
                        $expectedEnvironmentVariableScope.ToString() = $true
                    }
                }

                Context "no other parameters" {
                    It "should return all Machine-level environment variables" {
                        $expectedEnvironmentVariables = GetAllEnvironmentVariablesInScope -Scope $expectedEnvironmentVariableScope -Raw

                        $actual = Get-EnvVar @sutInvocationArgs

                        $actual | Should -BeHashtableEqualTo $expectedEnvironmentVariables -KeyComparer (GetPlatformEnvVarNameStringComparer)
                    }
                }

                Context "switch ValueOnly present" {
                    BeforeEach {
                        $sutInvocationArgs.ValueOnly = $true
                    }

                    It "should return the values of all Machine-level environment variables" {
                        $expectedEnvironmentVariables = GetAllEnvironmentVariablesInScope -Scope $expectedEnvironmentVariableScope -Hashtable

                        $actual = Get-EnvVar @sutInvocationArgs

                        Should -ActualValue $actual -BeOfType [System.Collections.IList]
                        $actual = ([System.Collections.ICollection]$actual)
                        $actual.PSBase.IsReadOnly | Should -Be $true -Because "the returned results should always be read-only"
                        $actual.PSBase.Count | Should -Be $expectedEnvironmentVariables.Count
                        $actual | Should -BeEnumerableSequenceEqualTo ($expectedEnvironmentVariables.Values)
                    }
                }

                Context "parameter Name matches existing environment variable name" {
                    BeforeEach {
                        $expectedEnvironmentVariableName = GetAllEnvironmentVariableKeysInScope $expectedEnvironmentVariableScope | Get-Random -Count 1
                        $sutInvocationArgs.Name = $expectedEnvironmentVariableName
                        $expectedEnvironmentVariableValue = [System.Environment]::GetEnvironmentVariable($expectedEnvironmentVariableName, $expectedEnvironmentVariableScope)
                    }

                    Context "no other parameters" {
                        It "returns the environment variable entry" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeOfType [System.Collections.DictionaryEntry]
                            $actual.Key | Should -Be $expectedEnvironmentVariableName
                            $actual.Value | Should -Be $expectedEnvironmentVariableValue
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "returns the environment variable value" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -Be $expectedEnvironmentVariableValue
                        }
                    }
                }

                Context "parameter Name NOT matches existing environment variable name" {
                    BeforeEach {
                        $attemptedEnvironmentVariableName = "foo" + [System.Guid]::NewGuid().ToString()
                        $sutInvocationArgs.Name = $attemptedEnvironmentVariableName
                    }

                    Context "no other parameters" {
                        It "errs" {
                            { Get-EnvVar @sutInvocationArgs } | Should -Throw  # TODO: Check for specific error.
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "errs" {
                            { Get-EnvVar @sutInvocationArgs } | Should -Throw  # TODO: Check for specific error.
                        }
                    }

                    Context "ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }

                    Context "switch ValueOnly present, parameter ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }
                }

                Context "parameter NameLike matches an existing environment variable name" {
                    BeforeEach {
                        $expectedEnvironmentVariableName = "foo" + [System.Guid]::NewGuid().ToString()
                        $expectedEnvironmentVariableValue = [System.Guid]::NewGuid().ToString()
                        [System.Environment]::SetEnvironmentVariable($expectedEnvironmentVariableName, $expectedEnvironmentVariableValue, $expectedEnvironmentVariableScope)
                        $sutInvocationArgs.NameLike = [System.Management.Automation.WildcardPattern]::Escape($expectedEnvironmentVariableName)
                    }

                    AfterEach {
                        [System.Environment]::SetEnvironmentVariable($expectedEnvironmentVariableName, $null, $expectedEnvironmentVariableScope)
                    }

                    Context "no other parameters" {
                        It "returns the environment variable entry in a read-only dictionary" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeOfType [System.Collections.IDictionary]
                            $actual = ([System.Collections.IDictionary]$actual)
                            $actual.PSBase.IsReadOnly | Should -Be $true -Because "the returned results should always be read-only"
                            $actual.PSBase.Count | Should -Be 1
                            $actual.PSBase.Keys | Should -Contain $expectedEnvironmentVariableName
                            $actual.PSBase.Values | Should -Contain $expectedEnvironmentVariableValue
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "returns the environment variable value" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -Be $expectedEnvironmentVariableValue
                        }
                    }
                }

                Context "parameter NameLike NOT matches an existing environment variable name" {
                    BeforeEach {
                        $attemptedEnvironmentVariableName = "foo" + [System.Guid]::NewGuid().ToString()
                        $sutInvocationArgs.NameLike = $attemptedEnvironmentVariableName
                    }

                    Context "no other parameters" {
                        It "returns nothing" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }

                    Context "ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "returns nothing" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }

                    Context "switch ValueOnly present, parameter ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }
                }

                Context "parameter NameMatch matches an existing environment variable name" {
                    BeforeEach {
                        $expectedEnvironmentVariableName = "foo" + [System.Guid]::NewGuid().ToString()
                        $expectedEnvironmentVariableValue = [System.Guid]::NewGuid().ToString()
                        [System.Environment]::SetEnvironmentVariable($expectedEnvironmentVariableName, $expectedEnvironmentVariableValue, $expectedEnvironmentVariableScope)
                        $sutInvocationArgs.NameMatch = [System.Text.RegularExpressions.Regex]::Escape($expectedEnvironmentVariableName)
                    }

                    AfterEach {
                        [System.Environment]::SetEnvironmentVariable($expectedEnvironmentVariableName, $null, $expectedEnvironmentVariableScope)
                    }

                    Context "no other parameters" {
                        It "returns the environment variable entry in a read-only dictionary" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeOfType [System.Collections.IDictionary]
                            $actual = ([System.Collections.IDictionary]$actual)
                            $actual.PSBase.IsReadOnly | Should -Be $true -Because "the returned results should always be read-only"
                            $actual.PSBase.Count | Should -Be 1
                            $actual.PSBase.Keys | Should -Contain $expectedEnvironmentVariableName
                            $actual.PSBase.Values | Should -Contain $expectedEnvironmentVariableValue
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "returns the environment variable value" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -Be $expectedEnvironmentVariableValue
                        }
                    }
                }

                Context "parameter NameMatch NOT matches an existing environment variable name" {
                    BeforeEach {
                        $attemptedEnvironmentVariableName = "foo" + [System.Guid]::NewGuid().ToString()
                        $sutInvocationArgs.NameMatch = [System.Text.RegularExpressions.Regex]::Escape($attemptedEnvironmentVariableName)
                    }

                    Context "no other parameters" {
                        It "returns nothing" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "returns nothing" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }

                    Context "ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }

                    Context "switch ValueOnly present, parameter ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }
                }
            }
        }

        Context "with pipeline input" {
            Context "scoped to Machine" {
                BeforeEach {
                    $sutInvocationArgs = [hashtable]@{
                        $expectedEnvironmentVariableScope.ToString() = $true
                    }
                }

                Context "pipeline is empty string" {
                    BeforeEach {
                        $sutInvocationPipelineInput = [string]::Empty
                    }

                    Context "no other parameters" {
                        It "errs" {
                            { $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs } | Should -Throw  # TODO: Check for specific error.
                        }
                    }

                    Context "ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "errs" {
                            { $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs } | Should -Throw  # TODO: Check for specific error.
                        }
                    }

                    Context "switch ValueOnly present, parameter ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }
                }

                Context "pipeline is single string matching environment variable name" {
                    BeforeEach {
                        $sutInvocationPipelineInput = [string](GetAllEnvironmentVariableKeysInScope $expectedEnvironmentVariableScope | Get-Random -Count 1)
                        $expectedEnvironmentVariableName = $sutInvocationPipelineInput
                        $expectedEnvironmentVariableValue = [System.Environment]::GetEnvironmentVariable($expectedEnvironmentVariableName, $expectedEnvironmentVariableScope)
                    }

                    Context "no other parameters" {
                        It "returns the environment variable entry" {
                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeOfType [System.Collections.DictionaryEntry]
                            $actual.Key | Should -Be $expectedEnvironmentVariableName
                            $actual.Value | Should -Be $expectedEnvironmentVariableValue
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "returns the environment variable value" {
                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -Be $expectedEnvironmentVariableValue
                        }
                    }
                }

                Context "pipeline is multiple strings ALL matching environment variable names" {
                    BeforeEach {
                        $expectedEnvironmentVariableNames = [string[]]@(GetAllEnvironmentVariableKeysInScope $expectedEnvironmentVariableScope | Get-Random -Count 3)
                        $sutInvocationPipelineInput = $expectedEnvironmentVariableNames
                    }

                    Context "no other parameters" {
                        It "returns the environment variable entries" {
                            $expectedEnvironmentVariableEntryTuples = [System.Collections.DictionaryEntry[]]($expectedEnvironmentVariableNames | ForEach-Object {
                                [System.Collections.DictionaryEntry]::new($_, [System.Environment]::GetEnvironmentVariable($_, $expectedEnvironmentVariableScope))
                            })

                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -Be $expectedEnvironmentVariableEntryTuples
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "returns the environment variable values" {
                            $expectedEnvironmentVariableValues = $expectedEnvironmentVariableNames | ForEach-Object {
                                [System.Environment]::GetEnvironmentVariable($_, $expectedEnvironmentVariableScope)
                            }

                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -Be $expectedEnvironmentVariableValues
                        }
                    }
                }

                Context "pipeline is single string NOT matching environment variable name" {
                    BeforeEach {
                        $sutInvocationPipelineInput = "foo" + [System.Guid]::NewGuid().ToString()
                    }

                    Context "no other parameters" {
                        It "errs" {
                            { $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs } | Should -Throw  # TODO: Check for specific error.
                        }
                    }

                    Context "ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "errs" {
                            { $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs } | Should -Throw  # TODO: Check for specific error.
                        }
                    }

                    Context "switch ValueOnly present, parameter ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }
                }

                Context "pipeline is multiple strings NONE matching environment variable names" {
                    BeforeEach {
                        $sutInvocationPipelineInput = [string[]]@("foo" + [System.Guid]::NewGuid().ToString(), "foo" + [System.Guid]::NewGuid().ToString(), "foo" + [System.Guid]::NewGuid().ToString())
                    }

                    Context "no other parameters" {
                        It "errs" {
                            { $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs } | Should -Throw  # TODO: Check for specific error.
                        }
                    }

                    Context "ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "errs" {
                            { $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs } | Should -Throw  # TODO: Check for specific error.
                        }
                    }

                    Context "switch ValueOnly present, parameter ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns nothing" {
                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -BeNullOrEmpty
                        }
                    }
                }

                Context "pipeline is multiple strings SOME matching environment variable names" {
                    BeforeEach {
                        $expectedEnvironmentVariableNames = [string[]]@(GetAllEnvironmentVariableKeysInScope $expectedEnvironmentVariableScope | Get-Random -Count 3)
                        $sutInvocationPipelineInput = [string[]]@()
                        $sutInvocationPipelineInput += $expectedEnvironmentVariableNames

                        # Add the names of some non-existent environment variables.
                        $sutInvocationPipelineInput += @("foo" + [System.Guid]::NewGuid().ToString(), "foo" + [System.Guid]::NewGuid().ToString(), "foo" + [System.Guid]::NewGuid().ToString())
                    }

                    Context "no other parameters" {
                        It "errs" {
                            { $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs } | Should -Throw  # TODO: Check for specific error.
                        }
                    }

                    Context "ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns the matching environment variable entries" {
                            $expectedEnvironmentVariableEntryTuples = [System.Collections.DictionaryEntry[]]($expectedEnvironmentVariableNames | ForEach-Object {
                                [System.Collections.DictionaryEntry]::new($_, [System.Environment]::GetEnvironmentVariable($_, $expectedEnvironmentVariableScope))
                            })

                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -Be $expectedEnvironmentVariableEntryTuples
                        }
                    }

                    Context "switch ValueOnly present" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                        }

                        It "errs" {
                            { $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs } | Should -Throw  # TODO: Check for specific error.
                        }
                    }

                    Context "switch ValueOnly present, parameter ErrorAction set to SilentlyContinue" {
                        BeforeEach {
                            $sutInvocationArgs.ValueOnly = $true
                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                        }

                        It "returns the matching environment variable values" {
                            $expectedEnvironmentVariableValues = $expectedEnvironmentVariableNames | ForEach-Object {
                                [System.Environment]::GetEnvironmentVariable($_, $expectedEnvironmentVariableScope)
                            }

                            $actual = $sutInvocationPipelineInput | Get-EnvVar @sutInvocationArgs

                            $actual | Should -Be $expectedEnvironmentVariableValues
                        }
                    }
                }
            }
        }
    }
}