// Screenshot of the Profil page Mühimmat card after "Özet mermi uzunluğu"
// (owner, 2026-10-17 18:13–18:26): firearm, factory round with a saved
// length of 31,2 mm -> "Tip / uzunluk" "Mermi 31,2 mm" and a last
// "Mühimmat türü" "Fabrika fişeği". For docs/reports/ozet_mermi_uzunlugu.md,
// 390 pt.
//
// Run by .github/workflows/sim-screens.yml with
//   test=integration_test/ozet_mermi_uzunlugu_screens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_sim',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 11,
};
// A listed factory round (factory_ammo_library.dart) with a length.
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_sim',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Barnes',
  'model': 'Harvest Collection 165 gr Sierra TGK',
  'caliberMm': 7.82,
  'grain': 165,
  'ammoType': 'bullet',
  'bc': 0.517,
  'bcModel': 'g1',
  'lengthMm': 31.2,
};

const _profile = RifleProfile(
  id: 'sim-308',
  name: 'Ateşli 308',
  rifleId: 'manual_rifle_sim',
  ammunitionId: 'manual_ammo_sim',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 805,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Özet mermi uzunluğu screenshot', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await ManualCatalogStore().upsert(_rifle);
    await ManualCatalogStore().upsert(_ammo);
    await PersistentProfileStore().save(_profile);
    await PersistentActiveProfileStore().setActiveProfileId(_profile.id);

    final failures = <String>[];
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
        () => Future<void>.delayed(const Duration(seconds: 10)),
      );
    }

    Future<void> step(String name, Future<void> Function() body) async {
      try {
        await body();
      } catch (error) {
        final line = error.toString().split('\n').first;
        failures.add('$name: $line');
        debugPrint('SIMSTEP_FAIL:$name: $line');
        await shot('FAIL_$name');
      }
    }

    app.main();
    await wait(3);

    // Only the pixel ratio changes (as in duzeltmeler_16_10_screens_test):
    // set twice, the first change is not always drawn.
    final physical = tester.view.physicalSize;
    for (final w in const [320.0, 390.0]) {
      tester.view.devicePixelRatio = physical.width / w;
      await wait(2);
    }

    await step('profil_390_muhimmat', () async {
      await tester.tap(
        find.descendant(
          of: find.byType(MenzilBottomNavigation),
          matching: find.text('Profil'),
        ),
      );
      await settle();
      final ammo = find.byKey(const Key('profile-summary-ammo'));
      await Scrollable.ensureVisible(tester.element(ammo), alignment: 1);
      await shot('profil_390_muhimmat');
      for (final text in const [
        'Tip / uzunluk',
        'Mermi 31,2 mm',
        'Mühimmat türü',
        'Fabrika fişeği',
      ]) {
        expect(
          find.descendant(of: ammo, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
    });

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
