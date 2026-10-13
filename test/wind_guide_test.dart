// Owner, 2026-10-13 19:43: Rüzgâr gözlemi wrote a Beaufort class middle into
// Rüzgâr hızı and silently replaced a fetched or measured wind (2 m/s →
// Orta 4,4). It is hidden; a display-only "Rüzgârı gözle tahmin et" guide
// sits below the Rüzgâr card and above "Pro Ayarlara Geç".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/beaufort.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/wind_guide.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-guide',
  name: 'Rehber',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _metricLines = [
  'Duman dümdüz yükselir: 0–0,2 m/s',
  'Duman hafifçe yana kayar: 0,3–1,5 m/s',
  'Rüzgâr yüzde hissedilir, yapraklar hışırdar: 1,6–3,3 m/s',
  'Yapraklar ve ince dallar durmadan kıpırdar: 3,4–5,4 m/s',
  'Toz ve kâğıt kalkar, küçük dallar sallanır: 5,5–7,9 m/s',
  'Küçük ağaçlar sallanır: 8,0–10,7 m/s',
];

const _imperialLines = [
  'Duman dümdüz yükselir: 0–0,4 mph',
  'Duman hafifçe yana kayar: 0,7–3,4 mph',
  'Rüzgâr yüzde hissedilir, yapraklar hışırdar: 3,6–7,4 mph',
  'Yapraklar ve ince dallar durmadan kıpırdar: 7,6–12,1 mph',
  'Toz ve kâğıt kalkar, küçük dallar sallanır: 12,3–17,7 mph',
  'Küçük ağaçlar sallanır: 17,9–23,9 mph',
];

const _weatherButton = Key('environment-fill-weather');
const _proButton = Key('environment-continue-pro');

Finder _field(Key k) =>
    find.descendant(of: find.byKey(k), matching: find.byType(TextField));

String _text(WidgetTester tester, Key k) =>
    tester.widget<TextField>(_field(k)).controller!.text;

Future<void> _screen(
  WidgetTester tester, {
  Size size = const Size(430, 2600),
  double textScale = 1.0,
  ThemeData? theme,
  double fetchedWindMps = 5.0,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final services = testServices(
    location: TestLocation(const LocationFix(39.9, 32.8)),
    weather: TestWeather(
      observation(
        fetchedAt: DateTime.utc(2026, 10, 13, 16, 43),
        windSpeedMps: fetchedWindMps,
      ),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? MenzilTheme.light(),
      builder: (context, c) => ToolsServicesScope(
        services: services,
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
      ),
      home: Scaffold(
        body: BallisticsScreen(
          profile: _profile,
          view: BallisticsView.environment,
          onContinueToPro: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the lines come from Beaufort.classes, forces 0–5, owner text', () {
    expect(
      [for (final b in Beaufort.guideClasses) b.force],
      [0, 1, 2, 3, 4, 5],
    );
    expect(WindGuide.lines(metric: true), _metricLines);
  });

  test('imperial shows the same ranges in mph, Turkish comma', () {
    expect(WindGuide.lines(metric: false), _imperialLines);
  });

  testWidgets('guide sits between the Rüzgâr card and Pro Ayarlara Geç', (
    tester,
  ) async {
    await _screen(tester);
    // Hidden by default (WIND_OBSERVATION).
    expect(find.text('Rüzgâr gözlemi'), findsNothing);

    final title = find.byKey(const Key('wind-guide-title'));
    expect(title, findsOneWidget);
    expect(tester.widget<Text>(title).data, 'Rüzgârı gözle tahmin et');
    for (var i = 0; i < 6; i++) {
      final line = find.byKey(Key('wind-guide-line-$i'));
      expect(line, findsOneWidget);
      expect(tester.widget<Text>(line).data, _metricLines[i]);
    }
    expect(find.byKey(const Key('wind-guide-line-6')), findsNothing);

    final windCard = find
        .ancestor(
          of: find.byKey(BallisticsFieldKeys.wind),
          matching: find.byType(MenzilCard),
        )
        .first;
    final cardRect = tester.getRect(windCard);
    final titleRect = tester.getRect(title);
    final lastRect = tester.getRect(find.byKey(const Key('wind-guide-line-5')));
    final proRect = tester.getRect(find.byKey(_proButton));
    expect(titleRect.top, greaterThanOrEqualTo(cardRect.bottom));
    for (var i = 1; i < 6; i++) {
      expect(
        tester.getRect(find.byKey(Key('wind-guide-line-$i'))).top,
        greaterThan(
          tester.getRect(find.byKey(Key('wind-guide-line-${i - 1}'))).top,
        ),
      );
    }
    expect(lastRect.bottom, lessThanOrEqualTo(proRect.top));
  });

  testWidgets('imperial block shows mph', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: const Scaffold(body: WindGuideBlock(metric: false)),
      ),
    );
    for (var i = 0; i < 6; i++) {
      expect(
        tester.widget<Text>(find.byKey(Key('wind-guide-line-$i'))).data,
        _imperialLines[i],
      );
    }
    expect(find.textContaining('m/s'), findsNothing);
  });

  testWidgets('typing a wind speed is unaffected by the guide', (tester) async {
    await _screen(tester);
    await tester.ensureVisible(_field(BallisticsFieldKeys.wind));
    await tester.enterText(_field(BallisticsFieldKeys.wind), '2');
    await tester.pumpAndSettle();
    expect(_text(tester, BallisticsFieldKeys.wind), '2');
    // Tapping the guide writes nothing.
    await tester.ensureVisible(find.byKey(const Key('wind-guide-line-3')));
    await tester.tap(find.byKey(const Key('wind-guide-line-3')));
    await tester.pumpAndSettle();
    expect(_text(tester, BallisticsFieldKeys.wind), '2');
  });

  testWidgets('a fetched wind stays as fetched', (tester) async {
    await _screen(tester, fetchedWindMps: 2.0);
    await tester.ensureVisible(find.byKey(_weatherButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_weatherButton));
    await tester.pumpAndSettle();
    expect(_text(tester, BallisticsFieldKeys.wind), '2.0');
    await tester.ensureVisible(find.byKey(const Key('wind-guide-title')));
    await tester.tap(find.byKey(const Key('wind-guide-line-3')));
    await tester.pumpAndSettle();
    expect(_text(tester, BallisticsFieldKeys.wind), '2.0');
  });

  testWidgets('narrow phone, text scale 1.3, dark theme: no overflow', (
    tester,
  ) async {
    await _screen(
      tester,
      size: const Size(320, 3600),
      textScale: 1.3,
      theme: MenzilTheme.dark(),
    );
    expect(tester.takeException(), isNull);
    final title = find.byKey(const Key('wind-guide-title'));
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 6; i++) {
      final r = tester.getRect(find.byKey(Key('wind-guide-line-$i')));
      expect(r.right, lessThanOrEqualTo(320));
    }
  });
}
