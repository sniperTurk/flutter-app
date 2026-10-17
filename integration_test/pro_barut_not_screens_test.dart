// Screenshots for "Pro barut notu" (owner, 2026-10-17, TestFlight 112):
// Pro > Tüfek düzeltmeleri open with Mermi uzunluğu | Mühimmat sıcaklığı
// on one row and the new powder note, for a firearm without Barut
// katsayısı / Hız ölçüm sıcaklığı (note case 1), a firearm with both
// (case 2) and a PCP profile (Mermi uzunluğu on its own row, no Mühimmat
// sıcaklığı). Report: docs/reports/pro_barut_not.md.
//
// Run by .github/workflows/sim-screens.yml with
//   test=integration_test/pro_barut_not_screens_test.dart device=iPhone 16e
// (390 pt wide). Prints the measured rectangles as SIMRECT lines.
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
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_sim',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 175',
  'model': '',
  'caliberMm': 7.62,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.243,
  'bcModel': 'g7',
};

const _noCoef = RifleProfile(
  id: 'sim-308-bos',
  name: 'Ateşli katsayısız',
  rifleId: 'manual_rifle_sim',
  ammunitionId: 'manual_ammo_sim',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 805,
  zeroRangeM: 100,
  sightHeightMm: 45,
);
const _withCoef = RifleProfile(
  id: 'sim-308-dolu',
  name: 'Ateşli katsayılı',
  rifleId: 'manual_rifle_sim',
  ammunitionId: 'manual_ammo_sim',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 805,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: 1.5,
  powderTempReferenceC: 21,
);
const _pcp = RifleProfile(
  id: 'sim-pcp',
  name: 'PCP',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pro barut notu screenshots', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await ManualCatalogStore().upsert(_rifle);
    await ManualCatalogStore().upsert(_ammo);
    for (final p in [_noCoef, _withCoef, _pcp]) {
      await PersistentProfileStore().save(p);
    }
    await PersistentActiveProfileStore().setActiveProfileId(_noCoef.id);

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

    void rect(String what, Finder f) {
      final r = f.evaluate().isEmpty ? null : tester.getRect(f.first);
      debugPrint(
        'SIMRECT:$what:'
        '${r == null ? 'yok' : '${r.left.toStringAsFixed(1)},'
                  '${r.top.toStringAsFixed(1)},${r.right.toStringAsFixed(1)},'
                  '${r.bottom.toStringAsFixed(1)}'}',
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

    Future<void> openTab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(MenzilBottomNavigation),
          matching: find.text(label),
        ),
      );
      await settle();
    }

    Future<void> pickProfile(RifleProfile p) async {
      await tester.tap(find.byKey(const Key('top-bar-profile-button')));
      await settle();
      await tester.tap(
        find
            .descendant(
              of: find.byKey(ValueKey(('top-bar-profile-item', p.id))),
              matching: find.text(p.name),
            )
            .last,
      );
      await settle();
    }

    Future<void> proRifle(String name) async {
      await openTab('Pro');
      await wait(1);
      final header = find.byKey(const Key('pro-section-rifle'));
      await tester.ensureVisible(header);
      await settle();
      if (find.byKey(const Key('pro-bullet-length')).evaluate().isEmpty) {
        final hh = tester.getSize(header).height;
        await tester.tapAt(tester.getTopLeft(header) + Offset(12, hh / 2));
        await settle();
      }
      await Scrollable.ensureVisible(tester.element(header), alignment: 0.05);
      await settle();
      rect('$name:mermi_uzunlugu', find.byKey(const Key('pro-bullet-length')));
      rect('$name:muhimmat_sicakligi', find.byKey(const Key('env-ammo-temp')));
      rect('$name:not', find.byKey(const Key('pro-powder-source')));
      final note = find.byKey(const Key('pro-powder-source'));
      if (note.evaluate().isNotEmpty) {
        debugPrint('SIMTEXT:$name:${tester.widget<Text>(note).data}');
      }
      await shot(name);
    }

    app.main();
    await wait(3);
    final view = tester.view;
    final width = view.physicalSize.width / view.devicePixelRatio;
    debugPrint('SIMRECT:ekran:0,0,${width.toStringAsFixed(1)}');

    await step('pro_atesli_not1', () => proRifle('pro_atesli_not1'));
    await step('pro_atesli_not2', () async {
      await pickProfile(_withCoef);
      await proRifle('pro_atesli_not2');
    });
    await step('pro_pcp', () async {
      await pickProfile(_pcp);
      await proRifle('pro_pcp');
    });

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
