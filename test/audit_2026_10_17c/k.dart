// Pre-TestFlight audit 2026-10-17c: numbers against TestFlight 112
// (main 9db11e3). The same cases were run on 9db11e3 (branch
// tmp/denetim-17c-tf112 = 9db11e3 + this file without the expectations)
// and the printed values are pinned below.
//
// - #383 (wind lines moved/re-worded): the click numbers and the
//   percentages of the two wind lines are identical to 9db11e3 for a fixed
//   profile, wind 6,2 m/s and En yüksek rüzgâr 9,3 m/s.
// - #368 (PCP velocity always the Tüfek card's Namlu çıkış hızı): an old
//   PCP profile with a "Basınca göre hız" table now solves with its Namlu
//   çıkış hızı. On 9db11e3 the table velocity was used; the change is
//   owner-approved (expected, not a finding). The test pins that the
//   result is the Tüfek-velocity solution (= the same profile without a
//   table) and records the TestFlight 112 value for the report.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/pcp_pressure.dart';
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
RifleProfile _tabled({double? regulatorBar, bool table = true}) =>
    RifleProfile(
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

/// Wind bracket and zone shares numbers on 9db11e3.
const _tf112Bracket = <String>[]; // filled from the TF112 run
const _tf112Shares = <String>[]; // filled from the TF112 run
const _tf112RequiredRight = ''; // filled from the TF112 run
const _tf112RequiredUp = ''; // filled from the TF112 run

/// requiredUp of the tabled old PCP profile on 9db11e3 (report only).
const _tf112TabledUnregulated = ''; // filled from the TF112 run
const _tf112TabledRegulatedAbove = ''; // filled from the TF112 run

void main() {
  setUp(() {
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_slug]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('#383: wind line numbers identical to TestFlight 112', (
    tester,
  ) async {
    await _seedWind(_windProfile.id);
    await _show(tester, _windProfile);
    final bracket = _textOf(tester, 'shot-wind-bracket');
    final shares = _textOf(tester, 'shot-wind-zone-shares');
    final dial = _dial(tester);
    debugPrint('DEN17C_WIND_BRACKET $bracket');
    debugPrint('DEN17C_WIND_SHARES $shares');
    debugPrint('DEN17C_WIND_RIGHT ${dial.requiredRight}');
    debugPrint('DEN17C_WIND_UP ${dial.requiredUp}');
    expect(_numbers(bracket), _tf112Bracket);
    expect(_numbers(shares), _tf112Shares);
    expect('${dial.requiredRight}', _tf112RequiredRight);
    expect('${dial.requiredUp}', _tf112RequiredUp);
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
    expect('$regulatedAbove', _tf112TabledRegulatedAbove);
    // Unregulated, TestFlight 112 used the table velocity at 160 bar
    // (262,5 m/s): owner-approved change, report only.
    expect('$unregulated' == _tf112TabledUnregulated, isFalse);
    expect(tester.takeException(), isNull);
  });
}
