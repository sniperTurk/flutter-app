// Tüfek eğimi (incline) and Dürbün eğimi (cant) on Pro Ayarlar: measuring
// with the phone, entering by hand, and the effect on Atış's corrections.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/incline_measure_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_cant_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/shot_angle_math.dart';
import 'package:sniper_turk/tools/ports/camera_service.dart';
import 'package:sniper_turk/tools/ports/tilt_provider.dart';
import 'package:sniper_turk/tools/tools_services.dart';

import 'support/tool_fakes.dart';

import 'support/pro_sections.dart';

const _profile = RifleProfile(
  id: 'p-angle',
  name: 'Eğim',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-angle',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _ammo = <String, dynamic>{
  'id': 'c-angle',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.25 slug',
  'caliberMm': 6.35,
  'grain': 33.95,
  'ammoType': 'slug',
  'bc': 0.08,
  'bcModel': 'G1',
};

GravityVector _pitched(double deg) {
  // Phone upright, camera tilted up by [deg]: y = g·cos, z = −g·sin.
  final r = deg * math.pi / 180;
  return GravityVector(0, 9.81 * math.cos(r), -9.81 * math.sin(r));
}

/// Incline and cant are set on Pro Ayarlar (owner, 2026-10-08); Atış shows
/// the result. Both views share one workspace state, as in the shell.
class _Workspace {
  final WidgetTester tester;
  final ToolsServices services;
  _Workspace(this.tester, TestTilt tilt)
    : services = testServices(
        tilt: tilt,
        camera: TestCamera(
          failure: const CameraUnavailable(
            CameraUnavailableReason.noCamera,
            'Kamera yok',
          ),
        ),
      );

  Future<void> show(BallisticsView view) async {
    await tester.pumpWidget(
      host(
        Scaffold(
          body: BallisticsScreen(profile: _profile, view: view),
        ),
        services: services,
      ),
    );
    await tester.pumpAndSettle();
  }
}

