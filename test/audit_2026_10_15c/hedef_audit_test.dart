// Pre-TestFlight audit 2026-10-15c — Hedef / turret area, merged after
// 4c51b77:
//  * #330 (a8f1c3c) result row "Üst kule" / "Yan kule" on top;
//  * #332 (d8f4efe) side turret box 66 × 180 pt;
//  * #349 (8a5f650) arrow tap areas 44 pt, zero alignment (HDF-2);
//  * #337 (a7478d5) KUL-1 turret travel with the zero angle;
//  * #352 (bf89a57) turret click sound;
//  * #357 (e7b29bf) HDF-1 removal (WIND_GUIDE_LINK);
//  * #358 (d4abfac) Pro Ayarlar row layout (Pro → Hedef path).
//
// References are hand calculations, not another ballistic app:
// tools/denetim_2026_10_15c_hedef.py (independent reference solver
// tools/formula_reference.py, unit definitions 1 MOA = π/10800 rad,
// 1 yd = 0,9144 m), checked by tools/test_denetim_2026_10_15c_hedef.py.
//
// Findings (expected behaviour; `skip:` while main fails it):
//   HDF-3 (low)    the row's direction word follows the one-decimal print,
//                  not the click count: "1 klik · 0,0 MRAD" (0,05 mrad
//                  turret, no direction) and "0 klik · 0,1 MOA yukarı"
//                  (¼ and 1/8 MOA turrets).
//   HDF-4 (medium) beyond the turret travel the row shows the unclamped
//                  need ("162 klik") while "Kuleleri kur" / the Pro
//                  auto-dial set the limit (145); nothing in the row says
//                  the turret cannot reach it.
//   HDF-5 (medium) no BC (vacuum, e.g. a catalog pellet without BC) with
//                  wind entered: "Yan kule 0 klik · 0,0 MRAD" on top,
//                  although wind is not modelled (KİLİTLİ).
// The other tests are passing guards.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/services/turret_click_sound.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

// tools/denetim_2026_10_15c_hedef.py (4 decimals). Elevation in the
// turret unit (+ = dial up), windage (+ = dial right; wind from 9 o'clock
// pushes the bullet right, so the correction is left).
const _up450 = 3.4136;
const _upMoa450 = 11.7352;
const _up620 = 5.8948;
const _upMoa620 = 20.2648;
const _right620 = -1.6080;
const _rightMoa620 = -5.5278;
const _up800yd = 7.9127;
const _right800yd = -2.0124;
const _zeroAngle = 1.2790;

/// Modelling spread between two independent solvers (as in
/// test/formula_reference_vectors_test.dart).
const _tol = 0.03;
const _moaPerMrad = 3.437746770784939;

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_hdf15c',
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
  'id': 'manual_ammo_hdf15c',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 175',
  'model': '',
  'caliberMm': 7.62,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.243,
  'bcModel': 'g7',
};

/// A 1/8 MOA scope with 13,09 mrad travel on both turrets (as typed with
/// "Listede yok").
const _eighthScope = <String, dynamic>{
  'id': 'manual_scope_hdf15c',
  'kind': 'scope',
  'brand': 'Test',
  'model': '1/8 MOA',
  'objectiveMm': 50,
  'click': 0.125,
  'clickUnit': 'moa',
  'focal': 'ffp',
  'minMag': 5,
  'maxMag': 25,
  'elevationRangeMrad': 13.09,
  'windageRangeMrad': 13.09,
};

const _id = 'p-hdf15c';

/// .308 175 gr G7 0,243, 790 m/s, 45 mm. Gazi Sniper 6–36×56 FFP: 0,1 mrad
/// clicks, 26 / 14,5 mrad travel.
RifleProfile _profile({
  AngularUnit unit = AngularUnit.mrad,
  String scopeId = 'gazi-6-36',
  bool yards = false,
}) => RifleProfile(
  id: _id,
  name: 'HDF15c',
  rifleId: 'manual_rifle_hdf15c',
  ammunitionId: 'manual_ammo_hdf15c',
  scopeId: scopeId,
  muzzleVelocityMps: 790,
  zeroRangeM: yards ? 91.44 : 100,
  sightHeightMm: 45,
  angularUnit: unit,
  distanceUnit: yards ? DistanceUnit.yard : DistanceUnit.meter,
);

