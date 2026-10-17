// Screenshot tour for DEN17B-1 (owner, 2026-10-17 11:14 Istanbul): the
// typed Dürbün with Üst kule klik sayısı filled, then Klik değeri changed
// (the count is empty and asked again), then Klik değeri on "Seçiniz"
// (Kaydet blocked, "Kaydetmek için eksik" names it). Same mechanics as
// sim_screens_durbun_test.dart (SIMSCREEN:<name> markers, sim-screens.yml).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour: DEN17B-1 kule klik', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
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

    // A "... listede yok mu?" link (owner, 2026-10-14): on the Simulator a
    // bottom bar can cover it, so its own action is called.
    Future<void> tapNotListed(String key) async {
      final link = find.byKey(Key(key));
      await tester.ensureVisible(link);
      await settle();
      tester.widget<TextButton>(link).onPressed!();
      await settle();
    }

    /// The Dürbün card from its heading down, then the rest of it.
    Future<void> scopeCard(String name) async {
      final card = find.byKey(const Key('profile-scope-form'));
      await Scrollable.ensureVisible(tester.element(card));
      await settle();
      final position = mainScroll();
      if (position != null) {
        // Leave the "Dürbün" heading in view above the card.
        position.jumpTo(
          math.max(position.minScrollExtent, position.pixels - 40),
        );
        await settle();
      }
      await shot(name);
      final bottom = find.byKey(const Key('scope-designation'));
      await Scrollable.ensureVisible(tester.element(bottom), alignment: 0.5);
      await settle();
      await shot('${name}_alt');
    }

    Future<void> rifleAmmoShot() async {
      // A typed PCP rifle and slug, as in the other tours.
      await choose('profile-platform', 'PCP Tüfek');
      await tapNotListed('rifle-not-listed');
      await type('rifle-brand', 'Test Marka');
      await type('rifle-model', 'Test Model');
      await choose('rifle-caliber', '6.35 mm (.25)');
      await type('rifle-twist-rate', '16');
      await choose('rifle-twist-direction', 'Sağ');
      await choose('ammo-type', 'Slug');
      await type('ammo-grain', '33,95');
      await type('ammo-bc', '0,08');
      await type('profile-velocity-fps', '900');
      await choose('profile-distance-unit', 'Metre');
      await type('profile-zero', '25');
      await type('scope-sight-height', '60');
    }

    await wait(3);

    /// The "Kaydetmek için eksik" line and the Kaydet button.
    Future<void> missingShot(String name) async {
      final missing = find.byKey(const Key('profile-missing'));
      final target = missing.evaluate().isEmpty
          ? find.text('Kaydet').last
          : missing;
      await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
      await settle();
      await shot(name);
    }

    await step('elle_kule_dolu', () async {
      await openTab('Profil');
      await tester.ensureVisible(find.text('İlk profilimi oluştur'));
      await settle();
      await tester.tap(find.text('İlk profilimi oluştur'));
      await settle();
      await rifleAmmoShot();
      await tapNotListed('scope-not-listed');
      await type('scope-brand', 'Benim Optik');
      await type('scope-model', 'X5 Pro');
      FocusManager.instance.primaryFocus?.unfocus();
      await choose('scope-unit', 'MRAD');
      await choose('scope-focal-plane', 'FFP');
      await choose('scope-min-mag', '5x');
      await choose('scope-max-mag', '25x');
      await choose('scope-objective', '56 mm');
      await choose('scope-click', '0,1 MRAD');
      await type('scope-travel-elevation', '200');
      FocusManager.instance.primaryFocus?.unfocus();
      await choose('scope-mount', 'Normal (0 MOA)');
      await choose('scope-reticle', 'Mil-Dot');
      FocusManager.instance.primaryFocus?.unfocus();
      await scopeCard('durbun_elle_kule_200');
      await missingShot('kaydet_acik');
    });
    await step('klik_degisti', () async {
      await choose('scope-click', '0,05 MRAD');
      FocusManager.instance.primaryFocus?.unfocus();
      await scopeCard('durbun_klik_005_kule_bos');
      await missingShot('klik_005_kaydet');
    });
    await step('klik_seciniz', () async {
      await choose('scope-click', 'Seçiniz');
      FocusManager.instance.primaryFocus?.unfocus();
      await scopeCard('durbun_klik_seciniz_kule_bos');
      await missingShot('klik_seciniz_kaydet_kapali');
    });

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
