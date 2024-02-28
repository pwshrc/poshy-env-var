#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function GetAllEnvironmentVariablesInScope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Raw')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Enumerate')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Hashtable')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Ordered')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Ordered_Readonly')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Readonly')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Immutable')]
        [System.EnvironmentVariableTarget] $Scope,

        [Parameter(Mandatory=$true, ParameterSetName='Scope_Raw')]
        [switch] $Raw,

        [Parameter(Mandatory=$true, ParameterSetName='Scope_Enumerate')]
        [switch] $Enumerate,

        [Parameter(Mandatory=$true, ParameterSetName='Scope_Hashtable', HelpMessage='Return a hashtable populated with the environment variables.')]
        [switch] $Hashtable,

        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Ordered')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Ordered_Readonly')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Readonly')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Immutable')]
        [switch] $Dictionary,

        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Ordered', HelpMessage='Attempt to preserve the ordering of the environment variables that are returned.')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Ordered_Readonly', HelpMessage='Attempt to preserve the ordering of the environment variables that are returned.')]
        [switch] $Ordered,

        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Readonly', HelpMessage='Makes the returned hashtable be read-only.')]
        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Ordered_Readonly', HelpMessage='Makes the returned hashtable be read-only.')]
        [switch] $ReadOnly,

        [Parameter(Mandatory=$true, ParameterSetName='Scope_Dictionary_Immutable', HelpMessage='Makes the returned dictionary be immutable.')]
        [switch] $Immutable
    )
    $originalDictionary = [System.Environment]::GetEnvironmentVariables($Scope)
    if ($Raw) {
        $originalDictionary | Write-Output
    } elseif ($Enumerate) {
        $originalDictionary | Enumerate-DictionaryEntry | Write-Output
    } elseif ($Hashtable) {
        [System.Collections.Hashtable]::new($originalDictionary, (GetPlatformEnvVarNameStringComparer)) | Write-Output
    } elseif ($Dictionary) {
        if ($Ordered) {
            $results = [System.Collections.Specialized.OrderedDictionary]::new((GetPlatformEnvVarNameStringComparer))
            $originalDictionary | Enumerate-DictionaryEntry | ForEach-Object {
                $results.Add($_.Key, $_.Value)
            }
            if ($ReadOnly) {
                $results.AsReadOnly() | Write-Output
            } else {
                $results | Write-Output
            }
        } elseif ($Immutable) {
            $results = [System.Collections.Immutable.ImmutableDictionary[string, object]]::Empty
            $results = $results.WithComparers((GetPlatformEnvVarNameStringComparer))
            $originalDictionary | Enumerate-DictionaryEntry | ForEach-Object {
                $results = $results.Add($_.Key, $_.Value)
            }
            $results | Write-Output
        }  elseif ($ReadOnly) {
            $results = [System.Collections.Generic.Dictionary[string, object]]::new((GetPlatformEnvVarNameStringComparer))
            $originalDictionary | Enumerate-DictionaryEntry | ForEach-Object {
                $results.Add($_.Key, $_.Value)
            }
            $results.AsReadOnly() | Write-Output
        } else {
            throw [System.NotImplementedException]::new("ParameterSet '$($PSCmdlet.ParameterSetName)' is not implemented.")
        }
    } else {
        throw [System.NotImplementedException]::new("ParameterSet '$($PSCmdlet.ParameterSetName)' is not implemented.")
    }
}
