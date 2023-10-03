#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Measures the changes to environment variables made by a script block.
.PARAMETER inner
    The script block to execute.
.OUTPUTS
    PSCustomObject with the following properties:
        key: The name of the environment variable that changed.
        before: The value of the environment variable before the script block was executed.
        after: The value of the environment variable after the script block was executed.
.COMPONENT
    env
#>
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
