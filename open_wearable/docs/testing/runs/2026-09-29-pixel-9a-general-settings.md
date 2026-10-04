# General settings — Pixel 9a, Android 17

## Environment

| Field | Value |
| --- | --- |
| Date | 2026-09-29 (Europe/Berlin) |
| Phone | Google Pixel 9a (`tegu`) |
| Android | 17, API 37 |
| Test app | `edu.kit.teco.openWearable.patrol` (`OpenWearables Test`) |
| Source | Local branch `test/patrol-ui-foundation`, working tree not committed |
| Journey | `patrol_test/general_settings_test.dart` |

## Result

The final run passed with one successful journey, zero failures, and zero
skips. It completed 43 logged Patrol actions in 13 seconds; the complete device
phase took 63.1 seconds.

The journey changed each of these settings independently:

- Enable Bluetooth auto-connect
- Keep screen awake
- Disable all sensors on app close
- Disable live data graphs
- Hide live data graphs without data

It left and reopened General settings, verified every changed value, restored
the five original values in reverse order, reopened the page again, and
verified cleanup. Platform semantics were disabled for this widget-value test
after Flutter's live Android binding leaked a semantics handle during the first
otherwise-functional attempt.

Process termination and relaunch persistence remain planned. Patrol removed
the temporary test packages after execution; the normal OpenWearables package
was not targeted.
