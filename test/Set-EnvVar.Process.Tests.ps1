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
                [object] $Value,

                [switch] $CaseChange
            )
            if (-not $CaseChange) {
                SetEnvironmentVariableInScope -Scope $expectedEnvironmentVariableScope -Name $Name -Value $Value
                $originalEnvironmentVariables[$Name] = $Value
            } else {
                # TODO: Confirm this works.
                $nameWithOriginalCasing = @($originalEnvironmentVariables.Keys | Where-Object { $_ -ieq $Name }) | Select-Object -First 1
                SetEnvironmentVariableInScope -Scope $expectedEnvironmentVariableScope -Name $nameWithOriginalCasing -Value $null
                $originalEnvironmentVariables.Remove($nameWithOriginalCasing)
                SetEnvironmentVariableInScope -Scope $expectedEnvironmentVariableScope -Name $Name -Value $Value
                $originalEnvironmentVariables[$Name] = $Value
            }
        }
        function Assert-EnvironmentVariablesAllUnchanged {
            $actualEnvironmentVariables = GetAllEnvironmentVariablesInScope -Scope $expectedEnvironmentVariableScope -Hashtable
            $actualEnvironmentVariables | Should -BeHashtableEqualTo $originalEnvironmentVariables -KeyComparer (GetPlatformEnvVarNameStringComparer)
        }
        function Assert-EnvironmentVariablesWereSet {
            [CmdletBinding()]
            param(
                [ValidateNotNullOrEmpty()]
                [hashtable] $envExpected
            )
            $expectedEnvironmentVariables = $originalEnvironmentVariables.Clone()
            $envExpected | Enumerate-DictionaryEntry | ForEach-Object {
                if ($null -ne $_.Value) {
                    $expectedEnvironmentVariables[$_.Key] = $_.Value
                } elseif ($expectedEnvironmentVariables.ContainsKey($_.Key)) {
                    $expectedEnvironmentVariables.Remove($_.Key)
                }
            }
            $actualEnvironmentVariables = GetAllEnvironmentVariablesInScope -Scope $expectedEnvironmentVariableScope -Hashtable
            $actualEnvironmentVariables | Should -BeHashtableEqualTo $expectedEnvironmentVariables -KeyComparer (GetPlatformEnvVarNameStringComparer)
        }
        function Assert-EnvironmentVariableWasSet {
            [CmdletBinding()]
            param(
                [ValidateNotNullOrEmpty()]
                [string] $Name,

                [AllowNull()][AllowEmptyString()]
                [object] $Value
            )
            Assert-EnvironmentVariablesWereSet -envExpected @{ $Name = $Value }
        }
        function Assert-EnvironmentVariableWasRemoved {
            [CmdletBinding()]
            param(
                [ValidateNotNullOrEmpty()]
                [string] $Name
            )
            Assert-EnvironmentVariablesWereSet -envExpected @{ $Name = $null }
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

                    Context "Value parameter is `$null" {
                        BeforeEach {
                            $sutInvocationArgs.Add("Value", $null)
                        }

                        Context "environment variable already existed" {
                            BeforeEach {
                                $originalEnvironmentVariableValue = "baz"+[System.Guid]::NewGuid().ToString()
                                Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableName -Value $originalEnvironmentVariableValue
                            }

                            It "removes the environment variable" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariableWasRemoved -Name $attemptedEnvironmentVariableName
                            }
                        }

                        Context "environment variable already existed, name cased differently" {
                            BeforeEach {
                                $originalEnvironmentVariableName = $attemptedEnvironmentVariableName.ToUpper()
                                $originalEnvironmentVariableValue = "baz"+[System.Guid]::NewGuid().ToString()
                                Set-EnvironmentVariableWithProvenance -Name $originalEnvironmentVariableName -Value $originalEnvironmentVariableValue
                            }

                            Context "platform env var names are case-insensitive" -Skip:(-not $IsWindows) {
                                It "removes the environment variable" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariableWasRemoved -Name $originalEnvironmentVariableName
                                }
                            }

                            Context "platform env var names are case-sensitive" -Skip:($IsWindows) {
                                It "removes the environment variable" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariableWasRemoved -Name $originalEnvironmentVariableName
                                }
                            }
                        }

                        Context "environment variable didn't already exist" {
                            It "does nothing" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariablesAllUnchanged
                            }
                        }
                    }

                    Context "Value parameter is empty string" {
                        BeforeEach {
                            $sutInvocationArgs.Add("Value", [string]::Empty)
                        }

                        Context "environment variable already existed" {
                            It "errs" {
                                { Set-EnvVar @sutInvocationArgs } | Should -Throw
                                Assert-EnvironmentVariablesAllUnchanged
                            }

                            Context "ErrorAction set to SilentlyContinue" {
                                BeforeEach {
                                    $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                                }

                                It "does nothing" {
                                    { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw
                                    Assert-EnvironmentVariablesAllUnchanged
                                }

                                It "returns nothing" {
                                    $result = Set-EnvVar @sutInvocationArgs
                                    $result | Should -BeNullOrEmpty
                                }
                            }
                        }

                        Context "environment variable already existed, name cased differently" {
                            Context "platform env var names are case-insensitive" -Skip:(-not $IsWindows) {
                                It "errs" {
                                    { Set-EnvVar @sutInvocationArgs } | Should -Throw
                                    Assert-EnvironmentVariablesAllUnchanged
                                }

                                Context "ErrorAction set to SilentlyContinue" {
                                    BeforeEach {
                                        $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                                    }

                                    It "does nothing" {
                                        { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw
                                        Assert-EnvironmentVariablesAllUnchanged
                                    }

                                    It "returns nothing" {
                                        $result = Set-EnvVar @sutInvocationArgs
                                        $result | Should -BeNullOrEmpty
                                    }
                                }
                            }

                            Context "platform env var names are case-sensitive" -Skip:($IsWindows) {
                                It "errs" {
                                    { Set-EnvVar @sutInvocationArgs } | Should -Throw
                                    Assert-EnvironmentVariablesAllUnchanged
                                }

                                Context "ErrorAction set to SilentlyContinue" {
                                    BeforeEach {
                                        $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                                    }

                                    It "does nothing" {
                                        { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw
                                        Assert-EnvironmentVariablesAllUnchanged
                                    }

                                    It "returns nothing" {
                                        $result = Set-EnvVar @sutInvocationArgs
                                        $result | Should -BeNullOrEmpty
                                    }
                                }
                            }
                        }

                        Context "environment variable didn't already exist" {
                            It "errs" {
                                { Set-EnvVar @sutInvocationArgs } | Should -Throw
                                Assert-EnvironmentVariablesAllUnchanged
                            }

                            Context "ErrorAction set to SilentlyContinue" {
                                BeforeEach {
                                    $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                                }

                                It "does nothing" {
                                    { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw
                                    Assert-EnvironmentVariablesAllUnchanged
                                }

                                It "returns nothing" {
                                    $result = Set-EnvVar @sutInvocationArgs
                                    $result | Should -BeNullOrEmpty
                                }
                            }
                        }
                    }
                }

                Context "Name parameter has multiple" {
                    BeforeEach {
                        $attemptedEnvironmentVariableNames = [string[]]@(("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()))
                        $sutInvocationArgs.Name = $attemptedEnvironmentVariableNames
                    }

                    Context "strings ALL matching environment variable names" {
                        BeforeEach {
                            $overwrittenEnvironmentVariableNames = $attemptedEnvironmentVariableNames
                            $overwrittenEnvironmentVariableValues = [string[]]@(("baz"+[System.Guid]::NewGuid().ToString()), ("baz"+[System.Guid]::NewGuid().ToString()), ("baz"+[System.Guid]::NewGuid().ToString()))
                            Set-EnvironmentVariableWithProvenance -Name $overwrittenEnvironmentVariableNames[0] -Value $overwrittenEnvironmentVariableValues[0]
                            Set-EnvironmentVariableWithProvenance -Name $overwrittenEnvironmentVariableNames[1] -Value $overwrittenEnvironmentVariableValues[1]
                            Set-EnvironmentVariableWithProvenance -Name $overwrittenEnvironmentVariableNames[2] -Value $overwrittenEnvironmentVariableValues[2]
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

                            Context "environment variables already existed" {
                                It "updates the environment variables" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariablesWereSet -envExpected @{
                                        $overwrittenEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValue;
                                        $overwrittenEnvironmentVariableNames[1] = $attemptedEnvironmentVariableValue;
                                        $overwrittenEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValue
                                    }
                                }
                            }

                            Context "environment variables already existed, names cased differently" {
                                BeforeEach {
                                    Set-EnvironmentVariableWithProvenance -Name $overwrittenEnvironmentVariableNames[1].ToUpper() -Value $overwrittenEnvironmentVariableValues[1] -CaseChange
                                }

                                Context "platform env var names are case-insensitive" -Skip:(-not $IsWindows) {
                                    It "updates the environment variables' values, but doesn't change their names" {
                                        Set-EnvVar @sutInvocationArgs

                                        Assert-EnvironmentVariablesWereSet -envExpected @{
                                            $overwrittenEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValue;
                                            $overwrittenEnvironmentVariableNames[1] = $attemptedEnvironmentVariableValue;
                                            $overwrittenEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValue
                                        }
                                    }
                                }

                                Context "platform env var names are case-sensitive" -Skip:($IsWindows) {
                                    It "creates new environment variables with alternate casing only when casing diverges" {
                                        Set-EnvVar @sutInvocationArgs

                                        Assert-EnvironmentVariablesWereSet -envExpected @{
                                            $overwrittenEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValue;
                                            $overwrittenEnvironmentVariableNames[1].ToUpper() = $attemptedEnvironmentVariableValue;
                                            $overwrittenEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValue
                                        }
                                    }
                                }
                            }
                        }

                        Context "Value parameter is `$null" {
                            BeforeEach {
                                $sutInvocationArgs.Add("Value", $null)
                            }

                            Context "environment variables already existed" {
                                It "removes the environment variables" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariablesWereSet -envExpected @{
                                        $overwrittenEnvironmentVariableNames[0] = $null;
                                        $overwrittenEnvironmentVariableNames[1] = $null;
                                        $overwrittenEnvironmentVariableNames[2] = $null
                                    }
                                }
                            }

                            Context "environment variables already existed, names cased differently" {
                                BeforeEach {
                                    Set-EnvironmentVariableWithProvenance -Name $overwrittenEnvironmentVariableNames[1].ToUpper() -Value $overwrittenEnvironmentVariableValues[1] -CaseChange
                                }

                                Context "platform env var names are case-insensitive" -Skip:(-not $IsWindows) {
                                    It "removes the environment variables" {
                                        Set-EnvVar @sutInvocationArgs

                                        Assert-EnvironmentVariablesWereSet -envExpected @{
                                            $overwrittenEnvironmentVariableNames[0] = $null;
                                            $overwrittenEnvironmentVariableNames[1] = $null;
                                            $overwrittenEnvironmentVariableNames[2] = $null
                                        }
                                    }
                                }

                                Context "platform env var names are case-sensitive" -Skip:($IsWindows) {
                                    It "removes the environment variables" {
                                        Set-EnvVar @sutInvocationArgs

                                        Assert-EnvironmentVariablesWereSet -envExpected @{
                                            $overwrittenEnvironmentVariableNames[0] = $null;
                                            $overwrittenEnvironmentVariableNames[1].ToUpper() = $null;
                                            $overwrittenEnvironmentVariableNames[2] = $null
                                        }
                                    }
                                }
                            }
                        }

                        Context "Value parameter is empty string" {
                            BeforeEach {
                                $sutInvocationArgs.Add("Value", [string]::Empty)
                            }

                            Context "environment variables already existed" {
                                It "errs" {
                                    { Set-EnvVar @sutInvocationArgs } | Should -Throw
                                    Assert-EnvironmentVariablesAllUnchanged
                                }

                                Context "ErrorAction set to SilentlyContinue" {
                                    BeforeEach {
                                        $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                                    }

                                    It "does nothing" {
                                        { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw
                                        Assert-EnvironmentVariablesAllUnchanged
                                    }

                                    It "returns nothing" {
                                        $result = Set-EnvVar @sutInvocationArgs
                                        $result | Should -BeNullOrEmpty
                                    }
                                }
                            }

                            Context "environment variables already existed, names cased differently" {
                                BeforeEach {
                                    Set-EnvironmentVariableWithProvenance -Name $overwrittenEnvironmentVariableNames[1].ToUpper() -Value $overwrittenEnvironmentVariableValues[1] -CaseChange
                                }

                                Context "platform env var names are case-insensitive" -Skip:(-not $IsWindows) {
                                    It "errs" {
                                        { Set-EnvVar @sutInvocationArgs } | Should -Throw
                                        Assert-EnvironmentVariablesAllUnchanged
                                    }

                                    Context "ErrorAction set to SilentlyContinue" {
                                        BeforeEach {
                                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                                        }

                                        It "does nothing" {
                                            { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw
                                            Assert-EnvironmentVariablesAllUnchanged
                                        }

                                        It "returns nothing" {
                                            $result = Set-EnvVar @sutInvocationArgs
                                            $result | Should -BeNullOrEmpty
                                        }
                                    }
                                }

                                Context "platform env var names are case-sensitive" -Skip:($IsWindows) {
                                    It "errs" {
                                        { Set-EnvVar @sutInvocationArgs } | Should -Throw
                                        Assert-EnvironmentVariablesAllUnchanged
                                    }

                                    Context "ErrorAction set to SilentlyContinue" {
                                        BeforeEach {
                                            $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                                        }

                                        It "does nothing" {
                                            { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw
                                            Assert-EnvironmentVariablesAllUnchanged
                                        }

                                        It "returns nothing" {
                                            $result = Set-EnvVar @sutInvocationArgs
                                            $result | Should -BeNullOrEmpty
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Context "strings NONE matching environment variable names" {
                        BeforeEach {
                            # Intentionally left blank.
                        }

                        Context "missing Value parameter" { # e.g. "no other parameters"
                            It "errs" {
                                { Set-EnvVar @sutInvocationArgs } | Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
                                Assert-EnvironmentVariablesAllUnchanged
                            }

                            # We don't test for 'ErrorAction set to SilentlyContinue' because it doesn't suppress ParameterBindingException.
                        }

                        # TODO:
                        # Context "Value parameter is valid" {
                            # TODO:
                            # Context "environment variables didn't already exist" {
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "Value parameter is `$null" {
                            # TODO:
                            # Context "environment variables didn't already exist" {
                                # TODO:
                                # It …
                            # }
                        # }

                        # TODO:
                        # Context "Value parameter is empty string" {
                            # TODO:
                            # Context "environment variables didn't already exist" {
                                # TODO:
                                # It …
                            # }
                        # }
                    }

                    Context "strings SOME matching environment variable names" {
                        BeforeEach {
                            $overwrittenEnvironmentVariableName = $attemptedEnvironmentVariableNames[1]
                            $overwrittenEnvironmentVariableValue = "baz"+[System.Guid]::NewGuid().ToString()
                            Set-EnvironmentVariableWithProvenance -Name $overwrittenEnvironmentVariableName -Value $overwrittenEnvironmentVariableValue
                        }

                        Context "missing Value parameter" { # e.g. "no other parameters"
                            It "errs" {
                                { Set-EnvVar @sutInvocationArgs } | Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
                                Assert-EnvironmentVariablesAllUnchanged
                            }

                            # We don't test for 'ErrorAction set to SilentlyContinue' because it doesn't suppress ParameterBindingException.
                        }

                        # TODO:
                        # Context "Value parameter is valid" {
                            # TODO:
                            # Context "environment variables mixed-existence" {
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "environment variables mixed-existence, select name cased differently" {
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
                        # }

                        # TODO:
                        # Context "Value parameter is `$null" {
                            # TODO:
                            # Context "environment variables mixed-existence" {
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "environment variables mixed-existence, select name cased differently" {
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
                        # }

                        # TODO:
                        # Context "Value parameter is empty string" {
                            # TODO:
                            # Context "environment variables mixed-existence" {
                                # TODO:
                                # It …
                            # }

                            # TODO:
                            # Context "environment variables mixed-existence, select name cased differently" {
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
                        # }
                    }
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
