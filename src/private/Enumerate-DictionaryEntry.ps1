#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Enumerate-DictionaryEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary] $InputObject
    )
    Process {
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $enumerator = $PSItem.GetEnumerator()
            while ($enumerator.MoveNext()) {
                Write-Output $enumerator.Entry
            }
        }
    }
    End {
        if ((-not $PSCmdlet.MyInvocation.ExpectingInput) -and $InputObject) {
            $enumerator = $InputObject.GetEnumerator()
            while ($enumerator.MoveNext()) {
                Write-Output $enumerator.Entry
            }
        }
    }
}
