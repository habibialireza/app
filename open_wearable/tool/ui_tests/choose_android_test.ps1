[CmdletBinding()]
param(
    [string] $AndroidDevice
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$choices = @(
    [PSCustomObject]@{ Suite = 'Navigation';         Description = 'Main navigation and empty states' }
    [PSCustomObject]@{ Suite = 'Permissions';        Description = 'First-run Android permissions' }
    [PSCustomObject]@{ Suite = 'PermissionRecovery'; Description = 'Skipped microphone permission recovery' }
    [PSCustomObject]@{ Suite = 'Overview';           Description = 'Overview shortcuts' }
    [PSCustomObject]@{ Suite = 'Settings';           Description = 'All General settings' }
    [PSCustomObject]@{ Suite = 'ThisDevice';         Description = 'Phone-as-device connection' }
    [PSCustomObject]@{ Suite = 'ThisDeviceData';     Description = 'Phone sensor stream and recording' }
    [PSCustomObject]@{ Suite = 'PairDiscovery';      Description = 'OpenEarable scan filtering' }
    [PSCustomObject]@{ Suite = 'PairHardware';       Description = 'Two-device L/R pairing lifecycle' }
    [PSCustomObject]@{ Suite = 'PairSampleRate';     Description = 'Two-device requested versus received sample rates' }
    [PSCustomObject]@{ Suite = 'Hardware';           Description = 'One exact OpenEarable connection' }
)

Write-Host ''
Write-Host 'Choose one Patrol test to run:'
for ($index = 0; $index -lt $choices.Count; $index++) {
    Write-Host ('  {0,2}. {1,-18} {2}' -f ($index + 1), $choices[$index].Suite, $choices[$index].Description)
}
Write-Host '   Q. Quit'

$selection = (Read-Host 'Test number').Trim()
if ($selection -match '^[qQ]$') {
    return
}

$number = 0
if (-not [int]::TryParse($selection, [ref] $number) -or
    $number -lt 1 -or
    $number -gt $choices.Count) {
    throw "Choose a number from 1 to $($choices.Count), or Q."
}

$suite = $choices[$number - 1].Suite
$arguments = @{
    Suite = $suite
}
if (-not [string]::IsNullOrWhiteSpace($AndroidDevice)) {
    $arguments.AndroidDevice = $AndroidDevice
}

if ($suite -eq 'Hardware') {
    $deviceId = (Read-Host 'Exact Android Bluetooth device ID').Trim()
    if ([string]::IsNullOrWhiteSpace($deviceId)) {
        throw 'The Hardware test requires a Bluetooth device ID.'
    }
    $arguments.OpenEarableDeviceId = $deviceId
}

if ($suite -eq 'PairSampleRate') {
    $rateText = (Read-Host 'Sample rates in Hz, comma-separated [25]').Trim()
    if ([string]::IsNullOrWhiteSpace($rateText)) {
        $rateText = '25'
    }
    try {
        $arguments.SampleRatesHz = [double[]] ($rateText -split ',' | ForEach-Object {
            [double]::Parse($_.Trim(), [Globalization.CultureInfo]::InvariantCulture)
        })
    } catch {
        throw 'Sample rates must be numbers separated by commas, for example 25,50,100.'
    }

    $durationText = (Read-Host 'Recording seconds per rate [12]').Trim()
    if (-not [string]::IsNullOrWhiteSpace($durationText)) {
        $arguments.SampleDurationSeconds = [int] $durationText
    }

    $toleranceText = (Read-Host 'Allowed deviation percent [15]').Trim()
    if (-not [string]::IsNullOrWhiteSpace($toleranceText)) {
        $arguments.SampleTolerancePercent = [double]::Parse(
            $toleranceText,
            [Globalization.CultureInfo]::InvariantCulture
        )
    }
}

& (Join-Path $PSScriptRoot 'run_android.ps1') @arguments
