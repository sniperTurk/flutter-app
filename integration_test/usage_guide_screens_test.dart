// Screenshot tour of Araçlar > Kullanım rehberi only (owner draft,
// 2026-10-11). Run through .github/workflows/sim-screens.yml with
// test=integration_test/usage_guide_screens_test.dart; like
// sim_screens_test.dart it prints `SIMSCREEN:<name>` and holds the frame
// while the workflow saves the Simulator screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour of Kullanım rehberi', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    app.main();

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

    var counter = 0;
    Future<void> shot(String name) async {
      await settle();
      counter++;
      debugPrint('SIMSCREEN:${counter.toString().padLeft(2, '0')}_$name');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 4)),
      );
    }

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await settle();

    await tester.tap(find.text('Araçlar').last);
    await settle();
    final tile = find.byKey(const Key('tool-usage-guide'));
    await tester.ensureVisible(tile);
    await settle();
    await shot('araclar_rehber');

    await tester.tap(tile);
    await settle();
    expect(find.byKey(const Key('usage-guide-page')), findsOneWidget);
    await shot('rehber');

    // One screenshot per screen height down to the end of the page.
    final scrollable = find.descendant(
      of: find.byKey(const Key('usage-guide-page')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable.first).position;
    for (var part = 2; part <= 20; part++) {
      if (position.pixels >= position.maxScrollExtent - 1) break;
      position.jumpTo(
        (position.pixels + position.viewportDimension * 0.85).clamp(
          0.0,
          position.maxScrollExtent,
        ),
      );
      await shot('rehber_$part');
    }
    expect(tester.takeException(), isNull);
  });
}
