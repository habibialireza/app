import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_driver.dart';

const _settingKeys = <ValueKey<String>>[
  UiTestKeys.settingsAutoConnect,
  UiTestKeys.settingsKeepScreenAwake,
  UiTestKeys.settingsDisableSensorsOnClose,
  UiTestKeys.settingsDisableLiveGraphs,
  UiTestKeys.settingsHideEmptyGraphs,
];

void main() {
  patrolTest(
    'SET-01: every General setting changes, persists after reopening, and is restored',
    ($) async {
      await startProductionApp($);
      await skipFirstRunPermissions($);
      await _openGeneralSettings($);

      final originalValues = <ValueKey<String>, bool>{};
      for (final key in _settingKeys) {
        await $(key).scrollTo();
        final originalValue = _switchValue($, key);
        originalValues[key] = originalValue;

        await $(key).tap();
        await _waitForSwitchValue($, key, !originalValue);
      }

      await $.tester.pageBack();
      await $(UiTestKeys.settingsGeneral).waitUntilVisible();
      await $(UiTestKeys.settingsGeneral).tap();

      for (final key in _settingKeys) {
        await $(key).scrollTo();
        expect(_switchValue($, key), !originalValues[key]!);
      }

      // Restore every preference so repeated runs and manual use start cleanly.
      for (final key in _settingKeys.reversed) {
        await $(key).scrollTo();
        await $(key).tap();
        await _waitForSwitchValue($, key, originalValues[key]!);
      }

      await $.tester.pageBack();
      await $(UiTestKeys.settingsGeneral).waitUntilVisible();
      await $(UiTestKeys.settingsGeneral).tap();

      for (final key in _settingKeys) {
        await $(key).scrollTo();
        expect(_switchValue($, key), originalValues[key]);
      }

      // Leave the lazily scrolled settings route before Patrol tears down the
      // live test binding. This also proves Back remains usable after edits.
      await $.tester.pageBack();
      await $(UiTestKeys.settingsGeneral).waitUntilVisible();
    },
    // This journey reads Flutter widget values directly; platform semantics
    // are unnecessary and can leak a handle in live Android tests.
    semanticsEnabled: false,
  );
}

Future<void> _openGeneralSettings(PatrolIntegrationTester $) async {
  await $(UiTestKeys.navSettings).tap();
  await $(UiTestKeys.settingsGeneral).waitUntilVisible();
  await $(UiTestKeys.settingsGeneral).tap();
  await $('General settings').waitUntilVisible();
}

bool _switchValue(
  PatrolIntegrationTester $,
  ValueKey<String> key,
) {
  return $.tester.widget<SwitchListTile>(find.byKey(key)).value;
}

Future<void> _waitForSwitchValue(
  PatrolIntegrationTester $,
  ValueKey<String> key,
  bool expected,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    await $.pump(const Duration(milliseconds: 100));
    if (_switchValue($, key) == expected) {
      return;
    }
  }

  throw TestFailure(
    'Setting ${key.value} did not change to $expected within 5 seconds.',
  );
}
