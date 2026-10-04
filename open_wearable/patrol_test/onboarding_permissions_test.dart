import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_driver.dart';

void main() {
  patrolTest(
    'NAV-01: grant Bluetooth, location, and microphone during onboarding',
    ($) async {
      await startProductionApp($);

      await $(UiTestKeys.onboardingGetStarted).waitUntilVisible(
        timeout: const Duration(seconds: 30),
      );
      expect($('Welcome to OpenWearables'), findsOneWidget);

      await grantFirstRunPermissions($);
      expect($(UiTestKeys.navOverview), findsOneWidget);

      await $(UiTestKeys.navDevices).tap();
      await $(UiTestKeys.devicesConnect).waitUntilVisible();
      await $(UiTestKeys.devicesConnect).tap();
      await $(UiTestKeys.scanStart).waitUntilVisible();
      await _waitForPermissionCardsToDisappear($);

      expect($(UiTestKeys.scanEnableBluetooth), findsNothing);
      expect($(UiTestKeys.scanEnableMicrophone), findsNothing);
    },
  );
}

Future<void> _waitForPermissionCardsToDisappear(
  PatrolIntegrationTester $,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    await $.pump(const Duration(milliseconds: 100));
    final bluetoothVisible =
        find.byKey(UiTestKeys.scanEnableBluetooth).evaluate().isNotEmpty;
    final microphoneVisible =
        find.byKey(UiTestKeys.scanEnableMicrophone).evaluate().isNotEmpty;
    if (!bluetoothVisible && !microphoneVisible) {
      return;
    }
  }

  throw TestFailure(
    'The connection screen still requested a permission after onboarding.',
  );
}
