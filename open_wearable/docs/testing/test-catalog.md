# Patrol test catalog

This catalog separates three different facts that are easy to confuse:

- **Implemented** means a Patrol test exists in this repository.
- **Verified** means that exact test has passed on the documented real phone and fixture.
- **Planned** means the app could be tested this way, but no automated journey implements it yet.

A green suite proves only the assertions listed below. It does not prove every
feature on the screens that the journey happened to visit.
The real-phone passes listed here record their specific run dates and fixtures.
The current main-based Android run passed several existing paths, including
the pair sample-rate check. See the
[current regression run](runs/2026-10-15-pixel-9a-upstream-main-regression.md)
for exact outcomes; historical passes do not substitute for unrun assertions.

## How to choose a test

Show the selectable suite names without running anything:

```powershell
.\tool\ui_tests\run_android.ps1 -ListSuites
```

Use the beginner-friendly numbered menu:

```powershell
.\tool\ui_tests\choose_android_test.ps1 -AndroidDevice '<phone-serial>'
```

Or select a suite directly:

```powershell
.\tool\ui_tests\run_android.ps1 `
  -Suite PairHardware `
  -AndroidDevice '<phone-serial>'
```

`<phone-serial>` means the first-column identifier reported by `adb devices
-l` or the identifier shown by `patrol devices`. If exactly one phone is
connected, omit `-AndroidDevice` entirely. Pair suites discover the two current
rotating OpenEarable Bluetooth IDs automatically; users never enter those
IDs. Only the single-device `Hardware` suite needs an
`-OpenEarableDeviceId`, copied from the app's Connect Devices scan screen.

