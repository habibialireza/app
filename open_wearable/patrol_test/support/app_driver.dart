import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_wearable/main.dart' as app;
import 'package:patrol/patrol.dart';

/// Stable UI identifiers shared by the initial Patrol journeys.
abstract final class UiTestKeys {
  static const onboardingGetStarted = ValueKey<String>(
    'ui.onboarding.getStarted',
  );
  static const onboardingBluetooth = ValueKey<String>(
    'ui.onboarding.bluetooth',
  );
  static const onboardingSkipBluetooth = ValueKey<String>(
    'ui.onboarding.skipBluetooth',
  );
  static const onboardingMicrophone = ValueKey<String>(
    'ui.onboarding.microphone',
  );
  static const onboardingSkipMicrophone = ValueKey<String>(
    'ui.onboarding.skipMicrophone',
  );
  static const upgradeClose = ValueKey<String>('ui.upgrade.close');
  static const permissionRequiredCancel = ValueKey<String>(
    'ui.permissions.required.cancel',
  );

  static const navOverview = ValueKey<String>('ui.nav.overview');
  static const navDevices = ValueKey<String>('ui.nav.devices');
  static const navSensors = ValueKey<String>('ui.nav.sensors');
  static const navApps = ValueKey<String>('ui.nav.apps');
  static const navSettings = ValueKey<String>('ui.nav.settings');

  static const overviewConnectDevices = ValueKey<String>(
    'ui.overview.connectDevices',
  );
  static const overviewConfigureSensors = ValueKey<String>(
    'ui.overview.configureSensors',
  );
  static const overviewViewSensorData = ValueKey<String>(
    'ui.overview.viewSensorData',
  );
  static const overviewRecord = ValueKey<String>('ui.overview.record');

  static const devicesConnect = ValueKey<String>('ui.devices.connect');
  static const scanStart = ValueKey<String>('ui.scan.start');
  static const scanAgain = ValueKey<String>('ui.scan.again');
  static const scanOpenEarableFilter = ValueKey<String>(
    'ui.scan.openEarableFilter',
  );
  static const scanEnableBluetooth = ValueKey<String>(
    'ui.scan.enableBluetooth',
  );
  static const scanEnableMicrophone = ValueKey<String>(
    'ui.scan.enableMicrophone',
  );
  static const scanThisDevice = ValueKey<String>('ui.scan.thisDevice');
  static const connectedThisDevice = ValueKey<String>(
    'ui.devices.thisDevice',
  );
  static const sensorConfiguration = ValueKey<String>(
    'ui.sensors.configuration',
  );
  static const sensorConfigureEmpty = ValueKey<String>(
    'ui.sensors.configure.empty',
  );
  static const sensorConfigureScan = ValueKey<String>(
    'ui.sensors.configure.scan',
  );
  static const sensorLiveDataEmpty = ValueKey<String>(
    'ui.sensors.liveData.empty',
  );
  static const sensorLiveDataScan = ValueKey<String>(
    'ui.sensors.liveData.scan',
  );
  static const sensorRecorderContent = ValueKey<String>(
    'ui.sensors.recorder.content',
  );
  static const sensorRecording = ValueKey<String>('ui.sensors.recording');
  static const sensorConfigAccelerometer = ValueKey<String>(
    'ui.sensor.config.Accelerometer',
  );
  static const sensorRateAccelerometer = ValueKey<String>(
    'ui.sensor.rate.Accelerometer',
  );
  static const sensorConfigClose = ValueKey<String>(
    'ui.sensor.config.close',
  );
  static const sensorApply = ValueKey<String>('ui.sensor.apply');
  static const recorderStartStop = ValueKey<String>(
    'ui.recorder.startStop',
  );
  static const recorderLatestFolder = ValueKey<String>(
    'ui.recorder.latestFolder',
  );
  static const recorderDeleteLatest = ValueKey<String>(
    'ui.recorder.deleteLatest',
  );
  static const recorderConfirmDelete = ValueKey<String>(
    'ui.recorder.confirmDelete',
  );
  static const settingsGeneral = ValueKey<String>('ui.settings.general');
  static const settingsKeepScreenAwake = ValueKey<String>(
    'ui.settings.keepScreenAwake',
  );
  static const settingsAutoConnect = ValueKey<String>(
    'ui.settings.autoConnect',
  );
  static const settingsDisableSensorsOnClose = ValueKey<String>(
    'ui.settings.disableSensorsOnClose',
  );
  static const settingsDisableLiveGraphs = ValueKey<String>(
    'ui.settings.disableLiveGraphs',
  );
  static const settingsHideEmptyGraphs = ValueKey<String>(
    'ui.settings.hideEmptyGraphs',
  );

  static ValueKey<String> scannedDevice(String deviceId) =>
      ValueKey<String>('ui.scan.device.$deviceId');
  static ValueKey<String> connectedDevice(String deviceId) =>
      ValueKey<String>('ui.devices.device.$deviceId');
  static ValueKey<String> deviceDetails(String deviceId) =>
      ValueKey<String>('ui.device.details.$deviceId');
  static ValueKey<String> sensorConfig(String configurationName) =>
      ValueKey<String>('ui.sensor.config.$configurationName');
  static ValueKey<String> sensorRate(String configurationName) =>
      ValueKey<String>('ui.sensor.rate.$configurationName');
  static ValueKey<String> sensorStreamTarget(String configurationName) =>
      ValueKey<String>('ui.sensor.target.$configurationName.stream');
  static ValueKey<String> sensorRecordTarget(String configurationName) =>
      ValueKey<String>('ui.sensor.target.$configurationName.record');
  static ValueKey<String> recordedFile(String fileName) =>
      ValueKey<String>('ui.recorder.file.$fileName');
  static ValueKey<String> combinedPair(String pairKey) =>
      ValueKey<String>('ui.devices.pair.$pairKey');
  static ValueKey<String> combinedPairToggle(String pairKey) =>
      ValueKey<String>('ui.devices.pair.combine.$pairKey');
  static ValueKey<String> splitPairToggle(String pairKey, String deviceId) =>
      ValueKey<String>('ui.devices.pair.combine.$pairKey.$deviceId');
  static const deviceDisconnect = ValueKey<String>('ui.device.disconnect');
}

