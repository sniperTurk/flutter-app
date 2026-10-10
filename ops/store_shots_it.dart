// App Store screenshots on the iOS Simulator. The host takes a real
// screenshot (`simctl io screenshot`) each time a STORE_SHOT line is printed.
// Ops only; never part of the app.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/app_settings.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _ammo = <String, dynamic>{
  'id': 'manual_ammo_308',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': '.308 Win',
  'model': '168 gr HPBT',
  'caliberMm': 7.62,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.462,
  'bcModel': 'g1',
};
const _profile = RifleProfile(
  id: 'p-store',
  name: 'Turqua .308',
  rifleId: 'ata-turqua-308',
  ammunitionId: 'manual_ammo_308',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screenshots', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (const bool.fromEnvironment('EMPTY_SHOTS') == false) {
      await prefs.setString(ManualCatalogStore.key, jsonEncode([_ammo]));
      await PersistentProfileStore().save(_profile);
      await PersistentActiveProfileStore().setActiveProfileId('p-store');
    }

    final settings = AppSettings();
    await settings.load();
    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: ToolsServicesScope(
          services: ToolsServices.production(),
          child: MenzilThemeScope(
            controller: MenzilThemeController(),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'SNIPER TÜRK',
              theme: MenzilTheme.light(),
              home: const HomeScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> shot(String name) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 800));
      // Handshake with the host: it screenshots and deletes the file.
      final req = File('${Directory.systemTemp.path}/store_shot_$name');
      req.writeAsStringSync(name);
      for (var i = 0; i < 120 && req.existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    Future<void> tab(String label) async {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    if (const bool.fromEnvironment('EMPTY_SHOTS')) {
      await shot('e1-profil');
      await tab('Hava Durumu');
      await shot('e2-hava');
      await tab('Pro');
      await shot('e3-pro');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await shot('e3b-pro-alt');
      await tab('Hedef');
      await shot('e4-hedef');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await shot('e4b-hedef-alt');
      return;
    }
    await tab('Pro');
    await tester.ensureVisible(find.byKey(const Key('pro-section-gravity')));
    await tester.tap(find.byKey(const Key('pro-section-gravity')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pro-gravity-switch')));
    await tester.tap(find.byKey(const Key('pro-gravity-switch')));
    await tester.pumpAndSettle();
    final gf = find.descendant(
      of: find.byKey(const Key('pro-gravity')),
      matching: find.byType(TextField),
    );
    await tester.enterText(gf, '9.7988');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pro-section-gravity')));
    await shot('g1-yercekimi');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
    await shot('g2-yercekimi-alt');
  });
}
