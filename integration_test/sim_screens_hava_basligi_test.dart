// Hava Durumu before/after screenshots for fix/hava-basligi-sil (2026-10-16).
// Run by .github/workflows/sim-screens.yml with
// `test: integration_test/sim_screens_hava_basligi_test.dart`. Same
// SIMSCREEN markers as sim_screens_test.dart. A saved catalog PCP profile is
// seeded, then the app is laid out 390 pt and 320 pt wide (left part of the
// Simulator screen) on the Hava Durumu tab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

const _profile = RifleProfile(
  id: 'sim-pcp',
  name: 'Profil',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Hava Durumu screenshots at 390 and 320 pt', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await PersistentProfileStore().save(_profile);
    await PersistentActiveProfileStore().setActiveProfileId(_profile.id);
    app.main();

    var counter = 0;
    Future<void> settle() async {
      try {
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 8),
        );
      } on FlutterError {
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }

    Future<void> wait(int seconds) async {
      await tester.runAsync(
        () => Future<void>.delayed(Duration(seconds: seconds)),
      );
      await settle();
    }

    Future<void> shot(String name) async {
      await settle();
      counter++;
      debugPrint('SIMSCREEN:${counter.toString().padLeft(2, '0')}_$name');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 4)),
      );
    }

    final dpr = tester.view.devicePixelRatio;
    final screenHeight = tester.view.physicalSize.height;
    addTearDown(tester.view.reset);

    await wait(3);
    await tester.tap(find.text('Hava Durumu').last);
    await wait(6);
    for (final points in const [390.0, 320.0]) {
      tester.view.physicalSize = Size(points * dpr, screenHeight);
      await settle();
      await shot('hava_durumu_${points.toInt()}');
    }
    debugPrint('SIMSCREEN_DONE failures=0');
  });
}
