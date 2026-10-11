import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/flight_warnings.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

Future<void> _pump(WidgetTester tester, List<Widget> notices) =>
    tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(child: Column(children: notices)),
        ),
      ),
    );

void main() {
  test('veri yoksa uyarı yok', () {
    expect(FlightWarnings.notices(), isEmpty);
    // Stable and supersonic at the target: nothing to say.
    expect(
      FlightWarnings.notices(sg: 1.8, muzzleMach: 2.4, targetMach: 1.6),
      isEmpty,
    );
  });

  testWidgets('Sg < 1: kararsız uyarısı, ⓘ ile', (tester) async {
    await _pump(tester, FlightWarnings.notices(sg: 0.92));
    expect(find.byKey(const Key('shot-stability-unstable')), findsOneWidget);
    expect(find.textContaining('Sg 0.92'), findsOneWidget);
    expect(find.byType(MenzilInfoButton), findsOneWidget);
    final notice = tester.widget<MenzilNotice>(
      find.byKey(const Key('shot-stability-unstable')),
    );
    expect(notice.tone, MenzilNoticeTone.danger);
  });

  testWidgets('Sg 1–1.5: BC uyarısı, kayıp tahmini, BC değişmez', (
    tester,
  ) async {
    await _pump(tester, FlightWarnings.notices(sg: 1.32));
    expect(find.byKey(const Key('shot-stability-marginal')), findsOneWidget);
    expect(find.textContaining('Sg 1.32'), findsOneWidget);
    // (1.5 − 1.32) / 0.1 × 3 % = 5.4 % → "%5".
    expect(find.textContaining('%5'), findsOneWidget);
    expect(find.textContaining('BC katalog değerinin altında'), findsOneWidget);
    await tester.tap(find.byType(MenzilInfoButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('%3'), findsWidgets);
    expect(find.textContaining('kendiliğinden düşürmez'), findsOneWidget);
  });

  testWidgets('hedefte Mach < 1.2: transonik uyarısı', (tester) async {
    await _pump(
      tester,
      FlightWarnings.notices(sg: 1.8, muzzleMach: 2.4, targetMach: 1.08),
    );
    expect(find.byKey(const Key('shot-transonic')), findsOneWidget);
    expect(find.textContaining('Mach 1.08'), findsOneWidget);
    expect(find.byKey(const Key('shot-stability-marginal')), findsNothing);
  });

  test('ses altı yük: transonik uyarısı yok', () {
    expect(
      FlightWarnings.notices(muzzleMach: 0.95, targetMach: 0.8),
      isEmpty,
    );
  });

  test('metinlerde parantez yok', () {
    for (final t in [
      FlightWarnings.unstableInfo,
      FlightWarnings.marginalInfo,
      FlightWarnings.transonicInfo,
    ]) {
      expect(t.contains('('), isFalse, reason: t);
    }
  });
}
