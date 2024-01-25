#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Where-DictionaryEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary] $InputObject,

        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [scriptblock] $Filter
    )
    Process {
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $PSItem | Enumerate-DictionaryEntry | Where-Object $Filter
        }
    }
    End {
        if ((-not $PSCmdlet.MyInvocation.ExpectingInput) -and $InputObject) {
            $InputObject | Enumerate-DictionaryEntry | Where-Object $Filter
        }
    }
}
