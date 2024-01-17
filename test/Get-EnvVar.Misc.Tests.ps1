#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest



. "$PSScriptRoot/Get-EnvVar.Common.ps1"

Describe "cmdlet Get-EnvVar" {
    BeforeEach {
        . "$PSScriptRoot/../src/Get-EnvVar.ps1"
    }

    It "should be defined" {
        Test-Path function:Get-EnvVar | Should -Be $true
    }

    Context "when invoked" {
        Context "without pipeline input" {
            Context "with no parameters" {
                It "errs" {
                    try {
                        Invoke-Command "Get-EnvVar" -ErrorAction 'Continue' | Out-Null
                    } catch {
                        $_.Exception.Message | Should -BeLike "*an insufficient number of parameters were provided*"
                    }
                }
            }
        }
    }
}
