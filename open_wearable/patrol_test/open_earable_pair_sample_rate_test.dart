import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_wearable/widgets/sensors/local_recorder/local_recorder_models.dart';
import 'package:open_wearable/widgets/sensors/local_recorder/local_recorder_storage.dart';
import 'package:patrol/patrol.dart';

import 'support/app_driver.dart';
import 'support/open_earable_pair_driver.dart';

const _requestedRatesCsv = String.fromEnvironment(
  'OPENEARABLE_SAMPLE_RATES_HZ',
  defaultValue: '25',
);
const _recordingDurationSeconds = int.fromEnvironment(
  'OPENEARABLE_SAMPLE_DURATION_SECONDS',
  defaultValue: 12,
);
const _tolerancePercentText = String.fromEnvironment(
  'OPENEARABLE_SAMPLE_TOLERANCE_PERCENT',
  defaultValue: '15',
);
final _tolerancePercent = double.tryParse(_tolerancePercentText) ?? double.nan;

const _imuConfigurationName = '9-Axis IMU';
const _accelerometerSensorName = 'ACCELEROMETER';

void main() {
  patrolTest(
    'RATE-01: requested pair sample rates match received left and right samples',
    ($) async {
      final requestedRates = _parseRequestedRates();
      _validateTestParameters(requestedRates);

      await startProductionApp($);
      await grantFirstRunPermissions($);
      final pair = await connectExactlyTwoOpenEarables($);

      try {
        for (final requestedRate in requestedRates) {
          await _configurePairImuStreaming($, requestedRate);
          await _recordAndVerifyRate($, requestedRate);
        }
      } finally {
        await _stopRecordingIfNecessary($);
        await cleanupConnectedPair($, pair);
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

List<double> _parseRequestedRates() {
  return _requestedRatesCsv
      .split(',')
      .map((value) => double.tryParse(value.trim()))
      .whereType<double>()
      .toList(growable: false);
}

void _validateTestParameters(List<double> requestedRates) {
  if (requestedRates.isEmpty ||
      requestedRates.any((rate) => !rate.isFinite || rate <= 0)) {
    throw TestFailure(
      'OPENEARABLE_SAMPLE_RATES_HZ must contain positive comma-separated '
      'numbers. Received "$_requestedRatesCsv".',
    );
  }
  if (_recordingDurationSeconds < 5) {
    throw TestFailure(
      'OPENEARABLE_SAMPLE_DURATION_SECONDS must be at least 5 seconds.',
    );
  }
  if (!_tolerancePercent.isFinite ||
      _tolerancePercent <= 0 ||
      _tolerancePercent >= 100) {
    throw TestFailure(
      'OPENEARABLE_SAMPLE_TOLERANCE_PERCENT must be between 0 and 100.',
    );
  }
}

Future<void> _configurePairImuStreaming(
  PatrolIntegrationTester $,
  double requestedRate,
) async {
  await $(UiTestKeys.navSensors).tap();
  await $(UiTestKeys.sensorConfiguration).tap();

  final configuration = $(UiTestKeys.sensorConfig(_imuConfigurationName));
  await configuration.scrollTo();
  await configuration.waitUntilVisible(timeout: const Duration(seconds: 20));
  await configuration.tap();

  final streamTarget = UiTestKeys.sensorStreamTarget(_imuConfigurationName);
  await $(streamTarget).waitUntilVisible();
  final streamSwitch = $.tester.widget<Switch>(find.byKey(streamTarget));
  if (!streamSwitch.value) {
    await $(streamTarget).tap();
  }

  final rateDropdown = UiTestKeys.sensorRate(_imuConfigurationName);
  await $(rateDropdown).waitUntilVisible();
  await $(rateDropdown).tap();
  final rateLabel = '${requestedRate.toStringAsFixed(2)} Hz';
  if (!$(rateLabel).visible) {
    throw TestFailure(
      'The connected OpenEarable pair does not offer $rateLabel for '
      '$_imuConfigurationName streaming.',
    );
  }
  await $(rateLabel).tap();
  await $(UiTestKeys.sensorConfigClose).tap();

  await $(UiTestKeys.sensorApply).scrollTo();
  await $(UiTestKeys.sensorApply).tap();
  await $(_accelerometerSensorName).waitUntilVisible(
    timeout: const Duration(seconds: 20),
  );
}

Future<void> _recordAndVerifyRate(
  PatrolIntegrationTester $,
  double requestedRate,
) async {
  final foldersBefore = await listRecordingFolders();
  final existingPaths = foldersBefore.map((folder) => folder.path).toSet();

  await $(UiTestKeys.sensorRecording).tap();
  await $(UiTestKeys.recorderStartStop).waitUntilVisible();
  await $(UiTestKeys.recorderStartStop).tap();
  await $('Recording in progress').waitUntilVisible();
  await $.pump(Duration(seconds: _recordingDurationSeconds));
  await $(UiTestKeys.recorderStartStop).tap();
  await $('Ready to record').waitUntilVisible(
    timeout: const Duration(seconds: 15),
  );

  final folder = await _waitForCompletedRecording(
    $,
    existingPaths: existingPaths,
  );
  final measurements = await _readSideMeasurements(folder);
  _assertMeasurements(
    measurements: measurements,
    requestedRate: requestedRate,
  );

  await $(UiTestKeys.recorderLatestFolder).scrollTo();
  await $(UiTestKeys.recorderLatestFolder).tap();
  final leftFileKey = UiTestKeys.recordedFile(measurements['L']!.fileName);
  await $(leftFileKey).scrollTo();
  await $(leftFileKey).waitUntilVisible();
  expect(
    find.byKey(UiTestKeys.recordedFile(measurements['R']!.fileName)),
    findsOneWidget,
    reason: 'The expanded recording folder should list the right-side CSV.',
  );
  await $(UiTestKeys.recorderDeleteLatest).tap();
  await $(UiTestKeys.recorderConfirmDelete).waitUntilVisible();
  await $(UiTestKeys.recorderConfirmDelete).tap();
  await _waitUntilFolderIsDeleted($, folder.path);
}

Future<LocalRecorderRecordingFolder> _waitForCompletedRecording(
  PatrolIntegrationTester $, {
  required Set<String> existingPaths,
}) async {
  LocalRecorderRecordingFolder? lastCandidate;
  Map<String, int>? previousSizes;
  var stableReads = 0;
  final deadline = DateTime.now().add(const Duration(seconds: 20));

  while (DateTime.now().isBefore(deadline)) {
    final folders = await listRecordingFolders();
    final candidates = folders
        .where((folder) => !existingPaths.contains(folder.path))
        .toList(growable: false);
    if (candidates.isNotEmpty) {
      lastCandidate = candidates.first;
      final sizes = <String, int>{
        for (final file in lastCandidate.files) file.path: file.sizeBytes,
      };
      final hasNonEmptyAccelerometers = lastCandidate.files
              .where(_isAccelerometerCsv)
              .where((file) => file.sizeBytes > 30)
              .length >=
          2;
      if (hasNonEmptyAccelerometers && _mapsEqual(sizes, previousSizes)) {
        stableReads++;
        if (stableReads >= 2) {
          return lastCandidate;
        }
      } else {
        stableReads = 0;
      }
      previousSizes = sizes;
    }
    await $.pump(const Duration(milliseconds: 250));
  }

  throw TestFailure(
    'The recording did not finish two non-empty accelerometer CSV files. '
    'Latest folder: ${lastCandidate?.path ?? 'none'}.',
  );
}

Future<Map<String, _RateMeasurement>> _readSideMeasurements(
  LocalRecorderRecordingFolder folder,
) async {
  final result = <String, _RateMeasurement>{};
  for (final file in folder.files.where(_isAccelerometerCsv)) {
    final content = await readRecordingFileText(file);
    final lines = const LineSplitter()
        .convert(content)
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (lines.length <= 2) {
      continue;
    }

    final side = _sideFromFilename(file.name);
    if (side == null) {
      continue;
    }
    if (result.containsKey(side)) {
      throw TestFailure(
        'More than one non-empty $_accelerometerSensorName CSV was found for '
        'side $side in ${folder.name}.',
      );
    }

    final timestamps = <int>[];
    for (final line in lines.skip(1)) {
      final firstColumn = line.split(',').first.trim();
      final timestamp = int.tryParse(firstColumn);
      if (timestamp == null) {
        throw TestFailure(
          'Invalid timestamp "$firstColumn" in ${file.name}.',
        );
      }
      timestamps.add(timestamp);
    }
    result[side] = _RateMeasurement.fromTimestamps(
      fileName: file.name,
      timestamps: timestamps,
    );
  }
  return result;
}

void _assertMeasurements({
  required Map<String, _RateMeasurement> measurements,
  required double requestedRate,
}) {
  expect(
    measurements.keys.toSet(),
    equals({'L', 'R'}),
    reason: 'A non-empty accelerometer CSV is required for both pair sides.',
  );

  final toleranceFraction = _tolerancePercent / 100;
  final minimum = requestedRate * (1 - toleranceFraction);
  final maximum = requestedRate * (1 + toleranceFraction);
  for (final entry in measurements.entries) {
    final measurement = entry.value;
    expect(
      measurement.sampleCount,
      greaterThanOrEqualTo(10),
      reason: '${measurement.fileName} has too few received samples.',
    );
    expect(
      measurement.durationSeconds,
      greaterThanOrEqualTo(_recordingDurationSeconds * 0.6),
      reason: '${measurement.fileName} covers too little recording time.',
    );
    expect(
      measurement.observedRateHz,
      inInclusiveRange(minimum, maximum),
      reason:
          'Side ${entry.key} received ${measurement.observedRateHz.toStringAsFixed(2)} '
          'Hz for a requested ${requestedRate.toStringAsFixed(2)} Hz '
          '(allowed ${minimum.toStringAsFixed(2)}-${maximum.toStringAsFixed(2)} Hz).',
    );
    debugPrint(
      'PAIR_SAMPLE_RATE side=${entry.key} '
      'requested_hz=${requestedRate.toStringAsFixed(2)} '
      'observed_hz=${measurement.observedRateHz.toStringAsFixed(2)} '
      'samples=${measurement.sampleCount} '
      'duration_s=${measurement.durationSeconds.toStringAsFixed(3)} '
      'file="${measurement.fileName}"',
    );
  }
}

bool _isAccelerometerCsv(LocalRecorderRecordingFile file) {
  final upper = file.name.toUpperCase();
  return upper.endsWith('.CSV') && upper.contains(_accelerometerSensorName);
}

String? _sideFromFilename(String name) {
  if (name.contains('-L-')) return 'L';
  if (name.contains('-R-')) return 'R';
  return null;
}

bool _mapsEqual(Map<String, int> current, Map<String, int>? previous) {
  if (previous == null || current.length != previous.length) {
    return false;
  }
  for (final entry in current.entries) {
    if (previous[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

Future<void> _waitUntilFolderIsDeleted(
  PatrolIntegrationTester $,
  String path,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    final folders = await listRecordingFolders();
    if (folders.every((folder) => folder.path != path)) {
      return;
    }
    await $.pump(const Duration(milliseconds: 100));
  }
  throw TestFailure('The test recording was not deleted: $path');
}

Future<void> _stopRecordingIfNecessary(PatrolIntegrationTester $) async {
  if ($('Recording in progress').visible &&
      $(UiTestKeys.recorderStartStop).visible) {
    await $(UiTestKeys.recorderStartStop).tap();
    await $('Ready to record').waitUntilVisible(
      timeout: const Duration(seconds: 15),
    );
  }
}

class _RateMeasurement {
  const _RateMeasurement({
    required this.fileName,
    required this.sampleCount,
    required this.durationSeconds,
    required this.observedRateHz,
  });

  factory _RateMeasurement.fromTimestamps({
    required String fileName,
    required List<int> timestamps,
  }) {
    if (timestamps.length < 2) {
      throw TestFailure('$fileName has fewer than two sensor timestamps.');
    }
    for (var index = 1; index < timestamps.length; index++) {
      if (timestamps[index] <= timestamps[index - 1]) {
        throw TestFailure(
          '$fileName contains non-increasing timestamps at row ${index + 2}.',
        );
      }
    }

    // OpenEarable v2 declares timestampExponent = -6, so CSV timestamps are
    // microseconds. Every timestamp used here belongs to a sample the app
    // actually received and wrote.
    final durationSeconds =
        (timestamps.last - timestamps.first) / Duration.microsecondsPerSecond;
    if (durationSeconds <= 0) {
      throw TestFailure('$fileName has a non-positive timestamp span.');
    }
    final observedRate = (timestamps.length - 1) / durationSeconds;
    return _RateMeasurement(
      fileName: fileName,
      sampleCount: timestamps.length,
      durationSeconds: durationSeconds,
      observedRateHz: observedRate,
    );
  }

  final String fileName;
  final int sampleCount;
  final double durationSeconds;
  final double observedRateHz;
}
