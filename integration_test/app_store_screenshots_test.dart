import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

// Example profiles a user could create from the bundled catalog, so the
// screenshots do not show the clean-install default "Yeni Profil".
const _profiles = [
  RifleProfile(
    id: 'shot-hercules-gmaz',
    name: 'Hercules 6.35 · G Maz 51 gr',
    rifleId: 'hatsan-hercules-635',
    ammunitionId: 'gmaz-51',
    scopeId: 'gazi-6-36',
    muzzleVelocityMps: 270,
    zeroRangeM: 25,
    sightHeightMm: 60,
    pressureBar: 200,
  ),
  RifleProfile(
    id: 'shot-hercules-jsb',
    name: 'Hercules 6.35 · JSB 33,95 gr',
    rifleId: 'hatsan-hercules-635',
    ammunitionId: 'jsb-exact-king-heavy-25',
    scopeId: 'gazi-6-36',
    muzzleVelocityMps: 285,
    zeroRangeM: 30,
    sightHeightMm: 60,
    pressureBar: 200,
  ),
  RifleProfile(
    id: 'shot-turqua-308',
    name: 'Ateşli · .308 tatbikat',
    rifleId: 'ata-turqua-308',
    ammunitionId: 'firearm-manual',
    scopeId: 'gazi-6-36',
    muzzleVelocityMps: 790,
    zeroRangeM: 100,
    sightHeightMm: 45,
  ),
];

/// App Store screenshot walk-through. Not a release gate and not run by
/// `iOS CI`; `.github/workflows/app-store-screenshots.yml` runs it on a booted
/// Simulator and captures each screen with `xcrun simctl io screenshot` when
/// it sees an `APPSTORE_SHOT:<name>` marker on the test output.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Fixed-duration pumping instead of pumpAndSettle: some screens animate
  // continuously and would never settle.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester);
    expect(tester.takeException(), isNull);
    debugPrint('APPSTORE_SHOT:$name');
    // Give the host time to see the marker and grab the Simulator screen.
    await Future<void>.delayed(const Duration(seconds: 6));
  }

  testWidgets('App Store screenshot walk-through', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    final store = PersistentProfileStore();
    for (final p in _profiles) {
      await store.save(p);
    }
    await PersistentActiveProfileStore().setActiveProfileId(_profiles[0].id);
    app.main();
    await settle(tester);
    await settle(tester);

    await tester.tap(find.text('Profil').first);
    await shot(tester, '05_profil');

    await tester.tap(find.text('Atış').first);
    await settle(tester);
    await tester.tap(find.text('Hesapla').first);
    await shot(tester, '01_atis');

    await tester.tap(find.text('Tablo').first);
    await settle(tester);
    await tester.tap(find.text('DOPE oluştur'));
    await shot(tester, '02_tablo');

    await tester.tap(find.text('Ortam').first);
    await shot(tester, '03_ortam');

    await tester.tap(find.text('Araçlar').first);
    await shot(tester, '04_araclar');

    await tester.tap(find.text('Katalog').first);
    await shot(tester, '06_katalog');
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.text('Ayarlar').first);
    await shot(tester, '07_ayarlar');
    await tester.pageBack();
    await settle(tester);

    debugPrint('APPSTORE_SHOT:DONE');
  });
}
