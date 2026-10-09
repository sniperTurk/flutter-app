// Converted from source-string matching to a real widget test: it drives the
// actual TextFields and solve button and checks the *displayed* physics
// output, so it would fail if any environment field were silently dropped
// before reaching Atmosphere/BallisticInput.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';

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

// Inputs are located by stable keys: the Menzil field shows its label and
// unit in a row above the text field instead of inside the decoration.
Finder _fieldFor(Key key) => find.byKey(key);

double _readDensity(WidgetTester tester) {
  final text = tester
      .widget<Text>(find.textContaining('Hava yoğunluğu:'))
      .data!;
  final match = RegExp(r'Hava yoğunluğu: ([\d.]+)').firstMatch(text)!;
  return double.parse(match.group(1)!);
}

void main() {
  testWidgets(
    'every environment field reaches the displayed atmosphere output',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BallisticsScreen(profile: _profile)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(_fieldFor(BallisticsFieldKeys.temperature), '15');
      await tester.enterText(
        _fieldFor(BallisticsFieldKeys.pressure),
        '1013.25',
      );
      await tester.enterText(_fieldFor(BallisticsFieldKeys.humidity), '50');
      await tester.ensureVisible(find.text('DOPE oluştur'));
      await tester.tap(find.text('DOPE oluştur'));
      await tester.pumpAndSettle();
      final baseline = _readDensity(tester);

      // Raising temperature at fixed pressure/humidity must lower air density
      // (ideal gas law). If temperature were not actually threaded through to
      // Atmosphere.densityKgM3, this value would stay identical to baseline.
      await tester.enterText(_fieldFor(BallisticsFieldKeys.temperature), '35');
      await tester.ensureVisible(find.text('DOPE oluştur'));
      await tester.tap(find.text('DOPE oluştur'));
      await tester.pumpAndSettle();
      final warmer = _readDensity(tester);
      expect(warmer, lessThan(baseline));

      // Comma decimal separators must be accepted (replaceAll(',', '.')).
      // 960 hPa: lower than standard but plausible at 0 m (no warning).
      await tester.enterText(_fieldFor(BallisticsFieldKeys.temperature), '15');
      await tester.enterText(_fieldFor(BallisticsFieldKeys.pressure), '960,00');
      await tester.ensureVisible(find.text('DOPE oluştur'));
      await tester.tap(find.text('DOPE oluştur'));
      await tester.pumpAndSettle();
      final lowerPressure = _readDensity(tester);
      expect(lowerPressure, lessThan(baseline));

      // Raising humidity at fixed temperature/pressure must slightly lower
      // density (water vapour is less dense than dry air at the same T, P).
      await tester.enterText(
        _fieldFor(BallisticsFieldKeys.pressure),
        '1013.25',
      );
      await tester.enterText(_fieldFor(BallisticsFieldKeys.humidity), '95');
      await tester.ensureVisible(find.text('DOPE oluştur'));
      await tester.tap(find.text('DOPE oluştur'));
      await tester.pumpAndSettle();
      final humid = _readDensity(tester);
      expect(humid, lessThan(baseline));
    },
  );
}