See [Find the command values](README.md#find-the-command-values) for examples,
defaults, and the complete parameter table.

## Implemented suites and their exact checks

### `Navigation`

File: [`navigation_and_settings_test.dart`](../../patrol_test/navigation_and_settings_test.dart)  
Real-device state: **verified** on Pixel 9a, Android 17/API 37.

It checks:

1. The welcome screen appears on a clean test-app install.
2. The user can skip first-run permission setup and reach the main app.
3. Connect Devices explains that Bluetooth and Location are required.
4. Back navigation returns from Connect Devices.
5. Devices, Sensors, Apps, and Settings can all be opened from the main navigation.
6. Sensors exposes its Configuration tab.
7. Apps contains the Posture Tracker tile.
8. General settings opens.
9. Keep screen awake changes when tapped and can be restored to its original value.

It does not check every control on those pages, physical Bluetooth discovery,
sensor data, recordings, app relaunch persistence, or the behavior of keeping
the real display awake.

### `Permissions`

File: [`onboarding_permissions_test.dart`](../../patrol_test/onboarding_permissions_test.dart)  
Real-device state: **verified** on Pixel 9a, Android 17/API 37.

It checks:

1. The welcome screen appears.
2. Android Bluetooth/nearby-device, Location, and Microphone permission dialogs can be completed through the onboarding UI.
3. The Overview page becomes available after onboarding.
4. Connect Devices no longer shows either permission-recovery card.

It does not check permanent denial, “Don't ask again,” permission revocation in
Android Settings, upgrading from an older app version, or iOS permission dialogs.

### `PermissionRecovery`

File: [`late_microphone_permission_test.dart`](../../patrol_test/late_microphone_permission_test.dart)  
Real-device state: **verified** on Pixel 9a, Android 17/API 37.

It checks:

1. Bluetooth/Location can be granted while Microphone is deliberately skipped.
2. Connect Devices shows the missing-Microphone recovery action but no Bluetooth recovery action.
3. Tapping recovery opens the Android permission flow.
4. After granting, both recovery messages disappear and scanning is available.

It does not check a permanently denied Microphone permission, denial a second
time, revocation while the app is running, or recovery through system Settings.

### `Overview`

File: [`overview_shortcuts_test.dart`](../../patrol_test/overview_shortcuts_test.dart)  
Real-device state: **verified** on Pixel 9a, Android 17/API 37.

It checks:

1. With no devices, Overview says that the app is disconnected.
2. Connect Devices opens the correct connection screen.
3. Configure Sensors opens the correct no-device configuration state with a scan action.
4. View Sensor Data opens the correct no-device Live Data state with a scan action.
5. Record opens Local Recorder.
6. Recorder reports that no sensors are connected.
7. Start Recording is disabled when no sensor exists.
8. The user can return to Overview.

It does not check shortcut behavior with connected devices, active streams, or
an active recording.

### `Settings`

File: [`general_settings_test.dart`](../../patrol_test/general_settings_test.dart)  
Real-device state: all six switches were verified on Pixel 9a, Android 17/API
37, 2026-10-15: each changed, remained changed after reopening General settings,
and was restored. Process-relaunch persistence remains planned; see the
[current regression run](runs/2026-10-15-pixel-9a-upstream-main-regression.md).

It checks each of these six switches:

- Bluetooth auto-connect
- Keep screen awake
- Disable all sensors on app close
- Disable live data graphs
- Hide live data graphs without data
- Show sampling rates

For every switch it records the original value, changes it, leaves and reopens
General settings, confirms that the changed value remains, restores the
original value, reopens the page again, and confirms cleanup.

It does not terminate/relaunch the process, wait for screen timeout, exercise
auto-connect with hardware, close the app with active sensors, or verify how
the graph settings change rendered graphs or sampling-rate labels.

### `ThisDevice`

File: [`this_device_connection_test.dart`](../../patrol_test/this_device_connection_test.dart)  
Real-device state: **verified** on Pixel 9a, Android 17/API 37 on 2026-09-29
and again on 2026-10-15 against the current main-based app.

It checks:

1. The phone can be chosen from the visible scan screen as a sensor device.
2. Its scan entry disappears after connection.
3. The Devices page shows the connected phone.
4. Overview changes to one connected device.
5. The phone's device-details page opens.
6. Disconnect removes the connected row and returns the Devices page to its connect state.

It does not check every phone sensor, unsupported-sensor handling, background
behavior, reconnect, or phone model-specific sampling limitations.

### `ThisDeviceData`

File: [`this_device_recording_test.dart`](../../patrol_test/this_device_recording_test.dart)  
Real-device state: **verified** on Pixel 9a, Android 17/API 37 twice on
2026-09-29 and again on 2026-10-15 against the current main-based app.

It checks:

1. The phone connects as a sensor device.
2. The Accelerometer configuration sheet opens.
3. A 5.00 Hz choice is selectable.
4. Applying the configuration exposes Accelerometer in Live Data.
5. Live Data is no longer stuck at “Waiting for live sensor data.”
6. Recorder is enabled.
7. A two-second recording starts and stops through the visible UI.
8. The latest recording exposes at least one CSV whose displayed size is not zero.
9. Confirmed deletion removes that recording and restores “No recordings yet.”
10. The phone sensor device disconnects cleanly.

It does not calculate the phone's actual received sample rate, validate CSV
columns or values, test other phone sensors/rates, keep multiple recordings, or
test file opening and sharing.

### `PairDiscovery`

File: [`pair_discovery_test.dart`](../../patrol_test/pair_discovery_test.dart)  
Real-device state: passed on Pixel 9a / Android 17 (API 37) on 2026-10-15 after
an initial scan with no results; it remains a discovery-only check, while the
pair lifecycle test makes the final pairing assertions.

It checks:

1. The OpenEarable-only filter can be enabled.
2. An eight-second BLE scan completes.
3. At least two filtered OpenEarable rows are present.
4. The phone-as-device row is absent from that filtered result.
5. It does not connect to any discovered device.

It does not require exactly two devices, distinguish left from right, connect,
or prove that either advertiser is usable.

### `PairHardware`

File: [`open_earable_pair_test.dart`](../../patrol_test/open_earable_pair_test.dart)  
Real-device state: **verified** on Pixel 9a, Android 17/API 37 with two
OpenEarable-2B01 devices running firmware `2.2.7-dev.12+g23ff47e.dirty` on
2026-09-30 and again on 2026-10-15 against the current main-based app.

It checks:

1. The app filters scan results to OpenEarables.
2. Exactly two matching devices must advertise; ambiguity causes a failure.
3. Their current rotating Android BLE IDs are captured at runtime.
4. Both exact scan rows connect.
5. The Devices page creates one combined stereo-pair card.
6. The combined card visibly contains both L and R identities.
7. Splitting produces both exact individual device rows.
8. The individual devices have different side labels, one L and one R.
9. Recombining recreates the combined pair card.
10. Guaranteed cleanup splits the pair and disconnects both devices.

It does not configure sensors, stream, record, test partial-pair loss, verify
audio/LED/battery features, or measure left/right time synchronization.

### `PairSampleRate`

File: [`open_earable_pair_sample_rate_test.dart`](../../patrol_test/open_earable_pair_sample_rate_test.dart)  
Real-device state: **verified** on Pixel 9a, Android 17/API 37 with two
OpenEarable-2B01 devices on 2026-09-30 and again on 2026-10-15 against current
main. The current-main run checked 25/50/100 Hz and measured 24.99, 49.95, and
99.90 Hz on both L/R accelerometer CSVs, respectively. An earlier attempt
revealed a firmware-update dialog that blocked the UI; the helper now dismisses
it and cleans up partial connections. See the [current regression run](runs/2026-10-15-pixel-9a-upstream-main-regression.md).

For every requested rate, it checks:

1. Exactly two OpenEarables are discovered and connected as a combined L/R pair.
2. The combined `9-Axis IMU` configuration sheet opens.
3. `Live stream to phone` is enabled for the pair.
4. The exact requested rate is offered by the connected firmware; absence fails clearly.
5. Applying the setting produces an `ACCELEROMETER` Live Data card.
6. Recording starts through the visible Recorder UI.
7. Recording stays active for the configured duration, 12 seconds by default.
8. Recording stops and its files finish writing.
9. The newest recording has one non-empty accelerometer CSV for L and one for R.
10. Every received timestamp in each checked file is numeric and strictly increasing.
11. Each file spans at least 60% of the requested recording window and contains at least ten samples.
12. The observed rate is calculated independently for L and R as `(received samples - 1) / (last timestamp - first timestamp)`.
13. Each observed rate is within the selected tolerance of the requested rate, 15% by default.
14. Requested rate, observed rate, sample count, time span, side, and filename are printed as evidence.
15. The test-created recording is deleted through the visible UI after a successful check.
16. Both devices are disconnected in guaranteed cleanup.

The OpenEarable 2 firmware in this workspace advertises `25`, `50`, and `100`
Hz as streamable 9-Axis IMU rates. Run all three in one connection:

```powershell
.\tool\ui_tests\run_android.ps1 `
  -Suite PairSampleRate `
  -AndroidDevice '<phone-serial>' `
  -SampleRatesHz 25,50,100 `
  -SampleDurationSeconds 12 `
  -SampleTolerancePercent 15
```

This test measures samples that reached the app and were written to CSV. It
does not prove that acceleration values are physically accurate, that samples
are synchronized between L and R, that packet timing has low jitter, that
every other sensor meets its rate, that long recordings remain loss-free, or
that the expected/actual sampling-rate labels on the live graphs agree with the
CSV measurements. Those are separate checks listed below.

### `Hardware`

File: [`open_earable_connection_test.dart`](../../patrol_test/open_earable_connection_test.dart)  
Real-device state: implemented for a single exact ID; rotating OpenEarable 2
addresses make `PairHardware` the safer default for the current two-device fixture.

It checks:

1. A non-empty exact Bluetooth ID was supplied.
2. That exact device appears in scan results and connects.
3. Its details page opens and contains Device Information and Battery sections.
4. It disconnects and becomes discoverable again.
5. It reconnects, reopens details, and disconnects again for cleanup.

It does not assert the displayed serial/version/battery values, accept rotating
IDs automatically, or test any device control beyond connect/disconnect.

## Features the framework could check but does not yet automate

The complete case-by-case backlog is in [`ui-coverage.md`](ui-coverage.md).
The main missing areas are:

| Area | Examples of checks still available to add |
| --- | --- |
| Connection failures | Bluetooth off, scan timeout, connection timeout, cancellation, retry, out-of-range loss, auto-reconnect, duplicate devices, a third nearby OpenEarable, one side disappearing from a pair, preserving the surviving side while recovering its partner, retrying an unknown stereo position, and Android BLE cleanup after reconnect. |
| Device information | Exact name, identifier, hardware/firmware version, battery level/status/health/energy, refresh behavior, and capability-dependent sections. |
| Pair behavior | Side reassignment, restart persistence, mismatched firmware, partial-pair operation, multiple pairs, pair time synchronization, and reconnect after one or both devices sleep. |
| Device controls | Listening mode, microphone source and gain, mute/reset, power-saving mode, saved status-LED/RGB values after reopening or changing devices, and verifying the physical output of those controls. |
| Sensor configuration | Every sensor, sorted rate choices, every advertised rate, device-reported state after Apply, Stream versus on-device SD target and filename prefix, Off, multiple simultaneous sensors, saved profiles, invalid/duplicate profile names, pair readback after splitting, and failure during Apply. |
| Sample-rate quality | The expected/actual labels on live graphs, all streamable sensors and rates, multiple sensors concurrently, long-duration loss rate, jitter distribution, maximum timestamp gap, duplicated samples, L/R clock offset and drift, background/locked-phone behavior, and repeatability across firmware versions. The current pair test checks only CSV timestamps for the 9-Axis IMU. |
| Live Data | Correct units and axes, numerical updates, chart detail, channel visibility, expected/actual rate labels, low/high-pass and notch controls, no-data hiding, disabled graphs, and disconnect/reconnect while graphs are open. |
| Recorder | Multiple recordings, elapsed-time accuracy, navigation while recording, rapid Start/Stop, stop-and-disable-sensors behavior, on-device recording prefixes/targets, filename/content schema, file-open failures, open/share/cancel, batch delete, locked/background recording, Android microphone capture during music playback, storage-full errors, and recordings across reconnect. |
| Labels | Create/edit/delete label groups, validation, persistence, segment switching while recording, and exported label timing. |
| Built-in apps | Posture Tracker stop/leave cleanup and reconnect recovery; calibration and reminders; Heart Tracker reconnect recovery, signals, and quality states; Seal Check measurement, graphs, export, retry, and disconnect behavior. |
| Network connector | Enable/disable, port/path validation, persistence, local client connection, message schema, sensor-configuration report sharing, websocket/log lifecycle, disconnection, and no-network recovery. |
| Logs and About | Open/share/delete logs, empty/error logs, shared logging lifecycle, version display, licenses, and browser links. |
| Firmware update | Checklist, release catalog, offline retry, file picker, progress, cancel/abort gating, early reconnect and verification countdown, image-slot recovery, preserved FOTA logs, successful lab update, and failure without a false success. |
| Android lifecycle/accessibility | Home/background, lock/unlock, process death, permission revocation, rotation, font/display scaling, keyboard overlap, dark mode, and screen-reader semantics. |
| iPhone | The corresponding iOS onboarding, permissions, Bluetooth, native dialogs, background behavior, recording storage/sharing, and hardware journeys. |
| Sensor decoding compatibility | 1.6 compact IMU/PPG data decoding and firmware-revision selection. The Patrol rate test inspects CSV timestamps only; deterministic payload decoding belongs in package tests with captured fixtures, plus hardware smoke tests for live values and firmware variants. |
| Performance/reliability | Memory growth, battery use, UI responsiveness, repeated connect/disconnect cycles, hour-long streaming/recording, and stress with many sensors. |
| Physical correctness | Known-motion sensor calibration, sensor bias/noise, optical/temperature reference comparison, audio quality, microphone gain response, LED color/brightness, and seal/heart algorithm accuracy. These require controlled fixtures or reference instruments in addition to Patrol. |

Patrol can automate the app and Android system UI for most rows. Physical
correctness needs external equipment or a controlled fixture, and firmware
unit/integration tests should cover low-level protocol behavior that cannot be
observed reliably through a phone UI alone.
