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
                    #
                    #     It "does nothing" {
                    #         { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw
                    #
                    #         Assert-EnvironmentVariablesAllUnchanged
                    #     }
                    #
                    #     It "returns nothing" {
                    #         $result = Set-EnvVar @sutInvocationArgs
                    #
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
                            # We skip calling Set-EnvironmentVariableWithProvenance so that the environment variables won't have previously existed.
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

                            It "adds the environment variables" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariablesWereSet -envExpected @{
                                    $attemptedEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValue;
                                    $attemptedEnvironmentVariableNames[1] = $attemptedEnvironmentVariableValue;
                                    $attemptedEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValue
                                }
                            }
                        }

                        Context "Value parameter is `$null" {
                            BeforeEach {
                                $sutInvocationArgs.Add("Value", $null)
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

                        Context "Value parameter is empty string" {
                            BeforeEach {
                                $sutInvocationArgs.Add("Value", [string]::Empty)
                            }

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

                    Context "strings SOME matching environment variable names" {
                        BeforeEach {
                            # We skip calling Set-EnvironmentVariableWithProvenance for some environment variables so that they won't have previously existed.
                            $overwrittenEnvironmentVariableName = $attemptedEnvironmentVariableNames[1]
                            Set-EnvironmentVariableWithProvenance -Name $overwrittenEnvironmentVariableName -Value ("baz"+[System.Guid]::NewGuid().ToString())
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

                            It "sets the environment variables" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariablesWereSet -envExpected @{
                                    $attemptedEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValue;
                                    $attemptedEnvironmentVariableNames[1] = $attemptedEnvironmentVariableValue;
                                    $attemptedEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValue
                                }
                            }
                        }

                        Context "Value parameter is `$null" {
                            BeforeEach {
                                $sutInvocationArgs.Add("Value", $null)
                            }

                            It "removes the matching environment variable" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariableWasRemoved -Name $overwrittenEnvironmentVariableName
                            }
                        }

                        Context "Value parameter is empty string" {
                            BeforeEach {
                                $sutInvocationArgs.Add("Value", [string]::Empty)
                            }

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

                Context "KVP parameter" {
                    BeforeEach {
                        $attemptedEnvironmentVariableName = "foo" + [System.Guid]::NewGuid().ToString()
                        $attemptedEnvironmentVariableValue = "bar" + [System.Guid]::NewGuid().ToString()
                        $attemptedKVP = [System.Collections.Generic.KeyValuePair[string, object]]::new($attemptedEnvironmentVariableName, $attemptedEnvironmentVariableValue)
                        $sutInvocationArgs.Add('KVP', $attemptedKVP)
                    }

                    Context "Value property is valid" {
                        Context "environment variable already existed" {
                            BeforeEach {
                                $originalEnvironmentVariableName = $attemptedEnvironmentVariableName
                                Set-EnvironmentVariableWithProvenance -Name $originalEnvironmentVariableName -Value ("baz"+[System.Guid]::NewGuid().ToString())
                            }

                            It "updates the environment variable" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariableWasSet -Name $attemptedKVP.Key -Value $attemptedKVP.Value
                            }
                        }

                        Context "environment variable already existed, name cased differently" {
                            BeforeEach {
                                $originalEnvironmentVariableName = $attemptedEnvironmentVariableName.ToUpper()
                                Set-EnvironmentVariableWithProvenance -Name $originalEnvironmentVariableName -Value ("baz"+[System.Guid]::NewGuid().ToString())
                            }

                            Context "platform env var names are case-insensitive" -Skip:(-not $IsWindows) {
                                It "updates the environment variable's value, but doesn't change its name" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariableWasSet -Name $originalEnvironmentVariableName -Value $attemptedEnvironmentVariableValue
                                }
                            }

                            Context "platform env var names are case-sensitive" -Skip:($IsWindows) {
                                It "creates a new environment variable, and doesn't change the original" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariableWasSet -Name $originalEnvironmentVariableName -Value $attemptedEnvironmentVariableValue
                                }
                            }
                        }

                        Context "environment variable didn't already exist" {
                            It "creates the environment variable" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariableWasSet -Name $attemptedEnvironmentVariableName -Value $attemptedEnvironmentVariableValue
                            }
                        }
                    }

                    Context "Value property is `$null" {
                        BeforeEach {
                            $attemptedKVP = [System.Collections.Generic.KeyValuePair[string, object]]::new($attemptedEnvironmentVariableName, $null)
                            $sutInvocationArgs['KVP'] = $attemptedKVP
                        }

                        Context "environment variable already existed" {
                            BeforeEach {
                                Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableName -Value ("baz"+[System.Guid]::NewGuid().ToString())
                            }

                            It "removes the environment variable" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariableWasRemoved -Name $attemptedEnvironmentVariableName
                            }
                        }

                        Context "environment variable already existed, name cased differently" {
                            BeforeEach {
                                $originalEnvironmentVariableName = $attemptedEnvironmentVariableName.ToUpper()
                                Set-EnvironmentVariableWithProvenance -Name $originalEnvironmentVariableName -Value ("baz"+[System.Guid]::NewGuid().ToString())
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
                }

                Context "Entry parameter" {
                    BeforeEach {
                        $attemptedEnvironmentVariableName = "foo" + [System.Guid]::NewGuid().ToString()
                        $attemptedEnvironmentVariableValue = "bar" + [System.Guid]::NewGuid().ToString()
                        $attemptedEntry = [System.Collections.DictionaryEntry]::new($attemptedEnvironmentVariableName, $attemptedEnvironmentVariableValue)
                        $sutInvocationArgs.Add('Entry', $attemptedEntry)
                    }

                    Context "Value property is valid" {
                        Context "environment variable already existed" {
                            BeforeEach {
                                $originalEnvironmentVariableName = $attemptedEnvironmentVariableName
                                Set-EnvironmentVariableWithProvenance -Name $originalEnvironmentVariableName -Value ("baz"+[System.Guid]::NewGuid().ToString())
                            }

                            It "updates the environment variable" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariableWasSet -Name $attemptedEntry.Key -Value $attemptedEntry.Value
                            }
                        }

                        Context "environment variable already existed, name cased differently" {
                            BeforeEach {
                                $originalEnvironmentVariableName = $attemptedEnvironmentVariableName.ToUpper()
                                Set-EnvironmentVariableWithProvenance -Name $originalEnvironmentVariableName -Value ("baz"+[System.Guid]::NewGuid().ToString())
                            }

                            Context "platform env var names are case-insensitive" -Skip:(-not $IsWindows) {
                                It "updates the environment variable's value, but doesn't change its name" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariableWasSet -Name $originalEnvironmentVariableName -Value $attemptedEnvironmentVariableValue
                                }
                            }

                            Context "platform env var names are case-sensitive" -Skip:($IsWindows) {
                                It "creates a new environment variable, and doesn't change the original" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariableWasSet -Name $originalEnvironmentVariableName -Value $attemptedEnvironmentVariableValue
                                }
                            }
                        }

                        Context "environment variable didn't already exist" {
                            It "creates the environment variable" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariableWasSet -Name $attemptedEnvironmentVariableName -Value $attemptedEnvironmentVariableValue
                            }
                        }
                    }

                    Context "Value property is `$null" {
                        BeforeEach {
                            $attemptedEntry = [System.Collections.DictionaryEntry]::new($attemptedEnvironmentVariableName, $null)
                            $sutInvocationArgs['Entry'] = $attemptedEntry
                        }

                        Context "environment variable already existed" {
                            BeforeEach {
                                Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableName -Value ("baz"+[System.Guid]::NewGuid().ToString())
                            }

                            It "removes the environment variable" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariableWasRemoved -Name $attemptedEnvironmentVariableName
                            }
                        }

                        Context "environment variable already existed, name cased differently" {
                            BeforeEach {
                                $originalEnvironmentVariableName = $attemptedEnvironmentVariableName.ToUpper()
                                Set-EnvironmentVariableWithProvenance -Name $originalEnvironmentVariableName -Value ("baz"+[System.Guid]::NewGuid().ToString())
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
                }

                Context "Environment parameter" {
                    Context "keys (ALL) match environment variable names" {
                        BeforeEach {
                            $attemptedEnvironmentVariableNames = [string[]]@(("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()))
                            Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableNames[0] -Value ("baz"+[System.Guid]::NewGuid().ToString())
                            Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableNames[1] -Value ("baz"+[System.Guid]::NewGuid().ToString())
                            Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableNames[2] -Value ("baz"+[System.Guid]::NewGuid().ToString())
                            Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableNames[3] -Value ("baz"+[System.Guid]::NewGuid().ToString())
                            Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableNames[4] -Value ("baz"+[System.Guid]::NewGuid().ToString())
                        }

                        Context "values (ALL) valid" {
                            BeforeEach {
                                $attemptedEnvironmentVariableValues = [string[]]@(("bar" + [System.Guid]::NewGuid().ToString()), ("bar" + [System.Guid]::NewGuid().ToString()), ("bar" + [System.Guid]::NewGuid().ToString()))
                            }

                            Context "environment variables already existed" {
                                BeforeEach {
                                    $expectedEnvironmentVariableChanges = @{
                                        $attemptedEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValues[0];
                                        $attemptedEnvironmentVariableNames[1] = $attemptedEnvironmentVariableValues[1];
                                        $attemptedEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValues[2]
                                    }
                                    $sutInvocationArgs['Environment'] = $expectedEnvironmentVariableChanges
                                }

                                It "updates the environment variables" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariablesWereSet -envExpected $expectedEnvironmentVariableChanges
                                }
                            }

                            Context "environment variables already existed, names cased differently" {
                                BeforeEach {
                                    Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableNames[1].ToUpper() -Value ("baz"+[System.Guid]::NewGuid().ToString()) -CaseChange

                                    $attemptedEnvironmentVariableChanges = @{
                                        $attemptedEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValues[0];
                                        $attemptedEnvironmentVariableNames[1] = $attemptedEnvironmentVariableValues[1];
                                        $attemptedEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValues[2]
                                    }
                                    $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
                                }

                                Context "platform env var names are case-insensitive" -Skip:(-not $IsWindows) {
                                    It "updates the environment variables' values, but doesn't change their names" {
                                        $expectedEnvironmentVariableChanges = @{
                                            $attemptedEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValues[0];
                                            $attemptedEnvironmentVariableNames[1] = $attemptedEnvironmentVariableValues[1];
                                            $attemptedEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValues[2]
                                        }

                                        Set-EnvVar @sutInvocationArgs

                                        Assert-EnvironmentVariablesWereSet -envExpected $expectedEnvironmentVariableChanges
                                    }
                                }

                                Context "platform env var names are case-sensitive" -Skip:($IsWindows) {
                                    It "creates new environment variables with alternate casing only when casing diverges" {
                                        $expectedEnvironmentVariableChanges = @{
                                            $attemptedEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValues[0];
                                            $attemptedEnvironmentVariableNames[1].ToUpper() = $attemptedEnvironmentVariableValues[1];
                                            $attemptedEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValues[2]
                                        }

                                        Set-EnvVar @sutInvocationArgs

                                        Assert-EnvironmentVariablesWereSet -envExpected $expectedEnvironmentVariableChanges
                                    }
                                }
                            }
                        }

                        Context "values (ALL) are `$null" {
                            BeforeEach {
                                $expectedEnvironmentVariableChanges = @{
                                    $attemptedEnvironmentVariableNames[0] = $null;
                                    $attemptedEnvironmentVariableNames[1] = $null;
                                    $attemptedEnvironmentVariableNames[2] = $null
                                }
                                $sutInvocationArgs['Environment'] = $expectedEnvironmentVariableChanges
                            }

                            Context "environment variables already existed" {
                                It "removes the environment variables" {
                                    Set-EnvVar @sutInvocationArgs

                                    Assert-EnvironmentVariablesWereSet -envExpected $expectedEnvironmentVariableChanges
                                }
                            }

                            Context "environment variables already existed, names cased differently" {
                                BeforeEach {
                                    Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableNames[1].ToUpper() -Value ("baz"+[System.Guid]::NewGuid().ToString()) -CaseChange
                                }

                                Context "platform env var names are case-insensitive" -Skip:(-not $IsWindows) {
                                    It "removes the environment variables" {
                                        Set-EnvVar @sutInvocationArgs

                                        Assert-EnvironmentVariablesWereSet -envExpected $expectedEnvironmentVariableChanges
                                    }
                                }

                                Context "platform env var names are case-sensitive" -Skip:($IsWindows) {
                                    It "removes the environment variables" {
                                        Set-EnvVar @sutInvocationArgs

                                        Assert-EnvironmentVariablesWereSet -envExpected @{
                                            $attemptedEnvironmentVariableNames[0] = $null;
                                            $attemptedEnvironmentVariableNames[1].ToUpper() = $null;
                                            $attemptedEnvironmentVariableNames[2] = $null
                                        }
                                    }
                                }
                            }
                        }

                        Context "values (ALL) are empty strings" {
                            BeforeEach {
                                $attemptedEnvironmentVariableChanges = @{
                                    $attemptedEnvironmentVariableNames[0] = [string]::Empty;
                                    $attemptedEnvironmentVariableNames[1] = [string]::Empty;
                                    $attemptedEnvironmentVariableNames[2] = [string]::Empty
                                }
                                $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
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
                                    Set-EnvironmentVariableWithProvenance -Name $attemptedEnvironmentVariableNames[1].ToUpper() -Value ("baz"+[System.Guid]::NewGuid().ToString()) -CaseChange
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

                        Context "values (SOME) are `$null" {
                            BeforeEach {
                                $expectedEnvironmentVariableChanges = @{
                                    $attemptedEnvironmentVariableNames[0] = ("bax"+[System.Guid]::NewGuid().ToString());
                                    $attemptedEnvironmentVariableNames[1] = $null;
                                    $attemptedEnvironmentVariableNames[2] = ("bax"+[System.Guid]::NewGuid().ToString());
                                    $attemptedEnvironmentVariableNames[3] = $null;
                                    $attemptedEnvironmentVariableNames[4] = ("bax"+[System.Guid]::NewGuid().ToString());
                                }
                                $sutInvocationArgs['Environment'] = $expectedEnvironmentVariableChanges
                            }

                            It "updates matching environment variables" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariablesWereSet -envExpected $expectedEnvironmentVariableChanges
                            }
                        }

                        Context "values (SOME) are empty strings" {
                            BeforeEach {
                                $expectedEnvironmentVariableChanges = @{
                                    $attemptedEnvironmentVariableNames[0] = ("bax"+[System.Guid]::NewGuid().ToString());
                                    $attemptedEnvironmentVariableNames[1] = [string]::Empty;
                                    $attemptedEnvironmentVariableNames[2] = [string]::Empty;
                                    $attemptedEnvironmentVariableNames[3] = ("bax"+[System.Guid]::NewGuid().ToString());
                                    $attemptedEnvironmentVariableNames[4] = $null;
                                }
                                $sutInvocationArgs['Environment'] = $expectedEnvironmentVariableChanges
                            }

                            It "errs" {
                                { Set-EnvVar @sutInvocationArgs } | Should -Throw

                                Assert-EnvironmentVariablesAllUnchanged
                            }

                            Context "ErrorAction set to SilentlyContinue" {
                                BeforeEach {
                                    $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue

                                    $attemptedEnvironmentVariableChanges = $expectedEnvironmentVariableChanges.Clone()
                                    $expectedEnvironmentVariableChanges.Remove($attemptedEnvironmentVariableNames[1]) # Entry with empty string value.
                                    $expectedEnvironmentVariableChanges.Remove($attemptedEnvironmentVariableNames[2]) # Entry with empty string value.
                                    $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
                                }

                                It "only applies valid environment variable values" {
                                    { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw

                                    Assert-EnvironmentVariablesWereSet -envExpected $expectedEnvironmentVariableChanges
                                }

                                It "returns nothing" {
                                    $result = Set-EnvVar @sutInvocationArgs

                                    $result | Should -BeNullOrEmpty
                                }
                            }
                        }
                    }

                    Context "keys (NONE) match environment variable names" {
                        BeforeEach {
                            $attemptedEnvironmentVariableNames = [string[]]@(("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()))

                            # We skip calling Set-EnvironmentVariableWithProvenance so that the environment variables won't have previously existed.
                        }

                        Context "values (ALL) are valid" {
                            BeforeEach {
                                $attemptedEnvironmentVariableValues = [string[]]@(("bar" + [System.Guid]::NewGuid().ToString()), ("bar" + [System.Guid]::NewGuid().ToString()), ("bar" + [System.Guid]::NewGuid().ToString()))
                                $expectedEnvironmentVariableChanges = @{
                                    $attemptedEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValues[0];
                                    $attemptedEnvironmentVariableNames[1] = $attemptedEnvironmentVariableValues[1];
                                    $attemptedEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValues[2]
                                }
                                $sutInvocationArgs['Environment'] = $expectedEnvironmentVariableChanges
                            }

                            It "adds the environment variables" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariablesWereSet -envExpected $expectedEnvironmentVariableChanges
                            }
                        }

                        Context "values (ALL) are `$null" {
                            BeforeEach {
                                $attemptedEnvironmentVariableChanges = @{
                                    $attemptedEnvironmentVariableNames[0] = $null;
                                    $attemptedEnvironmentVariableNames[1] = $null;
                                    $attemptedEnvironmentVariableNames[2] = $null
                                }
                                $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
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

                        Context "values (SOME) are `$null" {
                            BeforeEach {
                                $nonNullAttemptedEnvironmentVariableValues = @(("bax"+[System.Guid]::NewGuid().ToString()), ("bax"+[System.Guid]::NewGuid().ToString()))
                                $attemptedEnvironmentVariableChanges = @{
                                    $attemptedEnvironmentVariableNames[0] = $nonNullAttemptedEnvironmentVariableValues[0];
                                    $attemptedEnvironmentVariableNames[1] = $null;
                                    $attemptedEnvironmentVariableNames[2] = $null;
                                    $attemptedEnvironmentVariableNames[3] = $nonNullAttemptedEnvironmentVariableValues[1];
                                    $attemptedEnvironmentVariableNames[4] = $null
                                }
                                $expectedEnvironmentVariableChanges = @{
                                    $attemptedEnvironmentVariableNames[0] = $nonNullAttemptedEnvironmentVariableValues[0];
                                    $attemptedEnvironmentVariableNames[3] = $nonNullAttemptedEnvironmentVariableValues[1]
                                }
                                $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
                            }

                            It "updates existing environment variables with non-null values" {
                                Set-EnvVar @sutInvocationArgs

                                Assert-EnvironmentVariablesWereSet -envExpected $expectedEnvironmentVariableChanges
                            }
                        }

                        Context "values (ALL) are empty strings" {
                            BeforeEach {
                                $attemptedEnvironmentVariableChanges = @{
                                    $attemptedEnvironmentVariableNames[0] = [string]::Empty;
                                    $attemptedEnvironmentVariableNames[1] = [string]::Empty;
                                    $attemptedEnvironmentVariableNames[2] = [string]::Empty
                                }
                                $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
                            }

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

                        Context "values (SOME) are empty strings" {
                            BeforeEach {
                                $nonBlankAttemptedEnvironmentVariableValues = @(("bax"+[System.Guid]::NewGuid().ToString()), ("bax"+[System.Guid]::NewGuid().ToString()))
                                $attemptedEnvironmentVariableChanges = @{
                                    $attemptedEnvironmentVariableNames[0] = [string]::Empty;
                                    $attemptedEnvironmentVariableNames[1] = $nonBlankAttemptedEnvironmentVariableValues[0];
                                    $attemptedEnvironmentVariableNames[2] = [string]::Empty;
                                    $attemptedEnvironmentVariableNames[3] = $nonBlankAttemptedEnvironmentVariableValues[1];
                                    $attemptedEnvironmentVariableNames[4] = [string]::Empty
                                }
                                $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
                            }

                            It "errs" {
                                { Set-EnvVar @sutInvocationArgs } | Should -Throw

                                Assert-EnvironmentVariablesAllUnchanged
                            }

                            Context "ErrorAction set to SilentlyContinue" {
                                BeforeEach {
                                    $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                                }

                                It "only applies valid environment variable values" {
                                    $expectedEnvironmentVariableChanges = @{
                                        $attemptedEnvironmentVariableNames[1] = $nonBlankAttemptedEnvironmentVariableValues[0];
                                        $attemptedEnvironmentVariableNames[3] = $nonBlankAttemptedEnvironmentVariableValues[1];
                                    }

                                    { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw

                                    Assert-EnvironmentVariablesWereSet -envExpected $expectedEnvironmentVariableChanges
                                }

                                It "returns nothing" {
                                    $result = Set-EnvVar @sutInvocationArgs

                                    $result | Should -BeNullOrEmpty
                                }
                            }
                        }
                    }

                    # Context "keys (SOME) match environment variable names" {
                    #     BeforeEach {
                    #         $attemptedEnvironmentVariableNames = [string[]]@(("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()), ("foo" + [System.Guid]::NewGuid().ToString()))

                    #         # We skip calling Set-EnvironmentVariableWithProvenance for some environment variables so that they won't have previously existed.
                    #         $overwrittenEnvironmentVariableName = $attemptedEnvironmentVariableNames[1]
                    #         Set-EnvironmentVariableWithProvenance -Name $overwrittenEnvironmentVariableName -Value ("baz"+[System.Guid]::NewGuid().ToString())
                    #     }

                    #     Context "values (ALL) are valid" {
                    #         BeforeEach {
                    #             $attemptedEnvironmentVariableValues = [string[]]@(("bar" + [System.Guid]::NewGuid().ToString()), ("bar" + [System.Guid]::NewGuid().ToString()), ("bar" + [System.Guid]::NewGuid().ToString()))
                    #             $attemptedEnvironmentVariableChanges = @{
                    #                 $attemptedEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValues[0];
                    #                 $attemptedEnvironmentVariableNames[1] = $attemptedEnvironmentVariableValues[1];
                    #                 $attemptedEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValues[2]
                    #             }
                    #             $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
                    #         }

                    #         It "sets the environment variables" {
                    #             Set-EnvVar @sutInvocationArgs

                    #             Assert-EnvironmentVariablesWereSet -envExpected @{
                    #                 $attemptedEnvironmentVariableNames[0] = $attemptedEnvironmentVariableValues[0];
                    #                 $attemptedEnvironmentVariableNames[1] = $attemptedEnvironmentVariableValues[1];
                    #                 $attemptedEnvironmentVariableNames[2] = $attemptedEnvironmentVariableValues[2]
                    #             }
                    #         }
                    #     }

                    #     Context "values (ALL) are `$null" {
                    #         BeforeEach {
                    #             $attemptedEnvironmentVariableChanges = @{
                    #                 $attemptedEnvironmentVariableNames[0] = $null;
                    #                 $attemptedEnvironmentVariableNames[1] = $null;
                    #                 $attemptedEnvironmentVariableNames[2] = $null
                    #             }
                    #             $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
                    #         }

                    #         It "removes the matching environment variable" {
                    #             Set-EnvVar @sutInvocationArgs

                    #             Assert-EnvironmentVariableWasRemoved -Name $overwrittenEnvironmentVariableName
                    #         }
                    #     }

                    #     # TODO: add values that are NOT null. make SOME keys (of both value kinds!) match existing environment variable names.
                    #     Context "values (SOME) are `$null" {
                    #         BeforeEach {
                    #             $attemptedEnvironmentVariableChanges = @{
                    #                 $attemptedEnvironmentVariableNames[0] = $null;
                    #                 $attemptedEnvironmentVariableNames[1] = $null;
                    #                 $attemptedEnvironmentVariableNames[2] = $null
                    #             }
                    #             $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
                    #         }

                    #         It "removes the matching environment variable" {
                    #             Set-EnvVar @sutInvocationArgs

                    #             Assert-EnvironmentVariableWasRemoved -Name $overwrittenEnvironmentVariableName
                    #         }
                    #     }

                    #     Context "values (ALL) are empty strings" {
                    #         BeforeEach {
                    #             $attemptedEnvironmentVariableChanges = @{
                    #                 $attemptedEnvironmentVariableNames[0] = [string]::Empty;
                    #                 $attemptedEnvironmentVariableNames[1] = [string]::Empty;
                    #                 $attemptedEnvironmentVariableNames[2] = [string]::Empty;
                    #             }
                    #             $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
                    #         }

                    #         It "errs" {
                    #             { Set-EnvVar @sutInvocationArgs } | Should -Throw

                    #             Assert-EnvironmentVariablesAllUnchanged
                    #         }

                    #         Context "ErrorAction set to SilentlyContinue" {
                    #             BeforeEach {
                    #                 $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                    #             }

                    #             It "does nothing" {
                    #                 { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw

                    #                 Assert-EnvironmentVariablesAllUnchanged
                    #             }

                    #             It "returns nothing" {
                    #                 $result = Set-EnvVar @sutInvocationArgs

                    #                 $result | Should -BeNullOrEmpty
                    #             }
                    #         }
                    #     }

                    #     # TODO: add values that are NOT empty strings. make SOME keys match existing environment variable names.
                    #     Context "values (SOME) are empty strings" {
                    #         BeforeEach {
                    #             $attemptedEnvironmentVariableChanges = @{
                    #                 $attemptedEnvironmentVariableNames[0] = [string]::Empty;
                    #                 $attemptedEnvironmentVariableNames[1] = [string]::Empty;
                    #                 $attemptedEnvironmentVariableNames[2] = [string]::Empty;
                    #             }
                    #             $sutInvocationArgs['Environment'] = $attemptedEnvironmentVariableChanges
                    #         }

                    #         It "errs" {
                    #             { Set-EnvVar @sutInvocationArgs } | Should -Throw

                    #             Assert-EnvironmentVariablesAllUnchanged
                    #         }

                    #         Context "ErrorAction set to SilentlyContinue" {
                    #             BeforeEach {
                    #                 $sutInvocationArgs.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                    #             }

                    #             It "does nothing" {
                    #                 { Set-EnvVar @sutInvocationArgs } | Should -Not -Throw

                    #                 Assert-EnvironmentVariablesAllUnchanged
                    #             }

                    #             It "returns nothing" {
                    #                 $result = Set-EnvVar @sutInvocationArgs

                    #                 $result | Should -BeNullOrEmpty
                    #             }
                    #         }
                    #     }
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
