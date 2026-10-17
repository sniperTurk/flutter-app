// Screenshots for "Hava Durumu: rüzgâr tarihi solda, bölüm aralıkları"
// (owner, 2026-10-17 19:23 / 20:02 / 20:03).
// Run by .github/workflows/sim-screens.yml with
// `test: integration_test/hava_aralik_tarih_screens_test.dart`; same
// SIMSCREEN markers as sim_screens_test.dart. The real app (SniperTurkApp)
// is drawn inside a 390 × 844 pt and a 320 × 568 pt frame in the middle of
// the Simulator screen. Hava Durumu: the top of the page, then the Rüzgâr
// section (header, card, clock, "Saat 1 yönünde" + date) and the
// "Pro Ayarlar'a geç" button. Rectangles are printed as SIMTEXT lines.
// Report: docs/reports/hava_aralik_tarih.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/main.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _profile = RifleProfile(
  id: 'sim-hava-aralik',
  name: 'Hava aralık',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Hava Durumu gaps and wind date at 390 and 320 pt', (
    tester,
  ) async {
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
      // Hold the frame while the workflow saves the Simulator screen.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 15)),
      );
    }

    void rect(String what, Finder f) {
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

    Finder header(String title) => find.descendant(
      of: find.byType(MenzilSectionHeader),
      matching: find.text(title),
    );
    Finder edge(Finder card) =>
        find.descendant(of: card, matching: find.byType(Material)).first;
    Finder cardOf(Key k) => find
        .ancestor(of: find.byKey(k), matching: find.byType(MenzilCard))
        .first;

    void rects(String name) {
      rect('$name topCard', edge(cardOf(BallisticsFieldKeys.temperature)));
      rect('$name Basınç Ölçer', header('Basınç Ölçer'));
      rect(
        '$name baroCard',
        edge(find.byKey(const Key('environment-barometer-card'))),
      );
      rect('$name İrtifa', header('İrtifa'));
      rect(
        '$name altCard',
        edge(find.byKey(const Key('environment-altitude-card'))),
      );
      rect('$name Rüzgâr', header('Rüzgâr'));
      rect('$name windCard', edge(cardOf(BallisticsFieldKeys.wind)));
      rect(
        '$name Rüzgâr hızı',
        find.descendant(
          of: find.byKey(BallisticsFieldKeys.wind),
          matching: find.text('Rüzgâr hızı'),
        ),
      );
      rect('$name clockTitle', find.byKey(const ValueKey('wind-clock-title')));
      rect('$name hour12', find.byKey(const ValueKey('wind-clock-12')));
      rect('$name windLabel', find.byKey(const ValueKey('wind-clock-label')));
      rect('$name windDate', find.byKey(const ValueKey('wind-clock-date')));
      rect(
        '$name proButton',
        find.byKey(const Key('environment-continue-pro')),
      );
      rect('$name Hava özeti', header('Hava özeti'));
    }

    for (final size in const [Size(390, 844), Size(320, 568)]) {
      final name = 'hava_${size.width.toInt()}';
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
        await tester.tap(find.text('Hava Durumu').last);
        await settle();
        await shot('${name}_ust');

        // A direction, so line 1 reads "Saat 1 yönünde" over the date.
        final dir = find.descendant(
          of: find.byKey(BallisticsFieldKeys.windDirection),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(dir);
        await settle();
        await tester.enterText(dir, '1');
        await settle();
        FocusManager.instance.primaryFocus?.unfocus();
        await settle();

        // Rüzgâr header at the top of the view.
        final wind = header('Rüzgâr');
        await tester.ensureVisible(wind);
        await settle();
        await Scrollable.ensureVisible(tester.element(wind));
        await settle();
        rects(name);
        await shot('${name}_ruzgar');

        // The clock, the two lines and the button at the bottom.
        final button = find.byKey(const Key('environment-continue-pro'));
        await tester.ensureVisible(button);
        await settle();
        await Scrollable.ensureVisible(tester.element(button), alignment: 1);
        await settle();
        rects('${name}_alt');
        await shot('${name}_dugme');
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
