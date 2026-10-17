// Pre-TestFlight audit 2026-10-17c — #368 on main be7be4b against
// TestFlight 112 (9db11e3): an old PCP profile that holds a "Basınca göre
// hız" table (feature deleted, owner 2026-10-16) keeps its saved data.
//
// Guards (no finding):
// - the codec reads the table and writes it back unchanged;
// - Profili Düzenle → Güncelle keeps the table, Namlu çıkış hızı, Tüp and
//   Regülatör basıncı; En düşük / En yüksek stay empty;
// - with the table and any En düşük / En yüksek, Hedef solves with the
//   Tüfek card's Namlu çıkış hızı (same result as the bare profile).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/pcp_pressure.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _pcpRifle = <String, dynamic>{
  'id': 'manual_rifle_den17c',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'DEN17C',
  'model': 'Test',
  'caliberMm': 5.5,
  'barrelLengthMm': 500,
  'twistDirection': 'right',
  'twistRateIn': 18,
};

const _pcpAmmo = <String, dynamic>{
  'id': 'manual_ammo_den17c',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'DEN17C 18',
  'model': '',
  'caliberMm': 5.5,
  'grain': 18,
  'ammoType': 'pellet',
  'bc': 0.031,
  'bcModel': 'g1',
};

const _table = [
  PressureVelocityPoint(bar: 120, mps: 250),
  PressureVelocityPoint(bar: 200, mps: 275),
];

RifleProfile _old({bool table = true, double? minMps, double? maxMps}) =>
    RifleProfile(
      id: 'den17c-eski',
      name: 'Eski Tablolu',
      rifleId: 'manual_rifle_den17c',
      ammunitionId: 'manual_ammo_den17c',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: UnitSystem.fpsToMps(900),
      zeroRangeM: 30,
      sightHeightMm: 50,
      tubePressureBar: 250,
      pressureBar: 150,
      pressureVelocityTable: table ? _table : const [],
      pcpMinVelocityMps: minMps,
      pcpMaxVelocityMps: maxMps,
    );

/// The JSON as TestFlight 112 wrote it: no En düşük / En yüksek keys.
Map<String, dynamic> _oldJson() =>
    Map<String, dynamic>.of(const ProfileCodec().encode(_old()))
      ..remove('pcpMinVelocityMps')
      ..remove('pcpMaxVelocityMps');

Finder _k(String key) => find.byKey(Key(key));

String _text(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(of: _k(key), matching: find.byType(TextField)),
    )
    .controller!
    .text;

String _missing(WidgetTester tester) {
  final f = _k('profile-missing');
  return f.evaluate().isEmpty ? '' : tester.widget<Text>(f).data ?? '';
}

Future<double> _requiredUp(WidgetTester tester, RifleProfile p) async {
  tester.view.physicalSize = const Size(430, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: Scaffold(
        body: BallisticsScreen(profile: p, view: BallisticsView.shot),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final up = tester.widget<ScopeDialView>(find.byType(ScopeDialView));
  expect(up.requiredUp, isNotNull);
  return up.requiredUp!;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_pcpRifle, _pcpAmmo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  test('codec: the old table is read and written back unchanged', () {
    final p = const ProfileCodec().decode(_oldJson());
    expect(p.pressureVelocityTable, _table);
    expect(p.pcpMinVelocityMps, isNull);
    expect(p.pcpMaxVelocityMps, isNull);
    final again = const ProfileCodec().encode(p);
    expect(again['pressureVelocity'], _oldJson()['pressureVelocity']);
    expect(again['muzzleVelocityMps'], _oldJson()['muzzleVelocityMps']);
    expect(again['tubePressureBar'], 250);
    expect(again['pressureBar'], 150);
  });

  testWidgets('Profili Düzenle → Güncelle keeps the table and every '
      'saved number', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 3200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryProfileStore();
    await store.save(const ProfileCodec().decode(_oldJson()));
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: ProfilesScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eski Tablolu').first);
    await tester.pumpAndSettle();
    expect(find.text('Profili Düzenle'), findsOneWidget);
    expect(_text(tester, 'profile-velocity-fps'), '900');
    expect(_text(tester, 'profile-pcp-velocity-min'), '');
    expect(_text(tester, 'profile-pcp-velocity-max'), '');
    final update = find.widgetWithText(MenzilPrimaryButton, 'Güncelle');
    await tester.ensureVisible(update);
    await tester.pumpAndSettle();
    expect(
      tester.widget<MenzilPrimaryButton>(update).onPressed,
      isNotNull,
      reason: _missing(tester),
    );
    await tester.tap(update);
    await tester.pumpAndSettle();
    final saved = (await store.all()).single;
    expect(saved.pressureVelocityTable, _table);
    expect(saved.muzzleVelocityMps, closeTo(UnitSystem.fpsToMps(900), 1e-9));
    expect(saved.tubePressureBar, 250);
    expect(saved.pressureBar, 150);
    expect(saved.pcpMinVelocityMps, isNull);
    expect(saved.pcpMaxVelocityMps, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hedef: table and any En düşük / En yüksek → the Tüfek '
      'Namlu çıkış hızı solution', (tester) async {
    final bare = await _requiredUp(tester, _old(table: false));
    for (final (lo, hi) in [
      (null, null),
      (UnitSystem.fpsToMps(700), null),
      (null, UnitSystem.fpsToMps(1100)),
      (UnitSystem.fpsToMps(700), UnitSystem.fpsToMps(1100)),
    ]) {
      final up = await _requiredUp(tester, _old(minMps: lo, maxMps: hi));
      expect(up, bare, reason: 'min $lo max $hi');
    }
    expect(tester.takeException(), isNull);
  });
}
