// Screenshot tour of Profil Oluştur / Profili Düzenle -> Dürbün (owner,
// 2026-10-16): the list path (Marka, filters, Model, Retikül) and the typed
// path (Dürbün markası | Dürbün modeli ...), saved and opened again. Same
// mechanics as sim_screens_test.dart: `SIMSCREEN:<name>` markers are
// photographed by .github/workflows/sim-screens.yml (test input).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour: dürbün girişi', (tester) async {
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

    /// Screenshots of the whole page: top, then one per screen height.
    Future<void> page(String name) async {
      final top = mainScroll();
      if (top != null && top.pixels > top.minScrollExtent) {
        top.jumpTo(top.minScrollExtent);
        await settle();
      }
      await shot(name);
      for (var part = 2; part <= 10; part++) {
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
        await settle();
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

    Future<void> save(String label) async {
      await tester.ensureVisible(find.text(label).last);
      await settle();
      await tester.tap(find.text(label).last);
      await settle();
    }

    await wait(3);

    Future<void> openEditorOf(int index) async {
      // Düzenle is in the row's ⋯ menu (owner, 2026-10-14).
      final menus = find.byTooltip('Profil işlemleri');
      await tester.ensureVisible(menus.at(index));
      await settle();
      await tester.tap(menus.at(index));
      await settle();
      await tester.tap(find.text('Düzenle').last);
      await settle();
      expect(find.text('Profili Düzenle'), findsOneWidget);
    }

    Future<void> closeEditor() async {
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .popUntil((route) => route.isFirst);
      await settle();
    }

    // ---- Typed path first: the first saved profile is the active one, so
    // its summary card is on the Profil page. ----
    var typedSaved = false;
    await step('elle_dolu', () async {
      await openTab('Profil');
      await tester.ensureVisible(find.text('İlk profilimi oluştur'));
      await settle();
      await tester.tap(find.text('İlk profilimi oluştur'));
      await settle();
      await rifleAmmoShot();
      await tapNotListed('scope-not-listed');
      await scopeCard('durbun_elle_bos');
      await type('scope-brand', 'Benim Optik');
      await type('scope-model', 'X5 Pro');
      await choose('scope-min-mag', '5x');
      await choose('scope-max-mag', '25x');
      await choose('scope-objective', '56 mm');
      await choose('scope-focal-plane', 'FFP');
      await choose('scope-unit', 'MRAD');
      await choose('scope-click', '0,1 MRAD');
      await type('scope-travel-elevation', '200');
      await choose('scope-mount', 'Normal (0 MOA)');
      await choose('scope-reticle', 'Mil-Dot');
      FocusManager.instance.primaryFocus?.unfocus();
      await scopeCard('durbun_elle_dolu');
      await save('Kaydet');
      expect(find.text('Profil Oluştur'), findsNothing);
      typedSaved = true;
    });
    if (typedSaved) {
      await step('elle_ozet', () async {
        await page('profil_ozet_elle');
      });
      await step('elle_duzenle', () async {
        await openEditorOf(0);
        await scopeCard('durbun_elle_duzenle');
        await closeEditor();
      });
    }

    // ---- List path ----
    var listSaved = false;
    await step('liste_dolu', () async {
      await tester.ensureVisible(find.text('Profil ekle'));
      await settle();
      await tester.tap(find.text('Profil ekle'));
      await settle();
      expect(find.text('Profil Oluştur'), findsOneWidget);
      await scopeCard('durbun_liste_marka_secilmedi');
      await rifleAmmoShot();
      await choose('scope-brand-select', 'Element Optics');
      await choose('scope-filter-unit-Element Optics-null', 'MOA');
      await choose('scope-filter-ffp-Element Optics-null', 'FFP');
      await choose('scope-model-select', 'Titan 5-25x56 FFP MOA');
      await choose('scope-reticle', 'APR-2D MOA');
      await choose('scope-mount', 'Normal (0 MOA)');
      await scopeCard('durbun_liste_dolu');
      await save('Kaydet');
      expect(find.text('Profil Oluştur'), findsNothing);
      listSaved = true;
    });
    if (listSaved) {
      await step('liste_duzenle', () async {
        await openEditorOf(1);
        await scopeCard('durbun_liste_duzenle');
        await closeEditor();
      });
    }

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