/// Mounts the same root widget and production services used by [app.main].
Future<void> startProductionApp(PatrolIntegrationTester $) async {
  await $.pumpWidget(await app.createApp());
}

/// Completes first-run onboarding through its visible skip action.
Future<void> skipFirstRunPermissions(PatrolIntegrationTester $) async {
  await $(UiTestKeys.onboardingGetStarted).waitUntilVisible(
    timeout: const Duration(seconds: 30),
  );
  await $(UiTestKeys.onboardingGetStarted).tap();
  await $(UiTestKeys.onboardingSkipBluetooth).tap();
  await _closeUpgradeHighlightIfShown($);
  await waitForHome($);
}

/// Grants Android permission dialogs as a user would during first-run setup.
Future<void> grantFirstRunPermissions(PatrolIntegrationTester $) async {
  await $.platform.mobile.enableBluetooth();
  await $.platform.android.enableLocation();

  await $(UiTestKeys.onboardingGetStarted).waitUntilVisible(
    timeout: const Duration(seconds: 30),
  );
  await $(UiTestKeys.onboardingGetStarted).tap();
  await $(UiTestKeys.onboardingBluetooth).tap();
  await grantVisibleAndroidPermissionDialogs($);

  await $(UiTestKeys.onboardingMicrophone).waitUntilVisible(
    timeout: const Duration(seconds: 20),
  );
  await $(UiTestKeys.onboardingMicrophone).tap();
  await grantVisibleAndroidPermissionDialogs($);

  await _closeUpgradeHighlightIfShown($);
  await waitForHome($);
}

/// Grants Bluetooth/location during onboarding but deliberately skips audio.
Future<void> grantBluetoothAndSkipMicrophone(
  PatrolIntegrationTester $,
) async {
  await $.platform.mobile.enableBluetooth();
  await $.platform.android.enableLocation();

  await $(UiTestKeys.onboardingGetStarted).waitUntilVisible(
    timeout: const Duration(seconds: 30),
  );
  await $(UiTestKeys.onboardingGetStarted).tap();
  await $(UiTestKeys.onboardingBluetooth).tap();
  await grantVisibleAndroidPermissionDialogs($);

  await $(UiTestKeys.onboardingSkipMicrophone).waitUntilVisible(
    timeout: const Duration(seconds: 20),
  );
  await $(UiTestKeys.onboardingSkipMicrophone).tap();

  await _closeUpgradeHighlightIfShown($);
  await waitForHome($);
}

Future<void> waitForHome(PatrolIntegrationTester $) async {
  await $(UiTestKeys.navOverview).waitUntilVisible(
    timeout: const Duration(seconds: 30),
  );
}

/// Starts a fresh BLE scan without waiting for the timed scan spinner to stop.
Future<void> startBleScan(PatrolIntegrationTester $) async {
  await $(UiTestKeys.scanStart).waitUntilVisible();
  await $(UiTestKeys.scanStart).tap(
    settlePolicy: SettlePolicy.noSettle,
  );
}

/// Connects the phone itself through the same visible discovery row a user taps.
Future<void> connectThisDevice(PatrolIntegrationTester $) async {
  await $(UiTestKeys.navDevices).tap();
  await $(UiTestKeys.devicesConnect).waitUntilVisible();
  await $(UiTestKeys.devicesConnect).tap();
  await $(UiTestKeys.scanThisDevice).waitUntilVisible(
    timeout: const Duration(seconds: 15),
  );
  await $(UiTestKeys.scanThisDevice).tap();
  await $(UiTestKeys.connectedThisDevice).waitUntilVisible(
    timeout: const Duration(seconds: 20),
  );
}

Future<void> _closeUpgradeHighlightIfShown(
  PatrolIntegrationTester $,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    await $.pump(const Duration(milliseconds: 100));

    if ($(UiTestKeys.permissionRequiredCancel).visible) {
      await $(UiTestKeys.permissionRequiredCancel).tap();
      continue;
    }
    if ($(UiTestKeys.upgradeClose).visible) {
      await $(UiTestKeys.upgradeClose).tap();
      continue;
    }
    if ($(UiTestKeys.navOverview).visible) {
      // Auto-connect performs its permission check asynchronously. Give that
      // check a moment to surface before treating the home screen as ready.
      await $.pump(const Duration(milliseconds: 500));
      if (!$(UiTestKeys.permissionRequiredCancel).visible &&
          !$(UiTestKeys.upgradeClose).visible) {
        return;
      }
    }
  }

  throw TestFailure(
    'The first-run overlays did not settle within 30 seconds.',
  );
}

Future<void> grantVisibleAndroidPermissionDialogs(
  PatrolIntegrationTester $,
) async {
  for (var index = 0; index < 4; index++) {
    final isVisible = await $.platform.android.isPermissionDialogVisible(
      timeout: const Duration(seconds: 2),
    );
    if (!isVisible) {
      return;
    }

    try {
      await $.platform.android.grantPermissionWhenInUse();
    } catch (_) {
      await $.platform.android.allowPermission();
    }
    await $.pump(const Duration(milliseconds: 250));
  }

  if (await $.platform.android.isPermissionDialogVisible()) {
    throw TestFailure(
      'Android permission dialogs did not finish after 4 grants.',
    );
  }
}
