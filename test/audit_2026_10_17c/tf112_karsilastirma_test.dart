// Pre-TestFlight audit 2026-10-17c: numbers on main be7be4b, compared
// with TestFlight 112 (main 9db11e3).
//
// - #383 (wind lines moved/re-worded): the computation lines of the two
//   wind lines are unchanged since 9db11e3 (only the text around the
//   numbers changed), and the firearm golden (test/core/
//   hedef_golden_numbers_test.dart) keeps the same bracket numbers. This
//   file pins the numbers on main for a fixed PCP profile, wind 6,2 m/s and
//   En yüksek rüzgâr 9,3 m/s (recorded by test-diag run 39036267837 on
//   this branch). The same file could not be compiled on 9db11e3 in CI, so
//   a direct 9db11e3 run is "kontrol edilmedi" in the report.
// - #368 (PCP velocity always the Tüfek card's Namlu çıkış hızı): an old
//   PCP profile with a "Basınca göre hız" table solves exactly as the same
//   profile without a table. On 9db11e3 the unregulated case used the table
//   velocity (owner-approved change, not a finding).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/wind_clock.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';

const _slug = <String, dynamic>{
  'id': 'c-den17c-slug',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.25 slug',
  'caliberMm': 6.35,
  'grain': 34,
  'ammoType': 'slug',
  'bc': 0.08,
  'bcModel': 'G1',
};

const _windProfile = RifleProfile(
  id: 'p-den17c-ruzgar',
  name: 'Denetim rüzgâr',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-den17c-slug',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 60,
);

/// An old PCP profile (saved before 2026-10-16) with a "Basınca göre hız"
/// table. Namlu çıkış hızı 280 m/s; table 120 bar 250 m/s, 200 bar
/// 275 m/s; Tüp basıncı 160 bar.
RifleProfile _tabled({double? regulatorBar, bool table = true}) => RifleProfile(
  id: 'p-den17c-tablo',
  name: 'Eski tablolu PCP',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-den17c-slug',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 60,
  tubePressureBar: 160,
  pressureBar: regulatorBar,
  pressureVelocityTable: table
      ? const [
          PressureVelocityPoint(bar: 120, mps: 250),
          PressureVelocityPoint(bar: 200, mps: 275),
        ]
      : const [],
);

Future<void> _seedWind(String profileId) async {
  SharedPreferences.setMockInitialValues({});
  await const ShotSettingsStore().save(
    profileId,
    ShotSettings(
      weatherSaved: true,
      weatherSi: {'wind': 6.2, 'windDirection': WindClock.toDegrees(9)},
      windMaxText: '9.3',
    ),
  );
}

Future<void> _show(WidgetTester tester, RifleProfile p) async {
  tester.view.physicalSize = const Size(430, 3200) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BallisticsScreen(profile: p, view: BallisticsView.shot),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _textOf(WidgetTester tester, String key) {
  final f = find.byKey(Key(key));
  if (f.evaluate().isEmpty) return '-';
  return tester.widget<Text>(f).data ?? '-';
}

/// Every number in [s] in order ("6,2 m/s: 3 klik" → [6,2, 3]).
List<String> _numbers(String s) =>
    RegExp(r'\d+(?:,\d+)?').allMatches(s).map((m) => m.group(0)!).toList();

ScopeDialView _dial(WidgetTester tester) =>
    tester.widget<ScopeDialView>(find.byType(ScopeDialView));

// --- Values printed by the same cases on 9db11e3 (TestFlight 112). ---

/// Bracket numbers on main (run 39036267837): 6,2 m/s 24 klik, 9,3 m/s
/// 37 klik.
const _mainBracket = ['6,2', '24', '9,3', '37'];

/// requiredUp of the tabled old PCP profile on main (run 39036267837).
const _mainTabledUp = 3.862956004922863;

void main() {
  setUp(() {
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_slug]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('#383: wind line numbers pinned (6,2 / 9,3 m/s)', (tester) async {
    await _seedWind(_windProfile.id);
    await _show(tester, _windProfile);
    final bracket = _textOf(tester, 'shot-wind-bracket');
    final shares = _textOf(tester, 'shot-wind-zone-shares');
    final dial = _dial(tester);
    debugPrint('DEN17C_WIND_BRACKET $bracket');
    debugPrint('DEN17C_WIND_SHARES $shares');
    debugPrint('DEN17C_WIND_RIGHT ${dial.requiredRight}');
    debugPrint('DEN17C_WIND_UP ${dial.requiredUp}');
    expect(_numbers(bracket), _mainBracket);
    // Old order "6,2–9,3: 24 – 37" read as "6,2: 24 · 9,3: 37" (same
    // numbers, #383).
    expect(bracket, contains('6,2 m/s: 24 klik'));
    final pct = _numbers(shares).map(int.parse).toList();
    expect(pct, hasLength(3));
    expect(pct.reduce((a, b) => a + b), inInclusiveRange(99, 101));
    expect(dial.requiredUp, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('#368: old tabled PCP profile solves with Namlu çıkış hızı', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _show(tester, _tabled());
    final unregulated = _dial(tester).requiredUp!;
    await _show(tester, _tabled(regulatorBar: 150));
    // Tüp 160 bar ≥ Regülatör 150 bar: TestFlight 112 also used Namlu
    // çıkış hızı here, so this case must be unchanged.
    final regulatedAbove = _dial(tester).requiredUp!;
    await _show(tester, _tabled(table: false));
    final noTable = _dial(tester).requiredUp!;
    debugPrint('DEN17C_PCP_TABLE_UNREG $unregulated');
    debugPrint('DEN17C_PCP_TABLE_REGABOVE $regulatedAbove');
    debugPrint('DEN17C_PCP_NOTABLE $noTable');
    // Main: the table is ignored, the Tüfek card's 280 m/s is used.
    expect(unregulated, noTable);
    expect(regulatedAbove, noTable);
    expect(noTable, closeTo(_mainTabledUp, 1e-12));
    expect(tester.takeException(), isNull);
  });
}
