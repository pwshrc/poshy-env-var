#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# PSModule
# PSIncludes_Function
# PSFunction_*
# PSCommand_*
# PSIncludes_Cmdlet
# PSCmdlet_*
# PSIncludes_DscResource
# PSDscResource_*
# PSIncludes_RoleCapability
# PSRoleCapability_*
# PSIncludes_Workflow
# PSWorkflow_*
# *.psrc

function Get-PackageTags {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Constrained")]
        [Parameter(Mandatory = $true, ParameterSetName = "Extended")]
        [ValidateNotNullOrEmpty()]
        [string] $PackageId,

        [Parameter(Mandatory = $true, ParameterSetName = "Extended")]
        [switch] $PSGalleryExtended,

        [Parameter(Mandatory = $true, ParameterSetName = "Extended")]
        [hashtable] $ModuleExports,

        [Parameter(Mandatory = $false, ParameterSetName = "Extended")]
        [switch] $PSEdition_Desktop,

        [Parameter(Mandatory = $false, ParameterSetName = "Extended")]
        [switch] $PSEdition_Core
    )

    [string] $tagsFile = "${PSScriptRoot}${ds}..${ds}..${ds}.info${ds}tags.txt"
    if (-not (Test-Path $tagsFile -ErrorAction SilentlyContinue)) {
        throw "The file '${tagsFile}' does not exist."
    }
    [string[]] $tags = ((Get-Content -Path $tagsFile -Encoding utf8 | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) }))

    if (-not $PSGalleryExtended) {
        if (-not $tags) {
            throw "The file '${tagsFile}' is empty."
        }
        return $tags
    }

    $tags += @($PackageId)
    $tags += @('PSModule')

    if ($ModuleExports["Functions"].Count -gt 0) {
        $tags += @("PSIncludes_Function")
        $tags += @($ModuleExports["Functions"] | ForEach-Object { "PSFunction_${_}" })
    }
    if ($ModuleExports["Cmdlets"].Count -gt 0) {
        $tags += @("PSIncludes_Cmdlet")
        $tags += @($ModuleExports["Cmdlets"] | ForEach-Object { "PSCmdlet_${_}" })
    }
    if ($ModuleExports["Commands"].Count -gt 0) {
        $tags += @("PSIncludes_Command")
        $tags += @($ModuleExports["Commands"] | ForEach-Object { "PSCommand_${_}" })
    }
    if ($ModuleExports["DscResources"].Count -gt 0) {
        $tags += @("PSIncludes_DscResource")
        $tags += @($ModuleExports["DscResources"] | ForEach-Object { "PSDscResource_${_}" })
    }
    [System.IO.FileInfo[]] $roleCapabilityFiles = @(Get-ChildItem -Path "${PSScriptRoot}${ds}..${ds}..${ds}" -Filter "*.psrc" -Recurse -File -Force -ErrorAction SilentlyContinue)
    if ($roleCapabilityFiles.Count -gt 0) {
        [string[]] $roleCapabilities = $roleCapabilityFiles | ForEach-Object { $_.Name.Replace(".psrc", "") }
        $tags += @("PSIncludes_RoleCapability")
        $tags += @($roleCapabilities | ForEach-Object { "PSRoleCapability_$_" })
    }
    # TODO: PSIncludes_Workflow
    # TODO: PSWorkflow_*
    if ($PSEdition_Desktop) {
        $tags += @("PSEdition_Desktop")
    }
    if ($PSEdition_Core) {
        $tags += @("PSEdition_Core")
    }

    return $tags
}
