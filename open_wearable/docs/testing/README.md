# OpenWearables UI testing with Patrol

These tests drive the production Flutter app through visible controls, native
Android permission dialogs, and Bluetooth flows. Patrol is the test runner; the
OpenEarable remains the real hardware under test.

A phone is not needed to author tests or build the Android artifacts. A phone is
needed to install and execute them, and the hardware journey also needs an
advertising OpenEarable in range.

This first phase targets Android. The same journey design can be carried to
iOS after the Android suite is stable on real hardware.

## Current setup

| Component | Version or value |
| --- | --- |
| Flutter package | `patrol` `4.10.0` |
| Command-line tool | `patrol_cli` `4.8.0` |
| Android production app ID | `edu.kit.teco.openWearable` |
| Android Patrol/debug app ID | `edu.kit.teco.openWearable.patrol` |
| Android Patrol/debug label | `OpenWearables Test` |
| Android runner | `pl.leancode.patrol.PatrolJUnitRunner` |
| Test isolation | Android Test Orchestrator with only the test app's data cleared |

Keep the CLI at `4.8.0`: `patrol` `4.10.0` requires that version or newer, and
this repository pins the tested pair rather than silently taking a later CLI.

The initial automated journeys are:

| Test | Coverage matrix mapping | Current assertions |
| --- | --- | --- |
| `patrol_test/onboarding_permissions_test.dart` | `NAV-01` | Drives the real Android Bluetooth/location and microphone permission dialogs, reaches Overview, and confirms the connection screen no longer requests either permission. It passed on a Pixel 9a running Android 17/API 37 on 2026-09-29. |
| `patrol_test/late_microphone_permission_test.dart` | `NAV-03` | Grants Bluetooth/location but deliberately skips microphone during onboarding, verifies that Connect Devices offers microphone recovery, grants the native permission from that recovery action, and verifies that the reminder disappears. It passed on a Pixel 9a running Android 17/API 37 on 2026-09-29. |
| `patrol_test/overview_shortcuts_test.dart` | `NAV-07` | Opens all four Overview workflow shortcuts, verifies their Connect Devices, Configure, Live Data, and Recorder destinations, checks the no-device states, and confirms recording cannot start without connected sensors. It passed on a Pixel 9a running Android 17/API 37 on 2026-09-29. |
| `patrol_test/this_device_connection_test.dart` | `CON-13` | Connects the Pixel itself through the visible discovery row, verifies the Connected and Overview states, opens its device details, disconnects it, and verifies cleanup. It passed on a Pixel 9a running Android 17/API 37 on 2026-09-29. |
| `patrol_test/this_device_recording_test.dart` | `CFG-02`, `CFG-03`, `LIVE-01`, `REC-02`, `REC-08` (fixture-specific/partial) | Connects the Pixel as a sensor device, configures its accelerometer at 5 Hz, applies the setting, opens Live Data, records for two seconds, verifies a visible non-empty CSV, deletes the test recording, verifies empty history, and disconnects. The strengthened journey passed twice on a Pixel 9a running Android 17/API 37 on 2026-09-29. |
| `patrol_test/navigation_and_settings_test.dart` | `NAV-02`, `NAV-06`, `SET-01` (partial) | Completes first-run onboarding with the permission skip path, checks the missing-permission explanation, visits Devices, Sensors, Apps, and Settings, then toggles and restores Keep screen awake. It passed three times on a Pixel 9a running Android 17/API 37 on 2026-09-29. It does not yet check every setting, relaunch persistence, or every page scroll. |
| `patrol_test/general_settings_test.dart` | `SET-01` (partial) | Changes all five General settings, verifies the changed values after reopening the page, restores every original value, and verifies cleanup. It passed on a Pixel 9a running Android 17/API 37 on 2026-09-29. Process-relaunch persistence remains planned. |
| `patrol_test/open_earable_connection_test.dart` | `CON-01`, `CON-07`, `DEV-01` (partial) | Grants Android permissions, scans for one exact device ID, connects it, opens its information and battery sections, disconnects, reconnects, reopens details, and disconnects for cleanup. It does not yet assert every identity/version field. |
| `patrol_test/open_earable_pair_test.dart` | `CON-09` | Enables the OpenEarable name filter, requires exactly two matching advertisers, captures their rotating BLE addresses for that run, connects both, verifies a combined card with L/R identities, splits and recombines the pair, then splits and disconnects both during guaranteed cleanup. It passed on a Pixel 9a running Android 17/API 37 with two OpenEarable-2B01 devices on 2026-09-30. |
| `patrol_test/open_earable_pair_sample_rate_test.dart` | `RATE-01` | Connects exactly two OpenEarables as a pair, enables 9-Axis IMU streaming at each requested rate, records both devices, calculates the received accelerometer rate from each side's CSV timestamps, checks the configured tolerance, deletes successful test artifacts, and disconnects both devices. It passed at 25/50/100 Hz on a Pixel 9a with two OpenEarable-2B01 devices on 2026-09-30; [run record](runs/2026-09-30-pixel-9a-pair-sample-rates.md). |

