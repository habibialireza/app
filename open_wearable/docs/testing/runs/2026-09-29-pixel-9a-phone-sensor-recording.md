# Phone sensor configuration and recording — Pixel 9a, Android 17

## Environment

| Field | Value |
| --- | --- |
| Date | 2026-09-29 (Europe/Berlin) |
| Phone | Google Pixel 9a (`tegu`) |
| Android | 17, API 37 |
| Test app | `edu.kit.teco.openWearable.patrol` (`OpenWearables Test`) |
| Journey | `patrol_test/this_device_recording_test.dart` |

## Result

The full journey passed twice. Each run reported one successful journey, zero
failures, and zero skips. The stronger second run completed 50 logged Patrol
actions in 27 seconds; its complete device phase took 72.3 seconds.

Patrol connected the Pixel through the visible **this device** entry, opened
the Accelerometer configuration sheet, selected 5 Hz, closed the sheet, and
tapped Apply Profiles. Live Data displayed the Accelerometer card. The test
then opened Recorder, verified Start Recording was enabled, recorded for two
seconds, stopped, expanded the newest recording folder, and verified a CSV row
with a non-zero displayed size. It confirmed deletion of that test-created
folder, verified **No recordings yet**, and disconnected the phone fixture.

This proves the app's UI path from local sensor discovery through configuration,
stream setup, file creation, history refresh, and cleanup on this phone. It does
not replace the corresponding OpenEarable BLE, multi-sensor, accuracy, or
long-duration tests.
