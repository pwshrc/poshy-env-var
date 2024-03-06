#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Should-BeHashtableEqualTo {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function')]
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.IDictionary] $ActualValue,

        [Parameter()]
        [switch] $Negate,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary] $ExpectedValue,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [System.StringComparer] $KeyComparer,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrWhiteSpace()]
        [string] $Because = $null,

        [Parameter(Mandatory=$true)]
        $CallerSessionState
    )
    function New-KeysHashSet([System.StringComparer] $Comparer) {
        [System.Collections.Immutable.ImmutableHashSet[string]] $keys = [System.Collections.Immutable.ImmutableHashSet[string]]::Empty
        $keys = $keys.WithComparer($Comparer)
        Write-Output -InputObject $keys -NoEnumerate
    }
    function Get-KeysHashSet([System.Collections.IDictionary] $Dictionary, [System.StringComparer] $Comparer) {
        [System.Collections.Immutable.ImmutableHashSet[string]] $keys = (New-KeysHashSet)
        $Dictionary.Keys | ForEach-Object {
            $keys = $keys.Add($_)
        }
        Write-Output -InputObject $keys -NoEnumerate
    }

    $validationFailures = [System.Collections.Generic.List[string]]::new()

    if ($ActualValue.PSBase.Count -ne $ExpectedValue.PSBase.Count) {
        $validationFailures.Add("actual has different number of elements ($($ActualValue.PSBase.Count)) than expected ($($ExpectedValue.PSBase.Count))")
    }

    $expectedKeysExact = Get-KeysHashSet -Dictionary $ExpectedValue -Comparer ([System.StringComparer]::Ordinal)
    $expectedKeysAsExpected = Get-KeysHashSet -Dictionary $ExpectedValue -Comparer $KeyComparer
    $actualKeysExact = Get-KeysHashSet -Dictionary $ActualValue -Comparer ([System.StringComparer]::Ordinal)
    $actualKeysAsExpected = Get-KeysHashSet -Dictionary $ActualValue -Comparer $KeyComparer

    $missingKeysExact = $expectedKeysExact.Except($actualKeysExact)
    $missingKeysAsExpected = $expectedKeysAsExpected.Except($actualKeysAsExpected)
    $unexpectedKeysExact = $actualKeysExact.Except($expectedKeysExact)
    $unexpectedKeysAsExpected = $actualKeysAsExpected.Except($expectedKeysAsExpected)
    $identicalKeysExact = $expectedKeysExact.Intersect($actualKeysExact)
    $identicalKeysAsExpected = $expectedKeysAsExpected.Intersect($actualKeysAsExpected)
    $extraneousKeysExact = $actualKeysExact.SymmetricExcept($expectedKeysExact)
    $extraneousKeysAsExpected = $actualKeysAsExpected.SymmetricExcept($expectedKeysAsExpected)
    [bool] $keyCaseDifferencesExist = `
        ($expectedKeysExact.Count -ne $expectedKeysAsExpected.Count) -or
        ($actualKeysExact.Count -ne $actualKeysAsExpected.Count) -or
        ($missingKeysExact.Count -ne $missingKeysAsExpected.Count) -or
        ($unexpectedKeysExact.Count -ne $unexpectedKeysAsExpected.Count) -or
        ($identicalKeysExact.Count -ne $identicalKeysAsExpected.Count) -or
        ($extraneousKeysExact.Count -ne $extraneousKeysAsExpected.Count)
    if ($keyCaseDifferencesExist) {
        $missingKeysNotBecauseCasing = $missingKeysAsExpected.Except($missingKeysExact)
        $unexpectedKeysNotBecauseCasing = $unexpectedKeysAsExpected.Except($unexpectedKeysExact)
        $missingKeysBecauseCasing = $missingKeysAsExpected.Except($missingKeysNotBecauseCasing)
        $unexpectedKeysBecauseCasing = $unexpectedKeysAsExpected.Except($unexpectedKeysNotBecauseCasing)

        if ($missingKeysNotBecauseCasing.Count -gt 0) {
            $examples = $missingKeysAsExpected | Select-Object -First 3
            $examplesText = $examples -join ", "
            $validationFailures.Add("actual is wholly missing elements with expected keys (e.g. $examplesText) ($($missingKeysExact.Count) total)")
        }

        if ($unexpectedKeysNotBecauseCasing.Count -gt 0) {
            $examples = $unexpectedKeysNotBecauseCasing | Select-Object -First 3
            $examplesText = $examples -join ", "
            $validationFailures.Add("actual has elements with wholly unexpected keys (e.g. $examplesText) ($($unexpectedKeysNotBecauseCasing.Count) total)")
        }

        $keyCasingChanges = [System.Collections.Immutable.ImmutableDictionary[string, object]]::Empty.WithComparers([System.StringComparer]::Ordinal)
        foreach ($originalKey in $missingKeysBecauseCasing) {
            $changedKey = $actualKeysAsExpected | Where-Object { [System.StringComparer]::OrdinalIgnoreCase.Equals($originalKey, $_) } | Select-Object -First 1
            $keyCasingChanges = $keyCasingChanges.SetItem($originalKey, $changedKey)
        }
        foreach ($changedKey in $unexpectedKeysBecauseCasing) {
            $originalKey = $expectedKeysAsExpected | Where-Object { [System.StringComparer]::OrdinalIgnoreCase.Equals($_, $changedKey) } | Select-Object -First 1
            $keyCasingChanges = $keyCasingChanges.SetItem($originalKey, $changedKey)
        }
        $keyCasingChanges = @($keyCasingChanges | Enumerate-DictionaryEntry | ForEach-Object {
            [PSCustomObject]@{ Expected = $_.Key; Actual = $_.Value }
        })
        if ($keyCasingChanges.Count -gt 0) {
            $examples = $keyCasingChanges | Select-Object -First 1
            $examplesText = $examples -join ", "
            $validationFailures.Add("actual has elements with keys that differ only by case from expected (e.g. $examplesText) ($($keyCasingChanges.PSBase.Count) total)")
        }
    } else {
        if ($missingKeysExact.Count -gt 0) {
            $examples = $missingKeysExact | Select-Object -First 3
            $examplesText = $examples -join ", "
            $validationFailures.Add("actual is missing elements with expected keys (e.g. $examplesText) ($($missingKeysExact.Count) total)")
        }

        if ($unexpectedKeysExact.Count -gt 0) {
            $examples = $unexpectedKeysExact | Select-Object -First 3
            $examplesText = $examples -join ", "
            $validationFailures.Add("actual has elements with unexpected keys (e.g. $examplesText) ($($unexpectedKeysExact.Count) total)")
        }
    }

    $valueChanges = [System.Collections.Immutable.ImmutableDictionary[string, object]]::Empty.WithComparers($KeyComparer)
    foreach ($key in $identicalKeysAsExpected) {
        if (($null -eq $ExpectedValue[$key]) -and ($null -eq $ActualValue[$key])) {
            continue
        }
        if (($null -eq $ExpectedValue[$key]) -or ($null -eq $ActualValue[$key])) {
            $valueChanges = $valueChanges.Add($key, [PSCustomObject]@{ Expected = $ExpectedValue[$key]; Actual = $ActualValue[$key] })
            continue
        }
        elseif ($ExpectedValue[$key] -ne $ActualValue[$key]) {
            $valueChanges = $valueChanges.Add($key, [PSCustomObject]@{ Expected = $ExpectedValue[$key]; Actual = $ActualValue[$key] })
        }
    }
    $valueChanges = @($valueChanges | Enumerate-DictionaryEntry | ForEach-Object {
        [PSCustomObject]@{ Key = $_.Key; ExpectedValue = $_.Value.Expected; ActualValue = $_.Value.Actual }
    })
    if ($valueChanges.Count -gt 0) {
        $examples = $valueChanges | Select-Object -First 1
        $examplesText = $examples -join ", "
        $validationFailures.Add("actual has elements with values that differ from expected (e.g. $examplesText) ($($valueChanges.PSBase.Count) total)")
    }

    if (-not $Negate) {
        if ($validationFailures) {
            $FailureMessage = "Expected actual hashtable to be equal to the expected hashtable, but"
            foreach ($failure in $validationFailures) {
                $FailureMessage += "`n $failure,"
            }
            $FailureMessage = $FailureMessage.TrimEnd(",")+"."
            if ($Because) {
                $FailureMessage = $FailureMessage.TrimEnd(".")+": $Because."
            }
            [PSCustomObject]@{ Succeeded = $false; FailureMessage = $FailureMessage } | Write-Output
        } else {
            [PSCustomObject]@{ Succeeded = $true } | Write-Output
        }
    } else {
        if ($validationFailures.Count -eq 0) {
            [PSCustomObject]@{ Succeeded = $false; FailureMessage = "Expected hashtable not to be equal to the expected hashtable, but it was." } | Write-Output
        } else {
            [PSCustomObject]@{ Succeeded = $true } | Write-Output
        }
    }
}

