import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_wearable/models/wearable_display_group.dart';
import 'package:patrol/patrol.dart';

import 'app_driver.dart';

/// The two runtime Bluetooth IDs discovered for a stereo OpenEarable pair.
class ConnectedOpenEarablePair {
  const ConnectedOpenEarablePair({
    required this.deviceIds,
    required this.pairKey,
  });

  final List<String> deviceIds;
  final String pairKey;
}

/// Discovers exactly two filtered OpenEarables and connects both of them.
///
/// Bluetooth IDs are intentionally discovered at runtime because Android can
/// expose rotating addresses for these devices.
Future<ConnectedOpenEarablePair> connectExactlyTwoOpenEarables(
  PatrolIntegrationTester $,
) async {
  await $(UiTestKeys.navDevices).tap();
  await $(UiTestKeys.devicesConnect).waitUntilVisible();
  await $(UiTestKeys.devicesConnect).tap();
  await $(UiTestKeys.scanOpenEarableFilter).waitUntilVisible();
  await $(UiTestKeys.scanOpenEarableFilter).tap();

  final deviceIds = await _discoverExactlyTwoOpenEarables($);
  for (final deviceId in deviceIds) {
    debugPrint('PAIR_RUNTIME_DEVICE id="$deviceId"');
    await _connectExactDevice($, deviceId);
  }

  final pairKey = WearableDisplayGroup.stereoPairKeyForIds(
    deviceIds[0],
    deviceIds[1],
  );
  await openMainDevicesPage($);
  await $(UiTestKeys.combinedPair(pairKey)).waitUntilVisible(
    timeout: const Duration(seconds: 45),
  );

  return ConnectedOpenEarablePair(
    deviceIds: List.unmodifiable(deviceIds),
    pairKey: pairKey,
  );
}

Future<void> openMainDevicesPage(PatrolIntegrationTester $) async {
  if ($(UiTestKeys.devicesConnect).visible) {
    return;
  }
  await $.platform.android.pressBack();
  await $(UiTestKeys.devicesConnect).waitUntilVisible(
    timeout: const Duration(seconds: 20),
  );
}

/// Splits a combined pair if necessary and disconnects both exact devices.
Future<void> cleanupConnectedPair(
  PatrolIntegrationTester $,
  ConnectedOpenEarablePair pair,
) async {
  await $(UiTestKeys.navDevices).tap();
  await openMainDevicesPage($);

  final combinedPair = $(UiTestKeys.combinedPair(pair.pairKey));
  if (combinedPair.visible) {
    await $(UiTestKeys.combinedPairToggle(pair.pairKey)).tap();
    await $(UiTestKeys.connectedDevice(pair.deviceIds.first)).waitUntilVisible(
      timeout: const Duration(seconds: 20),
    );
  }

  for (final deviceId in pair.deviceIds) {
    if ($(UiTestKeys.connectedDevice(deviceId)).visible) {
      await _disconnectExactDevice($, deviceId);
    }
  }
}

String sideForDevice(PatrolIntegrationTester $, String deviceId) {
  final rowKey = UiTestKeys.connectedDevice(deviceId);
  final hasLeft = $.tester.any(descendantText(rowKey, 'L'));
  final hasRight = $.tester.any(descendantText(rowKey, 'R'));
  expect(hasLeft || hasRight, isTrue, reason: '$deviceId has no side label.');
  expect(
    hasLeft && hasRight,
    isFalse,
    reason: '$deviceId has both side labels.',
  );
  return hasLeft ? 'L' : 'R';
}

Finder descendantText(Key parentKey, String text) => find.descendant(
      of: find.byKey(parentKey),
      matching: find.text(text),
    );

Future<List<String>> _discoverExactlyTwoOpenEarables(
  PatrolIntegrationTester $,
) async {
  for (var attempt = 1; attempt <= 3; attempt++) {
    await startBleScan($);
    await $.pump(const Duration(seconds: 9));

    final ids = _visibleFilteredDeviceIds();
    if (ids.length == 2) {
      return ids;
    }
    if (ids.length > 2) {
      throw TestFailure(
        'Expected exactly two filtered OpenEarables, but found ${ids.length}: '
        '${ids.join(', ')}. Refusing to choose a device ambiguously.',
      );
    }
  }

  throw TestFailure(
    'Expected exactly two advertising OpenEarables after three scans.',
  );
}

List<String> _visibleFilteredDeviceIds() {
  final rows = find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('ui.scan.device.');
  });

  return rows
      .evaluate()
      .map((element) => element.widget.key)
      .whereType<ValueKey<String>>()
      .map((key) => key.value.substring('ui.scan.device.'.length))
      .toSet()
      .toList(growable: false);
}

Future<void> _connectExactDevice(
  PatrolIntegrationTester $,
  String deviceId,
) async {
  final discovered = $(UiTestKeys.scannedDevice(deviceId));
  if (discovered.visible) {
    await _tapDiscoveredAndWaitForConnection($, discovered, deviceId);
    return;
  }

  for (var attempt = 1; attempt <= 3; attempt++) {
    await startBleScan($);
    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (DateTime.now().isBefore(deadline)) {
      if (discovered.visible) {
        await _tapDiscoveredAndWaitForConnection($, discovered, deviceId);
        return;
      }
      await $.pump(const Duration(milliseconds: 250));
    }
  }

  throw TestFailure(
    'OpenEarable $deviceId was not discovered in three BLE scans.',
  );
}

Future<void> _tapDiscoveredAndWaitForConnection(
  PatrolIntegrationTester $,
  PatrolFinder discovered,
  String deviceId,
) async {
  await discovered.tap();
  await $(UiTestKeys.connectedDevice(deviceId)).waitUntilVisible(
    timeout: const Duration(seconds: 60),
  );
}

Future<void> _disconnectExactDevice(
  PatrolIntegrationTester $,
  String deviceId,
) async {
  await $(UiTestKeys.connectedDevice(deviceId)).tap();
  await $(UiTestKeys.deviceDetails(deviceId)).waitUntilVisible();
  await $(UiTestKeys.deviceDisconnect).scrollTo();
  await $(UiTestKeys.deviceDisconnect).tap();
  await _waitUntilAbsent($, UiTestKeys.connectedDevice(deviceId));
}

Future<void> _waitUntilAbsent(
  PatrolIntegrationTester $,
  Key key,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    if (!$.tester.any(find.byKey(key))) {
      return;
    }
    await $.pump(const Duration(milliseconds: 250));
  }
  throw TestFailure('Widget with key $key did not disappear after disconnect.');
}
