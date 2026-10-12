// Screenshot tour for Ö12 (WEZ ortak hata) and Ö5 (kararlılık, transonik),
// owner 2026-10-11. Run once with:
//   gh workflow run sim-screens.yml --ref main -f ref=<branch> \
//     -f test=integration_test/sim_screens_wez_test.dart
// Same SIMSCREEN marker protocol as sim_screens_test.dart. The steps live in
// wez_tour.dart; test/wez_tour_smoke_test.dart runs them on the host first.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wez_tour.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WEZ ve kararlılık ekranları', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    var counter = 0;
    await runWezTour(
      tester,
      shot: (name) async {
        counter++;
        debugPrint('SIMSCREEN:${counter.toString().padLeft(2, '0')}_$name');
        // Hold the frame while the workflow saves the Simulator screen.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 4)),
        );
      },
      log: debugPrint,
    );
    debugPrint('SIMSCREEN_DONE failures=0');
  });
}
