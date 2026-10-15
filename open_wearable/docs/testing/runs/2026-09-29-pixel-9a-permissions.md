# Onboarding permissions — Pixel 9a, Android 17

## Environment

| Field | Value |
| --- | --- |
| Date | 2026-09-29 (Europe/Berlin) |
| Phone | Google Pixel 9a (`tegu`) |
| Android | 17, API 37 |
| Test app | `edu.kit.teco.openWearable.patrol` (`OpenWearables Test`) |
| Journey | `patrol_test/onboarding_permissions_test.dart` |

## Result

The run passed with one successful journey, zero failures, and zero skips. It
completed 21 logged Patrol actions in 15 seconds; the complete device phase
took 81.2 seconds.

Patrol enabled the phone's Bluetooth and Location services, granted the two
Android dialogs produced by the Bluetooth/location request, granted the
microphone dialog, reached Overview, opened Connect Devices, and verified that
neither permission-recovery card remained.

The permissions belonged to the isolated test package. Patrol removed the
temporary test packages after execution and did not target the normal
OpenWearables installation.
