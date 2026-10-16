// Pre-TestFlight audit 2026-10-15b — PR #317 (commit cb9ffee): Hedef / Hava
// Durumu / Pro Ayarlar and the scope view split into part files, plus the
// clean design (turrets, side turret, collapsible "Hesap dökümü", done
// buttons, Rüzgâr ⓘ, WIND_GUIDE_LINK flag — deleted since, HDF-1).
//
// The split moved code without changing it (checked line by line against
// 2188ec9, the commit before #317): state fields, persistence keys, the
// solve and the auto-dial stayed in ballistics_screen.dart / the
// ScopeDialView build. These tests pin the user-visible result on a
// concrete profile:
//  * same inputs → Hedef turret numbers, clicks and DOPE rows equal the
//    hand calculation in tools/denetim_2026_10_15b_hedef.py (independent
//    reference solver tools/formula_reference.py; no other ballistic app);
//  * Pro distance → Hedef dials both turrets and opens the side turret;
//    "Kuleleri kur" opens it too;
//  * "Hesap dökümü" starts closed and opening/closing it changes no number;
//  * "Hava verisi alındı" survives a fresh State (saved, not re-fetched);
//  * the removed Rüzgâr link is deleted, not flagged (HDF-1, fixed).
// Tests for findings are skipped with their id (HDF-n).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/ballistics/wind_guide.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import '../support/library_source.dart';
import '../support/pro_sections.dart';
import '../support/tool_fakes.dart';

// tools/denetim_2026_10_15b_hedef.py (4 decimals). Correction in mrad
// (+ = dial up), windage correction in mrad (+ = dial right; wind from
// 9 o'clock pushes the bullet right, so the correction is left).
const _up100 = -0.0001;
const _right100 = -0.2067;
const _up350 = 2.2034;
const _upMoa350 = 7.5746;
const _right350 = -0.8007;
const _tof350 = 0.5131;
const _v350 = 589.6372;
const _up620 = 5.8948;
const _upMoa620 = 20.2648;
const _right620 = -1.6080;
const _tof620 = 1.0340;
const _v620 = 455.2890;

/// Modelling spread between two independent solvers (the same tolerance as
/// test/formula_reference_vectors_test.dart); every click count used below
/// is more than this away from a half-click rounding edge.
const _tol = 0.03;
const _moaPerMrad = 3.437746770784939;

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_hdf',
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
  'id': 'manual_ammo_hdf',
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

RifleProfile _profile({AngularUnit unit = AngularUnit.mrad}) => RifleProfile(
  id: 'p-hdf',
  name: 'HDF',
  rifleId: 'manual_rifle_hdf',
  ammunitionId: 'manual_ammo_hdf',
  // Gazi Sniper 6–36×56 FFP: 0,1 mrad clicks, 26 / 14,5 mrad travel.
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 790,
  zeroRangeM: 100,
  sightHeightMm: 45,
  angularUnit: unit,
);

/// Saved Hava Durumu: 15 °C, 1013,25 hPa, 50 %, 4 m/s from 9 o'clock. No
/// Mermi uzunluğu (spin drift and aerodynamic jump stay out), no zero
/// offset, no Coriolis.
const _settings = ShotSettings(
  weatherSaved: true,
  weatherSi: {
    'temperature': 15,
    'pressure': 1013.25,
    'humidity': 50,
    'wind': 4,
    'windDirection': 90,
  },
);

void _seed({bool saved = true}) {
  SharedPreferences.setMockInitialValues({
    if (saved)
      ShotSettingsStore.keyFor('p-hdf'): jsonEncode(_settings.toJson()),
  });
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries([_rifle, _ammo]),
  );
}

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget _app(RifleProfile p, BallisticsView view) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(
    body: BallisticsScreen(profile: p, view: view),
  ),
);

