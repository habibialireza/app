import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_driver.dart';

void main() {
  patrolTest(
    'CFG-02 CFG-03 LIVE-01 REC-02 REC-08(partial): phone sensor data loop',
    ($) async {
      await startProductionApp($);
      await grantFirstRunPermissions($);
      await connectThisDevice($);

      await $.tester.pageBack();
      await $(UiTestKeys.navSensors).tap();
      await $(UiTestKeys.sensorConfigAccelerometer).waitUntilVisible(
        timeout: const Duration(seconds: 15),
      );
      await $(UiTestKeys.sensorConfigAccelerometer).tap();

      await $(UiTestKeys.sensorRateAccelerometer).waitUntilVisible();
      await $(UiTestKeys.sensorRateAccelerometer).tap();
      await $('5.00 Hz').waitUntilVisible();
      await $('5.00 Hz').tap();
      await $(UiTestKeys.sensorConfigClose).tap();

      await $(UiTestKeys.sensorApply).scrollTo();
      await $(UiTestKeys.sensorApply).tap();
      await $('Accelerometer').waitUntilVisible(
        timeout: const Duration(seconds: 10),
      );
      expect($('Waiting for live sensor data'), findsNothing);

      await $(const ValueKey<String>('ui.sensors.recording')).tap();
      await $(UiTestKeys.recorderStartStop).waitUntilVisible();
      final recorderButton = find.byKey(UiTestKeys.recorderStartStop);
      expect(
        $.tester.widget<FilledButton>(recorderButton).onPressed,
        isNotNull,
      );

      await $(UiTestKeys.recorderStartStop).tap();
      await $('Recording in progress').waitUntilVisible();
      await $.pump(const Duration(seconds: 2));
      await $(UiTestKeys.recorderStartStop).tap();
      await $('Ready to record').waitUntilVisible(
        timeout: const Duration(seconds: 10),
      );

      await $(UiTestKeys.recorderLatestFolder).scrollTo();
      await $(UiTestKeys.recorderLatestFolder).tap();
      await _waitForCsvFile($);
      _expectRecordedCsvHasContent($);

      await $(UiTestKeys.recorderDeleteLatest).tap();
      await $(UiTestKeys.recorderConfirmDelete).waitUntilVisible();
      await $(UiTestKeys.recorderConfirmDelete).tap();
      await $('No recordings yet').waitUntilVisible();

      await $(UiTestKeys.navDevices).tap();
      await $(UiTestKeys.connectedThisDevice).tap();
      await $(UiTestKeys.deviceDisconnect).scrollTo();
      await $(UiTestKeys.deviceDisconnect).tap();
      await $(UiTestKeys.devicesConnect).waitUntilVisible();
    },
    // This journey asserts Flutter widgets directly; it does not need Android
    // semantics, which can remain active after the phone-device flow.
    semanticsEnabled: false,
  );
}

void _expectRecordedCsvHasContent(PatrolIntegrationTester $) {
  final nonEmptyFileSize = find
      .byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            RegExp(
              r'^(?:[1-9][0-9]* B|[0-9]+\.[0-9]+ (?:KB|MB))$',
            ).hasMatch(widget.data!),
      )
      .hitTestable();
  expect(nonEmptyFileSize, findsAtLeastNWidgets(1));
  expect(find.text('0 B').hitTestable(), findsNothing);
}

Future<void> _waitForCsvFile(PatrolIntegrationTester $) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    await $.pump(const Duration(milliseconds: 100));
    if (find.textContaining('.csv').hitTestable().evaluate().isNotEmpty) {
      return;
    }
  }
  throw TestFailure('The completed recording did not expose a CSV file.');
}
