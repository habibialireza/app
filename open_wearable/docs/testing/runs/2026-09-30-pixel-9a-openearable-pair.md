# OpenEarable stereo pair — Pixel 9a, Android 17

## Environment

| Field | Value |
| --- | --- |
| Date | 2026-09-30 (Europe/Berlin) |
| Phone | Google Pixel 9a (`tegu`) |
| Android | 17, API 37 |
| Test app | `edu.kit.teco.openWearable.patrol` (`OpenWearables Test`) |
| Journey | `patrol_test/open_earable_pair_test.dart` |
| Earables | Two `OpenEarable-2B01` devices, one left and one right |
| Firmware observed | `2.2.7-dev.12+g23ff47e.dirty` on both sides |

## Result

The final run passed with one successful journey, zero failures, and zero
skips. Patrol logged 45 actions in the 45-second Dart journey; the complete
build, installation, and device phase took 90.9 seconds.

The devices used private BLE addresses that changed after power cycling. The
successful run discovered `6E:02:38:B2:F9:67` and `79:BC:C9:DC:E0:ED` at
runtime. These are run-local identifiers, not stable fixture identities.

Patrol granted the Android permissions, opened Connect Devices, enabled the
OpenEarable-only filter, and required exactly two matching advertisers before
selecting anything. It connected both exact runtime rows and verified that the
main Devices screen produced one combined pair containing both `L` and `R`
status labels. It switched **Combine stereo pair** off and verified two
side-specific device rows, switched it on and verified the combined card
returned, then used guaranteed cleanup to split the pair and disconnect both
runtime IDs through their device-detail controls.

Several development runs established two fixture constraints. Android BLE
addresses rotate after a power cycle, so a saved address cannot select these
devices reliably. The tested devices also stopped advertising after an app
disconnect and needed to be woken or power-cycled before the next fresh run.
The final journey handles address rotation and scan retries; waking hardware
remains a physical fixture step.

This verifies app-visible discovery, two real GATT connections, stereo side
metadata, pair grouping, split/recombine behavior, and cleanup. It does not
verify physical audio output, sensor accuracy, partial-pair loss, or every
pair-specific control.
