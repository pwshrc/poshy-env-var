#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# Reads a dotenv file as a stream of name-value pairs.
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
