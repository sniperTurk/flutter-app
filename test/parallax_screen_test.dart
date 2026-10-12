// Ö8 Paralaks Mesafesi page: recording wheel marks, picking one in the
// field, handing the distance back to Pro, PCP-only visibility.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/parallax_range.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/features/tools/parallax_screen.dart';
import 'package:sniper_turk/features/tools/tools_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/parallax_table_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _pcp = RifleProfile(
  id: 'p-pcp',
  name: 'PCP',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-plx',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _pcpYard = RifleProfile(
  id: 'p-pcp-yd',
  name: 'PCP yd',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-plx',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  distanceUnit: DistanceUnit.yard,
);

const _ammo = <String, dynamic>{
  'id': 'c-plx',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.25 pellet',
  'caliberMm': 6.35,
  'grain': 25.4,
  'ammoType': 'pellet',
  'bc': 0.04,
  'bcModel': 'G1',
};

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_plx',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _fireAmmo = <String, dynamic>{
  'id': 'manual_ammo_plx',
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
const _firearm = RifleProfile(
  id: 'p-fire',
  name: 'NX',
  rifleId: 'manual_rifle_plx',
  ammunitionId: 'manual_ammo_plx',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

Widget _app(Widget home) => MaterialApp(theme: MenzilTheme.light(), home: home);

Future<void> _sized(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _pumpScreen(WidgetTester tester, RifleProfile p) async {
  await _sized(tester);
  final store = MemoryProfileStore();
  await store.save(p);
  await tester.pumpWidget(
    _app(
      ParallaxScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore()..value = p.id,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  final f = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _record(WidgetTester tester, String mark, String distance) async {
  await _type(tester, 'parallax-mark', mark);
  await _type(tester, 'parallax-distance', distance);
  await _tap(tester, find.byKey(const Key('parallax-save')));
}

Future<void> _pick(WidgetTester tester, String label) async {
  await _tap(tester, find.byKey(const Key('parallax-pick')));
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Metric tiles print "value unit" as one rich text.
Finder _inResult(Pattern text) => find.descendant(
  of: find.byKey(const Key('parallax-result')),
  matching: find.textContaining(text),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_ammo, _rifle, _fireAmmo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('two marks recorded: a midpoint gives the interpolated range', (
    tester,
  ) async {
    await _pumpScreen(tester, _pcp);
    expect(find.byKey(const Key('parallax-need-two')), findsOneWidget);
    await _record(tester, '10', '20');
    expect(find.byKey(const Key('parallax-need-two')), findsOneWidget);
    expect(find.byKey(const Key('parallax-pick')), findsNothing);
    await _record(tester, '20', '40');
    expect(find.byKey(const Key('parallax-need-two')), findsNothing);
    await _pick(tester, '15');
    expect(_inResult(RegExp(r'^30 ')), findsOneWidget);
    // Saved per profile, in metres.
    final saved = await const ParallaxTableStore().load(_pcp.id);
    expect(saved.map((p) => p.mark), [10, 20]);
    expect(saved.map((p) => p.distanceM), [20, 40]);
  });

  testWidgets('every entered value has its ⓘ, no helper text', (tester) async {
    await const ParallaxTableStore().save(_pcp.id, const [
      ParallaxPoint(mark: 10, distanceM: 20),
      ParallaxPoint(mark: 20, distanceM: 40),
    ]);
    await _pumpScreen(tester, _pcp);
    expect(find.byTooltip('Bilgi: İşaret'), findsOneWidget);
    expect(find.byTooltip('Bilgi: Mesafe'), findsOneWidget);
    expect(find.byTooltip('Bilgi: Tekerlek işareti'), findsOneWidget);
    for (final w in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(w.decoration?.helperText, isNull);
      expect(w.decoration?.hintText, isNull);
    }
    expect(find.text('Seçiniz'), findsOneWidget);
  });

  testWidgets('a mark can be deleted', (tester) async {
    await const ParallaxTableStore().save(_pcp.id, const [
      ParallaxPoint(mark: 10, distanceM: 20),
      ParallaxPoint(mark: 20, distanceM: 40),
    ]);
    await _pumpScreen(tester, _pcp);
    await _tap(tester, find.byKey(const Key('parallax-del-0')));
    expect(find.byKey(const Key('parallax-need-two')), findsOneWidget);
    final saved = await const ParallaxTableStore().load(_pcp.id);
    expect(saved.map((p) => p.mark), [20]);
  });

  testWidgets('an invalid distance is refused', (tester) async {
    await _pumpScreen(tester, _pcp);
    await _record(tester, '10', '0');
    expect(find.text('Mesafe 1 ile 300 m arasında olmalı.'), findsOneWidget);
    expect(await const ParallaxTableStore().load(_pcp.id), isEmpty);
  });

  testWidgets('a yard profile shows yards and stores metres', (tester) async {
    await _pumpScreen(tester, _pcpYard);
    await _record(tester, '10', '20');
    await _record(tester, '20', '40');
    await _pick(tester, '15');
    expect(_inResult(RegExp(r'^30 ')), findsOneWidget);
    expect(_inResult(RegExp(r'^30 yd')), findsWidgets);
    final saved = await const ParallaxTableStore().load(_pcpYard.id);
    expect(saved.first.distanceM, closeTo(18.288, 1e-6));
  });

  testWidgets('returnDistance: the picked range goes back in metres', (
    tester,
  ) async {
    await _sized(tester);
    await const ParallaxTableStore().save(_pcp.id, const [
      ParallaxPoint(mark: 10, distanceM: 20),
      ParallaxPoint(mark: 20, distanceM: 40),
    ]);
    double? got;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              got = await Navigator.push<double>(
                context,
                MaterialPageRoute<double>(
                  builder: (_) =>
                      const ParallaxScreen(profile: _pcp, returnDistance: true),
                ),
              );
            },
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('parallax-use')), findsNothing);
    await _pick(tester, '15');
    await _tap(tester, find.byKey(const Key('parallax-use')));
    expect(got, closeTo(30, 1e-9));
  });

  testWidgets('hub: Paralaks only for a PCP profile', (tester) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(body: ToolsScreen(activePlatform: WeaponPlatform.pcp)),
      ),
    );
    expect(find.byKey(const Key('tool-parallax')), findsOneWidget);
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: ToolsScreen(activePlatform: WeaponPlatform.firearm),
        ),
      ),
    );
    expect(find.byKey(const Key('tool-parallax')), findsNothing);
    await tester.pumpWidget(_app(const Scaffold(body: ToolsScreen())));
    expect(find.byKey(const Key('tool-parallax')), findsNothing);
  });

  testWidgets('shell passes the active profile platform to Araçlar', (
    tester,
  ) async {
    await _sized(tester);
    final store = MemoryProfileStore();
    await store.save(_pcp);
    await tester.pumpWidget(
      _app(
        HomeScreen(
          profileStore: store,
          activeProfileStore: MemoryActiveProfileStore()..value = _pcp.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Araçlar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tool-parallax')), findsOneWidget);
  });

  testWidgets('Pro: "Paralakstan" on PCP writes the distance, editable', (
    tester,
  ) async {
    await _sized(tester);
    await const ParallaxTableStore().save(_pcp.id, const [
      ParallaxPoint(mark: 10, distanceM: 20),
      ParallaxPoint(mark: 20, distanceM: 40),
    ]);
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: BallisticsScreen(profile: _pcp, view: BallisticsView.pro),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('pro-range-parallax')));
    await _pick(tester, '15');
    await _tap(tester, find.byKey(const Key('parallax-use')));
    final field = find.descendant(
      of: find.byKey(const Key('pro-shot-range')),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(field).controller!.text, '30');
    await tester.enterText(field, '31');
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, '31');
  });

  testWidgets('Pro: no "Paralakstan" on a firearm profile', (tester) async {
    await _sized(tester);
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: BallisticsScreen(profile: _firearm, view: BallisticsView.pro),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pro-range-map')), findsOneWidget);
    expect(find.byKey(const Key('pro-range-parallax')), findsNothing);
  });
}
