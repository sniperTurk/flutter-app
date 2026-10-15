// Owner, 2026-10-13 19:43: Rüzgâr gözlemi wrote a Beaufort class middle into
// Rüzgâr hızı and silently replaced a fetched or measured wind (2 m/s →
// Orta 4,4). It is hidden; a display-only "Rüzgârı gözle tahmin et" guide
// replaces it. Follow-up (19:49): only a "Rüzgâr tahmini nasıl yapılır?"
// link sits below the Rüzgâr card and above "Pro Ayarlara Geç"; the guide
// opens in a popup (MenzilInfoButton dialog style) with a Kapat action.
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
const _link = Key('wind-guide-link');
// Owner, 2026-10-15: the Rüzgâr heading's ⓘ opens the guide; the link is
// hidden behind WIND_GUIDE_LINK.
const _windInfo = Key('environment-wind-info');
const _title = Key('wind-guide-title');
const _close = Key('wind-guide-close');

Finder _line(int i) => find.byKey(Key('wind-guide-line-$i'));

Future<void> _openGuide(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(_windInfo));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_windInfo));
  await tester.pumpAndSettle();
}

void _expectLines(WidgetTester tester, List<String> expected) {
  for (var i = 0; i < 6; i++) {
    expect(_line(i), findsOneWidget);
    expect(tester.widget<Text>(_line(i)).data, expected[i]);
    expect(tester.widget<Text>(_line(i)).textAlign, TextAlign.left);
  }
  expect(_line(6), findsNothing);
}

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

  testWidgets('the Rüzgâr ⓘ holds the guide; the link is hidden', (
    tester,
  ) async {
    await _screen(tester);
    // Hidden by default (WIND_OBSERVATION).
    expect(find.text('Rüzgâr gözlemi'), findsNothing);
    // No inline guide and no link (WIND_GUIDE_LINK, owner 2026-10-15).
    expect(find.byKey(_title), findsNothing);
    expect(_line(0), findsNothing);
    expect(find.byKey(_link), findsNothing);
    expect(find.text('Rüzgâr tahmini nasıl yapılır?'), findsNothing);
    // The link text is kept for the flag and the ⓘ's VoiceOver label.
    expect(WindGuide.linkLabel, 'Rüzgâr tahmini nasıl yapılır?');

    // The ⓘ sits in the Rüzgâr heading, above the Rüzgâr card.
    final info = find.byKey(_windInfo);
    expect(info, findsOneWidget);
    expect(
      find.ancestor(of: info, matching: find.byType(MenzilSectionHeader)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.ancestor(of: info, matching: find.byType(MenzilSectionHeader)),
        matching: find.text('Rüzgâr'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip(WindGuide.linkLabel), findsOneWidget);
    final windCard = find
        .ancestor(
          of: find.byKey(BallisticsFieldKeys.wind),
          matching: find.byType(MenzilCard),
        )
        .first;
    expect(
      tester.getRect(info).bottom,
      lessThanOrEqualTo(tester.getRect(windCard).top),
    );
    // Nothing between the Rüzgâr card and Pro Ayarlara Geç any more.
    expect(
      tester.getRect(find.byKey(_proButton)).top,
      greaterThanOrEqualTo(tester.getRect(windCard).bottom),
    );
    final size = tester.getSize(info);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('the Rüzgâr ⓘ opens the popup with 6 lines; Kapat closes it', (
    tester,
  ) async {
    await _screen(tester);
    await _openGuide(tester);
    expect(find.byKey(const Key('wind-guide-dialog')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(_title)).data, WindGuide.title);
    expect(find.text('Rüzgârı gözle tahmin et'), findsOneWidget);
    _expectLines(tester, _metricLines);
    for (var i = 1; i < 6; i++) {
      expect(
        tester.getRect(_line(i)).top,
        greaterThan(tester.getRect(_line(i - 1)).top),
      );
    }
    expect(find.text('Kapat'), findsOneWidget);
    await tester.tap(find.byKey(_close));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wind-guide-dialog')), findsNothing);
    expect(_line(0), findsNothing);
  });

  testWidgets('imperial popup shows mph', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: const Scaffold(body: WindGuideLink(metric: false)),
      ),
    );
    await tester.tap(find.byKey(_link));
    await tester.pumpAndSettle();
    _expectLines(tester, _imperialLines);
    expect(find.textContaining('m/s'), findsNothing);
  });

  testWidgets('typing a wind speed is unaffected by the guide', (tester) async {
    await _screen(tester);
    await tester.ensureVisible(_field(BallisticsFieldKeys.wind));
    await tester.enterText(_field(BallisticsFieldKeys.wind), '2');
    await tester.pumpAndSettle();
    expect(_text(tester, BallisticsFieldKeys.wind), '2');
    // Opening the guide, tapping a line and closing writes nothing.
    await _openGuide(tester);
    await tester.tap(_line(3));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_close));
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
    await _openGuide(tester);
    await tester.tap(_line(3));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_close));
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
    await _openGuide(tester);
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 6; i++) {
      final r = tester.getRect(_line(i));
      expect(r.right, lessThanOrEqualTo(320));
    }
    await tester.tap(find.byKey(_close));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