Add-ShouldOperator -Name BeHashtableEqualTo -Test ${function:Should-BeHashtableEqualTo}


function Should-BeEnumerableSequenceEqualTo {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function')]
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.IEnumerable] $ActualValue,

        [Parameter()]
        [switch] $Negate,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [System.Collections.IEnumerable] $ExpectedValue,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrWhiteSpace()]
        [string] $Because = $null,

        [Parameter(Mandatory=$true)]
        $CallerSessionState
    )
    $actualEnumerator = $ActualValue.GetEnumerator()
    $expectedEnumerator = $ExpectedValue.GetEnumerator()
    $validationFailures = [System.Collections.Generic.List[string]]::new()
    $index = 0
    $actualEnumeratorActive = $actualEnumerator.MoveNext()
    $expectedEnumeratorActive = $expectedEnumerator.MoveNext()
    while ($actualEnumeratorActive -and $expectedEnumeratorActive) {
        if ($actualEnumerator.Current -ne $expectedEnumerator.Current) {
            $validationFailures.Add("at index $index expected '$($expectedEnumerator.Current)' but got '$($actualEnumerator.Current)'")
            break;
        }
        $index++
        $actualEnumeratorActive = $actualEnumerator.MoveNext()
        $expectedEnumeratorActive = $expectedEnumerator.MoveNext()
    }
    if ($actualEnumeratorActive -ne $expectedEnumeratorActive) {
        $validationFailures.Insert(0, "actual has $($actualEnumeratorActive ? 'more' : 'fewer') elements than expected")
    }

    if (-not $Negate) {
        if ($validationFailures) {
            $FailureMessage = "Expected actual enumerable to be sequence-equal to the expected enumerable, but"
            foreach ($failure in $validationFailures) {
                $FailureMessage += "`n $failure,"
            }
            $FailureMessage = $FailureMessage.TrimEnd(",")+"."
            if ($Because) {
                $FailureMessage = $FailureMessage.TrimEnd(".")+": $Because."
            }
            [PSCustomObject]@{ Succeeded = $true; FailureMessage = $FailureMessage } | Write-Output
        } else {
            [PSCustomObject]@{ Succeeded = $true } | Write-Output
        }
    } else {
        if ($validationFailures.Count -eq 0) {
            $FailureMessage = "Expected enumerable not to be sequence-equal to the expected enumerable, but it was."
            if ($Because) {
                $FailureMessage = $FailureMessage.TrimEnd(".")+": $Because."
            }
            [PSCustomObject]@{ Succeeded = $false; FailureMessage = $FailureMessage } | Write-Output
        } else {
            [PSCustomObject]@{ Succeeded = $true } | Write-Output
        }
    }
}

