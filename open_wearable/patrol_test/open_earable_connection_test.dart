import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_driver.dart';

const String _targetDeviceId = String.fromEnvironment(
  'OPENEARABLE_DEVICE_ID',
);

void main() {
  patrolTest(
    'CON-01 CON-07 DEV-01(partial): connect and inspect a selected OpenEarable',
    ($) async {
      expect(
        _targetDeviceId,
        isNotEmpty,
        reason: 'Pass the exact Android Bluetooth device ID with '
            '--dart-define=OPENEARABLE_DEVICE_ID=<id>.',
      );

      await startProductionApp($);
      await grantFirstRunPermissions($);

      await $(UiTestKeys.navDevices).tap();
      await $(UiTestKeys.devicesConnect).tap();
      await startBleScan($);

      final discoveredDevice = $(UiTestKeys.scannedDevice(_targetDeviceId));
      await discoveredDevice.waitUntilVisible(
        timeout: const Duration(seconds: 45),
      );
      await discoveredDevice.tap();

      final connectedDevice = $(UiTestKeys.connectedDevice(_targetDeviceId));
      await connectedDevice.waitUntilVisible(
        timeout: const Duration(seconds: 45),
      );
      await connectedDevice.tap();

      await $(UiTestKeys.deviceDetails(_targetDeviceId)).waitUntilVisible();
      expect($('Device Information'), findsOneWidget);
      expect($('Battery'), findsOneWidget);

      await $(UiTestKeys.deviceDisconnect).scrollTo();
      await $(UiTestKeys.deviceDisconnect).tap();
      await startBleScan($);
      await discoveredDevice.waitUntilVisible(
        timeout: const Duration(seconds: 45),
      );

      // Reconnect and reopen details to verify that disconnect did not leave
      // stale app state, then disconnect again so the fixture is reusable.
      await discoveredDevice.tap();
      await connectedDevice.waitUntilVisible(
        timeout: const Duration(seconds: 45),
      );
      await connectedDevice.tap();
      await $(UiTestKeys.deviceDetails(_targetDeviceId)).waitUntilVisible();
      await $(UiTestKeys.deviceDisconnect).scrollTo();
      await $(UiTestKeys.deviceDisconnect).tap();
      await startBleScan($);
      await discoveredDevice.waitUntilVisible(
        timeout: const Duration(seconds: 45),
      );
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