The exact assertions and limitations of every selectable suite are in
[`test-catalog.md`](test-catalog.md). The complete planned journey inventory is
in [`ui-coverage.md`](ui-coverage.md). An automated path being present does not
mean it has passed on a real phone; record that only after a device run.
Real-device run evidence is stored under [`runs/`](runs/).

## One-time Windows setup

Flutter plugins use symbolic links on Windows. Enable **Developer Mode** under
Windows **Settings > System > For developers**, then open a new terminal. Without
it, `flutter pub get` or the Android build ends with a symlink-support error.

From the `open_wearable` directory, install dependencies and the pinned Patrol
CLI:

```powershell
flutter pub get
dart pub global activate patrol_cli 4.8.0
patrol doctor
```

If PowerShell cannot find `patrol`, add Dart's global executable directory to
`PATH` as instructed by `dart pub global activate`, reopen the terminal, and run
`patrol doctor` again.

The helper scripts read the Android SDK path from `android/local.properties`
and export it for their Patrol process. When running Patrol directly, set
`ANDROID_HOME` and add its `platform-tools` directory to `PATH` if
`patrol doctor` cannot find `adb`.

## Build now without a phone

Build the UI-only journey:

```powershell
.\tool\ui_tests\build_android.ps1 -Suite Navigation
```

Build the real-device Bluetooth journey with the exact identifier used by the
app on Android (usually the Bluetooth address, not the display name):

```powershell
.\tool\ui_tests\build_android.ps1 `
  -Suite Hardware `
  -OpenEarableDeviceId 'AA:BB:CC:DD:EE:FF'
```

The hardware ID is compiled into that test build through
`OPENEARABLE_DEVICE_ID`. The test deliberately refuses to select the first scan
result because another nearby OpenEarable could otherwise be modified.

The initial hardware journey requires a directly connected GATT OpenEarable
that advertises again after disconnect and exposes the app's Device Information
and Battery sections. A device represented as a system-managed `SystemDevice`
uses the separate Forget/Bluetooth-settings flow and is covered by the planned
system-device journey rather than this direct-disconnect test.

Build the two-device stereo-pair journey:

```powershell
.\tool\ui_tests\build_android.ps1 -Suite PairHardware
```

The pair journey does not persist Android BLE addresses. The tested
OpenEarable firmware uses private addresses that change after a power cycle.
Instead, the test enables the app's OpenEarable name filter, requires exactly
two matching visible rows, captures their current addresses, and uses those
exact rows for the remainder of that run. It refuses to choose when the
filtered result is not exactly two devices.

`patrol build android` produces two APKs and prints their paths:

- the OpenWearables app under test;
- an Android instrumentation APK that controls the app and reports results.

The instrumentation APK is not a standalone app with a launcher icon. Both
APKs belong together and are normally installed and started by Patrol, `adb`
instrumentation tooling, or an Android device farm.

Android debug builds use the separate `edu.kit.teco.openWearable.patrol`
application ID and the launcher label **OpenWearables Test**. The release app
keeps `edu.kit.teco.openWearable`, so both can be installed at once. Patrol's
data cleanup applies to the test installation only. The helper scripts always
pass `--debug`; do the same if you run Patrol directly.

## Run later on a phone

### Find the command values

Values written inside angle brackets, such as `<phone-serial>`, are examples
that must be replaced in the command. They are not values to edit in the Dart
test or in this documentation.

Connect the unlocked Android phone with USB debugging enabled, accept the RSA
prompt on the phone, and run:

```powershell
adb devices -l
```

The first column on a `device` row is the phone serial. For example:

```text
List of devices attached
ABC123EXAMPLE    device product:tegu model:Pixel_9a
```

For that example, replace `<phone-serial>` with `ABC123EXAMPLE`. `patrol
devices` can also list phones visible to Patrol:

```powershell
patrol devices
```

If exactly one Android phone is connected, `-AndroidDevice` can be omitted and
Patrol will select that phone. The shortest pair-rate command is therefore:

