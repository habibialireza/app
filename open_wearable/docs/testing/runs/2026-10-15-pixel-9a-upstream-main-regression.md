# Pixel 9a regression run on updated upstream main

Date: 2026-10-15  
Phone: Pixel 9a, Android 17 / API 37  
App source: `upstream/main` at `38beb402e27c6f9ffff2e0e5a259bc3821e4ddc1`  
Test source: `test/patrol-after-merged-pr` at `daebce0aa9d4047271e08f67cfd9230a3e846446` plus the uncommitted test/doc updates in that checkout.  
Build: Android debug Patrol APKs built successfully for Settings, PairSampleRate, and each executed suite.

## Results

| Suite | Result | Notes |
| --- | --- | --- |
| `Settings` | Passed | All six General settings changed, remained changed after reopening the page, then were restored. This includes the new Show sampling rates setting. |
| `Navigation` | Passed | Onboarding skip path, main tabs, missing-permission explanation, and Keep screen awake toggle. |
| `Overview` | Passed | All four shortcuts opened the expected no-device destination. |
| `Permissions` | Passed | Granted Android Bluetooth/location and microphone prompts during onboarding. |
| `PermissionRecovery` | Passed | Skipped microphone during onboarding, then granted it from Connect Devices. |
| `ThisDevice` | Passed after test-harness fix | First run completed its UI assertions but failed teardown with an active Flutter semantics handle. Disabling semantics for this widget-tree-driven Patrol test fixed teardown; the rerun passed. |
| `ThisDeviceData` | Passed | Selected 5 Hz for the phone Accelerometer, streamed, recorded a non-empty CSV, deleted it, and disconnected. This test verifies CSV existence, not the phone's measured 5 Hz rate. |
| `PairDiscovery` | Passed on retry | The first run found no matching rows; after the pair lifecycle run, the discovery-only rerun found at least two devices. |
| `PairHardware` | Passed | Discovered and connected two devices, checked L/R identities, split and recombined the pair, then disconnected both. |
| `PairSampleRate` | Passed after fixture wake and test fix | The first attempt found no pair. The next attempt connected both rotating IDs, but a “Firmware Update Available” dialog for firmware 2.2.9 covered the app. Added visible dismissal and partial-pair cleanup, then woke both devices and reran successfully. L and R CSV measurements were 24.99 Hz for requested 25 Hz, 49.95 Hz for requested 50 Hz, and 99.90 Hz for requested 100 Hz. Every rate passed the 15% tolerance; all three test recordings were deleted and both devices disconnected. |
| `Hardware` (single exact ID) | Not completed | APK built, but the exact BLE ID captured by the earlier pair test was no longer visible when this run scanned. The Pixel also briefly disappeared from ADB during this run. This is not a device-details assertion result. |

### RATE-01 measurements

The sample-rate assertion used each received CSV's first-column timestamps;
the values below were captured from the phone's test log. Each side passed the
15% tolerance, with strictly increasing timestamps and sufficient recording
span.

| Requested | Left samples / span / measured rate | Right samples / span / measured rate |
| --- | --- | --- |
| 25 Hz | 309 / 12.323 s / 24.99 Hz | 318 / 12.683 s / 24.99 Hz |
| 50 Hz | 621 / 12.412 s / 49.95 Hz | 637 / 12.732 s / 49.95 Hz |
| 100 Hz | 1,244 / 12.442 s / 99.90 Hz | 1,271 / 12.712 s / 99.90 Hz |

## Interpretation

The latest main-based app passed the phone-only flows, all six settings, phone
sensor recording, the two-device pairing lifecycle, and RATE-01. The sample-rate
test verified all three requested settings against timestamps in the CSV files
written by the app: both sides measured 24.99 Hz, 49.95 Hz, and 99.90 Hz for
requested 25, 50, and 100 Hz. It checked monotonic timestamps, recording span,
sample count, and the 15% tolerance. This run did not validate the
expected/actual rate labels on the live charts; those remain outside the
existing Patrol assertions.

The PairDiscovery test's empty scan and the later successful hardware runs show
that BLE visibility varied during this session. OpenEarables must be advertising
when the test scans; being powered on alone does not guarantee that the phone
will see them. A wake/power cycle restored advertising. The PairSampleRate helper
now dismisses the firmware notice and attempts cleanup after an interrupted
partial connection.

## Rerun commands

From `open_wearable` in PowerShell, replace the Android serial with the value
shown by `adb devices -l`:

```powershell
.\tool\ui_tests\run_android.ps1 -Suite PairSampleRate `
  -AndroidDevice <phone-serial> `
  -SampleRatesHz 25,50,100 `
  -SampleDurationSeconds 12 `
  -SampleTolerancePercent 15
```

The sample-rate test calculates the received accelerometer rate on the phone
from each device's CSV timestamps. A pass checks the left and right rates
against each requested rate within 15%. The table above records the observed
sample counts, durations, and rates from this run.
