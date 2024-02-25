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
    }

    Context "when invoked" {
        Context "without pipeline input" {
            Context "no explicit scope" {
                BeforeEach {
                    $sutInvocationArgs = [hashtable]@{
                    }
                }

                Context "no other parameters" {
                    It "errs" {
                        { Set-EnvVar @sutInvocationArgs } | Should -Throw  # TODO: Check for specific error.
                    }
                }

                # TODO:
                # Context "*, ErrorAction set to SilentlyContinue" {
                # }
            }
        }
    }
}
