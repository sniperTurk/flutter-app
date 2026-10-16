// Screenshot tour for "Pro kutularından ⓘ kaldır" (owner, 2026-10-16
// 21:17): the real Pro Ayarlar page at 390 pt with Hareketli hedef and
// Tüfek düzeltmeleri open, plus the Hareketli hedef title ⓘ sheet. Run with:
//   gh workflow run sim-screens.yml --ref main -f ref=<branch or sha> \
//     -f test=integration_test/sim_screens_pro_kutu_test.dart
// Same SIMSCREEN marker protocol as sim_screens_test.dart. Uses only keys
// that exist before and after the change, so it photographs both.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import '../test/support/pro_sections.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_sim',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_sim',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 168',
  'model': '',
  'caliberMm': 7.62,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.462,
  'bcModel': 'g1',
};
const _profile = RifleProfile(
  id: 'p-sim',
  name: 'Test 308',
  rifleId: 'manual_rifle_sim',
  ammunitionId: 'manual_ammo_sim',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

/// Layout width of the photographed page (owner: 390 pt).
const _width = 390.0;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pro Ayarlar kutuları, 390 pt', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
    var counter = 0;
    Future<void> shot(String name) async {
      counter++;
      debugPrint('SIMSCREEN:${counter.toString().padLeft(2, '0')}_$name');
      // Hold the frame while the workflow saves the Simulator screen.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 4)),
      );
    }

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

    Widget app() => MaterialApp(
      theme: MenzilTheme.light(),
      debugShowCheckedModeBanner: false,
      // The page laid out at exactly 390 pt, left-aligned on the screen.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return ColoredBox(
          color: Colors.black,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _width,
              child: MediaQuery(
                data: mq.copyWith(size: Size(_width, mq.size.height)),
                child: child!,
              ),
            ),
          ),
        );
      },
      home: const Scaffold(
        body: SafeArea(
          child: BallisticsScreen(profile: _profile, view: BallisticsView.pro),
        ),
      ),
    );

    for (final id in ['target', 'rifle']) {
      await tester.pumpWidget(app());
      await settle();
      final header = find.byKey(Key('pro-section-$id'));
      await tester.ensureVisible(header);
      await settle();
      await tapProHeader(tester, header);
      await settle();
      // The opened box at the top of the screen.
      await tester.ensureVisible(find.byKey(Key('pro-box-$id')));
      await settle();
      await shot('pro_${id}_acik');
      if (id == 'target') {
        await tester.tap(find.byKey(const Key('pro-info-target')));
        await settle();
        await shot('pro_target_baslik_bilgi');
        // Its "Kutular" list (every box of the section, with its text).
        await tester.ensureVisible(find.byKey(const Key('pro-info-fields')));
        await settle();
        await shot('pro_target_baslik_bilgi_kutular');
        await tester.tap(find.byKey(const Key('pro-info-close')));
        await settle();
      }
    }
    debugPrint('SIMSCREEN_DONE failures=0');
  });
}
