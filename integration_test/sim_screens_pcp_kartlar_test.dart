// Screenshot tour for PR #368 (owner, 2026-10-16 20:49–21:04, approved
// drawing): the PCP Tüfek card (Kalibre | Namlu çıkış hızı, Yiv oranı |
// Namlu yiv yönü, Tüp basıncı | Regülatör basıncı, Sıfırlama mesafesi |
// Mesafe birimi, Sight height), the PCP Mühimmat card (Tip | Marka, Model,
// link, Ağırlık | BC, BC modeli, En düşük | En yüksek namlu çıkış hızı), the
// Ateşli Tüfek card, and Hava Durumu and Pro to show the units inside the
// boxes, at 390 pt and at 320 pt wide. Same mechanics as
// sim_screens_test.dart: `SIMSCREEN:<name>` markers are photographed by
// .github/workflows/sim-screens.yml (test input). The narrower widths are
// the app laid out in a 390 / 320 pt wide box at the left of the
// Simulator's screen (its own MediaQuery says 390 / 320 pt); the rest of
// the screen stays black.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart';
import 'package:sniper_turk/services/turret_click_sound.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour: PCP mühimmat', (tester) async {
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

    // A "... listede yok mu?" link: on the Simulator a bottom bar can cover
    // it, so its own action is called.
    Future<void> tapNotListed(String key) async {
      final link = find.byKey(Key(key));
      await tester.ensureVisible(link);
      await settle();
      tester.widget<TextButton>(link).onPressed!();
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

    /// Profil > + (Yeni profil) > Ateşli Tüfek: the Tüfek card, then close.
    Future<void> firearmCard(String name) async {
      await openTab('Profil');
      final add = find.byKey(const Key('profiles-add'));
      await tester.ensureVisible(add);
      await settle();
      await tester.tap(add);
      await settle();
      await choose('profile-platform', 'Ateşli Tüfek');
      await type('profile-velocity-fps', '2650');
      await type('rifle-twist-rate', '11');
      await type('profile-zero', '100');
      await type('scope-sight-height', '45');
      await card('profile-rifle-form', 'scope-sight-height', name);
      await closeEditor();
    }

    await wait(3);
    await width(390);

    var saved = false;
    await step('pcp_390', () async {
      await openTab('Profil');
      await tester.ensureVisible(find.text('İlk profilimi oluştur'));
      await settle();
      await tester.tap(find.text('İlk profilimi oluştur'));
      await settle();
      await choose('profile-platform', 'PCP Tüfek');
      await tapNotListed('rifle-not-listed');
      await type('rifle-brand', 'Test Marka');
      await type('rifle-model', 'Test Model');
      await choose('rifle-caliber', '5.50 mm (.22)');
      await type('profile-velocity-fps', '950');
      await type('rifle-twist-rate', '18');
      await choose('rifle-twist-direction', 'Sağ');
      await type('profile-tube-pressure', '250');
      await type('profile-regulator-pressure', '200');
      await type('profile-zero', '30');
      await choose('profile-distance-unit', 'Metre');
      await type('scope-sight-height', '50');
      await card('profile-rifle-form', 'scope-sight-height', 'pcp_tufek_390');
      await choose('ammo-type', 'Pellet');
      await choose('ammo-brand-select', 'H&N');
      await choose('ammo-model-select', 'Baracuda Match .22 cal. · 21.14 gr');
      await choose('scope-brand-select', 'Element Optics');
      await choose('scope-model-select', 'Titan 5-25x56 FFP MOA');
      await choose('scope-reticle', 'APR-2D MOA');
      await choose('scope-mount', 'Normal (0 MOA)');
      // Only En düşük (owner, 2026-10-17): no warning, Kaydet enabled.
      await type('profile-pcp-velocity-min', '830');
      await card(
        'profile-ammo-form',
        'profile-pcp-velocity-max',
        'pcp_muhimmat_tek_hiz_390',
      );
      expect(find.textContaining('ikisini de girin'), findsNothing);
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await tester.ensureVisible(find.text('Kaydet').last);
      await settle();
      final kaydet = find.ancestor(
        of: find.text('Kaydet').last,
        matching: find.byType(MenzilPrimaryButton),
      );
      expect(tester.widget<MenzilPrimaryButton>(kaydet).onPressed, isNotNull);
      await shot('pcp_tek_hiz_kaydet_390');
      await type('profile-pcp-velocity-max', '860');
      await card(
        'profile-ammo-form',
        'profile-pcp-velocity-max',
        'pcp_muhimmat_390',
      );
      await tester.ensureVisible(find.text('Kaydet').last);
      await settle();
      await tester.tap(find.text('Kaydet').last);
      await settle();
      expect(find.text('Profil Oluştur'), findsNothing);
      saved = true;
    });
    await step('atesli_390', () => firearmCard('atesli_tufek_390'));
    if (saved) {
      await step('hava_390', () async {
        await openTab('Hava Durumu');
        await wait(6);
        await page('hava_durumu_390');
      });
      await step('pro_390', () async {
        await openTab('Pro');
        await page('pro_390');
      });
      await step('hedef_390', () async {
        await openTab('Hedef');
        await wait(2);
        await page('hedef_390');
      });
    }

    await width(320);
    if (saved) {
      await step('pcp_320', () async {
        await openTab('Profil');
        // Düzenle is in the row's ⋯ menu.
        final menu = find.byTooltip('Profil işlemleri').first;
        await tester.ensureVisible(menu);
        await settle();
        await tester.tap(menu);
        await settle();
        await tester.tap(find.text('Düzenle').last);
        await settle();
        expect(find.text('Profili Düzenle'), findsOneWidget);
        await card('profile-rifle-form', 'scope-sight-height', 'pcp_tufek_320');
        await card(
          'profile-ammo-form',
          'profile-pcp-velocity-max',
          'pcp_muhimmat_320',
        );
        await closeEditor();
      });
    }
    await step('atesli_320', () => firearmCard('atesli_tufek_320'));
    if (saved) {
      await step('hava_320', () async {
        await openTab('Hava Durumu');
        await wait(3);
        await page('hava_durumu_320');
      });
      await step('pro_320', () async {
        await openTab('Pro');
        await page('pro_320');
      });
    }

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
