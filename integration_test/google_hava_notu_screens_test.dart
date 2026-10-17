// Screenshots for "Google hava verisi" (owner, 2026-10-17, TestFlight 113):
// Hava Durumu after "Konumdan canlı hava verisi al" with the Hava note
// "(Google, HH:MM)" and the Rüzgâr card note, at 390 × 844 and 320 × 568 pt,
// plus one MET Norway fallback shot at 390 pt.
// Run by .github/workflows/sim-screens.yml with
// `test: integration_test/google_hava_notu_screens_test.dart`. The weather
// service and location are FAKES (no key in the Simulator build): the same
// app shell as SniperTurkApp, with ToolsServicesScope holding test doubles.
// Report: docs/reports/google_hava_verisi.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/app_settings.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/tools/ports/clock.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/weather_provider.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/keyboard_done_bar.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import '../test/support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'sim-google-hava',
  name: 'Google hava',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

WeatherObservation _obs(WeatherSource source) {
  final now = DateTime.now();
  final at = DateTime(now.year, now.month, now.day, now.hour).toUtc();
  return WeatherObservation(
    temperatureC: 14.6,
    humidityPercent: 63,
    pressureHpa: 1016.2,
    pressureKind: PressureKind.seaLevel,
    windSpeedMps: 4.2,
    windFromDeg: 315,
    validAt: at,
    fetchedAt: DateTime.now().toUtc(),
    sourceName: source == WeatherSource.google
        ? 'Google'
        : 'MET Norway (CC BY 4.0)',
    source: source,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Hava Durumu notes at 390 and 320 pt', (tester) async {
    final failures = <String>[];
    var counter = 0;

    Future<void> settle() async {
      try {
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 8),
        );
      } on FlutterError {
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }

    Future<void> shot(String name) async {
      await settle();
      counter++;
      debugPrint('SIMSCREEN:${counter.toString().padLeft(2, '0')}_$name');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 15)),
      );
    }

    void text(String what, Key key) {
      final f = find.byKey(key);
      if (f.evaluate().isEmpty) {
        debugPrint('SIMTEXT:$what: yok');
        return;
      }
      final r = tester.getRect(f.first);
      debugPrint(
        'SIMTEXT:$what: ${r.left.toStringAsFixed(1)},'
        '${r.top.toStringAsFixed(1)},${r.right.toStringAsFixed(1)},'
        '${r.bottom.toStringAsFixed(1)}',
      );
    }

    final runs = [
      (const Size(390, 844), WeatherSource.google),
      (const Size(320, 568), WeatherSource.google),
      (const Size(390, 844), WeatherSource.metNorway),
    ];
    for (final (size, source) in runs) {
      final name = 'hava_${source.name}_${size.width.toInt()}';
      try {
        await (await SharedPreferences.getInstance()).clear();
        await PersistentProfileStore().save(_profile);
        await PersistentActiveProfileStore().setActiveProfileId(_profile.id);
        final settings = AppSettings()..load();
        final services = testServices(
          location: TestLocation(const LocationFix(39.92, 32.85)),
          weather: TestWeather(_obs(source)),
          clock: const _Now(),
        );
        final view = tester.view;
        await tester.pumpWidget(
          ColoredBox(
            color: const Color(0xFF6E6E6E),
            child: Center(
              child: SizedBox.fromSize(
                size: size,
                child: MediaQuery(
                  data: MediaQueryData.fromView(view).copyWith(size: size),
                  child: AppSettingsScope(
                    key: ValueKey(name),
                    settings: settings,
                    child: ToolsServicesScope(
                      services: services,
                      child: MaterialApp(
                        debugShowCheckedModeBanner: false,
                        theme: MenzilTheme.dark(),
                        darkTheme: MenzilTheme.dark(),
                        themeMode: ThemeMode.dark,
                        home: const HomeScreen(),
                        builder: (context, child) =>
                            KeyboardDoneBar(child: child!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await settle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        await settle();
        await tester.tap(find.text('Hava Durumu').last);
        await settle();
        final fill = find.byKey(const Key('environment-fill-weather'));
        await tester.ensureVisible(fill);
        await settle();
        await tester.tap(fill);
        await settle();
        const hava = Key('environment-weather-status');
        const ruzgar = Key('environment-wind-source-note');
        await Scrollable.ensureVisible(
          tester.element(find.byKey(hava)),
          alignment: 0.3,
        );
        text('$name hava', hava);
        await shot('${name}_hava');
        await Scrollable.ensureVisible(
          tester.element(find.byKey(ruzgar)),
          alignment: 0.8,
        );
        text('$name ruzgar', ruzgar);
        await shot('${name}_ruzgar');
      } catch (error) {
        final line = error.toString().split('\n').first;
        failures.add('$name: $line');
        debugPrint('SIMSTEP_FAIL:$name: $line');
        await shot('FAIL_$name');
      }
      final exception = tester.takeException();
      if (exception != null) {
        final line = exception.toString().split('\n').first;
        failures.add('$name: $line');
        debugPrint('SIMSTEP_FAIL:$name: $line');
      }
    }

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 30)),
    );
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}

class _Now implements Clock {
  const _Now();
  @override
  DateTime now() => DateTime.now();
}
