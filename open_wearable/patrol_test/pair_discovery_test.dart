import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_driver.dart';

void main() {
  patrolTest(
    'PAIR-DISCOVERY: report two OpenEarable IDs without connecting',
    ($) async {
      await startProductionApp($);
      await grantFirstRunPermissions($);

      await $(UiTestKeys.navDevices).tap();
      await $(UiTestKeys.devicesConnect).waitUntilVisible();
      await $(UiTestKeys.devicesConnect).tap();
      await $(UiTestKeys.scanOpenEarableFilter).waitUntilVisible();
      await $(UiTestKeys.scanOpenEarableFilter).tap();
      await startBleScan($);

      // The app intentionally scans for eight seconds. Let that complete so
      // the result represents the full visible discovery window.
      await $.pump(const Duration(seconds: 9));
      // The bottom "Scan Again" button is lazily built only after scrolling.
      // The status at the top is visible throughout and changes when the
      // timed scan has completed.
      await $('Ready to scan').waitUntilVisible();

      final filteredDeviceRows = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('ui.scan.device.');
      });
      expect(
        filteredDeviceRows,
        findsAtLeastNWidgets(2),
        reason: 'Two advertising OpenEarables must be visible before the '
            'left/right pair test can be built safely.',
      );
      expect($(UiTestKeys.connectedThisDevice), findsNothing);
    },
  );
}
