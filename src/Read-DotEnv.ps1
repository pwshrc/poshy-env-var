#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Reads a .env file and outputs a hashtable of the key-value pairs.
.PARAMETER FilePath
    The path to the .env file to read.
.OUTPUTS
    System.Collections.DictionaryEntry
.COMPONENT
    env
#>
function Read-DotEnv() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="FilePath", Position=0)]
        [string] $FilePath
    )
    Process {
        foreach ($line in (Get-Content -LiteralPath $FilePath)) {
            [int] $splitAt = $line.IndexOf('=')
            if ($splitAt -gt -1) {
                [string] $name = $line.Substring(0, $splitAt)
                [string] $value = $line.Substring($splitAt+1)

                [string] $valueTrimmed = $value.Trim()
                if ($valueTrimmed.StartsWith('"') -and $valueTrimmed.EndsWith('"')) {
                    $value = $valueTrimmed.Substring(1, $valueTrimmed.Length-2)
                }

                [System.Collections.DictionaryEntry] $de = [System.Collections.DictionaryEntry]::new($name, $value)
                Write-Output $de
            }
        }
    }
}
