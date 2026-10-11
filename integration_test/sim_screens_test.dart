// Screenshot tour of the main pages on an iOS Simulator (owner, 2026-10-11).
//
// Run by .github/workflows/sim-screens.yml. The test itself takes no
// screenshot: before each one it prints `SIMSCREEN:<name>` and holds the
// frame for a few seconds; the workflow watches the log and saves the real
// Simulator screen with `xcrun simctl io <udid> screenshot <name>.png`.
//
// A step that fails is logged as `SIMSTEP_FAIL:<step>: <error>`, gets a
// FAIL_ screenshot and the tour goes on, so one broken page does not hide the
// others. The test still fails at the end when any step failed.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour of the main pages', (tester) async {
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

    // ---- Clean install: no profile yet ---------------------------------
    await step('profil_karsilama', () => page('profil_karsilama'));
    await step('hava_durumu_bos', () async {
      await openTab('Hava Durumu');
      await wait(6); // live weather for the simulated location
      await page('hava_durumu_bos');
    });
    await step('pro_ayarlar_bos', () async {
      await openTab('Pro');
      await page('pro_ayarlar_bos');
    });
    await step('hedef_bos', () async {
      await openTab('Hedef');
      await page('hedef_bos');
    });
    await step('araclar', () async {
      await openTab('Araçlar');
      await page('araclar');
    });
    await step('hesaplayicilar', () async {
      await tester.ensureVisible(find.text('Hesaplayıcılar').first);
      await settle();
      await tester.tap(find.text('Hesaplayıcılar').first);
      await settle();
      await page('hesaplayicilar');
      await tester.pageBack();
      await settle();
    });

    // ---- Profil Oluştur: PCP, then Ateşli ------------------------------
    await step('profil_olustur_pcp', () async {
      await openTab('Profil');
      await tester.ensureVisible(find.text('İlk profilimi oluştur'));
      await settle();
      await tester.tap(find.text('İlk profilimi oluştur'));
      await settle();
      expect(find.text('Profil Oluştur'), findsOneWidget);
      // A new profile starts on Ateşli Tüfek (owner, 2026-10-11).
      await choose('profile-platform', 'PCP Tüfek');
      await page('profil_olustur_pcp');
    });
    await step('profil_olustur_atesli', () async {
      await choose('profile-platform', 'Ateşli Tüfek');
      await page('profil_olustur_atesli');
      await choose('profile-platform', 'PCP Tüfek');
    });

    // ---- Save a PCP profile so the ballistic pages unlock --------------
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
      await shot('profil_retikul_liste');
      await tester.tap(find.text('APR-2D MOA').last);
      await settle();
      await choose('scope-mount', 'Normal (0 MOA)');
      await page('profil_olustur_dolu');
      await tester.ensureVisible(find.text('Kaydet'));
      await settle();
      await tester.tap(find.text('Kaydet'));
      await settle();
      expect(find.text('Yeni Profil'), findsWidgets);
      saved = true;
      await page('profil_kayitli');
    });

    if (saved) {
      await step('hava_durumu', () async {
        await openTab('Hava Durumu');
        await wait(6);
        await page('hava_durumu');
      });
      await step('pro_ayarlar', () async {
        await openTab('Pro');
        await page('pro_ayarlar');
      });
      await step('hedef_atis', () async {
        await openTab('Hedef');
        await wait(2);
        await page('hedef_atis');
      });
      await step('hedef_tablo', () async {
        await tester.tap(find.text('Tablo').first);
        await settle();
        await tester.tap(find.text('DOPE oluştur'));
        await settle();
        await page('hedef_tablo');
      });
    }

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
