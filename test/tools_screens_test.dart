// Widget tests for the Araçlar hub and tool screens. All platform access is
// replaced by test doubles (test/support/tool_fakes.dart); nothing here
// exercises a real GPS, compass, accelerometer or camera.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/tools/chronograph_screen.dart';
import 'package:sniper_turk/features/tools/compass_screen.dart';
import 'package:sniper_turk/features/tools/level_screen.dart';
import 'package:sniper_turk/features/tools/sight_height_screen.dart';
import 'package:sniper_turk/features/tools/tools_screen.dart';
import 'package:sniper_turk/features/tools/weather_screen.dart';
import 'package:sniper_turk/tools/ports/camera_service.dart';
import 'package:sniper_turk/tools/ports/heading_provider.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/photo_picker.dart';
import 'package:sniper_turk/tools/ports/tilt_provider.dart';
import 'package:sniper_turk/tools/ports/weather_provider.dart';

import 'support/tool_fakes.dart';

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  group('Tool hub', () {
    testWidgets('lists the seven V1 tools and no separate vision tool', (tester) async {
      await tester.pumpWidget(host(const Scaffold(body: ToolsScreen())));
      for (final k in ['chronograph', 'sight-height', 'compass', 'level', 'weather', 'catalog', 'settings']) {
        expect(find.byKey(Key('tool-$k')), findsOneWidget, reason: k);
      }
      expect(find.textContaining('Qwen'), findsNothing);
    });

    testWidgets('tiles open their screens', (tester) async {
      await tester.pumpWidget(host(const Scaffold(body: ToolsScreen())));
      await tester.tap(find.byKey(const Key('tool-compass')));
      await tester.pumpAndSettle();
      expect(find.byType(CompassScreen), findsOneWidget);
      await _unmount(tester);
    });
  });

  group('Pusula', () {
    testWidgets('no sensor data: no heading is invented', (tester) async {
      final heading = TestHeading();
      await tester.pumpWidget(host(const CompassScreen(), services: testServices(heading: heading)));
      await tester.pump();
      expect(find.textContaining('°'), findsNothing);
      heading.controller.add(const HeadingUnavailable(HeadingUnavailableReason.noSensor));
      await tester.pump();
      expect(find.text('Bu cihazda pusula sensörü bulunamadı.'), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('available reading shows degrees and abbreviation', (tester) async {
      final heading = TestHeading();
      await tester.pumpWidget(host(const CompassScreen(), services: testServices(heading: heading)));
      await tester.pump();
      heading.controller.add(const HeadingAvailable(HeadingReading(90, accuracyDeg: 5)));
      await tester.pump();
      expect(find.textContaining('90°'), findsWidgets);
      expect(find.text('90°  D'), findsOneWidget);
      expect(find.text('E'), findsNothing, reason: 'Turkish abbreviations only');
      await _unmount(tester);
    });

    testWidgets('a still phone keeps its last bearing (iOS sends no event without change)', (tester) async {
      final heading = TestHeading();
      await tester.pumpWidget(host(const CompassScreen(), services: testServices(heading: heading)));
      await tester.pump();
      heading.controller.add(const HeadingAvailable(HeadingReading(90, accuracyDeg: 5)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('90°  D'), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('invalid (negative) iOS heading shows a reason, not a bearing', (tester) async {
      final heading = TestHeading();
      await tester.pumpWidget(host(const CompassScreen(), services: testServices(heading: heading)));
      await tester.pump();
      heading.controller.add(const HeadingUnavailable(HeadingUnavailableReason.noReference));
      await tester.pump();
      expect(find.textContaining('geçersiz bir referans değeri'), findsOneWidget);
      expect(find.textContaining('Konum ayarlarını kontrol edip'), findsOneWidget);
      expect(find.textContaining('°'), findsNothing);
      await _unmount(tester);
    });

    testWidgets('poor accuracy shows the calibration notice', (tester) async {
      final heading = TestHeading();
      await tester.pumpWidget(host(const CompassScreen(), services: testServices(heading: heading)));
      await tester.pump();
      heading.controller.add(const HeadingAvailable(HeadingReading(10, accuracyDeg: 60)));
      await tester.pump();
      expect(find.text('Kalibrasyon gerekli'), findsOneWidget);
      await _unmount(tester);
    });
  });

  group('Su Terazisi', () {
    testWidgets('shows X/Y with 0.01° resolution and the resolution caveat', (tester) async {
      final tilt = TestTilt();
      await tester.pumpWidget(host(const LevelScreen(), services: testServices(tilt: tilt)));
      await tester.pump();
      tilt.controller.add(const TiltAvailable(GravityVector(0.5, -0.3, 9.79)));
      await tester.pump();
      expect(find.textContaining(RegExp(r'-?\d+,\d{2}°')), findsWidgets);
      expect(find.textContaining('yalnızca ekran çözünürlüğüdür'), findsOneWidget);
      // Design: circular gauge + X horizontal tube + Y vertical tube, together.
      expect(find.byKey(const Key('level-circle')), findsOneWidget);
      expect(find.byKey(const Key('level-tube-x')), findsOneWidget);
      expect(find.byKey(const Key('level-tube-y')), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('state is conveyed by text, not colour alone', (tester) async {
      final tilt = TestTilt();
      await tester.pumpWidget(host(const LevelScreen(), services: testServices(tilt: tilt)));
      await tester.pump();
      tilt.controller.add(const TiltAvailable(GravityVector(0, 0, 9.81)));
      await tester.pump();
      expect(find.text('Seviyede'), findsOneWidget);
      tilt.controller.add(const TiltAvailable(GravityVector(2, 0, 9.6)));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Eğik'), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('sensor missing shows a message, not a gauge value', (tester) async {
      final tilt = TestTilt();
      await tester.pumpWidget(host(const LevelScreen(), services: testServices(tilt: tilt)));
      await tester.pump();
      tilt.controller.add(const TiltUnavailable(TiltUnavailableReason.noSensor));
      await tester.pump();
      expect(find.text('Bu cihazda ivmeölçer bulunamadı.'), findsOneWidget);
      await _unmount(tester);
    });
  });

  group('Hava & Rüzgâr', () {
    testWidgets('idle -> fresh data with source and non-measurement notice', (tester) async {
      final clock = TestClock(DateTime.utc(2026, 10, 3, 12));
      final weather = TestWeather(observation(fetchedAt: clock.current));
      await tester.pumpWidget(host(const WeatherScreen(), services: testServices(weather: weather, clock: clock)));
      expect(find.text('Hava verisini getir'), findsOneWidget);
      expect(find.text('Bu bir ölçüm değildir'), findsOneWidget);
      await tester.tap(find.text('Hava verisini getir'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('weather-wind-speed')), findsOneWidget);
      expect(find.text('Güncel'), findsOneWidget);
      expect(find.textContaining('Kaynak: Test servisi'), findsOneWidget);
      expect(find.textContaining('270°'), findsOneWidget);
    });

    testWidgets('shows loading while the service is pending', (tester) async {
      final clock = TestClock(DateTime.utc(2026, 10, 3, 12));
      final weather = TestWeather(null)..hold = Completer<WeatherObservation>();
      await tester.pumpWidget(host(const WeatherScreen(), services: testServices(weather: weather, clock: clock)));
      await tester.tap(find.text('Hava verisini getir'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Hava verisi yükleniyor…'), findsOneWidget);
      weather.hold!.complete(observation(fetchedAt: clock.current));
      await tester.pumpAndSettle();
    });

    testWidgets('offline failure without cache shows an error and retry', (tester) async {
      final weather = TestWeather(const WeatherFailure(WeatherFailureKind.offline, 'x'));
      await tester.pumpWidget(host(const WeatherScreen(), services: testServices(weather: weather)));
      await tester.tap(find.text('Hava verisini getir'));
      await tester.pumpAndSettle();
      expect(find.textContaining('İnternet bağlantısı yok'), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
    });

    testWidgets('old data after a failed refresh is labelled stale with its time', (tester) async {
      final clock = TestClock(DateTime.utc(2026, 10, 3, 12));
      final weather = TestWeather(observation(fetchedAt: clock.current));
      await tester.pumpWidget(host(const WeatherScreen(), services: testServices(weather: weather, clock: clock)));
      await tester.tap(find.text('Hava verisini getir'));
      await tester.pumpAndSettle();
      clock.current = clock.current.add(const Duration(hours: 2));
      weather.outcome = const WeatherFailure(WeatherFailureKind.offline, 'x');
      await tester.tap(find.text('Yenile'));
      await tester.pumpAndSettle();
      expect(find.text('Bayat veri'), findsOneWidget);
      expect(find.text('Güncel'), findsNothing);
      expect(find.text('Güncelleme başarısız'), findsOneWidget);
      expect(find.byKey(const Key('weather-age')), findsOneWidget);
    });

    testWidgets('permanent location denial offers Settings and does not crash', (tester) async {
      final location = TestLocation(const LocationDenied(permanent: true));
      await tester.pumpWidget(host(const WeatherScreen(), services: testServices(location: location)));
      await tester.tap(find.text('Hava verisini getir'));
      await tester.pumpAndSettle();
      expect(find.textContaining('kalıcı olarak kapalı'), findsOneWidget);
      await tester.tap(find.text('Ayarlar\'ı aç'));
      await tester.pump();
      expect(location.settingsOpened, 1);
    });

    testWidgets('location services off is handled', (tester) async {
      final location = TestLocation(const LocationServiceOff());
      await tester.pumpWidget(host(const WeatherScreen(), services: testServices(location: location)));
      await tester.tap(find.text('Hava verisini getir'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Konum servisleri kapalı'), findsOneWidget);
    });
  });

  group('Kronograf', () {
    testWidgets('records shots and shows count/mean/ES; apply is gated', (tester) async {
      await tester.pumpWidget(host(const ChronographScreen()));
      await tester.enterText(find.byKey(const Key('chrono-velocity')), '270');
      await tester.ensureVisible(find.text('Atış ekle'));
      await tester.tap(find.text('Atış ekle'));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('chrono-velocity')), '272');
      await tester.ensureVisible(find.text('Atış ekle'));
      await tester.tap(find.text('Atış ekle'));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('4 · Sonuç'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('4 · Sonuç'), findsOneWidget);
      expect(find.textContaining('Aktarım için'), findsOneWidget);
    });

    testWidgets('PCP session shows pressure drop per shot', (tester) async {
      await tester.pumpWidget(host(const ChronographScreen()));
      await tester.enterText(find.byKey(const Key('chrono-start-bar')), '200');
      await tester.enterText(find.byKey(const Key('chrono-end-bar')), '180');
      for (final v in ['270', '268', '272']) {
        await tester.enterText(find.byKey(const Key('chrono-velocity')), v);
        await tester.ensureVisible(find.text('Atış ekle'));
        await tester.tap(find.text('Atış ekle'));
        await tester.pump();
      }
      await tester.ensureVisible(find.byKey(const Key('chrono-pressure')));
      expect(find.text('20 bar'), findsOneWidget);
      expect(find.text('6,7 bar'), findsOneWidget);
    });

    testWidgets('invalid velocity is rejected', (tester) async {
      await tester.pumpWidget(host(const ChronographScreen()));
      await tester.enterText(find.byKey(const Key('chrono-velocity')), 'abc');
      await tester.ensureVisible(find.text('Atış ekle'));
      await tester.tap(find.text('Atış ekle'));
      await tester.pump();
      expect(find.text('Geçerli bir hız girin.'), findsOneWidget);
    });
  });

  group('Sight Height', () {
    Future<void> enter(WidgetTester tester, String key, String text) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.enterText(find.byKey(Key(key)), text);
      await tester.pump();
    }

    testWidgets('vision is shown as not connected; nothing is uploaded', (tester) async {
      await tester.pumpWidget(host(const SightHeightScreen()));
      await tester.scrollUntilVisible(find.byKey(const Key('sight-vision-off')), 300, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const Key('sight-vision-off')), findsOneWidget);
    });

    testWidgets('muzzle-device and inclined-mount guidance is shown', (tester) async {
      await tester.pumpWidget(host(const SightHeightScreen()));
      await tester.scrollUntilVisible(find.byKey(const Key('sight-muzzle-warning')), 300, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const Key('sight-muzzle-warning')), findsOneWidget);
      expect(find.byKey(const Key('sight-inclined-mount')), findsOneWidget);
    });

    testWidgets('physical method: 3,18 + 5,80 + 21,40 + 32,00 = 62,4 mm (front/objective end)', (tester) async {
      await tester.pumpWidget(host(const SightHeightScreen()));
      await enter(tester, 'sight-bore', '6,36');
      await enter(tester, 'sight-wall', '5,8');
      await enter(tester, 'sight-gap', '21,4');
      await enter(tester, 'sight-objective', '64');
      await tester.ensureVisible(find.byKey(const Key('sight-total')));
      expect(find.text('62,4 mm'), findsOneWidget);
    });

    testWidgets('physical method is independent: no photo, no camera, no gallery needed', (tester) async {
      final picker = TestPhotoPicker();
      await tester.pumpWidget(host(const SightHeightScreen(), services: testServices(photoPicker: picker)));
      await enter(tester, 'sight-bore', '6,36');
      await enter(tester, 'sight-wall', '5,8');
      await enter(tester, 'sight-gap', '21,4');
      await enter(tester, 'sight-objective', '64');
      await tester.ensureVisible(find.byKey(const Key('sight-total')));
      expect(find.text('62,4 mm'), findsOneWidget);
      expect(picker.calls, 0);
    });

    testWidgets('incomplete physical input gives no total', (tester) async {
      await tester.pumpWidget(host(const SightHeightScreen()));
      await enter(tester, 'sight-bore', '6,36');
      await tester.ensureVisible(find.byKey(const Key('sight-total')));
      expect(find.text('— mm'), findsOneWidget);
    });

    testWidgets('both photo entry points exist: camera and gallery', (tester) async {
      await tester.pumpWidget(host(const SightHeightScreen()));
      await tester.ensureVisible(find.byKey(const Key('sight-capture-side')));
      expect(find.text('Fotoğraf çek'), findsOneWidget);
      expect(find.text('Galeriden seç'), findsOneWidget);
    });

    testWidgets('gallery denial shows a message instead of crashing', (tester) async {
      final picker = TestPhotoPicker(failure: const PhotoPickFailure(PhotoPickFailureReason.denied, 'Fotoğraflara erişim kapalı.'));
      await tester.pumpWidget(host(const SightHeightScreen(), services: testServices(photoPicker: picker)));
      await tester.ensureVisible(find.byKey(const Key('sight-gallery')));
      await tester.tap(find.byKey(const Key('sight-gallery')));
      await tester.pumpAndSettle();
      expect(picker.calls, 1);
      expect(find.text('Fotoğraflara erişim kapalı.'), findsOneWidget);
    });

    testWidgets('gallery cancel changes nothing', (tester) async {
      final picker = TestPhotoPicker();
      await tester.pumpWidget(host(const SightHeightScreen(), services: testServices(photoPicker: picker)));
      await tester.ensureVisible(find.byKey(const Key('sight-gallery')));
      await tester.tap(find.byKey(const Key('sight-gallery')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sight-mark-area')), findsNothing);
      expect(find.byKey(const Key('sight-photo-result')), findsNothing);
    });

    testWidgets('camera permission denial shows a message instead of crashing', (tester) async {
      final camera = TestCamera(
        failure: const CameraUnavailable(CameraUnavailableReason.deniedPermanently, 'Kamera erişimi kapalı. Ayarlar\'dan açın.'),
      );
      await tester.pumpWidget(host(const SightHeightScreen(), services: testServices(camera: camera)));
      await tester.ensureVisible(find.byKey(const Key('sight-capture-side')));
      await tester.tap(find.byKey(const Key('sight-capture-side')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kamera erişimi kapalı'), findsOneWidget);
      expect(find.text('Ayarları aç'), findsOneWidget);
    });

    testWidgets('side capture shows the alignment template', (tester) async {
      await tester.pumpWidget(host(const SightHeightScreen()));
      await tester.ensureVisible(find.byKey(const Key('sight-capture-side')));
      await tester.tap(find.byKey(const Key('sight-capture-side')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sight-template-side')), findsOneWidget);
      expect(find.byKey(const Key('sight-shutter')), findsOneWidget);
    });
  });

  group('Responsive', () {
    const sizes = <Size>[Size(320, 568), Size(393, 852), Size(430, 932)];
    for (final size in sizes) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('hub and tools fit ${size.width.toInt()}x${size.height.toInt()} at ${scale}x text', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          final screens = <Widget>[
            const Scaffold(body: ToolsScreen()),
            const CompassScreen(),
            const LevelScreen(),
            const WeatherScreen(),
            const ChronographScreen(),
            const SightHeightScreen(),
          ];
          for (final s in screens) {
            await tester.pumpWidget(host(s, textScale: scale));
            await tester.pump();
            expect(tester.takeException(), isNull, reason: '${s.runtimeType} $size $scale');
            await _unmount(tester);
          }
          // Su Terazisi WITH a reading: the X/Y row must lay out inside the
          // scroll view (previously an unbounded `stretch` row crashed here).
          final tilt = TestTilt();
          await tester.pumpWidget(host(const LevelScreen(), services: testServices(tilt: tilt), textScale: scale));
          await tester.pump();
          tilt.controller.add(const TiltAvailable(GravityVector(0.5, -0.3, 9.79)));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'LevelScreen with data $size $scale');
          await _unmount(tester);
        });
      }
    }
  });
}
