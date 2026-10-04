# Overview shortcuts — Pixel 9a, Android 17

## Environment

| Field | Value |
| --- | --- |
| Date | 2026-09-29 (Europe/Berlin) |
| Phone | Google Pixel 9a (`tegu`) |
| Android | 17, API 37 |
| Test app | `edu.kit.teco.openWearable.patrol` (`OpenWearables Test`) |
| Journey | `patrol_test/overview_shortcuts_test.dart` |

## Result

The final run passed with one successful journey, zero failures, and zero
skips. It completed 22 logged Patrol actions in 8 seconds; the complete device
phase took 52.6 seconds.

Patrol finished onboarding through the skip path and dismissed the app's
asynchronous Bluetooth/location permission explanation when it appeared. From
Overview, it opened all four visible workflow shortcuts and returned between
them. It verified the missing-Bluetooth recovery on Connect Devices, the
no-device prompts on Configure and Live Data, and the Local Recorder's
no-sensors state. The test also inspected the visible Start Recording button
and confirmed it was disabled while no sensors were connected.

This run covers the no-device variant of NAV-07. The same shortcuts still need
to be repeated with an identified connected device so their connected-session
content can be verified.

The isolated Patrol test package was removed after execution. The normal
OpenWearables installation and nearby OpenEarables were not targeted.
