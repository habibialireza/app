import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_driver.dart';

void main() {
  patrolTest(
    'NAV-07: Overview shortcuts open the correct empty-state destinations',
    ($) async {
      await startProductionApp($);
      await skipFirstRunPermissions($);

      expect($('No devices connected'), findsOneWidget);
      expect($('DISCONNECTED'), findsOneWidget);

      await _tapOverviewShortcut($, UiTestKeys.overviewConnectDevices);
      await $(UiTestKeys.scanEnableBluetooth).waitUntilVisible();
      expect($('Connect Devices'), findsOneWidget);
      await $.tester.pageBack();
      await $(UiTestKeys.navOverview).waitUntilVisible();

      await _tapOverviewShortcut($, UiTestKeys.overviewConfigureSensors);
      await $(UiTestKeys.sensorConfigureScan).waitUntilVisible();
      expect(find.text('No devices connected').hitTestable(), findsOneWidget);
      expect(find.text('Scan for devices').hitTestable(), findsOneWidget);

      await $(UiTestKeys.navOverview).tap();
      await _tapOverviewShortcut($, UiTestKeys.overviewViewSensorData);
      await $(UiTestKeys.sensorLiveDataScan).waitUntilVisible();
      expect(find.text('No devices connected').hitTestable(), findsOneWidget);
      expect(find.text('Scan for devices').hitTestable(), findsOneWidget);

      await $(UiTestKeys.navOverview).tap();
      await _tapOverviewShortcut($, UiTestKeys.overviewRecord);
      await $('Local Recorder').waitUntilVisible();
      expect($('Local Recorder'), findsOneWidget);
      expect($('No sensors connected'), findsOneWidget);

      final startRecording = find.widgetWithText(
        FilledButton,
        'Start Recording',
      );
      expect(startRecording, findsOneWidget);
      expect($.tester.widget<FilledButton>(startRecording).onPressed, isNull);

      await $(UiTestKeys.navOverview).tap();
      await $(UiTestKeys.navOverview).waitUntilVisible();
    },
  );
}

Future<void> _tapOverviewShortcut(
  PatrolIntegrationTester $,
  ValueKey<String> key,
) async {
  await $(key).scrollTo();
  await $(key).tap();
}
