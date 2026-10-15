# Phone-as-device connection — Pixel 9a, Android 17

## Environment

| Field | Value |
| --- | --- |
| Date | 2026-09-29 (Europe/Berlin) |
| Phone | Google Pixel 9a (`tegu`) |
| Android | 17, API 37 |
| Test app | `edu.kit.teco.openWearable.patrol` (`OpenWearables Test`) |
| Journey | `patrol_test/this_device_connection_test.dart` |

## Result

The run passed with one successful journey, zero failures, and zero skips. It
completed 31 logged Patrol actions in 19 seconds; the complete device phase
took 82.8 seconds.

Patrol granted the native Android permissions, opened Connect Devices, and
tapped the Pixel entry marked **this device**. The app probed the phone's real
local sensor capabilities before adding it. The test verified the phone in the
Connected list, a Connected Devices count of one on Overview, and the phone's
device-detail page. It then disconnected the phone fixture and verified the
empty Devices action returned.

No external OpenEarable was selected or changed. The isolated Patrol package
was removed after execution.
