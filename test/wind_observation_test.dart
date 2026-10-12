// Ö2 (docs/yeni-hesaplar-2026-10-11.md): Rüzgâr gözlemi fills Rüzgâr hızı
// with the Beaufort class middle and En yüksek rüzgâr with its top; Hedef
// shows how much of the wind drift each third of the path gives.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _profile = RifleProfile(
  id: 'p-obs',
  name: 'Gözlem',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

Widget _app(BallisticsView view) => MaterialApp(
  home: Scaffold(
    body: BallisticsScreen(profile: _profile, view: view),
  ),
);

Finder _field(Key k) =>
    find.descendant(of: find.byKey(k), matching: find.byType(TextField));

String _text(WidgetTester tester, Key k) =>
    tester.widget<TextField>(_field(k)).controller!.text;

Future<void> _sized(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Finder get _select => find.byWidgetPredicate(
  (w) => w is MenzilSelect<int> && w.label == 'Rüzgâr gözlemi',
);

Future<void> _pick(WidgetTester tester, String prefix) async {
  await tester.ensureVisible(_select);
  await tester.pumpAndSettle();
  await tester.tap(_select);
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining(prefix).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('starts at Seçiniz with an ⓘ that warns about the 10 m height', (
    tester,
  ) async {
    await _sized(tester);
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    final s = tester.widget<MenzilSelect<int>>(_select);
    expect(s.hint, 'Seçiniz');
    expect(s.initialValue, isNull);
    expect(s.info, EnvironmentFieldInfo.windObservation);
    expect(s.info, contains('10 m'));
    expect(s.items, hasLength(8));
    expect(s.label.contains('('), isFalse);
  });

  testWidgets('a class fills Rüzgâr hızı and En yüksek rüzgâr', (tester) async {
    await _sized(tester);
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    await _pick(tester, 'Hafif: ');
    expect(_text(tester, BallisticsFieldKeys.wind), '2.5');
    expect(_text(tester, const Key('pro-wind-max')), '3.3');
    expect(find.text('Hafif'), findsOneWidget);

    // Still editable: a typed wind is the shooter's and resets the list.
    await tester.ensureVisible(_field(BallisticsFieldKeys.wind));
    await tester.enterText(_field(BallisticsFieldKeys.wind), '4');
    await tester.pumpAndSettle();
    expect(tester.widget<MenzilSelect<int>>(_select).initialValue, isNull);
    expect(_text(tester, const Key('pro-wind-max')), '3.3');
  });

  testWidgets('Hedef shows the near / middle / far wind shares', (
    tester,
  ) async {
    await _sized(tester);
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    await _pick(tester, 'Orta: ');
    // A wind needs its direction before Hedef solves.
    await tester.ensureVisible(_field(BallisticsFieldKeys.windDirection));
    await tester.enterText(_field(BallisticsFieldKeys.windDirection), '9');
    await tester.pump();
    await tester.pumpWidget(_app(BallisticsView.shot));
    await tester.pumpAndSettle();
    final line = tester
        .widget<Text>(find.byKey(const Key('shot-wind-zone-shares')))
        .data!;
    final m = RegExp(
      r'^Rüzgâr etkisi: yakın %(\d+) · orta %(\d+) · uzak %(\d+)$',
    ).firstMatch(line);
    expect(m, isNotNull, reason: line);
    final p = [for (var i = 1; i <= 3; i++) int.parse(m!.group(i)!)];
    expect(p[0] + p[1] + p[2], 100);
    expect(p[0], greaterThan(p[1]));
    expect(p[1], greaterThan(p[2]));
  });
}