Future<_Workspace> _pumpShot(WidgetTester tester, TestTilt tilt) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final ws = _Workspace(tester, tilt);
  // Atış solves on its own when it opens: no Hesapla button.
  await ws.show(BallisticsView.shot);
  return ws;
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

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_ammo]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('ShotAngleMath', () {
    test('incline from the accelerometer', () {
      expect(
        ShotAngleMath.inclineDeg(const GravityVector(0, 9.81, 0)),
        closeTo(0, 1e-9),
      );
      // Lying flat, screen up: camera points straight down.
      expect(
        ShotAngleMath.inclineDeg(const GravityVector(0, 0, 9.81)),
        closeTo(-90, 1e-9),
      );
      expect(ShotAngleMath.inclineDeg(_pitched(30)), closeTo(30, 0.05));
      expect(ShotAngleMath.inclineDeg(_pitched(-20)), closeTo(-20, 0.05));
      // No artificial limit: tipping past straight down keeps counting.
      expect(ShotAngleMath.inclineDeg(_pitched(-102)), closeTo(-102, 0.05));
      expect(ShotAngleMath.inclineDeg(_pitched(120)), closeTo(120, 0.05));
      // Rolling the phone sideways does not change the incline.
      expect(
        ShotAngleMath.inclineDeg(const GravityVector(5, 8, -2)),
        closeTo(
          ShotAngleMath.inclineDeg(const GravityVector(0, 9.434, -2))!,
          1e-3,
        ),
      );
      expect(ShotAngleMath.inclineDeg(const GravityVector(0, 0, 1)), isNull);
    });

    test('cant: clockwise roll is positive', () {
      // Rotated clockwise by 10°: x = −g·sin, y = g·cos.
      expect(
        ShotAngleMath.cantDeg(const GravityVector(-1.7035, 9.6610, 0)),
        closeTo(10, 0.01),
      );
      expect(
        ShotAngleMath.cantDeg(const GravityVector(1.7035, 9.6610, 0)),
        closeTo(-10, 0.01),
      );
      expect(ShotAngleMath.cantDeg(const GravityVector(0, 0, 9.8)), isNull);
    });

    test('clock and degree text', () {
      expect(ShotAngleMath.clock(0), '0:00');
      expect(ShotAngleMath.clock(90), '3:00');
      expect(ShotAngleMath.clock(-30), '11:00');
      expect(ShotAngleMath.degrees(-0.3), '0°');
      expect(ShotAngleMath.degrees(-12.4), '−12°');
      expect(ShotAngleMath.relative(170, -20), closeTo(-170, 1e-9));
    });
  });

  testWidgets('incline screen: live angle, Set 0°, OK returns it', (
    tester,
  ) async {
    final tilt = TestTilt();
    double? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<double>(
                  MaterialPageRoute(
                    builder: (_) => const InclineMeasureScreen(),
                  ),
                );
              },
              child: const Text('aç'),
            ),
          ),
        ),
        services: testServices(
          tilt: tilt,
          camera: TestCamera(
            failure: const CameraUnavailable(
              CameraUnavailableReason.noCamera,
              'Kamera yok',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    // Works without a camera: the angle comes from the accelerometer.
    for (var i = 0; i < 40; i++) {
      tilt.controller.add(TiltAvailable(_pitched(-12)));
      await tester.pump();
    }
    expect(
      tester.widget<Text>(find.byKey(InclineMeasureScreen.angleKey)).data,
      '−12°',
    );
    await tester.tap(find.byKey(InclineMeasureScreen.okKey));
    await tester.pumpAndSettle();
    expect(result, closeTo(-12, 0.2));

    // Set 0° makes the current reading the reference.
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 40; i++) {
      tilt.controller.add(TiltAvailable(_pitched(5)));
      await tester.pump();
    }
    await tester.tap(find.byKey(InclineMeasureScreen.zeroKey));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(InclineMeasureScreen.angleKey)).data,
      '0°',
    );
  });

  testWidgets('Pro: entering an incline lowers the elevation correction', (
    tester,
  ) async {
    final ws = await _pumpShot(tester, TestTilt());
    final level = _impact(tester);
    // The tiles left Atış for Pro Ayarlar.
    expect(find.byKey(const Key('shot-incline')), findsNothing);
    expect(find.byKey(const Key('shot-cant')), findsNothing);

    await ws.show(BallisticsView.pro);
    await openProFor(tester, const Key('shot-incline'));
    await tester.ensureVisible(find.byKey(const Key('shot-incline')));
    await tester.tap(find.byKey(const Key('shot-incline')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('incline-field')),
        matching: find.byType(TextField),
      ),
      '-35',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('incline-done')));
    await tester.pumpAndSettle();

    expect(find.text('∠ −35°'), findsOneWidget);
    await ws.show(BallisticsView.shot);
    final inclined = _impact(tester);
    expect(inclined, isNot(level));
    expect(find.textContaining('Tüfek eğimi ∠-35°'), findsOneWidget);
  });

  testWidgets('Pro: a canted scope adds a sideways correction on Atış', (
    tester,
  ) async {
    final ws = await _pumpShot(tester, TestTilt());
    // Calm and level: nothing sideways.
    expect(_impact(tester).split(' · ').last, startsWith('0.0 cm'));

    await ws.show(BallisticsView.pro);
    await openProFor(tester, const Key('shot-cant'));
    await tester.ensureVisible(find.byKey(const Key('shot-cant')));
    await tester.tap(find.byKey(const Key('shot-cant')));
    await tester.pumpAndSettle();
    expect(find.text('Dürbün eğim açısı'), findsWidgets);
    await tester.enterText(
      find.descendant(
        of: find.byKey(ScopeCantScreen.fieldKey),
        matching: find.byType(TextField),
      ),
      '8',
    );
    await tester.pump();
    await tester.tap(find.byKey(ScopeCantScreen.saveKey));
    await tester.pumpAndSettle();

    expect(find.text('8° sağa'), findsOneWidget);
    await ws.show(BallisticsView.shot);
    // A right cant moves the shot right: dial left.
    final side = _impact(tester).split(' · ').last;
    expect(side, isNot(startsWith('0.0 cm')));
    expect(side, endsWith('sağ'));
    expect(await _dialSolution(tester), contains('klik sol'));

    // Dürbün eğimini sil → back to level.
    await ws.show(BallisticsView.pro);
    await openProFor(tester, const Key('shot-cant'));
    await tester.ensureVisible(find.byKey(const Key('shot-cant')));
    await tester.tap(find.byKey(const Key('shot-cant')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(ScopeCantScreen.clearKey));
    await tester.tap(find.byKey(ScopeCantScreen.clearKey));
    await tester.pumpAndSettle();
    expect(find.text('Yok'), findsOneWidget);
  });
}
