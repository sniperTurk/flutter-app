// Screenshot tour for "Pro Ayarlar aralıkları" (owner, 2026-10-17
// 20:55–21:01): the real Pro Ayarlar page with every box closed at 390 and
// 320 pt, and Hareketli hedef open at 390 pt. Prints the measured spacing
// as SIMMEASURE lines (card top → Atış mesafesi label, closed header
// heights, gaps between cards). Run with:
//   gh workflow run sim-screens.yml --ref main -f ref=<branch> \
//     -f test=integration_test/sim_screens_pro_aralik_test.dart
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pro Ayarlar aralıkları, 390 ve 320 pt', (tester) async {
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

    Widget app(double width) => MaterialApp(
      theme: MenzilTheme.light(),
      debugShowCheckedModeBanner: false,
      // The page laid out at exactly [width] pt, left-aligned on the screen.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return ColoredBox(
          color: Colors.black,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: MediaQuery(
                data: mq.copyWith(size: Size(width, mq.size.height)),
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

    Rect surface(Key key) => tester.getRect(
      find
          .descendant(of: find.byKey(key), matching: find.byType(Material))
          .first,
    );
    String f(double v) => v.toStringAsFixed(1);

    for (final width in const [390.0, 320.0]) {
      await tester.pumpWidget(app(width));
      await settle();
      final w = width.toStringAsFixed(0);
      final card = surface(const Key('pro-range-card'));
      final label = tester.getRect(
        find.descendant(
          of: find.byKey(const Key('pro-shot-range')),
          matching: find.text('Atış mesafesi'),
        ),
      );
      debugPrint('SIMMEASURE:$w card_top_to_label=${f(label.top - card.top)}');
      var previous = card.bottom;
      for (final id in const [
        'angle',
        'wind',
        'coriolis',
        'gravity',
        'target',
        'rifle',
        'ammo-temp',
      ]) {
        final key = Key('pro-box-$id');
        if (find.byKey(key).evaluate().isEmpty) continue;
        final box = surface(key);
        final header = tester.getRect(find.byKey(Key('pro-section-$id')));
        debugPrint(
          'SIMMEASURE:$w $id height=${f(box.height)} '
          'tap=${f(header.height)} gap=${f(box.top - previous)}',
        );
        previous = box.bottom;
      }
      await shot('pro_aralik_${w}_kapali');
    }

    // Hareketli hedef open at 390 pt: its content is unchanged.
    await tester.pumpWidget(app(390));
    await settle();
    final header = find.byKey(const Key('pro-section-target'));
    await tester.ensureVisible(header);
    await settle();
    await tapProHeader(tester, header);
    await settle();
    await tester.ensureVisible(find.byKey(const Key('pro-box-target')));
    await settle();
    await shot('pro_aralik_390_target_acik');
    debugPrint('SIMSCREEN_DONE failures=0');
  });
}
