# Pixel 9a OpenEarable pair sample-rate run — 2026-09-30

## Fixture

| Item | Value |
| --- | --- |
| Phone | Google Pixel 9a |
| Android | Android 17 / API 37 |
| Phone serial | Redacted from public documentation |
| Devices | Two OpenEarable-2B01 units, combined as L/R pair |
| Firmware observed for this fixture | `2.2.7-dev.12+g23ff47e.dirty` |
| Runtime BLE IDs | Automatically discovered; redacted from public documentation |
| Suite | `PairSampleRate` / `RATE-01` |
| Requested rates | 25, 50, and 100 Hz |
| Recording window | 12 seconds per requested rate |
| Allowed deviation | 15% |

The BLE IDs are evidence for this run only. These devices use rotating Android
addresses, so the test discovers and captures the current IDs each time. A
reader does not enter or replace these historical values when running the pair
test.

## Result

**Passed:** 1 test, 120 Patrol actions, 0 failures, 0 skipped. The test phase
took 106 seconds; build plus installation and execution took 2 minutes 35
seconds.

| Side | Requested | Observed | Samples received | Timestamp span | Difference |
| --- | ---: | ---: | ---: | ---: | ---: |
| L | 25.00 Hz | 24.99 Hz | 309 | 12.323 s | -0.04% |
| R | 25.00 Hz | 24.99 Hz | 318 | 12.683 s | -0.04% |
| L | 50.00 Hz | 49.95 Hz | 621 | 12.412 s | -0.10% |
| R | 50.00 Hz | 49.95 Hz | 638 | 12.752 s | -0.10% |
| L | 100.00 Hz | 99.90 Hz | 1,245 | 12.452 s | -0.10% |
| R | 100.00 Hz | 99.90 Hz | 1,271 | 12.712 s | -0.10% |

For each requested rate, Patrol opened the combined pair's 9-Axis IMU
configuration, enabled Bluetooth streaming, selected the exact rate, applied
the configuration, confirmed the accelerometer Live Data card, recorded, and
stopped through visible controls. The test then found the non-empty left and
right accelerometer CSV files and checked numeric, strictly increasing
microsecond timestamps.

The observed rate for each side was calculated from data the app received and
wrote:

```text
(number of received samples - 1) / (last timestamp - first timestamp)
```

Each result was inside the configured ±15% range. The test also confirmed both
files appeared in the expanded Recorder UI, deleted each successful test
recording through its confirmation dialog, split the pair during cleanup, and
disconnected both devices.

## Scope limit

This result verifies end-to-end received accelerometer cadence for the tested
rates and fixture. It does not establish accelerometer value accuracy, packet
jitter distribution, L/R clock synchronization, performance during phone
background/lock, other sensors, or long-duration loss behavior.

The generated Android report for the most recent local run is under
`build/app/reports/androidTests/connected/debug/index.html`.