Add-ShouldOperator -Name BeEnumerableSequenceEqualTo -Test ${function:Should-BeEnumerableSequenceEqualTo}

function TestCanSetEnvironmentVariablesInScope {
    param(
        [Parameter()]
        [System.EnvironmentVariableTarget] $scope
    )
    if (($scope -ne [System.EnvironmentVariableTarget]::Process) -and (-not $IsWindows)) {
        $false
    } else {
        try {
            [string] $envVarName = "foo" + [System.Guid]::NewGuid().ToString()
            [string] $envVarValue = [System.Guid]::NewGuid().ToString()
            [System.Environment]::SetEnvironmentVariable($envVarName, $envVarValue, $scope)
            try {
                $actual = [System.Environment]::GetEnvironmentVariable($envVarName, $scope)
                $actual | Should -Be $envVarValue
            } finally {
                [System.Environment]::SetEnvironmentVariable($envVarName, $null, $scope)
            }
            $true
        } catch {
            $false
        }
    }
}

function RemoveBlankEnvironmentVariablesInProcessScope {
    . "$PSScriptRoot/../src/private/GetAllEnvironmentVariableKeysInScope.ps1"

    $scope = [System.EnvironmentVariableTarget]::Process
    (GetAllEnvironmentVariableKeysInScope $scope) | ForEach-Object {
        if ([string]::IsNullOrWhiteSpace([System.Environment]::GetEnvironmentVariable($_, $scope))) {
            [System.Environment]::SetEnvironmentVariable($_, $null, $scope)
        }
    }
}

RemoveBlankEnvironmentVariablesInProcessScope
