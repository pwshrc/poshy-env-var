#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


BeforeDiscovery {
    . "$PSScriptRoot/Common.ps1"
}

Describe "cmdlet Set-EnvVar" {
    BeforeEach {
        . "$PSScriptRoot/../src/Set-EnvVar.ps1"
    }

    It "should be defined" {
        Test-Path function:Set-EnvVar | Should -Be $true
    }

    Context "when invoked" {
        Context "without pipeline input" {
            Context "with no parameters" {
                It "errs" {
                    { Set-EnvVar } | Should -Throw  # TODO: Check for specific error.
                }
            }
        }
    }
}

Describe "the current process" {
    It "can get environment variables by scope" {
        $expectedMethodName = 'GetEnvironmentVariables'
        $expectedMethodReturnType = [System.Collections.IDictionary]
        $expectedMethodParameterType = [System.EnvironmentVariableTarget]

        $actualMethod = [System.Environment].GetMembers() | Where-Object {
            ($_.Name -eq $expectedMethodName) -and ($_ -is [System.Reflection.MethodInfo]) -and ($_.GetParameters().Count -eq 1)
        }

        $actualMethod | Should -Not -BeNullOrEmpty
        $actualMethod.ReturnType | Should -Be $expectedMethodReturnType
        $actualMethod.GetParameters()[0].ParameterType | Should -Be $expectedMethodParameterType
    }

    It "has internally-consistent environment variables" {
        [System.Collections.DictionaryEntry[]] $allProcessEnvVariablesViaSystemEnvironment = @()
        foreach ($key in [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process).Keys | Sort-Object) {
            $allProcessEnvVariablesViaSystemEnvironment += @([System.Collections.DictionaryEntry]::new($key, [System.Environment]::GetEnvironmentVariable($key, [System.EnvironmentVariableTarget]::Process)))
        }

        [System.Collections.DictionaryEntry[]] $allProcessEnvVariablesViaEnvironmentPSProvider = @()
        foreach ($envVar in Get-ChildItem -Path "Env:" | Sort-Object -Property 'Name') {
            $allProcessEnvVariablesViaEnvironmentPSProvider += @([System.Collections.DictionaryEntry]::new($envVar.Name, $envVar.Value))
        }

        # Make sure PowerShell hasn't been runtime-patched to expose a different environment than the one the process actually has.
        $allProcessEnvVariablesViaSystemEnvironment | Should -Be $allProcessEnvVariablesViaEnvironmentPSProvider
    }
}