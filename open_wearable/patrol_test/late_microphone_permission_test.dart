import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_driver.dart';

void main() {
  patrolTest(
    'NAV-03: skip microphone onboarding and grant it from Connect Devices',
    ($) async {
      await startProductionApp($);
      await grantBluetoothAndSkipMicrophone($);

      await $(UiTestKeys.navDevices).tap();
      await $(UiTestKeys.devicesConnect).waitUntilVisible();
      await $(UiTestKeys.devicesConnect).tap();

      await $(UiTestKeys.scanEnableMicrophone).waitUntilVisible(
        timeout: const Duration(seconds: 10),
      );
      expect($(UiTestKeys.scanEnableBluetooth), findsNothing);

      await $(UiTestKeys.scanEnableMicrophone).tap();
      await grantVisibleAndroidPermissionDialogs($);
      await _waitForMicrophoneCardToDisappear($);

      expect($(UiTestKeys.scanEnableMicrophone), findsNothing);
      expect($(UiTestKeys.scanEnableBluetooth), findsNothing);
      expect($(UiTestKeys.scanStart), findsOneWidget);
    },
  );
}

Future<void> _waitForMicrophoneCardToDisappear(
  PatrolIntegrationTester $,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    await $.pump(const Duration(milliseconds: 100));
    if (find.byKey(UiTestKeys.scanEnableMicrophone).evaluate().isEmpty) {
      return;
    }
  }

  throw TestFailure(
    'The microphone recovery card remained after permission was granted.',
  );
}
