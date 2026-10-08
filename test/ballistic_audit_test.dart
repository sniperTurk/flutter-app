// Fixes from the 2026-10-08 ballistic audit (see AUDIT_2026-10-08.md):
// the wind card says which way the pellet drifts and which way to dial,
// the scope shows a target at its true size that grows with zoom, and
// Namlu çıkış hızı is entered in fps as on Profil.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/ballistics/wind_clock_picker.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _profile = RifleProfile(
  id: 'p-audit',
  name: 'Denetim',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-audit',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _ammo = <String, dynamic>{
  'id': 'c-audit',
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

Future<void> _pumpShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(_profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore()..value = 'p-audit',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The Rüzgâr box left Atış (owner, 2026-10-08): the scope's impact line
/// says where the pellet goes, "Çözümü kuleye kur" which way to dial.
Future<(String, String)> _windAfter(
  WidgetTester tester, {
  required String direction,
}) async {
  await tester.tap(find.text('Hava Durumu'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(BallisticsFieldKeys.wind), '4');
  // Clock face: 9 = from the left (90°), 3 = from the right (270°).
  final hour = direction == '90' ? 9 : 3;
  final dial = find.byKey(WindClockPicker.hourKey(hour));
  await tester.ensureVisible(dial);
  await tester.tap(dial);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Hedef'));
  await tester.pumpAndSettle();
  final impact = _impact(tester);
  return (impact, await _dialSolution(tester));
}

String _impact(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ScopeDialKeys.impactText)).data!;

/// Taps "Çözümü kuleye kur" and returns the "Kule: …" readout.
Future<String> _dialSolution(WidgetTester tester) async {
  final button = find.byKey(ScopeDialKeys.dialSolution);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  return tester.widget<Text>(find.textContaining('Kule:')).data!;
}

ScopeDialView _scope(double mag, {required bool ffp, double rangeM = 100}) =>
    ScopeDialView(
      unit: AngularUnit.mrad,
      clickValue: 0.1,
      elevationClicks: 0,
      windageClicks: 0,
      maxElevationClicks: 100,
      maxWindageClicks: 100,
      onElevationChanged: (_) {},
      onWindageChanged: (_) {},
      requiredUp: 1.5,
      firstFocalPlane: ffp,
      minMagnification: 6,
      maxMagnification: 24,
      magnification: mag,
      onMagnificationChanged: (_) {},
      rangeM: rangeM,
      samples: const [],
      toDisplayRange: (m) => m,
      distanceUnit: 'm',
      metric: true,
    );

double _targetPx(ScopeDialView v) => ScopeReticlePainter.targetRadiusPx(
  radius: 100,
  trueHalfField: v.trueHalfField,
  targetRadius: v.targetRadius!,
);

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_ammo]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  test('angleAtRange: 10 cm at 50 m is 2 mrad (≈ 6.9 MOA)', () {
    expect(
      ScopeDialMath.angleAtRange(0.10, 50, AngularUnit.mrad),
      closeTo(2.0, 1e-3),
    );
    expect(
      ScopeDialMath.angleAtRange(0.10, 50, AngularUnit.moa),
      closeTo(6.875, 0.01),
    );
    // Round trip with linearAtRange.
    final a = ScopeDialMath.angleAtRange(0.37, 83, AngularUnit.moa);
    expect(
      ScopeDialMath.linearAtRange(a, 83, AngularUnit.moa),
      closeTo(0.37, 1e-9),
    );
  });

  for (final ffp in const [true, false]) {
    test('zooming in makes the target bigger (${ffp ? 'FFP' : 'SFP'})', () {
      final low = _targetPx(_scope(6, ffp: ffp));
      final high = _targetPx(_scope(24, ffp: ffp));
      // 4× magnification = 4× bigger on screen, like a real scope.
      expect(high, greaterThan(low));
      expect(high / low, closeTo(4, 1e-9));
    });
  }

  test('a farther target is drawn smaller', () {
    final near = _targetPx(_scope(24, ffp: true, rangeM: 25));
    final far = _targetPx(_scope(24, ffp: true, rangeM: 100));
    expect(near, greaterThan(far));
  });

  testWidgets('scope workings state the target size', (tester) async {
    tester.view.physicalSize = const Size(430, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(child: _scope(12, ffp: true)),
        ),
      ),
    );
    // 10 cm at 100 m = 1 mrad.
    expect(
      find.textContaining('Hedef halkası Ø10 cm = 1.00 mrad'),
      findsOneWidget,
    );
  });

  testWidgets('wind from the left: drifts right, dial L', (tester) async {
    await _pumpShell(tester);
    final (impact, turret) = await _windAfter(tester, direction: '90');
    expect(impact, endsWith('cm sağ'));
    expect(turret, contains('klik sol'));
  });

  testWidgets('wind from the right: drifts left, dial R', (tester) async {
    await _pumpShell(tester);
    final (impact, turret) = await _windAfter(tester, direction: '270');
    expect(impact, endsWith('cm sol'));
    expect(turret, contains('klik sağ'));
  });

  testWidgets('velocity field is fps (270 m/s shown as 885.8)', (tester) async {
    tester.view.physicalSize = const Size(430, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // The shell no longer repeats Profil values on Hava Durumu (owner,
    // 2026-10-08); the full workspace still shows the field in fps.
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: const BallisticsScreen(profile: _profile),
      ),
    );
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(BallisticsFieldKeys.velocity),
        matching: find.byType(TextField),
      ),
    );
    // Profile stores 270 m/s = 885.8 fps.
    expect(field.controller!.text, '885.8');
  });
}