/// Pro Ayarlar → Atış mesafesi [text], then the Hedef tab (same State, as
/// in the shell).
Future<void> _hedefFromPro(
  WidgetTester tester,
  RifleProfile p,
  String text,
) async {
  await tester.pumpWidget(_app(p, BallisticsView.pro));
  await tester.pumpAndSettle();
  await openProFor(tester, const Key('pro-shot-range'));
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

MenzilSecondaryButton _button(WidgetTester tester, Key key) =>
    tester.widget<MenzilSecondaryButton>(find.byKey(key));

String _readout(WidgetTester tester) =>
    tester.widget<Text>(find.textContaining('Kule: ').first).data!;

void main() {
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('Hedef numbers = hand calculation', () {
    testWidgets('Pro 620 m → Hedef: required correction, auto-dial 59 U · '
        '16 L, side turret open', (tester) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await _hedefFromPro(tester, _profile(), '620');

      final dial = _dial(tester);
      expect(dial.rangeM, closeTo(620, 1e-9));
      expect(dial.clickValue, closeTo(0.1, 1e-12));
      expect(dial.requiredUp, isNotNull);
      expect(dial.requiredUp!, closeTo(_up620, _tol));
      expect(dial.requiredRight, closeTo(_right620, _tol));
      // Auto-dial: the nearest click of each correction, inside the
      // travel (up 130 − zero clicks, windage ±72).
      expect(dial.elevationClicks, 59);
      expect(dial.windageClicks, -16);
      expect(find.byKey(ScopeDialKeys.windageDrumBox), findsOneWidget);
      expect(
        _button(tester, ScopeDialKeys.dialSolution).label,
        'Çözüm kulelere kuruldu',
      );
      expect(_button(tester, ScopeDialKeys.dialSolution).active, isTrue);
      expect(_readout(tester), startsWith('Kule: 59 klik yukarı (5,90 '));
      expect(_readout(tester), contains('· 16 klik sol (1,60 '));
      expect(find.text('Vuruş noktası: artı işaretinde'), findsOneWidget);
    });

    testWidgets('MOA profile, same scope: the correction is the mrad one × '
        '3,4377 and the turret uses ¼ MOA clicks', (tester) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await _hedefFromPro(tester, _profile(unit: AngularUnit.moa), '620');

      final dial = _dial(tester);
      expect(dial.unit, AngularUnit.moa);
      expect(dial.clickValue, closeTo(0.25, 1e-12));
      expect(dial.requiredUp!, closeTo(_upMoa620, _tol * _moaPerMrad));
      expect(
        dial.requiredRight,
        closeTo(_right620 * _moaPerMrad, _tol * _moaPerMrad),
      );
      // 20,26 MOA / 0,25 = 81,06 → 81 (0,11 MOA from the edge).
      expect(dial.elevationClicks, 81);
      expect(
        dial.windageClicks,
        (dial.requiredRight / dial.clickValue).round(),
      );
      expect(find.byKey(ScopeDialKeys.windageDrumBox), findsOneWidget);
    });

    testWidgets('Hedef opened directly: 100 m, turrets at 0, side turret '
        'closed; "Kuleleri kur" dials 0 U · 2 L and opens it', (tester) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await tester.pumpWidget(_app(_profile(), BallisticsView.shot));
      await tester.pumpAndSettle();

      var dial = _dial(tester);
      expect(dial.rangeM, closeTo(100, 1e-9));
      expect(dial.requiredUp!, closeTo(_up100, _tol));
      expect(dial.requiredRight, closeTo(_right100, _tol));
      expect(dial.elevationClicks, 0);
      expect(dial.windageClicks, 0);
      expect(find.byKey(ScopeDialKeys.windageDrumBox), findsNothing);
      expect(_button(tester, ScopeDialKeys.dialSolution).label, 'Kuleleri kur');

      await _tap(tester, find.byKey(ScopeDialKeys.dialSolution));
      dial = _dial(tester);
      expect(dial.elevationClicks, 0);
      expect(dial.windageClicks, -2);
      expect(find.byKey(ScopeDialKeys.windageDrumBox), findsOneWidget);
      expect(
        _button(tester, ScopeDialKeys.dialSolution).label,
        'Çözüm kulelere kuruldu',
      );
    });

    testWidgets('DOPE rows 350 / 620 m: MOA, MRAD, wind, speed, TOF', (
      tester,
    ) async {
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
      await tester.enterText(ranges, '350 620');
      await tester.pump();
      final dope = find.text('DOPE oluştur').first;
      await tester.ensureVisible(dope);
      await tester.tap(dope);
      await tester.pumpAndSettle();

      final table = tester.widget<DataTable>(find.byType(DataTable).first);
      int col(String label) {
        final i = table.columns.indexWhere(
          (c) => c.label is Text && (c.label as Text).data == label,
        );
        expect(i, isNonNegative, reason: 'no "$label" column');
        return i;
      }

      double cell(DataRow r, int i) =>
          double.parse((r.cells[i].child as Text).data!.replaceAll(',', '.'));
      final moa = col('Yükseklik MOA');
      final mrad = col('Yükseklik MRAD');
      final wind = col('Rüzgâr MRAD');
      final speed = col('Hız m/s');
      final tof = col('TOF');
      for (final (r, up, upMoa, right, v, t) in const [
        (350.0, _up350, _upMoa350, _right350, _v350, _tof350),
        (620.0, _up620, _upMoa620, _right620, _v620, _tof620),
      ]) {
        final row = table.rows.firstWhere((x) => (cell(x, 0) - r).abs() < 0.5);
        expect(cell(row, mrad), closeTo(up, _tol), reason: '$r m MRAD');
        expect(
          cell(row, moa),
          closeTo(upMoa, _tol * _moaPerMrad),
          reason: '$r m MOA',
        );
        // The table shows the size of the wind correction.
        expect(cell(row, wind), closeTo(right.abs(), _tol), reason: '$r m');
        expect(cell(row, speed), closeTo(v, 0.005 * v), reason: '$r m v');
        expect(cell(row, tof), closeTo(t, 0.005 * t), reason: '$r m TOF');
      }
    });
  });

  group('Hesap dökümü', () {
    testWidgets('closed at first; opening and closing changes no number', (
      tester,
    ) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await _hedefFromPro(tester, _profile(), '620');

      final before = _readout(tester);
      final upBefore = _dial(tester).requiredUp;
      expect(find.byKey(ScopeDialKeys.workings), findsOneWidget);
      expect(find.textContaining('Klik = '), findsNothing);
      expect(find.textContaining('Kulede: '), findsNothing);

      await _tap(tester, find.byKey(ScopeDialKeys.workingsToggle));
      // The lines repeat the same clicks as the turrets.
      expect(find.textContaining('= 59 klik U'), findsOneWidget);
      expect(find.textContaining('→ 16 klik L'), findsOneWidget);
      expect(find.textContaining('Kulede: 59 × 0,1 = 5,90 '), findsOneWidget);
      expect(_readout(tester), before);
      expect(_dial(tester).requiredUp, upBefore);
      expect(_dial(tester).elevationClicks, 59);
      expect(_dial(tester).windageClicks, -16);

      await _tap(tester, find.byKey(ScopeDialKeys.workingsToggle));
      expect(find.textContaining('Kulede: '), findsNothing);
      expect(_readout(tester), before);
      expect(_dial(tester).requiredUp, upBefore);
    });
  });

  group('Done buttons', () {
    testWidgets('"Hava verisi alındı" comes back on a fresh State, from the '
        'saved settings (no new fetch)', (tester) async {
      _seed(saved: false);
      _size(tester, const Size(430, 3000));
      final clock = TestClock(DateTime(2026, 10, 15, 10, 30));
      final weather = TestWeather(
        observation(fetchedAt: clock.current.toUtc()),
      );
      final services = testServices(
        location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
        weather: weather,
        pressure: TestPressure(const PressureRead(998.4)),
        clock: clock,
      );
      Widget app() => MaterialApp(
        theme: MenzilTheme.light(),
        builder: (context, c) =>
            ToolsServicesScope(services: services, child: c!),
        home: Scaffold(
          body: BallisticsScreen(
            profile: _profile(),
            view: BallisticsView.environment,
            onContinueToPro: () {},
          ),
        ),
      );
      const btn = Key('environment-fill-weather');

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(btn));
      expect(_button(tester, btn).label, 'Hava verisi alındı');
      expect(_button(tester, btn).active, isTrue);
      expect(weather.calls, 1);

      // Unmount: the next pump builds a new State that reads the store.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(_button(tester, btn).label, 'Hava verisi alındı');
      expect(_button(tester, btn).active, isTrue);
      expect(_button(tester, btn).icon, Icons.check);
      expect(weather.calls, 1, reason: 'restored, not fetched again');
    });
  });

  group('WIND_GUIDE_LINK', () {
    // HDF-1 (= FLG-1, fixed by fix/hdf1-ruzgar-rehberi-sil): the removed
    // "Rüzgâr tahmini nasıl yapılır?" link was hidden behind
    // bool.fromEnvironment('WIND_GUIDE_LINK'); it is now deleted. The
    // Rüzgâr ⓘ still opens the guide.
    testWidgets('no link on Hava Durumu, the Rüzgâr ⓘ opens the guide', (
      tester,
    ) async {
      _seed();
      _size(tester, const Size(430, 3000));
      await tester.pumpWidget(_app(_profile(), BallisticsView.environment));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wind-guide-link')), findsNothing);
      final info = find.byKey(const Key('environment-wind-info'));
      expect(info, findsOneWidget);
      expect(
        tester.widget<MenzilInfoButton>(info).tooltip,
        WindGuide.linkLabel,
      );
      await tester.ensureVisible(info);
      await tester.tap(info);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wind-guide-dialog')), findsOneWidget);
      expect(find.text(WindGuide.title), findsOneWidget);
      final lines = WindGuide.lines(metric: true);
      expect(lines, hasLength(6));
      for (var i = 0; i < lines.length; i++) {
        expect(
          tester.widget<Text>(find.byKey(Key('wind-guide-line-$i'))).data,
          lines[i],
        );
      }
    });

    test('removed link is deleted, not kept behind a flag', () {
      final src = [
        librarySource('lib/features/ballistics/ballistics_screen.dart'),
        librarySource('lib/features/ballistics/wind_guide.dart'),
      ].join('\n');
      expect(src.contains('WIND_GUIDE_LINK'), isFalse);
      expect(src.contains('_showWindGuideLink'), isFalse);
      expect(src.contains('WindGuideLink'), isFalse);
      expect(src.contains("Key('wind-guide-link')"), isFalse);
      // Nowhere in lib/ either.
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final text = f.readAsStringSync();
        expect(text.contains('WIND_GUIDE_LINK'), isFalse, reason: f.path);
        expect(text.contains('WindGuideLink'), isFalse, reason: f.path);
      }
    });
  });

  group('Turret step arrows', () {
    // HDF-2 (fixed by #349): #317 arrows were 28 pt wide (top) and 30·k pt
    // tall (side, ≈23 pt on a 320 pt phone). Now every arrow's tap area is
    // at least 44 × 44 pt where it fits and never lies over L-R.
    testWidgets('tap targets at least 44 pt on a 320 pt phone, none over '
        'L-R', (tester) async {
      _seed();
      _size(tester, const Size(320, 2400));
      await tester.pumpWidget(_app(_profile(), BallisticsView.shot));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(ScopeDialKeys.turretToggle));
      final toggle = tester.getRect(find.byKey(ScopeDialKeys.turretToggle));
      for (final tip in const [
        'Yükseklik kulesi 1 klik yukarı',
        'Yükseklik kulesi 1 klik aşağı',
        'Rüzgâr kulesi 1 klik sağa',
        'Rüzgâr kulesi 1 klik sola',
      ]) {
        final r = tester.getRect(find.byTooltip(tip));
        expect(r.width, greaterThanOrEqualTo(44), reason: tip);
        expect(r.height, greaterThanOrEqualTo(44), reason: tip);
        expect(
          r.overlaps(toggle),
          isFalse,
          reason: '$tip tap area $r overlaps L-R $toggle',
        );
      }
    });
  });
}
