# Navigation smoke test — Pixel 9a, Android 17

## Environment

| Field | Value |
| --- | --- |
| Date | 2026-09-29 (Europe/Berlin) |
| Phone | Google Pixel 9a (`tegu`) |
| Android | 17, API 37 |
| CPU ABI | `arm64-v8a` |
| Test app | `edu.kit.teco.openWearable.patrol` (`OpenWearables Test`) |
| Controller | `edu.kit.teco.openWearable.patrol.test` |
| Target SDK | 36 |
| Source | Local branch `test/patrol-ui-foundation`, working tree not committed |
| Journey | `patrol_test/navigation_and_settings_test.dart` |

## Result

The journey passed three times from Patrol's cleared test-app state. Each run
reported one successful Dart journey and zero failures or skips. The third run
was a regression check after making the shared onboarding helper handle the
app's asynchronous permission explanation.

| Run | Result | Automated actions | Dart journey time | End-to-end device phase |
| --- | --- | ---: | ---: | ---: |
| 1 | Passed | 19 | 8 seconds | 87 seconds |
| 2 | Passed | 19 | 8.327 seconds | 64.3 seconds |
| 3 | Passed | 19 | 8 seconds | 59.0 seconds |

The run verified the permission-skip onboarding route, the missing-Bluetooth
recovery explanation, forward navigation through Devices, Sensors, Apps, and
Settings, and changing then restoring **Keep screen awake**.

The production package `edu.kit.teco.openWearable` remained installed after
the run. Patrol removed the temporary test and controller packages during its
cleanup. Generated HTML, XML, and device logs remain under `build/app/` on the
test PC and are ignored by Git.

## Remaining scope

This evidence does not cover permission grants, persistence after relaunch,
reverse navigation and scrolling, the other General settings, BLE connection,
OpenEarable capabilities, or physical behavior. Those remain separate rows in
the coverage inventory.
