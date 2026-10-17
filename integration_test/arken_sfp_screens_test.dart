// Screenshot tour for the Arken Optics SFP scopes (owner, 2026-10-17
// 17:59–18:01 Istanbul: "ekle"): Profil → Dürbün list path, Marka Arken
// Optics, Birim MOA, Odak düzlemi SFP, the Model list open (OUTRIDER
// 2-12x42 SFP, OUTRIDER 3-18x50 SFP, LH-6 1-6x24 SFP); then Birim MRAD with
// the Odak düzlemi list open (FFP only). Same mechanics as
// den17b_kule_klik_screens_test.dart (SIMSCREEN:<name> markers,
// sim-screens.yml).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour: Arken Optics SFP', (tester) async {
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

    await wait(3);

    /// Opens the list of the select [key] (a key prefix when [prefix]).
    Future<void> openList(String key, {bool prefix = false}) async {
      final box = prefix
          ? find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(key),
            )
          : find.byKey(Key(key));
      await Scrollable.ensureVisible(tester.element(box.first), alignment: 0.3);
      await settle();
      await tester.tap(box.first);
      await settle();
    }

    Future<void> closeList() async {
      await tester.tapAt(const Offset(2, 2));
      await settle();
    }

    const brand = 'Arken Optics';

    await step('arken_moa_sfp', () async {
      await openTab('Profil');
      await tester.ensureVisible(find.text('İlk profilimi oluştur'));
      await settle();
      await tester.tap(find.text('İlk profilimi oluştur'));
      await settle();
      await choose('scope-brand-select', brand);
      await choose('scope-filter-unit-$brand-null', 'MOA');
      await choose('scope-filter-ffp-$brand-null', 'SFP');
      await scopeCard('arken_moa_sfp');
      await openList('scope-model-select');
      await shot('arken_moa_sfp_model_listesi');
      await closeList();
    });
    await step('arken_outrider_secildi', () async {
      await choose('scope-model-select', 'OUTRIDER 2-12x42 SFP · MOA');
      await openList('scope-reticle');
      await shot('arken_outrider_2_12_retikul_listesi');
      await closeList();
    });
    await step('arken_mrad', () async {
      await choose('scope-filter-unit-$brand-MOA', 'MRAD');
      await openList('scope-filter-ffp-', prefix: true);
      await shot('arken_mrad_odak_listesi');
      await closeList();
    });

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