/// Catalog PCP whose pellet has no BC (vacuum baseline), Gazi MRAD.
const _vacuumPcp = RifleProfile(
  id: _id,
  name: 'Vakum',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.mrad,
);

/// Saved Hava Durumu: 15 °C, 1013,25 hPa, 50 %, 4 m/s from 9 o'clock.
ShotSettings _settings({double wind = 4}) => ShotSettings(
  weatherSaved: true,
  weatherSi: {
    'temperature': 15,
    'pressure': 1013.25,
    'humidity': 50,
    'wind': wind,
    'windDirection': 90,
  },
);

void _seed({double wind = 4}) {
  SharedPreferences.setMockInitialValues({
    ShotSettingsStore.keyFor(_id): jsonEncode(_settings(wind: wind).toJson()),
  });
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries([_rifle, _ammo, _eighthScope]),
  );
}

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget _app(RifleProfile p, BallisticsView view) => MaterialApp(
  theme: MenzilTheme.dark(),
  home: Scaffold(
    body: BallisticsScreen(profile: p, view: view),
  ),
);

/// Pro Ayarlar → Atış mesafesi [text] (in the profile's distance unit),
/// then the Hedef tab (same State, as in the shell).
Future<void> _hedefFromPro(
  WidgetTester tester,
  RifleProfile p,
  String text,
) async {
  await tester.pumpWidget(_app(p, BallisticsView.pro));
  await tester.pumpAndSettle();
  final range = find.descendant(
    of: find.byKey(const Key('pro-shot-range')),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(range);
  await tester.enterText(range, text);
  await tester.pump();
  await tester.pumpWidget(_app(p, BallisticsView.shot));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

ScopeDialView _dial(WidgetTester tester) =>
    tester.widget<ScopeDialView>(find.byType(ScopeDialView));

/// The texts of one result column, top to bottom.
List<String> _texts(WidgetTester tester, Key key) => tester
    .widgetList<Text>(
      find.descendant(of: find.byKey(key), matching: find.byType(Text)),
    )
    .map((t) => t.data!)
    .toList();

List<String> _up(WidgetTester tester) =>
    _texts(tester, TurretSolutionRow.elevationKey);

List<String> _side(WidgetTester tester) =>
    _texts(tester, TurretSolutionRow.windageKey);

String _readout(WidgetTester tester) =>
    tester.widget<Text>(find.textContaining('Kule: ').first).data!;

String _fmt1(double v) => v.abs().toStringAsFixed(1).replaceAll('.', ',');

/// The row for the dial's own angles, by the rules of the hand calculation
/// (nearest click; one decimal; + up / + right).
({List<String> up, List<String> side}) _expectedFromDial(ScopeDialView d) {
  final unit = d.unit.label;
  String detail(double a, String pos, String neg) {
    final s = _fmt1(a);
    return s == '0,0' ? '0,0 $unit' : '$s $unit ${a > 0 ? pos : neg}';
  }

  final upAngle = d.requiredUp!;
  final sideAngle = d.requiredRight;
  final up = (upAngle / d.clickValue).round().abs();
  final side = (sideAngle / d.clickValue).round().abs();
  return (
    up: ['Üst kule', '$up klik', detail(upAngle, 'yukarı', 'aşağı')],
    side: ['Yan kule', '$side klik', detail(sideAngle, 'sağ', 'sol')],
  );
}

class _CountingClickSound implements TurretClickSound {
  int clicks = 0;

  @override
  void click() => clicks++;

  @override
  void preload() {}
}

Future<void> _pumpRow(
  WidgetTester tester, {
  required double up,
  required double right,
  required double click,
  required AngularUnit unit,
  bool windCalm = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.dark(),
      home: Scaffold(
        body: TurretSolutionRow(
          requiredUp: up,
          requiredRight: right,
          clickValue: click,
          unit: unit,
          windCalm: windCalm,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('#330 result row = hand calculation', () {
    testWidgets('MRAD, Pro 620 m: 59 klik · 5,9 MRAD yukarı, 16 klik · 1,6 '
        'MRAD sol; turrets, readout and row agree', (tester) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await _hedefFromPro(tester, _profile(), '620');

      final d = _dial(tester);
      expect(d.rangeM, closeTo(620, 1e-9));
      expect(d.clickValue, closeTo(0.1, 1e-12));
      expect(d.requiredUp!, closeTo(_up620, _tol));
      expect(d.requiredRight, closeTo(_right620, _tol));
      expect(_up(tester), ['Üst kule', '59 klik', '5,9 MRAD yukarı']);
      expect(_side(tester), ['Yan kule', '16 klik', '1,6 MRAD sol']);
      // Pro → Hedef auto-dial set the same clicks (inside the travel).
      expect(d.elevationClicks, 59);
      expect(d.windageClicks, -16);
      expect(_readout(tester), startsWith('Kule: 59 klik yukarı (5,90 '));
      expect(_readout(tester), contains('· 16 klik sol (1,60 '));
      expect(find.text('Vuruş noktası: artı işaretinde'), findsOneWidget);
    });

    testWidgets('MOA on a 0,1 mrad scope (¼ MOA standard click), 620 m: 81 '
        'klik; the angle is the mrad one × 3,4377', (tester) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await _hedefFromPro(tester, _profile(unit: AngularUnit.moa), '620');

      final d = _dial(tester);
      expect(d.unit, AngularUnit.moa);
      expect(d.clickValue, closeTo(0.25, 1e-12));
      expect(d.requiredUp!, closeTo(_upMoa620, _tol * _moaPerMrad));
      expect(d.requiredRight, closeTo(_rightMoa620, _tol * _moaPerMrad));
      expect(_up(tester)[1], '81 klik');
      final e = _expectedFromDial(d);
      expect(_up(tester), e.up);
      expect(_side(tester), e.side);
      expect(_up(tester)[2], endsWith('MOA yukarı'));
      expect(_side(tester)[2], endsWith('MOA sol'));
      expect(d.elevationClicks, 81);
      expect('${d.windageClicks.abs()} klik', _side(tester)[1]);
      expect(d.windageClicks, lessThan(0));
    });

    testWidgets('yard profile, Pro 800 yd (731,52 m): 79 klik · 7,9 MRAD '
        'yukarı, 20 klik · 2,0 MRAD sol', (tester) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await _hedefFromPro(tester, _profile(yards: true), '800');

      final d = _dial(tester);
      expect(d.rangeM, closeTo(731.52, 1e-6));
      expect(d.distanceUnit, 'yd');
      expect(d.requiredUp!, closeTo(_up800yd, _tol));
      expect(d.requiredRight, closeTo(_right800yd, _tol));
      expect(_up(tester), ['Üst kule', '79 klik', '7,9 MRAD yukarı']);
      expect(_side(tester), ['Yan kule', '20 klik', '2,0 MRAD sol']);
      expect(d.elevationClicks, 79);
      expect(d.windageClicks, -20);
    });

    testWidgets('1/8 MOA scope, 450 m: clicks of 0,125 MOA, travel 180 − '
        'zero clicks, row = turrets', (tester) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await _hedefFromPro(
        tester,
        _profile(unit: AngularUnit.moa, scopeId: 'manual_scope_hdf15c'),
        '450',
      );

      final d = _dial(tester);
      expect(d.clickValue, closeTo(0.125, 1e-12));
      expect(d.requiredUp!, closeTo(_upMoa450, _tol * _moaPerMrad));
      expect(d.requiredUp! / _moaPerMrad, closeTo(_up450, _tol));
      // 13,09 mrad / 2 = 22,50 MOA = 180 clicks; zero angle 1,279 mrad =
      // 4,40 MOA ≈ 35 clicks (± 1 for the solver spread).
      expect(d.halfElevationClicks, 180);
      final zero = (_zeroAngle * _moaPerMrad / 0.125).round();
      expect(d.zeroAngleClicks, inInclusiveRange(zero - 1, zero + 1));
      expect(d.maxElevationClicks, 180 - d.zeroAngleClicks);
      expect(d.maxElevationDownClicks, 180 + d.zeroAngleClicks);
      final e = _expectedFromDial(d);
      expect(_up(tester), e.up);
      expect(_side(tester), e.side);
      // 11,74 MOA / 0,125 = 93,9 → 94 (± 1 for the solver spread).
      final need = (_upMoa450 / 0.125).round();
      expect(d.elevationClicks, inInclusiveRange(need - 1, need + 1));
      expect('${d.elevationClicks} klik', _up(tester)[1]);
      expect('${d.windageClicks.abs()} klik', _side(tester)[1]);
    });

    testWidgets('DOPE row 620 m agrees with the Hedef row (5,89 mrad → 59 '
        'klik)', (tester) async {
      _seed();
      tester.view.physicalSize = const Size(1000, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: BallisticsScreen(profile: _profile())),
      );
      await tester.pumpAndSettle();
      final ranges = find
          .descendant(
            of: find.byKey(BallisticsFieldKeys.ranges),
            matching: find.byType(TextField),
            matchRoot: true,
          )
          .first;
      await tester.ensureVisible(ranges);
      await tester.enterText(ranges, '620');
      await tester.pump();
      final dope = find.text('DOPE oluştur').first;
      await tester.ensureVisible(dope);
      await tester.tap(dope);
      await tester.pumpAndSettle();

      final table = tester.widget<DataTable>(find.byType(DataTable).first);
      final mrad = table.columns.indexWhere(
        (c) => c.label is Text && (c.label as Text).data == 'Yükseklik MRAD',
      );
      final wind = table.columns.indexWhere(
        (c) => c.label is Text && (c.label as Text).data == 'Rüzgâr MRAD',
      );
      expect(mrad, isNonNegative);
      expect(wind, isNonNegative);
      double cell(DataRow r, int i) =>
          double.parse((r.cells[i].child as Text).data!.replaceAll(',', '.'));
      final row = table.rows.firstWhere((x) => (cell(x, 0) - 620).abs() < 0.5);
      expect(cell(row, mrad), closeTo(_up620, _tol));
      expect((cell(row, mrad) / 0.1).round(), 59);
      expect((cell(row, wind) / 0.1).round(), 16);
    });

    testWidgets('normal rows: nearest click, one decimal, direction words', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        up: 5.8948,
        right: -1.608,
        click: 0.1,
        unit: AngularUnit.mrad,
        windCalm: false,
      );
      expect(_up(tester), ['Üst kule', '59 klik', '5,9 MRAD yukarı']);
      expect(_side(tester), ['Yan kule', '16 klik', '1,6 MRAD sol']);
      // Below the zero range: down; wind from the right: right.
      await _pumpRow(
        tester,
        up: -0.6,
        right: 0.9,
        click: 0.25,
        unit: AngularUnit.moa,
        windCalm: false,
      );
      expect(_up(tester), ['Üst kule', '2 klik', '0,6 MOA aşağı']);
      expect(_side(tester), ['Yan kule', '4 klik', '0,9 MOA sağ']);
      // On the zero, no wind.
      await _pumpRow(
        tester,
        up: 0,
        right: 0,
        click: 0.1,
        unit: AngularUnit.mrad,
      );
      expect(_up(tester), ['Üst kule', '0 klik', '0,0 MRAD']);
      expect(_side(tester), ['Yan kule', '0 klik', 'rüzgâr yok']);
      expect(tester.takeException(), isNull);
    });
  });

  group('HDF-3 direction word vs click count', () {
    testWidgets('a non-zero click count names its direction; 0 klik names '
        'none', (tester) async {
      // 0,05 mrad turret (10 catalog scopes), 0,03 mrad up: 1 klik.
      await _pumpRow(
        tester,
        up: 0.03,
        right: -0.03,
        click: 0.05,
        unit: AngularUnit.mrad,
        windCalm: false,
      );
      expect(_up(tester)[1], '1 klik');
      expect(_up(tester)[2], contains('yukarı'));
      expect(_side(tester)[1], '1 klik');
      expect(_side(tester)[2], contains('sol'));
      // ¼ MOA turret, 0,1 MOA up: 0 klik, so nothing to dial up.
      await _pumpRow(
        tester,
        up: 0.1,
        right: 0,
        click: 0.25,
        unit: AngularUnit.moa,
      );
      expect(_up(tester)[1], '0 klik');
      expect(_up(tester)[2], isNot(contains('yukarı')));
    }, skip: true); // HDF-3: direction word follows "0,0", not the clicks
  });

  group('HDF-4 beyond the turret travel', () {
    testWidgets('guard: 1/8 MOA scope at 620 m needs ≈162 clicks, the UP '
        'travel is 180 − zero (≈145); auto-dial stops at the limit', (
      tester,
    ) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await _hedefFromPro(
        tester,
        _profile(unit: AngularUnit.moa, scopeId: 'manual_scope_hdf15c'),
        '620',
      );
      final d = _dial(tester);
      expect(d.requiredUp!, closeTo(_upMoa620, _tol * _moaPerMrad));
      final need = (d.requiredUp! / d.clickValue).round();
      expect(need, greaterThan(d.maxElevationClicks));
      expect(d.elevationClicks, d.maxElevationClicks);
      expect(find.byKey(ScopeDialKeys.travelNote), findsOneWidget);
      expect(
        tester
            .widget<MenzilSecondaryButton>(
              find.byKey(ScopeDialKeys.dialSolution),
            )
            .label,
        'Kule sınırına kuruldu',
      );
      // The row shows the unclamped need.
      expect(_up(tester)[1], '$need klik');
    });

    testWidgets('the row agrees with what "Kuleleri kur" sets, or says the '
        'turret cannot reach it', (tester) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await _hedefFromPro(
        tester,
        _profile(unit: AngularUnit.moa, scopeId: 'manual_scope_hdf15c'),
        '620',
      );
      final d = _dial(tester);
      final texts = _up(tester);
      final agrees = texts[1] == '${d.elevationClicks} klik';
      final saysLimit = texts.any(
        (t) => t.contains('yetmez') || t.contains('sınır'),
      );
      expect(agrees || saysLimit, isTrue, reason: '$texts');
    }, skip: true); // HDF-4: row shows 162 klik, turret limit 145, no note
  });

  group('HDF-5 no BC (vacuum) with wind', () {
    testWidgets('guard: vacuum PCP, 4 m/s wind: the side angle is 0 and the '
        'page says wind is locked', (tester) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await tester.pumpWidget(_app(_vacuumPcp, BallisticsView.shot));
      await tester.pumpAndSettle();
      final d = _dial(tester);
      expect(d.requiredUp, isNotNull);
      expect(d.requiredRight, 0);
      expect(find.textContaining('KİLİTLİ'), findsWidgets);
      expect(_side(tester), ['Yan kule', '0 klik', '0,0 MRAD']);
    });

    testWidgets('Yan kule does not present 0 klik as the wind solution', (
      tester,
    ) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await tester.pumpWidget(_app(_vacuumPcp, BallisticsView.shot));
      await tester.pumpAndSettle();
      final side = _side(tester);
      expect(
        side.any(
          (t) =>
              t.contains('KİLİTLİ') ||
              t.contains('hesaplan') ||
              t.contains('modellen'),
        ),
        isTrue,
        reason: '$side',
      );
    }, skip: true); // HDF-5: "0 klik · 0,0 MRAD" while 4 m/s is not modelled
  });

  group('#332 / #349 / #352 side turret, arrows and click sound', () {
    for (final width in const [320.0, 390.0]) {
      testWidgets('${width.toInt()} pt, 1/8 MOA scope: box 66·k × 180·k on '
          'the line, pointer inside; each arrow tap = one click and one '
          'sound; the row stays on the required solution', (tester) async {
        _seed();
        final sound = _CountingClickSound();
        TurretClickSound.instance = sound;
        addTearDown(
          () => TurretClickSound.instance = const SilentTurretClickSound(),
        );
        _size(tester, Size(width, 2400));
        await tester.pumpWidget(
          _app(
            _profile(unit: AngularUnit.moa, scopeId: 'manual_scope_hdf15c'),
            BallisticsView.shot,
          ),
        );
        await tester.pumpAndSettle();
        await _tap(tester, find.byKey(ScopeDialKeys.turretToggle));
        expect(tester.takeException(), isNull);

        final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
        final k = reticle.width / 334;
        final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
        expect(box.width, moreOrLessEquals(66 * k, epsilon: 0.5));
        expect(box.height, moreOrLessEquals(180 * k, epsilon: 0.5));
        final lineY = reticle.center.dy;
        expect(box.center.dy, moreOrLessEquals(lineY, epsilon: 0.5));
        expect(box.right, lessThanOrEqualTo(reticle.right + 0.01));
        final pointer = SideTurretPointer.rect(box.size);
        expect((Offset.zero & box.size).contains(pointer.topLeft), isTrue);
        expect((Offset.zero & box.size).contains(pointer.bottomRight), isTrue);
        expect(pointer.center.dy, moreOrLessEquals(box.height / 2));

        final upBefore = _up(tester);
        final sideBefore = _side(tester);
        final requiredBefore = _dial(tester).requiredUp;
        for (final (tip, elev, wind) in const [
          ('Rüzgâr kulesi 1 klik sağa', 0, 1),
          ('Rüzgâr kulesi 1 klik sağa', 0, 2),
          ('Rüzgâr kulesi 1 klik sola', 0, 1),
          ('Yükseklik kulesi 1 klik yukarı', 1, 1),
          ('Yükseklik kulesi 1 klik aşağı', 0, 1),
          ('Yükseklik kulesi 1 klik aşağı', -1, 1),
        ]) {
          await _tap(tester, find.byTooltip(tip));
          final d = _dial(tester);
          expect(d.elevationClicks, elev, reason: tip);
          expect(d.windageClicks, wind, reason: tip);
        }
        expect(sound.clicks, 6);
        // Dialled clicks never change the required solution on top.
        expect(_dial(tester).requiredUp, requiredBefore);
        expect(_up(tester), upBefore);
        expect(_side(tester), sideBefore);

        // "Kuleleri kur" is programmatic: no sound, turrets = row.
        await _tap(tester, find.byKey(ScopeDialKeys.dialSolution));
        expect(sound.clicks, 6);
        final d = _dial(tester);
        expect('${d.elevationClicks.abs()} klik', _up(tester)[1]);
        expect('${d.windageClicks.abs()} klik', _side(tester)[1]);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('silent default: arrows work without a sound service', (
      tester,
    ) async {
      _seed();
      expect(TurretClickSound.instance, isA<SilentTurretClickSound>());
      _size(tester, const Size(320, 568));
      await tester.pumpWidget(_app(_profile(), BallisticsView.shot));
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Yükseklik kulesi 1 klik yukarı'));
      expect(_dial(tester).elevationClicks, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
