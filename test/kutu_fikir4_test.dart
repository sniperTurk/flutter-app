// Kutu "Fikir 4" (owner, 2026-10-13): on Hava Durumu and Pro Ayarlar the
// small label sits ≤ 8 pt above a 44 pt box; the unit and the ⓘ are inside
// the box on the right; the ⓘ keeps a 44 × 44 pt tap target, opens the same
// popup and neither focuses the field nor opens a list. Every other page
// (Profil here) keeps the 44 pt label row and the 46 pt box.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/pro_sections.dart';
import 'support/rifle_form.dart';
import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

Finder _infoIn(Finder box) =>
    find.descendant(of: box, matching: find.byType(MenzilInfoButton));

Finder _selectBox(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(InputDecorator));

Finder get _dropdownMenu => find.byWidgetPredicate(
  (w) => w.runtimeType.toString().startsWith('_DropdownMenu<'),
);

Future<void> _pump(
  WidgetTester tester,
  BallisticsView view, {
  Size size = const Size(430, 2600),
  double textScale = 1.0,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final screen = Scaffold(
    body: BallisticsScreen(profile: _profile, view: view),
  );
  final services = testServices(
    location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
    weather: TestWeather(observation(fetchedAt: DateTime.utc(2026, 10, 12))),
    pressure: TestPressure(const PressureRead(912.4)),
  );
  await tester.pumpWidget(
    theme == null
        ? host(screen, services: services, textScale: textScale)
        : MaterialApp(
            theme: theme,
            builder: (context, c) =>
                ToolsServicesScope(services: services, child: c!),
            home: screen,
          ),
  );
  await tester.pumpAndSettle();
}

/// Label text bottom to box top, box height, ⓘ inside the box with a
/// 44 × 44 pt target, unit inside the box left of the ⓘ.
void _expectCompactInput(
  WidgetTester tester,
  Key key, {
  required String label,
  required String unit,
}) {
  final field = _field(key);
  expect(field, findsOneWidget, reason: '$key');
  final box = tester.getRect(field);
  final labelRect = tester.getRect(
    find.descendant(of: find.byKey(key), matching: find.text(label)),
  );
  final gap = box.top - labelRect.bottom;
  expect(gap, inInclusiveRange(0, 8), reason: '$key gap');
  expect(box.height, moreOrLessEquals(44, epsilon: 0.01), reason: '$key');
  final info = _infoIn(field);
  expect(info, findsOneWidget, reason: '$key ⓘ inside the box');
  final infoRect = tester.getRect(info);
  expect(infoRect.width, greaterThanOrEqualTo(44 - 0.01), reason: '$key ⓘ');
  expect(infoRect.height, greaterThanOrEqualTo(44 - 0.01), reason: '$key ⓘ');
  expect(infoRect.right, lessThanOrEqualTo(box.right + 0.01));
  expect(infoRect.top, greaterThanOrEqualTo(box.top - 0.01));
  expect(infoRect.bottom, lessThanOrEqualTo(box.bottom + 0.01));
  final unitText = find.descendant(of: field, matching: find.text(unit));
  expect(unitText, findsOneWidget, reason: '$key unit inside the box');
  final unitRect = tester.getRect(unitText);
  // Right before the ⓘ, at the right of the box.
  expect(unitRect.right, lessThanOrEqualTo(infoRect.left + 0.01));
  expect(infoRect.left - unitRect.right, lessThan(1), reason: '$key unit');
  // No unit in a label row any more.
  expect(
    find.descendant(of: find.byKey(key), matching: find.text(unit)),
    findsOneWidget,
  );
}

Future<void> _scrollThrough(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 12; i++) {
    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'scroll step $i');
  }
}

