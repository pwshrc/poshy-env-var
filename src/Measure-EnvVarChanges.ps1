#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Measure-EnvVarChanges([ScriptBlock] $inner) {
    [Hashtable] $before = @{}
    Get-ChildItem Env:\ | %{ $before[$_.Name] = $_.Value }

    &$inner

    [Hashtable] $after = @{}
    Get-ChildItem Env:\ | %{ $after[$_.Name] = $_.Value }

    return ($before.Keys + $after.Keys) `
            | Select-Object -Unique `
            | %{ New-Object PSCustomObject -Property @{key = $_; before=$before[$_]; after=$after[$_]}} `
            | ?{$_.before -ne $_.after}
}
