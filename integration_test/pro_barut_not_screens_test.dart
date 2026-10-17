// Screenshots for "Pro barut notu" (owner, 2026-10-17, TestFlight 112) and
// "Mermi uzunluğu profile, Mühimmat sıcaklığı bölümü" (owner, 2026-10-17
// 11:34–11:41): Profil > Mühimmat with BC modeli | Mermi uzunluğu (firearm
// filled, PCP); Pro > Tüfek düzeltmeleri open (no Mermi uzunluğu) and the
// new Mühimmat sıcaklığı box open with the powder note (firearm without
// and with Barut katsayısı / Hız ölçüm sıcaklığı); Pro on PCP (no
// Mühimmat sıcaklığı box). Report: docs/reports/pro_barut_not.md.
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
  'brand': 'Test',
  'model': '175 gr',
  'caliberMm': 7.62,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.243,
  'bcModel': 'g7',
  'lengthMm': 31.2,
};
const _pcpRifle = <String, dynamic>{
  'id': 'manual_rifle_sim_pcp',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Test',
  'model': 'PCP 6.35',
  'caliberMm': 6.35,
  'twistDirection': 'right',
  'twistRateIn': 17,
  'regulatorBar': 120,
};
const _pcpAmmo = <String, dynamic>{
  'id': 'manual_ammo_sim_pcp',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Test slug',
  'model': '',
  'caliberMm': 6.35,
  'grain': 33.95,
  'ammoType': 'slug',
  'bc': 0.08,
  'bcModel': 'g1',
  'lengthMm': 10.4,
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
  rifleId: 'manual_rifle_sim_pcp',
  ammunitionId: 'manual_ammo_sim_pcp',
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
    await ManualCatalogStore().upsert(_pcpRifle);
    await ManualCatalogStore().upsert(_pcpAmmo);
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
      // Long enough for the runner to see the marker in the log and take
      // the picture before the next step changes the screen.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 25)),
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

    /// Opens the Pro box [id] (one open at a time) and scrolls it to the
    /// top.
    Future<void> proBox(String id) async {
      await openTab('Pro');
      await wait(1);
      final header = find.byKey(Key('pro-section-$id'));
      await tester.ensureVisible(header);
      await settle();
      if (find.byKey(Key('pro-summary-$id')).evaluate().isNotEmpty) {
        final hh = tester.getSize(header).height;
        await tester.tapAt(tester.getTopLeft(header) + Offset(12, hh / 2));
        await settle();
      }
      await Scrollable.ensureVisible(tester.element(header), alignment: 0.05);
      await settle();
    }

    Future<void> proRifle(String name) async {
      await proBox('rifle');
      rect('$name:mermi_uzunlugu', find.byKey(const Key('pro-bullet-length')));
      rect('$name:gercek_yazan', find.byKey(const Key('pro-turret-scale')));
      rect('$name:yukari', find.byKey(const Key('pro-zero-up')));
      rect('$name:sag', find.byKey(const Key('pro-zero-right')));
      rect('$name:muhimmat_kutusu', find.byKey(const Key('pro-box-ammo-temp')));
      await shot(name);
    }

    Future<void> proAmmoTemp(String name) async {
      await proBox('ammo-temp');
      rect('$name:bolum', find.byKey(const Key('pro-box-ammo-temp')));
      rect('$name:muhimmat_sicakligi', find.byKey(const Key('env-ammo-temp')));
      rect('$name:not', find.byKey(const Key('pro-powder-source')));
      final note = find.byKey(const Key('pro-powder-source'));
      if (note.evaluate().isNotEmpty) {
        debugPrint('SIMTEXT:$name:${tester.widget<Text>(note).data}');
      }
      await shot(name);
    }

    /// Profil > Düzenle of [p] scrolled to BC modeli | Mermi uzunluğu.
    Future<void> profileAmmo(RifleProfile p, String name) async {
      await openTab('Profil');
      await wait(1);
      // The ⋯ menu on the row of [p] (nearest to its name).
      final menus = find.byTooltip('Profil işlemleri');
      final names = find.text(p.name);
      var index = 0;
      if (names.evaluate().isNotEmpty) {
        final y = tester.getCenter(names.last).dy;
        var best = double.infinity;
        for (var i = 0; i < menus.evaluate().length; i++) {
          final d = (tester.getCenter(menus.at(i)).dy - y).abs();
          if (d < best) {
            best = d;
            index = i;
          }
        }
      }
      await tester.ensureVisible(menus.at(index));
      await settle();
      await tester.tap(menus.at(index));
      await settle();
      await tester.tap(find.text('Düzenle').last);
      await settle();
      final pair = find.byKey(const Key('ammo-bc-model-length-row'));
      await tester.ensureVisible(pair);
      await settle();
      await Scrollable.ensureVisible(tester.element(pair), alignment: 0.55);
      await settle();
      rect('$name:bc_modeli', find.byKey(const Key('ammo-bc-model')));
      rect('$name:mermi_uzunlugu', find.byKey(const Key('ammo-length')));
      await shot(name);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .popUntil((route) => route.isFirst);
      await settle();
    }

    app.main();
    await wait(3);
    final view = tester.view;
    final width = view.physicalSize.width / view.devicePixelRatio;
    debugPrint('SIMRECT:ekran:0,0,${width.toStringAsFixed(1)}');

    await step('profil_muhimmat_atesli', () async {
      await profileAmmo(_noCoef, 'profil_muhimmat_atesli');
    });
    await step('profil_muhimmat_pcp', () async {
      await profileAmmo(_pcp, 'profil_muhimmat_pcp');
    });
    await step('pro_atesli_tufek', () => proRifle('pro_atesli_tufek'));
    await step('pro_atesli_muhimmat_not1', () async {
      await proAmmoTemp('pro_atesli_muhimmat_not1');
    });
    await step('pro_atesli_muhimmat_not2', () async {
      await pickProfile(_withCoef);
      await proAmmoTemp('pro_atesli_muhimmat_not2');
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
