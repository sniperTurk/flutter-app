// Screenshots of the Kronograf page and the firearm Hava Durumu row
// (Ö3 / Ö1, 2026-10-12). Run once by .github/workflows/sim-screens.yml with
// `test: integration_test/chrono_screens_test.dart`; same SIMSCREEN markers
// as sim_screens_test.dart.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/chrono_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

const _profile = RifleProfile(
  id: 'sim-308',
  name: 'Ateşli 308',
  rifleId: 'ata-turqua-308',
  ammunitionId: 'firearm-manual',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Kronograf and Mühimmat sıcaklığı screenshots', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await PersistentProfileStore().save(_profile);
    await PersistentActiveProfileStore().setActiveProfileId(_profile.id);
    // One string measured in winter, so the page can fit the coefficient
    // after today's string is saved.
    await const ChronoStore().add(
      _profile.id,
      ChronoSession(
        date: DateTime.utc(2026, 2, 3, 10),
        tempC: 4,
        mps: const [789, 791, 788, 790, 792, 789, 790, 791, 788, 790],
      ),
    );
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
      debugPrint('SIMSCREEN:${counter.toString().padLeft(2, '0')}_$name');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 4)),
      );
    }

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
            position.viewportDimension > best.viewportDimension) {
          best = position;
        }
      }
      return best;
    }

    Future<void> page(String name) async {
      mainScroll()?.jumpTo(0);
      await shot(name);
      for (var part = 2; part <= 6; part++) {
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
      await settle();
    }

    Future<void> choose(String key, String label) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
      await settle();
      await tester.tap(find.text(label).last);
      await settle();
    }

    await wait(3);
    await step('araclar', () async {
      await openTab('Araçlar');
      await page('araclar');
    });
    await step('kronograf_bos', () async {
      await tester.tap(find.byKey(const Key('tool-chrono')));
      await settle();
      await page('kronograf_bos');
    });
    await step('kronograf_dolu', () async {
      await choose('chrono-unit', 'fps');
      await type('chrono-ammo-temp', '32');
      await type('chrono-velocities', '2631\n2618\n2640\n2627\n2622');
      tester.testTextInput.hide();
      await settle();
      await tester.ensureVisible(find.byKey(const Key('chrono-save-series')));
      await tester.tap(find.byKey(const Key('chrono-save-series')));
      await wait(1);
      await page('kronograf_dolu');
      await tester.pageBack();
      await settle();
    });
    await step('hava_durumu_atesli', () async {
      await openTab('Hava Durumu');
      await wait(6);
      await type('env-ammo-temp', '32');
      tester.testTextInput.hide();
      await settle();
      await page('hava_durumu_atesli');
    });

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
