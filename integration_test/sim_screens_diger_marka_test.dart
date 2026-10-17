// Screenshot tour for feat/diger-marka-urun-bildir (owner, 2026-10-17
// 21:26–21:53 Istanbul, approved drawings): the Mühimmat card in the
// "Diğer marka" state (PCP 6,35 mm and Ateşli .308 Win), the link
// "Aradığın mühimmat listede yok mu?" at the bottom of the card, and its
// dialog, at 390 pt and at 320 pt wide. Same mechanics as
// sim_screens_pcp_kartlar_test.dart. Gönder is NEVER tapped here: the
// Simulator app uses the real service, and no test request may reach it.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart';
import 'package:sniper_turk/services/turret_click_sound.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour: Diğer marka', (tester) async {
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

    Future<void> openEditor() async {
      await openTab('Profil');
      final first = find.text('İlk profilimi oluştur');
      if (first.evaluate().isNotEmpty) {
        await tester.ensureVisible(first);
        await settle();
        await tester.tap(first);
      } else {
        final add = find.byKey(const Key('profiles-add'));
        await tester.ensureVisible(add);
        await settle();
        await tester.tap(add);
      }
      await settle();
    }

    Future<void> pcpOther(String w) async {
      await choose('profile-platform', 'PCP Tüfek');
      await choose('rifle-caliber', '6.35 mm (.25)');
      await choose('ammo-type', 'Pellet');
      await choose('ammo-brand-select', 'Diğer marka');
      await card(
        'profile-ammo-form',
        'ammo-not-listed',
        'pcp_diger_marka_$w',
      );
    }

    Future<void> firearmOther(String w) async {
      await choose('profile-platform', 'Ateşli Tüfek');
      await choose('rifle-caliber', '.308 Win');
      await choose('ammo-source', 'Fabrika fişeği');
      await choose('ammo-brand-select', 'Diğer marka');
      await type('ammo-grain', '168');
      await type('ammo-bc', '0,462');
      await choose('ammo-bc-model', 'G1');
      await card(
        'profile-ammo-form',
        'ammo-not-listed',
        'atesli_diger_marka_$w',
      );
    }

    /// Opens the dialog, types an example, photographs it and closes it
    /// with Vazgeç (never Gönder).
    Future<void> dialog(String w) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await tapNotListed('ammo-not-listed');
      await shot('dialog_bos_$w');
      final field = find.descendant(
        of: find.byKey(const Key('ammo-report-text')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'H&N Slug HP 50 gr');
      await settle();
      await shot('dialog_$w');
      await tester.tap(find.byKey(const Key('ammo-report-cancel')));
      await settle();
    }

    await wait(3);
    await width(390);
    await step('editor', openEditor);
    await step('pcp_390', () => pcpOther('390'));
    await step('dialog_390', () => dialog('390'));
    await step('atesli_390', () => firearmOther('390'));
    await width(320);
    await step('atesli_320', () => firearmOther('320'));
    await step('dialog_320', () => dialog('320'));
    await step('pcp_320', () => pcpOther('320'));

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
