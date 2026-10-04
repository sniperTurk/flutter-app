import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;

/// App Store screenshot walk-through. Not a release gate and not run by
/// `iOS CI`; `.github/workflows/app-store-screenshots.yml` runs it on a booted
/// Simulator and captures each screen with `xcrun simctl io screenshot` when
/// it sees an `APPSTORE_SHOT:<name>` marker on the test output.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    debugPrint('APPSTORE_SHOT:$name');
    // Give the host time to see the marker and grab the Simulator screen.
    await Future<void>.delayed(const Duration(seconds: 6));
  }

  testWidgets('App Store screenshot walk-through', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    app.main();
    await tester.pumpAndSettle();

    // Create one profile so the ballistic screens are unlocked.
    await tester.tap(find.text('Profil').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yeni profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    await shot(tester, '05_profil');

    await tester.tap(find.text('Atış').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hesapla').first);
    await shot(tester, '01_atis');

    await tester.tap(find.text('Tablo').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DOPE oluştur'));
    await shot(tester, '02_tablo');

    await tester.tap(find.text('Ortam').first);
    await shot(tester, '03_ortam');

    await tester.tap(find.text('Araçlar').first);
    await shot(tester, '04_araclar');

    await tester.tap(find.text('Katalog').first);
    await shot(tester, '06_katalog');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ayarlar').first);
    await shot(tester, '07_ayarlar');
    await tester.pageBack();
    await tester.pumpAndSettle();

    debugPrint('APPSTORE_SHOT:DONE');
  });
}
