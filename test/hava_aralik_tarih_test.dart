// Hava Durumu: rüzgâr tarihi solda, bölüm aralıkları (owner, 2026-10-17
// Istanbul, 19:23 "Tarihi ve saati sola al tüm sayfada solda" option B,
// 20:02 "tüm önerileri uygula", 20:03 approved drawing "sağdaki görsel" and
// "rüzgâr yönü ve saat arasını değiştirme").
//
// Visible gaps are text-box edges (card edge → header text top, header text
// bottom → card edge), ±0,5 pt:
//   card → next section header text: 20 pt (was ≈30)
//   header text → its card:           8 pt (was ≈25)
//   last card → "Pro Ayarlar'a geç": 10 pt (unchanged)
//   "Rüzgâr yönü" title → clock:      8 pt to the hour-12 button (unchanged)
// Under the clock: "Saat N yönünde" on line 1, the date on line 2, both at
// the card content's left edge, 3 pt apart.
// Report: docs/reports/hava_aralik_tarih.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/wind_clock_picker.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-hava-aralik',
  name: 'Hava aralık',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _eps = 0.5;
const _proButton = Key('environment-continue-pro');
const _label = ValueKey('wind-clock-label');
const _date = ValueKey('wind-clock-date');

Future<void> _pump(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final services = testServices(
    location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
    weather: TestWeather(observation(fetchedAt: DateTime.utc(2026, 10, 17))),
    pressure: TestPressure(const PressureRead(998.4)),
    clock: TestClock(DateTime(2026, 10, 17, 19, 22)),
  );
  await tester.pumpWidget(
    host(
      Scaffold(
        body: BallisticsScreen(
          profile: _profile,
          view: BallisticsView.environment,
          onContinueToPro: () {},
        ),
      ),
      services: services,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

/// The card's visible edge (its Material, without the outer margin).
Rect _edge(WidgetTester tester, Finder card) => tester.getRect(
  find.descendant(of: card, matching: find.byType(Material)).first,
);

Finder _cardOf(Key fieldKey) => find
    .ancestor(of: find.byKey(fieldKey), matching: find.byType(MenzilCard))
    .first;

Finder _headerText(String title) => find.descendant(
  of: find.byType(MenzilSectionHeader),
  matching: find.text(title),
);

Finder _header(String title) =>
    find.ancestor(of: _headerText(title), matching: find.byType(MenzilSectionHeader));

Future<void> _setDirection(WidgetTester tester, String hour) async {
  await tester.ensureVisible(_field(BallisticsFieldKeys.windDirection));
  await tester.pumpAndSettle();
  await tester.enterText(_field(BallisticsFieldKeys.windDirection), hour);
  await tester.pumpAndSettle();
}

/// Header text 20 pt under [above]'s bottom and 8 pt over [card]'s top; its
/// ⓘ (if any) is a 44 pt target inside the header with the icon on the text.
void _expectSection(
  WidgetTester tester,
  String title, {
  required double above,
  required Rect card,
  Key? infoKey,
  required String why,
}) {
  expect(_headerText(title), findsOneWidget, reason: '$why $title');
  final text = tester.getRect(_headerText(title));
  expect(
    text.top - above,
    moreOrLessEquals(20, epsilon: _eps),
    reason: '$why: gap above "$title"',
  );
  expect(
    card.top - text.bottom,
    moreOrLessEquals(8, epsilon: _eps),
    reason: '$why: "$title" → card',
  );
  if (infoKey == null) return;
  final header = tester.getRect(_header(title));
  final info = tester.getRect(find.byKey(infoKey));
  expect(info.width, greaterThanOrEqualTo(44 - 0.01), reason: '$why $title');
  expect(info.height, greaterThanOrEqualTo(44 - 0.01), reason: '$why $title');
  expect(info.top, greaterThanOrEqualTo(header.top - 0.01), reason: why);
  expect(info.bottom, lessThanOrEqualTo(header.bottom + 0.01), reason: why);
  expect(info.bottom, lessThanOrEqualTo(card.top + 0.01), reason: why);
  final icon = tester.getRect(
    find.descendant(
      of: find.byKey(infoKey),
      matching: find.byIcon(Icons.info_outline),
    ),
  );
  // The icon sits on the title's first line.
  final lineHeight = tester.widget<Text>(_headerText(title)).style!.fontSize! *
      MediaQuery.textScalerOf(tester.element(_headerText(title))).scale(1) *
      1.1;
  expect(
    icon.center.dy,
    moreOrLessEquals(text.top + lineHeight / 2, epsilon: _eps),
    reason: '$why: ⓘ on "$title"',
  );
  // Right after the title, not over it.
  expect(info.left, greaterThanOrEqualTo(text.right - 0.01), reason: why);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (width, scale) in const [(390.0, 1.0), (320.0, 1.0), (320.0, 1.3)]) {
    final why = '$width pt ×$scale';

    testWidgets('wind label on line 1, date on line 2, both left ($why)', (
      tester,
    ) async {
      await _pump(tester, width: width, textScale: scale);
      await _setDirection(tester, '1');
      expect(tester.widget<Text>(find.byKey(_label)).data, 'Saat 1 yönünde');
      expect(tester.widget<Text>(find.byKey(_date)).data, '17.10.2026 19:22');
      final label = tester.getRect(find.byKey(_label));
      final date = tester.getRect(find.byKey(_date));
      // Line 2 directly under line 1 (~3 pt).
      expect(date.top - label.bottom, moreOrLessEquals(3, epsilon: _eps));
      // Both at the card content's left edge (card edge + 14 pt padding).
      final contentLeft =
          _edge(tester, _cardOf(BallisticsFieldKeys.wind)).left +
          MenzilSpace.lg;
      expect(label.left, moreOrLessEquals(contentLeft, epsilon: _eps));
      expect(date.left, moreOrLessEquals(contentLeft, epsilon: _eps));
      expect(
        tester.getRect(find.byType(WindClockPicker)).left,
        moreOrLessEquals(contentLeft, epsilon: _eps),
      );
      // One line each, same styles as before.
      for (final k in [_label, _date]) {
        final t = tester.widget<Text>(find.byKey(k));
        expect(t.maxLines, 1, reason: '$k');
        expect(t.softWrap, isFalse, reason: '$k');
        expect(
          find.ancestor(of: find.byKey(k), matching: find.byType(FittedBox)),
          findsWidgets,
          reason: '$k scales down instead of wrapping',
        );
      }
      final c = MenzilColors.of(tester.element(find.byKey(_label)));
      expect(tester.widget<Text>(find.byKey(_label)).style!.color, c.ink);
      expect(tester.widget<Text>(find.byKey(_date)).style!.color, c.ink2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('section gaps 20 / 8 pt, wind card top, button gap ($why)', (
      tester,
    ) async {
      await _pump(tester, width: width, textScale: scale);
      final top = _edge(tester, _cardOf(BallisticsFieldKeys.temperature));
      final baro = _edge(
        tester,
        find.byKey(const Key('environment-barometer-card')),
      );
      final alt = _edge(
        tester,
        find.byKey(const Key('environment-altitude-card')),
      );
      final wind = _edge(tester, _cardOf(BallisticsFieldKeys.wind));
      _expectSection(
        tester,
        'Basınç Ölçer',
        above: top.bottom,
        card: baro,
        infoKey: const Key('environment-barometer-info'),
        why: why,
      );
      _expectSection(
        tester,
        'İrtifa',
        above: baro.bottom,
        card: alt,
        infoKey: const Key('environment-altitude-info'),
        why: why,
      );
      _expectSection(
        tester,
        'Rüzgâr',
        above: alt.bottom,
        card: wind,
        infoKey: const Key('environment-wind-info'),
        why: why,
      );

      // Rüzgâr card: no empty card padding above the field labels; the
      // row starts with the ⓘ's 44 pt target at the card's top edge.
      final windInfo = tester.getRect(
        find.descendant(
          of: find.byKey(BallisticsFieldKeys.wind),
          matching: find.byType(MenzilInfoButton),
        ),
      );
      expect(windInfo.top, moreOrLessEquals(wind.top, epsilon: _eps));
      final labelTop = tester
          .getRect(
            find.descendant(
              of: find.byKey(BallisticsFieldKeys.wind),
              matching: find.text('Rüzgâr hızı'),
            ),
          )
          .top;
      debugPrint(
        'HAVA_ARALIK $why: wind card top → "Rüzgâr hızı" '
        '${(labelTop - wind.top).toStringAsFixed(1)} pt',
      );
      // The other cards keep their 14 pt inner top padding.
      final tempInfo = tester.getRect(
        find.descendant(
          of: find.byKey(BallisticsFieldKeys.temperature),
          matching: find.byType(MenzilInfoButton),
        ),
      );
      expect(
        tempInfo.top - top.top,
        moreOrLessEquals(MenzilSpace.lg, epsilon: _eps),
      );

      // "Rüzgâr yönü" title → clock unchanged (title bottom → hour 12).
      final title = tester.getRect(
        find.byKey(const ValueKey('wind-clock-title')),
      );
      final twelve = tester.getRect(find.byKey(WindClockPicker.hourKey(12)));
      expect(twelve.top - title.bottom, moreOrLessEquals(8, epsilon: _eps));

      // Last card → "Pro Ayarlar'a geç" unchanged.
      final button = tester.getRect(find.byKey(_proButton));
      expect(button.top - wind.bottom, moreOrLessEquals(10, epsilon: _eps));

      // Hava özeti: the same 20 / 8 pt.
      final summary = _edge(
        tester,
        find.byKey(const Key('environment-summary-card')),
      );
      _expectSection(
        tester,
        'Hava özeti',
        above: button.bottom,
        card: summary,
        why: why,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pressure warning between İrtifa and Rüzgâr: no overlap', (
    tester,
  ) async {
    await _pump(tester);
    await tester.ensureVisible(_field(BallisticsFieldKeys.pressure));
    await tester.pumpAndSettle();
    await tester.enterText(_field(BallisticsFieldKeys.pressure), '900');
    await tester.pumpAndSettle();
    final warning = find.byKey(const Key('environment-pressure-warning'));
    expect(warning, findsOneWidget);
    final alt = _edge(tester, find.byKey(const Key('environment-altitude-card')));
    final box = tester.getRect(
      find.descendant(of: warning, matching: find.byType(DecoratedBox)).first,
    );
    // İrtifa card → warning as before (10 pt).
    expect(box.top - alt.bottom, moreOrLessEquals(10, epsilon: _eps));
    final text = tester.getRect(_headerText('Rüzgâr'));
    expect(text.top - box.bottom, greaterThanOrEqualTo(20 - _eps));
    final wind = _edge(tester, _cardOf(BallisticsFieldKeys.wind));
    expect(wind.top - text.bottom, moreOrLessEquals(8, epsilon: _eps));
    final info = tester.getRect(find.byKey(const Key('environment-wind-info')));
    expect(info.top, greaterThanOrEqualTo(box.bottom - 0.01));
    expect(info.height, greaterThanOrEqualTo(44 - 0.01));
    expect(tester.takeException(), isNull);
  });
}