void main() {
  group('Hava Durumu', () {
    testWidgets('label ≤ 8 pt above a 44 pt box; unit and ⓘ inside', (
      tester,
    ) async {
      await _pump(tester, BallisticsView.environment);
      _expectCompactInput(
        tester,
        BallisticsFieldKeys.temperature,
        label: 'Sıcaklık',
        unit: '°C',
      );
      _expectCompactInput(
        tester,
        BallisticsFieldKeys.humidity,
        label: 'Bağıl nem',
        unit: '%',
      );
      _expectCompactInput(
        tester,
        BallisticsFieldKeys.pressure,
        label: 'İstasyon basıncı',
        unit: 'hPa',
      );
      _expectCompactInput(
        tester,
        BallisticsFieldKeys.altitude,
        label: 'İrtifa',
        unit: 'm',
      );
      _expectCompactInput(
        tester,
        BallisticsFieldKeys.wind,
        label: 'Rüzgâr hızı',
        unit: 'm/s',
      );
      _expectCompactInput(
        tester,
        BallisticsFieldKeys.windDirection,
        label: 'Rüzgâr yönü',
        unit: 'saat',
      );
      // No 44 pt label row: no ⓘ outside a box.
      for (final k in [
        BallisticsFieldKeys.temperature,
        BallisticsFieldKeys.pressure,
        BallisticsFieldKeys.wind,
      ]) {
        expect(
          _infoIn(find.byKey(k)).evaluate().length,
          _infoIn(_field(k)).evaluate().length,
        );
      }
      // Measurements for docs/reports/kutu_fikir4.md.
      final box = tester.getRect(_field(BallisticsFieldKeys.temperature));
      final label = tester.getRect(
        find.descendant(
          of: find.byKey(BallisticsFieldKeys.temperature),
          matching: find.text('Sıcaklık'),
        ),
      );
      final whole = tester.getRect(find.byKey(BallisticsFieldKeys.temperature));
      debugPrint(
        'FIKIR4 compact: gap=${(box.top - label.bottom).toStringAsFixed(1)} '
        'box=${box.height.toStringAsFixed(1)} '
        'row=${whole.height.toStringAsFixed(1)} '
        'labelToBoxTop=${(box.top - whole.top).toStringAsFixed(1)}',
      );
    });

    testWidgets('side-by-side boxes and labels line up', (tester) async {
      await _pump(tester, BallisticsView.environment);
      for (final pair in [
        [BallisticsFieldKeys.temperature, BallisticsFieldKeys.humidity],
        [BallisticsFieldKeys.pressure, BallisticsFieldKeys.altitude],
        [BallisticsFieldKeys.wind, BallisticsFieldKeys.windDirection],
      ]) {
        final a = tester.getRect(_field(pair[0]));
        final b = tester.getRect(_field(pair[1]));
        expect(b.top, moreOrLessEquals(a.top, epsilon: 0.01));
        expect(b.left, greaterThan(a.right), reason: 'two per row');
        Rect labelSlot(Key k) => tester.getRect(
          find.descendant(
            of: find.byKey(k),
            matching: find.byKey(const ValueKey('menzil-compact-label')),
          ),
        );
        final la = labelSlot(pair[0]), lb = labelSlot(pair[1]);
        expect(lb.top, moreOrLessEquals(la.top, epsilon: 0.01));
        expect(lb.height, moreOrLessEquals(la.height, epsilon: 0.01));
      }
    });

    testWidgets('ⓘ opens the popup and does not focus the field', (
      tester,
    ) async {
      await _pump(tester, BallisticsView.environment);
      final field = _field(BallisticsFieldKeys.temperature);
      await tester.tap(_infoIn(field));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sıcaklık'),
        ),
        findsOneWidget,
      );
      final editable = tester.widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isFalse);
      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(editable.focusNode.hasFocus, isFalse);
      // Tapping the box itself still focuses it.
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('VoiceOver: label + unit on the field, ⓘ still reachable', (
      tester,
    ) async {
      await _pump(tester, BallisticsView.environment);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Sıcaklık (°C)',
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Bilgi: Sıcaklık'), findsOneWidget);
      expect(find.byTooltip('Bilgi: İstasyon basıncı'), findsOneWidget);
    });

    testWidgets('done texts: "Hava verisi alındı", "Basınç alındı", one line', (
      tester,
    ) async {
      await _pump(tester, BallisticsView.environment);
      // Idle texts unchanged.
      expect(find.text('Konumdan canlı hava verisi al'), findsOneWidget);
      expect(find.text('Basıncı telefondan al'), findsOneWidget);
      for (final key in const [
        Key('environment-fill-weather'),
        Key('environment-phone-pressure'),
      ]) {
        await tester.ensureVisible(find.byKey(key));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
      }
      for (final t in ['Hava verisi alındı', 'Basınç alındı']) {
        expect(find.text(t), findsOneWidget, reason: t);
        expect(tester.widget<Text>(find.text(t)).maxLines, 1, reason: t);
      }
      expect(find.text('Konumdan canlı hava verisi alındı'), findsNothing);
      expect(find.text('Basınç telefondan alındı'), findsNothing);
    });

    testWidgets('narrow phone, text scale 1.3: no overflow', (tester) async {
      await _pump(
        tester,
        BallisticsView.environment,
        size: const Size(320, 568),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      await _scrollThrough(tester);
    });

    testWidgets('dark theme: same layout, no overflow', (tester) async {
      await _pump(
        tester,
        BallisticsView.environment,
        theme: MenzilTheme.dark(),
      );
      expect(tester.takeException(), isNull);
      final box = tester.getRect(_field(BallisticsFieldKeys.temperature));
      expect(box.height, moreOrLessEquals(44, epsilon: 0.01));
      expect(_infoIn(_field(BallisticsFieldKeys.temperature)), findsOneWidget);
    });
  });

  group('Pro Ayarlar', () {
    testWidgets('inputs: label ≤ 8 pt above a 44 pt box; unit and ⓘ inside', (
      tester,
    ) async {
      await _pump(tester, BallisticsView.pro);
      _expectCompactInput(
        tester,
        const Key('pro-shot-range'),
        label: 'Atış mesafesi',
        unit: 'm',
      );
      await openProFor(tester, const Key('pro-group'));
      _expectCompactInput(
        tester,
        const Key('pro-target-speed'),
        label: 'Hedef hızı',
        unit: 'm/s',
      );
      _expectCompactInput(
        tester,
        const Key('pro-bc-error'),
        label: 'BC hatası',
        unit: '%',
      );
      // A Pro box field ⓘ opens the box's sheet (as today) and does not
      // focus the field.
      final speed = _field(const Key('pro-target-speed'));
      await tester.tap(_infoIn(speed));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pro-info-sheet')), findsOneWidget);
      final editable = tester.widget<EditableText>(
        find.descendant(of: speed, matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isFalse);
      await tester.tap(find.byKey(const Key('pro-info-close')));
      await tester.pumpAndSettle();
      expect(editable.focusNode.hasFocus, isFalse);
    });

    testWidgets('an error stays below the 44 pt box', (tester) async {
      await _pump(tester, BallisticsView.pro);
      final field = _field(const Key('pro-shot-range'));
      await tester.enterText(field, '999999');
      await tester.pumpAndSettle();
      final error = find.textContaining('arasında olmalı');
      expect(error, findsOneWidget);
      final trailing = tester.getRect(
        find.descendant(of: field, matching: find.byType(MenzilInfoButton)),
      );
      final top = tester.getTopLeft(field).dy;
      // The box is still 44 pt (its ⓘ fills it); the error is under it.
      expect(trailing.height, moreOrLessEquals(44, epsilon: 0.01));
      expect(trailing.top, moreOrLessEquals(top, epsilon: 0.01));
      expect(tester.getRect(error).top, greaterThanOrEqualTo(top + 44 - 0.01));
    });

    testWidgets('select: 44 pt box, ⓘ left of the arrow, no list on ⓘ', (
      tester,
    ) async {
      await _pump(tester, BallisticsView.pro);
      const key = Key('pro-wez-shots');
      await openProFor(tester, key);
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      final box = _selectBox(key);
      expect(box, findsOneWidget);
      final rect = tester.getRect(box);
      expect(rect.height, moreOrLessEquals(44, epsilon: 0.01));
      final label = tester.getRect(
        find.descendant(
          of: find.byKey(key),
          matching: find.text('Atış sayısı'),
        ),
      );
      expect(rect.top - label.bottom, inInclusiveRange(0, 8));
      final info = _infoIn(box);
      expect(info, findsOneWidget);
      final infoRect = tester.getRect(info);
      expect(infoRect.width, greaterThanOrEqualTo(44 - 0.01));
      expect(infoRect.height, greaterThanOrEqualTo(44 - 0.01));
      final arrow = tester.getRect(
        find.descendant(of: box, matching: find.byIcon(Icons.expand_more)),
      );
      expect(infoRect.right, lessThanOrEqualTo(arrow.left + 0.01));
      expect(arrow.right, lessThanOrEqualTo(rect.right));

      // Same as today (#279): a field ⓘ in a Pro box opens the box's
      // bottom sheet; never the list.
      await tester.tap(info);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pro-info-sheet')), findsOneWidget);
      expect(_dropdownMenu, findsNothing);
      await tester.tap(find.byKey(const Key('pro-info-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pro-info-sheet')), findsNothing);

      // The rest of the box still opens the list.
      await tester.tapAt(arrow.center);
      await tester.pumpAndSettle();
      expect(_dropdownMenu, findsOneWidget);
    });

    testWidgets('narrow phone, text scale 1.3: no overflow', (tester) async {
      await _pump(
        tester,
        BallisticsView.pro,
        size: const Size(320, 568),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      for (final k in const [
        Key('pro-wind-max'),
        Key('pro-group'),
        Key('pro-turret-scale'),
      ]) {
        await openProFor(tester, k);
        expect(tester.takeException(), isNull, reason: '$k');
      }
      await _scrollThrough(tester);
    });
  });

  testWidgets('measure: regular vs compact box (same theme)', (tester) async {
    tester.view.physicalSize = const Size(430, 900) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final a = TextEditingController(), b = TextEditingController();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              MenzilInput(
                key: const Key('old'),
                controller: a,
                label: 'Sıcaklık',
                unit: '°C',
                info: 'x',
              ),
              MenzilInput(
                key: const Key('new'),
                controller: b,
                label: 'Nem',
                unit: '%',
                info: 'x',
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
    final oldBox = tester.getRect(_field(const Key('old')));
    final oldWhole = tester.getRect(find.byKey(const Key('old')));
    final oldLabel = tester.getRect(find.text('Sıcaklık'));
    final newBox = tester.getRect(_field(const Key('new')));
    final newWhole = tester.getRect(find.byKey(const Key('new')));
    final newLabel = tester.getRect(find.text('Nem'));
    debugPrint(
      'FIKIR4 before: gap=${(oldBox.top - oldLabel.bottom).toStringAsFixed(1)} '
      'labelRow=${(oldBox.top - oldWhole.top).toStringAsFixed(1)} '
      'box=${oldBox.height.toStringAsFixed(1)} '
      'field=${oldWhole.height.toStringAsFixed(1)}',
    );
    debugPrint(
      'FIKIR4 after: gap=${(newBox.top - newLabel.bottom).toStringAsFixed(1)} '
      'labelRow=${(newBox.top - newWhole.top).toStringAsFixed(1)} '
      'box=${newBox.height.toStringAsFixed(1)} '
      'field=${newWhole.height.toStringAsFixed(1)}',
    );
    expect(oldBox.height, greaterThanOrEqualTo(MenzilSpace.control - 0.01));
    expect(newBox.height, moreOrLessEquals(44, epsilon: 0.01));
    expect(newWhole.height, lessThan(oldWhole.height));
  });

  testWidgets('Profil keeps the old layout: 44 pt label row, 46 pt box', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: ProfilesScreen(store: MemoryProfileStore()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Yeni profil'));
    await tester.pumpAndSettle();
    await chooseInSelect(tester, 'profile-platform', 'PCP Tüfek');
    const key = Key('profile-tube-pressure');
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    final field = _field(key);
    final box = tester.getRect(field);
    final whole = tester.getRect(find.byKey(key));
    // The ⓘ is in the label row, not in the box.
    expect(_infoIn(find.byKey(key)), findsOneWidget);
    expect(_infoIn(field), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(MenzilFieldLabel),
      ),
      findsOneWidget,
    );
    expect(box.top - whole.top, greaterThanOrEqualTo(44 - 0.01));
    expect(box.height, greaterThanOrEqualTo(MenzilSpace.control - 0.01));
    expect(
      find.descendant(of: field, matching: find.text('bar')),
      findsNothing,
    );
    // A Profil select keeps its label row too.
    final platform = _selectBox(const Key('profile-platform'));
    expect(_infoIn(platform), findsNothing);
    expect(
      tester.getSize(platform).height,
      greaterThanOrEqualTo(MenzilSpace.control - 0.01),
    );
    expect(MenzilSpace.control, 46);
  });
}
