#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


if (-not (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue)) {
    throw "Invoke-ScriptAnalyzer not found. Please install the PowerShell module 'PSScriptAnalyzer'."
}

Invoke-ScriptAnalyzer -Path "$PSScriptRoot\..\*.ps1","$PSScriptRoot\..\*.psm1" -Recurse -ReportSummary -OutVariable issues
$errors   = $issues.Where({$_.Severity -eq 'Error'})
$warnings = $issues.Where({$_.Severity -eq 'Warning'})
if ($errors) {
    Write-Error "There were $($errors.Count) errors and $($warnings.Count) warnings total." -ErrorAction Stop
} else {
    Write-Output "There were $($errors.Count) errors and $($warnings.Count) warnings total."
}
