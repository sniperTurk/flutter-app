// Screenshots of the four pages changed by "Düzeltmeler 16.10.2026" (owner,
// 2026-10-16 20:06, design PR #366; item 5 changed 20:07), for the report
// docs/reports/duzeltmeler_16_10.md: Profil (Profil ekle), the top-bar
// profile list (open, long and short active name), Hava Durumu, Pro >
// Tüfek düzeltmeleri (Mühimmat sıcaklığı) and Hedef, 390 and 320 pt
// wide, plus an opened standard select (Profil Oluştur > Kalibre) to
// compare the profile list with.
//
// Run by .github/workflows/sim-screens.yml with
//   test=integration_test/duzeltmeler_16_10_screens_test.dart
// The app is laid out at the requested width by changing the pixel ratio
// of the Simulator window (the height follows the window). The test
// prints the measured rectangles as SIMRECT lines for the report.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
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

RifleProfile _profile(String id, String name) => RifleProfile(
  id: id,
  name: name,
  rifleId: 'manual_rifle_sim',
  ammunitionId: 'manual_ammo_sim',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 805,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: 1,
  powderTempReferenceC: 21,
);

final _main = _profile('sim-308', 'Ateşli 308');
final _long = _profile('sim-long', 'Tikka T3x Varmint gece avı ana namlu');
final _short = _profile('sim-short', 'bbbbb');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Düzeltmeler 16.10 screenshots', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await ManualCatalogStore().upsert(_rifle);
    await ManualCatalogStore().upsert(_ammo);
    for (final p in [_main, _long, _short]) {
      await PersistentProfileStore().save(p);
    }
    await PersistentActiveProfileStore().setActiveProfileId(_main.id);

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
        () => Future<void>.delayed(const Duration(seconds: 4)),
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

    Finder tab(String label) => find.descendant(
      of: find.byType(MenzilBottomNavigation),
      matching: find.text(label),
    );

    Future<void> openTab(String label) async {
      await tester.tap(tab(label));
      await settle();
    }

    Future<void> closeList() async {
      // The list's barrier: a tap outside closes it without a pick.
      await tester.tapAt(const Offset(4, 300));
      await settle();
    }

    Future<void> pickProfile(RifleProfile p) async {
      await tester.tap(find.byKey(const Key('top-bar-profile-button')));
      await settle();
      await tester.tap(find.byKey(ValueKey(('top-bar-profile-item', p.id))));
      await settle();
    }

    final pill = find.byKey(const Key('top-bar-profile-button'));

    app.main();
    await wait(3);

    // The Simulator's own window (physical pixels) is kept: a different
    // physical size makes the engine drop every frame (first try,
    // 2026-10-16). Only the pixel ratio changes, so the app is laid out
    // [w] pt wide and fills the screen; the height follows the window.
    final physical = tester.view.physicalSize;
    for (final w in const [390.0, 320.0]) {
      final size = '${w.toInt()}';
      tester.view.devicePixelRatio = physical.width / w;
      await wait(1);
      debugPrint(
        'SIMRECT:ekran_$size:0,0,${w.toStringAsFixed(1)},'
        '${(physical.height / (physical.width / w)).toStringAsFixed(1)}',
      );

      await step('profil_$size', () async {
        await openTab('Profil');
        await tester.ensureVisible(find.byKey(const Key('profiles-add')));
        final scroll = Scrollable.maybeOf(
          tester.element(find.byKey(const Key('profiles-add'))),
        );
        scroll?.position.jumpTo(0);
        await settle();
        rect('profil_$size:profil_ekle', find.byKey(const Key('profiles-add')));
        await shot('profil_$size');
      });

      await step('secici_$size', () async {
        await tester.tap(pill);
        await settle();
        rect('secici_$size:dugme', pill);
        rect(
          'secici_$size:liste',
          find
              .ancestor(
                of: find.byKey(ValueKey(('top-bar-profile-item', _main.id))),
                matching: find.byType(Material),
              )
              .first,
        );
        await shot('secici_$size');
        await closeList();
      });

      await step('secici_kisa_$size', () async {
        await pickProfile(_short);
        await tester.tap(pill);
        await settle();
        rect('secici_kisa_$size:dugme', pill);
        await shot('secici_kisa_$size');
        await closeList();
      });

      await step('secici_uzun_$size', () async {
        await pickProfile(_long);
        await tester.tap(pill);
        await settle();
        rect('secici_uzun_$size:dugme', pill);
        await shot('secici_uzun_$size');
        await closeList();
        await pickProfile(_main);
      });

      await step('hava_$size', () async {
        await openTab('Hava Durumu');
        await wait(2);
        await shot('hava_$size');
        final s = find.byType(Scrollable).hitTestable();
        if (s.evaluate().isNotEmpty) {
          final pos = tester.state<ScrollableState>(s.first).position;
          pos.jumpTo(pos.viewportDimension * 0.85);
          await settle();
          await shot('hava_${size}_2');
          pos.jumpTo(0);
          await settle();
        }
      });

      await step('pro_$size', () async {
        await openTab('Pro');
        await wait(1);
        final header = find.byKey(const Key('pro-section-rifle'));
        await tester.ensureVisible(header);
        await settle();
        if (find.byKey(const Key('pro-ammo-temp-row')).evaluate().isEmpty) {
          final hh = tester.getSize(header).height;
          await tester.tapAt(tester.getTopLeft(header) + Offset(12, hh / 2));
          await settle();
        }
        final row = find.byKey(const Key('pro-ammo-temp-row'));
        await tester.ensureVisible(row);
        await settle();
        await Scrollable.ensureVisible(tester.element(row), alignment: 0.6);
        await settle();
        rect('pro_$size:muhimmat_satiri', row);
        await shot('pro_$size');
      });

      await step('hedef_$size', () async {
        await openTab('Hedef');
        await wait(2);
        final s = find.byType(Scrollable).hitTestable();
        if (s.evaluate().isNotEmpty) {
          tester.state<ScrollableState>(s.first).position.jumpTo(0);
          await settle();
        }
        rect('hedef_$size:slider', find.byType(Slider));
        rect('hedef_$size:klik_satiri', find.byKey(TurretSolutionRow.rowKey));
        rect('hedef_$size:durbun', find.byKey(ScopeDialKeys.reticle));
        rect('hedef_$size:alt_menu', find.byType(MenzilBottomNavigation));
        await shot('hedef_$size');
      });

      await step('kalibre_select_$size', () async {
        await openTab('Profil');
        await tester.ensureVisible(find.byKey(const Key('profiles-add')));
        await settle();
        await tester.tap(find.byKey(const Key('profiles-add')));
        await settle();
        final cal = find.byKey(const Key('rifle-caliber'));
        await tester.ensureVisible(cal);
        await settle();
        await tester.tap(cal);
        await settle();
        await shot('kalibre_select_$size');
        await closeList();
        await tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .maybePop();
        await settle();
        // "Çıkılsın mı?" when the editor asks before leaving.
        for (final t in const ['Çık', 'Çıkış', 'Vazgeç', 'Kaydetmeden çık']) {
          final b = find.text(t);
          if (b.evaluate().isNotEmpty) {
            await tester.tap(b.last);
            await settle();
            break;
          }
        }
      });
    }

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
