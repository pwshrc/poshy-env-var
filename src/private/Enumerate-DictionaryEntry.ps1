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
        function Enumerate {
            param([System.Collections.IDictionary] $dictionary)
            $enumerator = $dictionary.GetEnumerator()
            while ($enumerator.MoveNext()) {
                Write-Output $enumerator.Entry
            }
        }
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            Enumerate $PSItem
        }
    }
    End {
        if ((-not $PSCmdlet.MyInvocation.ExpectingInput) -and $InputObject) {
            Enumerate $InputObject
        }
    }
}
