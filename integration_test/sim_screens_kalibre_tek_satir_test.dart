// Screenshot tour for fix/kalibre-tek-satir (owner, 2026-10-17 17:54–18:05,
// TestFlight 113): every closed select box shows its value on ONE line at
// the normal size, cut with "…" when it does not fit ("C: mühimmattaki
// gibi, sığdığı kadar görünür"); Sight height is a half box ("Tabiki A").
// Profil > Tüfek (Beretta BRX1 / .30-06 Springfield), Mühimmat (Federal
// Gold Medal Sierra MatchKing 168 gr), Dürbün from the catalog (Arken
// Optics SH-4J GENII) and the PCP Tüfek card, at 390 pt. Same mechanics as
// sim_screens_pcp_kartlar_test.dart: `SIMSCREEN:<name>` markers are
// photographed by .github/workflows/sim-screens.yml (test input).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart';
import 'package:sniper_turk/services/turret_click_sound.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour: select boxes on one line', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    // As main(), with the app in a box of [appWidth] points.
    TurretClickSound.instance = AudioTurretClickSound();
    final appWidth = ValueNotifier<double>(390);
    await tester.pumpWidget(
      ValueListenableBuilder<double>(
        valueListenable: appWidth,
        builder: (context, width, _) {
          final data = MediaQueryData.fromView(View.of(context));
          return ColoredBox(
            color: const Color(0xFF000000),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: MediaQuery(
                  data: data.copyWith(size: Size(width, data.size.height)),
                  child: const SniperTurkApp(),
                ),
              ),
            ),
          );
        },
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
        // A page with a running animation (spinner, compass) never settles.
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
      final id = '${counter.toString().padLeft(2, '0')}_$name';
      debugPrint('SIMSCREEN:$id');
      // The marker reached the log late (4 s and 10 s holds photographed a
      // later frame): a filler line pushes it out, and the frame is held
      // longer.
      debugPrint('SIMPAD:${'.' * 4000}');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 20)),
      );
    }

    /// The page's main vertical scroll view: the tallest one on screen.
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
            position.viewportDimension > best.viewportDimension ||
            (position.viewportDimension == best.viewportDimension &&
                position.maxScrollExtent > best.maxScrollExtent)) {
          best = position;
        }
      }
      return best;
    }

    Future<void> step(String name, Future<void> Function() body) async {
      try {
        await body();
      } catch (error) {
        final line = error.toString().split('\n').first;
        failures.add('$name: $line');
        debugPrint('SIMSTEP_FAIL:$name: $line');
        await shot('FAIL_$name');
        // Close a menu or sub-page left open so the next step starts clean.
        try {
          tester
              .state<NavigatorState>(find.byType(Navigator).first)
              .popUntil((route) => route.isFirst);
          await settle();
        } catch (_) {
          // Nothing to close.
        }
      }
      final exception = tester.takeException();
      if (exception != null) {
        final line = exception.toString().split('\n').first;
        failures.add('$name: $line');
        debugPrint('SIMSTEP_FAIL:$name: $line');
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
      await tester.pump();
    }

    Future<void> choose(String key, String label) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
      await settle();
      final item = find.text(label);
      if (item.evaluate().isEmpty) {
        await tester.dragUntilVisible(
          item,
          find.byType(Scrollable).last,
          const Offset(0, -300),
        );
      }
      await tester.ensureVisible(item.last);
      await settle();
      await tester.tap(item.last);
      await settle();
    }

    /// Lays the app out [points] wide (the left part of the screen).
    Future<void> width(double points) async {
      appWidth.value = points;
      await settle();
    }

    /// The card [key] from its heading down, then its lower part down to
    /// [bottomKey].
    Future<void> card(String key, String bottomKey, String name) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await Scrollable.ensureVisible(tester.element(find.byKey(Key(key))));
      await settle();
      final position = mainScroll();
      if (position != null) {
        position.jumpTo(
          math.max(position.minScrollExtent, position.pixels - 40),
        );
        await settle();
      }
      await shot(name);
      await Scrollable.ensureVisible(
        tester.element(find.byKey(Key(bottomKey))),
        alignment: 0.85,
      );
      await settle();
      await shot('${name}_alt');
    }

    Future<void> closeEditor() async {
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .popUntil((route) => route.isFirst);
      await settle();
    }

    /// Profil > Yeni profil (the first one, or + when there are some).
    Future<void> newProfile(String platform) async {
      await openTab('Profil');
      final add = find.byKey(const Key('profiles-add'));
      final first = find.text('İlk profilimi oluştur');
      final target = add.evaluate().isNotEmpty ? add : first;
      await tester.ensureVisible(target);
      await settle();
      await tester.tap(target);
      await settle();
      await choose('profile-platform', platform);
    }

    await wait(3);
    await width(390);

    await step('atesli_390', () async {
      await newProfile('Ateşli Tüfek');
      await choose('rifle-brand-select', 'Beretta');
      await choose('rifle-model-select', 'BRX1');
      await choose('rifle-caliber', '.30-06 Springfield');
      await type('profile-velocity-fps', '2700');
      await type('rifle-twist-rate', '10');
      await choose('rifle-twist-direction', 'Sağ');
      await type('profile-zero', '100');
      await choose('profile-distance-unit', 'Metre');
      await type('scope-sight-height', '45');
      await card('profile-rifle-form', 'scope-sight-height', 'tufek_brx1_390');
      await choose('ammo-source', 'Fabrika fişeği');
      await choose('ammo-brand-select', 'Federal');
      await choose(
        'ammo-model-select',
        'Gold Medal Sierra MatchKing 168 gr Sierra MatchKing BTHP',
      );
      await card('profile-ammo-form', 'ammo-bc', 'muhimmat_gold_medal_390');
      await choose('scope-brand-select', 'Arken Optics');
      await choose('scope-model-select', 'SH-4J GENII 6–24×50 FFP VPR (MRAD)');
      await card('profile-scope-form', 'scope-reticle', 'durbun_sh4j_390');
      await closeEditor();
    });
    await step('pcp_390', () async {
      await newProfile('PCP Tüfek');
      await choose('rifle-brand-select', 'Hatsan');
      await choose('rifle-model-select', 'Hercules');
      await choose('rifle-caliber', '11.43 mm (.45)');
      await type('profile-velocity-fps', '900');
      await type('profile-zero', '30');
      await type('scope-sight-height', '50');
      await card('profile-rifle-form', 'scope-sight-height', 'pcp_tufek_390');
      await closeEditor();
    });

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
