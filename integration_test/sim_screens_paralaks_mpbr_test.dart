// Screenshot tour of Paralaks Mesafesi and Avcı Sıfırı (owner, 2026-10-12).
// Same mechanics as sim_screens_test.dart: `SIMSCREEN:<name>` markers are
// photographed by .github/workflows/sim-screens.yml (test input).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour: paralaks and avcı sıfırı', (tester) async {
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
      // Hold the frame while the workflow saves the Simulator screen.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 4)),
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

    await wait(3);

    await step('profil_olustur_pcp', () async {
      await openTab('Profil');
      await tester.ensureVisible(find.text('İlk profilimi oluştur'));
      await settle();
      await tester.tap(find.text('İlk profilimi oluştur'));
      await settle();
      await choose('profile-platform', 'PCP Tüfek');
    });
    var saved = false;
    await step('profil_kaydet', () async {
      await choose('rifle-brand-select', 'Listede yok');
      await type('rifle-brand', 'Test Marka');
      await type('rifle-model', 'Test Model');
      await tester.ensureVisible(find.byKey(const Key('rifle-caliber')));
      await tester.tap(find.byKey(const Key('rifle-caliber')));
      await settle();
      await tester.tap(find.text('6.35 mm (.25)').last);
      await settle();
      await type('rifle-twist-rate', '16');
      await choose('rifle-twist-direction', 'Sağ');
      await choose('ammo-brand-select', 'Listede yok');
      await type('ammo-brand', 'Test Mühimmat Slug');
      await choose('ammo-type', 'Slug');
      await type('ammo-grain', '33,95');
      await type('ammo-bc', '0,08');
      await choose('ammo-bc-model', 'G1');
      await type('profile-velocity-fps', '900');
      await choose('profile-distance-unit', 'Metre');
      await type('profile-zero', '25');
      await type('scope-sight-height', '60');
      // A catalog scope sold with two reticles ("APR-1C MOA / APR-2D
      // MOA"): Retikül lists both, and the Hedef screenshots show the
      // chosen reticle's own drawing from its manufacturer data.
      await choose('scope-brand-select', 'Element Optics');
      await choose('scope-model-select', 'Titan 5-25x56 FFP MOA');
      await tester.ensureVisible(find.byKey(const Key('scope-reticle')));
      await tester.tap(find.byKey(const Key('scope-reticle')));
      await settle();
      await tester.tap(find.text('APR-2D MOA').last);
      await settle();
      await choose('scope-mount', 'Normal (0 MOA)');
      await settle();
      await tester.ensureVisible(find.text('Kaydet'));
      await settle();
      await tester.tap(find.text('Kaydet'));
      await settle();
      expect(find.text('Yeni Profil'), findsWidgets);
      saved = true;
      await settle();
    });

    if (saved) {
      await step('araclar_pcp', () async {
        await openTab('Araçlar');
        await page('araclar_pcp');
      });
      await step('paralaks_bos', () async {
        await tester.ensureVisible(find.byKey(const Key('tool-parallax')));
        await settle();
        await tester.tap(find.byKey(const Key('tool-parallax')));
        await settle();
        await page('paralaks_bos');
      });
      await step('paralaks_dolu', () async {
        for (final (mark, m) in [('2', '15'), ('4', '25'), ('6', '40'), ('8', '60')]) {
          await type('parallax-mark', mark);
          await type('parallax-distance', m);
          await tester.ensureVisible(find.byKey(const Key('parallax-save')));
          await settle();
          await tester.tap(find.byKey(const Key('parallax-save')));
          await settle();
        }
        await choose('parallax-pick', '5');
        await page('paralaks_dolu');
        await tester.pageBack();
        await settle();
      });
      await step('avci_sifiri_pcp', () async {
        await tester.ensureVisible(find.byKey(const Key('tool-mpbr')));
        await settle();
        await tester.tap(find.byKey(const Key('tool-mpbr')));
        await settle();
        await shot('avci_sifiri_secilmemis');
        await choose('mpbr-zone', '2,5 cm');
        await page('avci_sifiri_pcp');
        await tester.pageBack();
        await settle();
      });
      await step('pro_paralakstan', () async {
        await openTab('Pro');
        await tester.tap(find.byKey(const Key('pro-range-parallax')));
        await settle();
        await choose('parallax-pick', '5');
        await tester.ensureVisible(find.byKey(const Key('parallax-use')));
        await settle();
        await tester.tap(find.byKey(const Key('parallax-use')));
        await settle();
        await page('pro_paralakstan');
      });
    }

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
