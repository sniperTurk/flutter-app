// Before/after screenshots for "yan kule konum" (owner, 2026-10-16 21:08:
// "Sağ kulenin sağ tarafında dürbün beyazlığı var … Kuleyi biraz sağa al").
// Run by .github/workflows/sim-screens.yml with
// `test: integration_test/yan_kule_konum_screens_test.dart`; same
// SIMSCREEN markers as sim_screens_test.dart. The real app (SniperTurkApp)
// is drawn inside a 390 × 844 pt and a 320 × 568 pt frame in the middle of
// the Simulator screen, so one Simulator shows both phone widths; the Hedef
// page is opened with the side (windage) turret shown.
// Report: docs/reports/yan_kule_konum.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/main.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

// Gazi Sniper 6–36×56 FFP in MOA, as in test/yan_kule_kucuk_test.dart.
const _profile = RifleProfile(
  id: 'sim-yan-kule',
  name: 'Yan kule',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Hedef side turret at 390 and 320 pt', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
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

    Future<void> shot(String name) async {
      await settle();
      counter++;
      debugPrint('SIMSCREEN:${counter.toString().padLeft(2, '0')}_$name');
      // Hold the frame while the workflow saves the Simulator screen. The
      // marker reaches the workflow's log a few seconds late, so the hold
      // is longer than sim_screens_test.dart's 4 s.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 15)),
      );
    }

    for (final size in const [Size(390, 844), Size(320, 568)]) {
      final name = 'hedef_yan_kule_${size.width.toInt()}';
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
        final toggle = find.byKey(ScopeDialKeys.turretToggle);
        await tester.ensureVisible(toggle);
        await settle();
        await tester.tap(toggle);
        await settle();
        // The scope (turret row + reticle) in the middle of the frame.
        await Scrollable.ensureVisible(
          tester.element(find.byKey(ScopeDialKeys.reticle)),
          alignment: 0.5,
        );
        await settle();
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
    // Keep the last frame up until its late marker has been seen.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 30)),
    );
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
