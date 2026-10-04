[CmdletBinding()]
param(
    [ValidateSet('Navigation', 'Permissions', 'PermissionRecovery', 'Overview', 'Settings', 'ThisDevice', 'ThisDeviceData', 'PairDiscovery', 'PairHardware', 'PairSampleRate', 'Hardware')]
    [string] $Suite = 'Navigation',

    [string] $OpenEarableDeviceId,

    [double[]] $SampleRatesHz = @(25),

    [ValidateRange(5, 600)]
    [int] $SampleDurationSeconds = 12,

    [ValidateRange(0.1, 99.9)]
    [double] $SampleTolerancePercent = 15,

    [switch] $ListSuites
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$suiteDescriptions = [ordered]@{
    Navigation         = 'Open every main tab and verify the empty states and Settings entry.'
    Permissions        = 'Complete first-run Android Bluetooth and microphone permissions.'
    PermissionRecovery = 'Recover after microphone permission was skipped during onboarding.'
    Overview           = 'Check every Overview shortcut reaches its intended screen.'
    Settings           = 'Toggle, reopen, verify, and restore all five General settings.'
    ThisDevice         = 'Connect the phone as a sensor device, inspect details, and disconnect.'
    ThisDeviceData     = 'Set phone Accelerometer to 5 Hz, stream, record CSV, and delete it.'
    PairDiscovery      = 'Exercise the OpenEarable-only scan filter without connecting hardware.'
    PairHardware       = 'Discover two OpenEarables, connect, verify L/R pair, split/recombine, and disconnect.'
    PairSampleRate     = 'For two OpenEarables, set requested IMU rate(s) and verify received L/R CSV rates.'
    Hardware           = 'Connect one exact Bluetooth device ID, inspect it, and disconnect.'
}

if ($ListSuites) {
    $suiteDescriptions.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{ Suite = $_.Key; Checks = $_.Value }
    } | Format-Table -AutoSize -Wrap
    return
}

function Resolve-PatrolExecutable {
    param([string] $ProjectRoot)

    $command = Get-Command patrol -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    $candidates = @(
        (Join-Path $ProjectRoot '..\..\.pub-cache\bin\patrol.bat'),
        (Join-Path $env:LOCALAPPDATA 'Pub\Cache\bin\patrol.bat')
    )
    if (-not [string]::IsNullOrWhiteSpace($env:PUB_CACHE)) {
        $candidates = @((Join-Path $env:PUB_CACHE 'bin\patrol.bat')) + $candidates
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw 'Patrol CLI 4.8.0 is required. Run: dart pub global activate patrol_cli 4.8.0'
}

function Initialize-AndroidSdkEnvironment {
    param([string] $ProjectRoot)

    if ([string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
        $propertiesPath = Join-Path $ProjectRoot 'android\local.properties'
        if (Test-Path -LiteralPath $propertiesPath) {
            $sdkLine = Get-Content -LiteralPath $propertiesPath |
                Where-Object { $_ -match '^sdk\.dir=' } |
                Select-Object -First 1
            if ($null -ne $sdkLine) {
                $env:ANDROID_HOME = $sdkLine.Substring('sdk.dir='.Length).Replace('\\', '\')
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($env:ANDROID_HOME) -or
        -not (Test-Path -LiteralPath $env:ANDROID_HOME)) {
        throw 'Android SDK was not found. Set ANDROID_HOME or run flutter pub get to generate android/local.properties.'
    }

    $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
    $platformTools = Join-Path $env:ANDROID_HOME 'platform-tools'
    if (Test-Path -LiteralPath $platformTools) {
        $env:Path = "$platformTools;$env:Path"
    }

    # Pub-generated Windows launchers call `dart` by name. Put dart.exe ahead
    # of Flutter's extensionless Unix launcher so patrol.bat is reliable.
    $propertiesPath = Join-Path $ProjectRoot 'android\local.properties'
    if (Test-Path -LiteralPath $propertiesPath) {
        $flutterLine = Get-Content -LiteralPath $propertiesPath |
            Where-Object { $_ -match '^flutter\.sdk=' } |
            Select-Object -First 1
        if ($null -ne $flutterLine) {
            $flutterSdk = $flutterLine.Substring('flutter.sdk='.Length).Replace('\\', '\')
            $dartSdkBin = Join-Path $flutterSdk 'bin\cache\dart-sdk\bin'
            if (Test-Path -LiteralPath $dartSdkBin) {
                $env:Path = "$dartSdkBin;$env:Path"
            }
        }
    }
}

if ($Suite -eq 'Hardware' -and [string]::IsNullOrWhiteSpace($OpenEarableDeviceId)) {
    throw 'Hardware builds require -OpenEarableDeviceId with the exact Android Bluetooth device ID.'
}
if ($Suite -eq 'PairSampleRate' -and
    ($SampleRatesHz.Count -eq 0 -or @($SampleRatesHz | Where-Object { $_ -le 0 }).Count -gt 0)) {
    throw 'PairSampleRate requires one or more positive -SampleRatesHz values.'
}

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$workspacePubCache = Join-Path $projectRoot '..\..\.pub-cache'
if (Test-Path -LiteralPath $workspacePubCache) {
    $env:PUB_CACHE = (Resolve-Path -LiteralPath $workspacePubCache).Path
}
$patrolExecutable = Resolve-PatrolExecutable -ProjectRoot $projectRoot
Initialize-AndroidSdkEnvironment -ProjectRoot $projectRoot
$target = switch ($Suite) {
    'Hardware' { 'patrol_test/open_earable_connection_test.dart' }
    'Permissions' { 'patrol_test/onboarding_permissions_test.dart' }
    'PermissionRecovery' { 'patrol_test/late_microphone_permission_test.dart' }
    'Overview' { 'patrol_test/overview_shortcuts_test.dart' }
    'Settings' { 'patrol_test/general_settings_test.dart' }
    'ThisDevice' { 'patrol_test/this_device_connection_test.dart' }
    'ThisDeviceData' { 'patrol_test/this_device_recording_test.dart' }
    'PairDiscovery' { 'patrol_test/pair_discovery_test.dart' }
    'PairHardware' { 'patrol_test/open_earable_pair_test.dart' }
    'PairSampleRate' { 'patrol_test/open_earable_pair_sample_rate_test.dart' }
    default { 'patrol_test/navigation_and_settings_test.dart' }
}

$patrolArguments = @('build', 'android', '--debug', '--target', $target)
if ($Suite -eq 'Hardware') {
    $patrolArguments += "--dart-define=OPENEARABLE_DEVICE_ID=$OpenEarableDeviceId"
}
if ($Suite -eq 'PairSampleRate') {
    $invariantRates = ($SampleRatesHz | ForEach-Object {
        $_.ToString([Globalization.CultureInfo]::InvariantCulture)
    }) -join ','
    $invariantTolerance = $SampleTolerancePercent.ToString(
        [Globalization.CultureInfo]::InvariantCulture
    )
    $patrolArguments += "--dart-define=OPENEARABLE_SAMPLE_RATES_HZ=$invariantRates"
    $patrolArguments += "--dart-define=OPENEARABLE_SAMPLE_DURATION_SECONDS=$SampleDurationSeconds"
    $patrolArguments += "--dart-define=OPENEARABLE_SAMPLE_TOLERANCE_PERCENT=$invariantTolerance"
}

Push-Location -LiteralPath $projectRoot
try {
    & $patrolExecutable @patrolArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Patrol Android build failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}