```powershell
.\tool\ui_tests\run_android.ps1 `
  -Suite PairSampleRate `
  -SampleRatesHz 25,50,100
```

The pair suites do **not** require Bluetooth IDs on the command line.
`PairHardware` and `PairSampleRate` enable the OpenEarable scan filter, require
exactly two matching advertisers, capture their current rotating IDs, and use
those exact devices for the remainder of that run. Wake or power-cycle both
OpenEarables before the run and keep them near the phone. If fewer or more than
two filtered devices are visible, the test fails instead of choosing
ambiguously.

Only the single-device `Hardware` suite requires
`-OpenEarableDeviceId`. Find that current ID below the device name on the app's
**Connect Devices** scan screen, then pass it exactly as displayed. An
OpenEarable 2 ID can change after a power cycle, so read it again for a later
single-device run. Prefer the pair suites when testing two OpenEarables.

| Command value | Where it comes from | Required? |
| --- | --- | --- |
| `-AndroidDevice '<phone-serial>'` | First column from `adb devices -l`, or the identifier shown by `patrol devices`. | Optional when exactly one phone is connected. |
| `-OpenEarableDeviceId 'AA:BB:CC:DD:EE:FF'` | Current ID shown for that device on the app's Connect Devices scan screen. | Only for the single-device `Hardware` suite. |
| Pair Bluetooth IDs | Discovered automatically after filtering the app's scan results. | Never entered manually. |
| `-SampleRatesHz 25,50,100` | Rates the user wants to test; the current OpenEarable 2 firmware offers 25, 50, and 100 Hz for 9-Axis IMU Bluetooth streaming. | Optional; default is 25 Hz. |
| `-SampleDurationSeconds 12` | Recording time for each requested rate. Longer runs contain more samples. | Optional; default is 12 seconds and minimum is 5. |
| `-SampleTolerancePercent 15` | Maximum allowed percentage difference between requested and received rate. | Optional; default is 15%. |

Runtime BLE IDs written in a historical run record are evidence from that
completed run. A reader does not reuse or replace them when starting a new pair
test because the test discovers new IDs automatically.

List every selectable suite or use the numbered chooser:

```powershell
.\tool\ui_tests\run_android.ps1 -ListSuites
.\tool\ui_tests\choose_android_test.ps1 -AndroidDevice '<phone-serial>'
```

After confirming that the phone appears in both `adb devices` and `patrol
devices`, run the UI-only journey:

```powershell
.\tool\ui_tests\run_android.ps1 `
  -Suite Navigation `
  -AndroidDevice '<phone-serial>'
```

For the hardware journey, charge and advertise the selected OpenEarable, keep
it near the phone, and disconnect other apps that may already own its Bluetooth
connection:

```powershell
.\tool\ui_tests\run_android.ps1 `
  -Suite Hardware `
  -AndroidDevice '<phone-serial>' `
  -OpenEarableDeviceId 'AA:BB:CC:DD:EE:FF'
```

For a stereo pair, wake both sides and keep them near the phone. On the tested
firmware the devices stop advertising after the test disconnects them, so wake
or power-cycle both sides before another pair run:

```powershell
.\tool\ui_tests\run_android.ps1 `
  -Suite PairHardware `
  -AndroidDevice '<phone-serial>'
```

To set and verify one or more received pair IMU sample rates, wake both sides
first and run:

```powershell
.\tool\ui_tests\run_android.ps1 `
  -Suite PairSampleRate `
  -AndroidDevice '<phone-serial>' `
  -SampleRatesHz 25,50,100 `
  -SampleDurationSeconds 12 `
  -SampleTolerancePercent 15
```

The current OpenEarable 2 firmware exposes 25, 50, and 100 Hz for Bluetooth
9-Axis IMU streaming. The test checks the left and right accelerometer files
independently using the timestamps of samples that the app actually received.

`patrol test` builds the current sources, installs both APKs, runs the selected
test through Android instrumentation, and reports the result. Omitting
`-AndroidDevice` lets Patrol select the only connected device or prompt when
several are available. App data is cleared for isolation, so these journeys
start at onboarding and should use a dedicated test installation/account.

Direct Patrol equivalents are:

```powershell
patrol build android --debug --target patrol_test/navigation_and_settings_test.dart

patrol test `
  --debug `
  --device '<phone-serial>' `
  --target patrol_test/open_earable_connection_test.dart `
  --dart-define=OPENEARABLE_DEVICE_ID=AA:BB:CC:DD:EE:FF
```

Patrol reference: [build](https://patrol.leancode.co/cli-commands/build) and
[test](https://patrol.leancode.co/cli-commands/test).
