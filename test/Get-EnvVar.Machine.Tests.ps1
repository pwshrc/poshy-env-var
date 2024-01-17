#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest



. "$PSScriptRoot/Get-EnvVar.Common.ps1"

Describe "cmdlet Get-EnvVar" -Skip:(-not (TestCanSetEnvironmentVariablesInScope ([System.EnvironmentVariableTarget]::Machine))) {
    BeforeAll {
        $expectedEnvironmentVariableScope = [System.EnvironmentVariableTarget]::Machine
    }

    BeforeEach {
        . "$PSScriptRoot/../src/Get-EnvVar.ps1"
    }

    Context "when invoked" {
        Context "scoped to Machine" {
            BeforeEach {
                $sutInvocationArgs = [hashtable]@{
                    $expectedEnvironmentVariableScope.ToString() = $true
                }
            }

            Context "parameter Name matches existing environment variable name" {
                BeforeEach {
                    $expectedEnvironmentVariableName = [System.Environment]::GetEnvironmentVariables($expectedEnvironmentVariableScope).Keys | Get-Random -Count 1
                    $sutInvocationArgs.Name = $expectedEnvironmentVariableName
                    $expectedEnvironmentVariableValue = [System.Environment]::GetEnvironmentVariable($expectedEnvironmentVariableName, $expectedEnvironmentVariableScope)
                }

                Context "no other parameters" {
                    It "returns the environment variable entry" {
                        $actual = Get-EnvVar @sutInvocationArgs

                        $actual | Should -BeOfType [System.Collections.DictionaryEntry]
                        $actual.Name | Should -Be $expectedEnvironmentVariableName
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
                    It "returns the environment variable entry" {
                        $actual = Get-EnvVar @sutInvocationArgs

                        $actual | Should -BeOfType [System.Collections.DictionaryEntry]
                        $actual.Name | Should -Be $expectedEnvironmentVariableName
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

                Context "switch ValueOnly present" {
                    BeforeEach {
                        $sutInvocationArgs.ValueOnly = $true
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
                    It "returns the environment variable entry" {
                        $actual = Get-EnvVar @sutInvocationArgs

                        $actual | Should -BeOfType [System.Collections.DictionaryEntry]
                        $actual.Name | Should -Be $expectedEnvironmentVariableName
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

            Context "parameter NameMatch NOT matches an existing environment variable name" {
                BeforeEach {
                    $attemptedEnvironmentVariableName = "foo" + [System.Guid]::NewGuid().ToString()
                    $sutInvocationArgs.NameMatch = $attemptedEnvironmentVariableName
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
            }
        }
    }
}
