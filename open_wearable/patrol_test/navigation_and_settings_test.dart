import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_driver.dart';

void main() {
  patrolTest(
    'NAV-02 NAV-06(partial) SET-01(partial): onboarding, navigation, and a setting control',
    ($) async {
      await startProductionApp($);

      await $(UiTestKeys.onboardingGetStarted).waitUntilVisible(
        timeout: const Duration(seconds: 30),
      );
      expect($('Welcome to OpenWearables'), findsOneWidget);
      await skipFirstRunPermissions($);

      await $(UiTestKeys.navDevices).tap();
      await $(UiTestKeys.devicesConnect).waitUntilVisible();
      await $(UiTestKeys.devicesConnect).tap();
      await $(UiTestKeys.scanEnableBluetooth).waitUntilVisible();
      expect($('Enable Bluetooth & Location'), findsOneWidget);
      expect(
        $('Allow Bluetooth and Location so the app can find and connect to '
            'your wearable.'),
        findsOneWidget,
      );
      await $.tester.pageBack();
      await $(UiTestKeys.navSensors).waitUntilVisible();

      await $(UiTestKeys.navSensors).tap();
      await $(UiTestKeys.sensorConfiguration).waitUntilVisible();

      await $(UiTestKeys.navApps).tap();
      await $('Posture Tracker').waitUntilVisible();

      await $(UiTestKeys.navSettings).tap();
      await $(UiTestKeys.settingsGeneral).waitUntilVisible();
      await $(UiTestKeys.settingsGeneral).tap();
      expect($('General settings'), findsOneWidget);

      final switchFinder = find.byKey(UiTestKeys.settingsKeepScreenAwake);
      final originalValue = $.tester.widget<SwitchListTile>(switchFinder).value;

      await $(UiTestKeys.settingsKeepScreenAwake).tap();
      await $.pump(const Duration(milliseconds: 250));
      expect(
        $.tester.widget<SwitchListTile>(switchFinder).value,
        isNot(originalValue),
      );

      // Restore the user's original setting so this journey is repeatable.
      await $(UiTestKeys.settingsKeepScreenAwake).tap();
      await $.pump(const Duration(milliseconds: 250));
      expect(
        $.tester.widget<SwitchListTile>(switchFinder).value,
        originalValue,
      );
    },
  );
}
