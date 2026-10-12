// Screenshots for Ö4 (Basıncı telefondan al) and Ö6 (Sürüklenme eğrisi on
// Hız Doğrulama), 2026-10-12. Run once by .github/workflows/sim-screens.yml
// with `test: integration_test/barometre_screens_test.dart`; same SIMSCREEN
// markers as sim_screens_test.dart. The Simulator has no barometer, so the
// button must show "Basınç okunamadı" there.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/main.dart' as app;
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

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
const _profile = RifleProfile(
  id: 'sim-308',
  name: 'Ateşli 308',
  rifleId: 'manual_rifle_sim',
  ammunitionId: 'manual_ammo_sim',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 790,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

/// What Hız Doğrulama predicts with its default air (15 °C, 1013,25 hPa,
/// %50); the observations below are a little lower far out.
List<double> _predicted(List<double> ranges) => [
  for (final p in const BallisticEngine().solve(
    BallisticInput(
      muzzleVelocityMps: 790,
      grain: 175,
      zeroRangeM: 100,
      sightHeightMm: 45,
      rangesM: ranges,
      environment: const EnvironmentData(
        temperatureC: 15,
        pressureHpa: 1013.25,
        humidityPercent: 50,
      ),
      ballisticCoefficient: 0.243,
      ballisticModel: BallisticModel.g7,
    ),
  ))
    p.correctionMrad,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Barometre and Sürüklenme eğrisi screenshots', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await ManualCatalogStore().upsert(_rifle);
    await ManualCatalogStore().upsert(_ammo);
    await PersistentProfileStore().save(_profile);
    await PersistentActiveProfileStore().setActiveProfileId(_profile.id);
    app.main();

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

    ScrollPosition? mainScroll() {
      ScrollPosition? best;
      for (final element in find.byType(Scrollable).hitTestable().evaluate()) {
        final state = (element as StatefulElement).state;
        if (state is! ScrollableState) continue;
        final position = state.position;
        if (position.axis != Axis.vertical ||
            !position.hasContentDimensions ||
            !position.hasViewportDimension) {
          continue;
        }
        if (best == null ||
            position.viewportDimension > best.viewportDimension) {
          best = position;
        }
      }
      return best;
    }

    Future<void> page(String name) async {
      mainScroll()?.jumpTo(0);
      await shot(name);
      for (var part = 2; part <= 6; part++) {
        final position = mainScroll();
        if (position == null ||
            position.pixels >= position.maxScrollExtent - 1) {
          break;
        }
        position.jumpTo(
          math.min(
            position.pixels + position.viewportDimension * 0.85,
            position.maxScrollExtent,
          ),
        );
        await shot('${name}_$part');
      }
      mainScroll()?.jumpTo(0);
      await settle();
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
      await tester.tap(find.text(label).last);
      await settle();
    }

    Future<void> type(String key, String text) async {
      final field = find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, text);
      await settle();
    }

    await wait(3);
    await step('hava_durumu_basinc', () async {
      await openTab('Hava Durumu');
      await wait(6);
      await page('hava_durumu_once');
      final button = find.byKey(const Key('environment-phone-pressure'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await wait(4);
      await tester.ensureVisible(button);
      await shot('hava_durumu_basinc_sonra');
    });
    await step('dogrulama_cok_mesafe', () async {
      await openTab('Araçlar');
      await tester.tap(find.byKey(const Key('tool-truing')));
      await settle();
      await tester.tap(find.text('Namlu çıkış hızı').first);
      await settle();
      await tester.tap(find.text('Sürüklenme eğrisi').last);
      await settle();
      const ranges = [500.0, 700.0, 900.0];
      final p = _predicted(ranges);
      final observed = [p[0] + 0.02, p[1] + 0.06, p[2] + 0.16];
      for (var i = 0; i < 3; i++) {
        await type('truing-drag-range-$i', ranges[i].toStringAsFixed(0));
        await type('truing-drag-observed-$i', observed[i].toStringAsFixed(2));
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await page('dogrulama_giris');
      await tester.ensureVisible(find.byKey(const Key('truing-compute')));
      await tester.tap(find.byKey(const Key('truing-compute')));
      await wait(3);
      await tester.ensureVisible(find.byKey(const Key('truing-drag-result')));
      await shot('dogrulama_sonuc');
      await tester.ensureVisible(find.byKey(const Key('truing-drag-apply')));
      await shot('dogrulama_sonuc_2');
    });

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
