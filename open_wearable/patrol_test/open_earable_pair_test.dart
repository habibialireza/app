import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_driver.dart';
import 'support/open_earable_pair_driver.dart';

void main() {
  patrolTest(
    'PAIR-01 PAIR-02 PAIR-03: connect, identify, split, and recombine a stereo pair',
    ($) async {
      await startProductionApp($);
      await grantFirstRunPermissions($);

      final pairFixture = await connectExactlyTwoOpenEarables($);
      final deviceId1 = pairFixture.deviceIds[0];
      final deviceId2 = pairFixture.deviceIds[1];
      final pairKey = pairFixture.pairKey;
      try {
        final pair = $(UiTestKeys.combinedPair(pairKey));

        expect(
          descendantText(UiTestKeys.combinedPair(pairKey), 'L'),
          findsOneWidget,
        );
        expect(
          descendantText(UiTestKeys.combinedPair(pairKey), 'R'),
          findsOneWidget,
        );

        await $(UiTestKeys.combinedPairToggle(pairKey)).tap();
        await $(UiTestKeys.connectedDevice(deviceId1)).waitUntilVisible();
        await $(UiTestKeys.connectedDevice(deviceId2)).waitUntilVisible();

        final side1 = sideForDevice($, deviceId1);
        final side2 = sideForDevice($, deviceId2);
        expect({side1, side2}, equals({'L', 'R'}));
        debugPrint('PAIR_SIDE_MAPPING id="$deviceId1" side="$side1"');
        debugPrint('PAIR_SIDE_MAPPING id="$deviceId2" side="$side2"');

        await $(UiTestKeys.splitPairToggle(pairKey, deviceId1)).tap();
        await pair.waitUntilVisible(timeout: const Duration(seconds: 30));
      } finally {
        await cleanupConnectedPair($, pairFixture);
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
