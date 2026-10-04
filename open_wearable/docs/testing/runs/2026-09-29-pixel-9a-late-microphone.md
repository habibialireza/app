# Late microphone permission recovery — Pixel 9a, Android 17

## Environment

| Field | Value |
| --- | --- |
| Date | 2026-09-29 (Europe/Berlin) |
| Phone | Google Pixel 9a (`tegu`) |
| Android | 17, API 37 |
| Test app | `edu.kit.teco.openWearable.patrol` (`OpenWearables Test`) |
| Journey | `patrol_test/late_microphone_permission_test.dart` |

## Result

The run passed with one successful journey, zero failures, and zero skips. It
completed 21 logged Patrol actions in 14 seconds; the complete device phase
took 75.1 seconds.

Patrol enabled Bluetooth and Location, granted the two Android dialogs produced
by the Bluetooth/location request, and deliberately used **Skip for now** on
the app's microphone onboarding page. It then reached Overview, opened Devices
and Connect Devices, and verified that the microphone recovery card was visible
while the Bluetooth recovery card was absent. Tapping the microphone recovery
action opened the native Android permission dialog. After Patrol granted it,
the test verified that both recovery cards were absent and the scan action was
still available.

The permissions belonged to the isolated test package. Patrol removed the
temporary test packages after execution and did not target the normal
OpenWearables installation.
