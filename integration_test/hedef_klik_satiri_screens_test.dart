// Before/after screenshots for "Hedef klik satırı" (owner, 2026-10-17,
// TestFlight 112: "Üst kule klik sayısını sağ çizgiye yasla. Solda bulunan
// çizgiyi kaldır."). Run by .github/workflows/sim-screens.yml with
// `test: integration_test/hedef_klik_satiri_screens_test.dart` on an
// iPhone 16e (390 pt). Hedef page top: distance slider and the click line.
// Wind 6,2 m/s from 9 o'clock so Yan kule shows clicks.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/wind_clock.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/main.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';

const _ammo = <String, dynamic>{
  'id': 'manual_ammo_klik',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.25 slug',
  'caliberMm': 6.35,
  'grain': 34,
  'ammoType': 'slug',
  'bc': 0.08,
  'bcModel': 'g1',
};

const _profile = RifleProfile(
  id: 'sim-klik-satiri',
  name: 'Klik satırı',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'manual_ammo_klik',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 60,
  pressureBar: 200,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Hedef click line at 390 pt', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await ManualCatalogStore().upsert(_ammo);
    await PersistentProfileStore().save(_profile);
    await PersistentActiveProfileStore().setActiveProfileId(_profile.id);
    await const ShotSettingsStore().save(
      _profile.id,
      ShotSettings(
        weatherSaved: true,
        weatherSi: {'wind': 6.2, 'windDirection': WindClock.toDegrees(9)},
      ),
    );
    final failures = <String>[];

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

    Future<void> shot(String name) async {
      await settle();
      debugPrint('SIMSCREEN:$name');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 15)),
      );
    }

    try {
      await tester.pumpWidget(const SniperTurkApp());
      await settle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await settle();
      await tester.tap(find.text('Hedef').last);
      await settle();
      for (final k in const [
        TurretSolutionRow.rowKey,
        TurretSolutionRow.elevationKey,
        TurretSolutionRow.windageKey,
      ]) {
        final f = find.byKey(k);
        if (f.evaluate().isEmpty) {
          debugPrint('SIMTEXT:$k yok');
          continue;
        }
        final r = tester.getRect(f.first);
        final texts = tester
            .widgetList<RichText>(
              find.descendant(of: f.first, matching: find.byType(RichText)),
            )
            .map((t) => t.text.toPlainText())
            .join(' | ');
        debugPrint(
          'SIMTEXT:$k: $texts | ${r.left.toStringAsFixed(1)},'
          '${r.top.toStringAsFixed(1)},${r.right.toStringAsFixed(1)},'
          '${r.bottom.toStringAsFixed(1)}',
        );
      }
      await shot('01_hedef_klik_satiri_390');
    } catch (error) {
      final line = error.toString().split('\n').first;
      failures.add(line);
      debugPrint('SIMSTEP_FAIL:$line');
      await shot('FAIL_hedef');
    }
    final exception = tester.takeException();
    if (exception != null) {
      failures.add(exception.toString().split('\n').first);
    }
    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 30)),
    );
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
