// Before/after screenshots for "Rüzgâr satırları" (owner, 2026-10-17,
// TestFlight 112: "Yazı sanki hesap dökümü olarak algılanıyor" · "İki
// yazıyı da tek satıra sığdır, toplam 2 satır olacak").
// Run by .github/workflows/sim-screens.yml with
// `test: integration_test/ruzgar_satirlari_screens_test.dart`; same
// SIMSCREEN markers as sim_screens_test.dart. The real app (SniperTurkApp)
// is drawn inside a 390 × 844 pt and a 320 × 568 pt frame in the middle of
// the Simulator screen; the Hedef page is scrolled to Vuruş noktası → wind
// lines → Hesap dökümü. Hava Durumu wind 6,2 m/s from 9 o'clock, En yüksek
// rüzgâr 9,3 m/s. The texts are printed as SIMTEXT lines.
// Report: docs/reports/ruzgar_satirlari.md.
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

// A PCP slug with a G1 BC so the drag solver (wind) runs, as in
// test/ruzgar_satirlari_test.dart.
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_ruz',
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
  id: 'sim-ruz-satir',
  name: 'Rüzgâr satırları',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'manual_ammo_ruz',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 60,
  pressureBar: 200,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Hedef wind lines at 390 and 320 pt', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await ManualCatalogStore().upsert(_ammo);
    await PersistentProfileStore().save(_profile);
    await PersistentActiveProfileStore().setActiveProfileId(_profile.id);
    await const ShotSettingsStore().save(
      _profile.id,
      ShotSettings(
        weatherSaved: true,
        weatherSi: {'wind': 6.2, 'windDirection': WindClock.toDegrees(9)},
        windMaxText: '9.3',
      ),
    );

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

    Future<void> shot(String name) async {
      await settle();
      counter++;
      debugPrint('SIMSCREEN:${counter.toString().padLeft(2, '0')}_$name');
      // Hold the frame while the workflow saves the Simulator screen.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 15)),
      );
    }

    void text(String what, Key key) {
      final f = find.byKey(key);
      if (f.evaluate().isEmpty) {
        debugPrint('SIMTEXT:$what: yok');
        return;
      }
      final r = tester.getRect(f.first);
      final w = tester.widget(f.first);
      debugPrint(
        'SIMTEXT:$what: ${w is Text ? w.data : w.runtimeType} | '
        '${r.left.toStringAsFixed(1)},${r.top.toStringAsFixed(1)},'
        '${r.right.toStringAsFixed(1)},${r.bottom.toStringAsFixed(1)}',
      );
    }

    for (final size in const [Size(390, 844), Size(320, 568)]) {
      final name = 'hedef_ruzgar_${size.width.toInt()}';
      try {
        final view = tester.view;
        await tester.pumpWidget(
          ColoredBox(
            color: const Color(0xFF6E6E6E),
            child: Center(
              child: SizedBox.fromSize(
                size: size,
                child: MediaQuery(
                  data: MediaQueryData.fromView(view).copyWith(size: size),
                  child: SniperTurkApp(key: ValueKey(size)),
                ),
              ),
            ),
          ),
        );
        await settle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        await settle();
        await tester.tap(find.text('Hedef').last);
        await settle();
        // Vuruş noktası near the top, Hesap dökümü below it.
        final impact = find.byKey(ScopeDialKeys.impactText);
        await tester.ensureVisible(impact);
        await settle();
        await Scrollable.ensureVisible(
          tester.element(impact),
          alignment: 0.15,
        );
        await settle();
        text('$name impact', ScopeDialKeys.impactText);
        text('$name bracket', const Key('shot-wind-bracket'));
        text('$name shares', const Key('shot-wind-zone-shares'));
        text('$name workings', ScopeDialKeys.workingsToggle);
        await shot(name);
      } catch (error) {
        final line = error.toString().split('\n').first;
        failures.add('$name: $line');
        debugPrint('SIMSTEP_FAIL:$name: $line');
        await shot('FAIL_$name');
      }
      final exception = tester.takeException();
      if (exception != null) {
        final line = exception.toString().split('\n').first;
        failures.add('$name: $line');
        debugPrint('SIMSTEP_FAIL:$name: $line');
      }
    }

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 30)),
    );
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
