import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_driver.dart';

void main() {
  patrolTest(
    'CON-13: connect, inspect, and disconnect the phone as a sensor device',
    ($) async {
      await startProductionApp($);
      await grantFirstRunPermissions($);

      await connectThisDevice($);
      expect(
        find.textContaining('(this device)').hitTestable(),
        findsNothing,
      );
      expect($(UiTestKeys.scanThisDevice), findsNothing);

      await $.tester.pageBack();
      await $(UiTestKeys.connectedThisDevice).waitUntilVisible();

      await $(UiTestKeys.navOverview).tap();
      await $('Connected Devices (1)').waitUntilVisible();
      expect($('No devices connected.'), findsNothing);

      await $(UiTestKeys.navDevices).tap();
      await $(UiTestKeys.connectedThisDevice).tap();
      await $(UiTestKeys.deviceDisconnect).waitUntilVisible();
      await $(UiTestKeys.deviceDisconnect).scrollTo();
      await $(UiTestKeys.deviceDisconnect).tap();

      await $(UiTestKeys.devicesConnect).waitUntilVisible(
        timeout: const Duration(seconds: 10),
      );
      expect($(UiTestKeys.connectedThisDevice), findsNothing);
    },
    // This journey asserts the Flutter widget tree directly. The production
    // phone-device flow can leave Patrol's semantics handle active on Android.
    semanticsEnabled: false,
  );
}
