// Tüfek eğimi (incline) and Dürbün eğimi (cant) on Atış: measuring with the
// phone, entering by hand, and the effect on the shown corrections.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/incline_measure_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_cant_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/shot_angle_math.dart';
import 'package:sniper_turk/tools/ports/camera_service.dart';
import 'package:sniper_turk/tools/ports/tilt_provider.dart';

import 'support/tool_fakes.dart';

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

Future<void> _pumpShot(WidgetTester tester, TestTilt tilt) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      const Scaffold(
        body: BallisticsScreen(profile: _profile, view: BallisticsView.shot),
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
  await tester.pumpAndSettle();
  await tester.tap(find.text('Hesapla'));
  await tester.pumpAndSettle();
}

String _cardText(WidgetTester tester, Key key) => tester
    .widgetList<Text>(
      find.descendant(of: find.byKey(key), matching: find.byType(Text)),
    )
    .map((t) => t.data ?? '')
    .join(' | ');

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
      // Rolling the phone sideways does not change the incline.
      expect(
        ShotAngleMath.inclineDeg(const GravityVector(5, 8, -2)),
        closeTo(ShotAngleMath.inclineDeg(const GravityVector(0, 9.434, -2))!, 1e-3),
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

  testWidgets('Atış: entering an incline lowers the elevation correction', (
    tester,
  ) async {
    await _pumpShot(tester, TestTilt());
    final level = _cardText(tester, const Key('elevation-status-card'));

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
    final inclined = _cardText(tester, const Key('elevation-status-card'));
    expect(inclined, isNot(level));
    expect(find.textContaining('Tüfek eğimi ∠-35°'), findsOneWidget);
  });

  testWidgets('Atış: a canted scope adds a sideways correction', (
    tester,
  ) async {
    await _pumpShot(tester, TestTilt());
    expect(_cardText(tester, const Key('wind-status-card')), contains('0 girildi'));

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
    final card = _cardText(tester, const Key('wind-status-card'));
    expect(card, contains('Yan (rüzgâr + dürbün eğimi)'));
    // A right cant moves the shot right: dial left.
    expect(card, contains('L (sola)'));

    // Dürbün eğimini sil → back to level.
    await tester.tap(find.byKey(const Key('shot-cant')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(ScopeCantScreen.clearKey));
    await tester.tap(find.byKey(ScopeCantScreen.clearKey));
    await tester.pumpAndSettle();
    expect(find.text('Yok'), findsOneWidget);
  });
}
