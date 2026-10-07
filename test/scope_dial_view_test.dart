import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

// Gazi Sniper 6–36×56 FFP: 0.1 mrad clicks, 26 mrad elevation travel.
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

Future<void> _pumpSolved(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(_profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Hesapla'));
  await tester.pumpAndSettle();
}

String _impact(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ScopeDialKeys.impactText)).data!;

void main() {
  testWidgets('turrets and reticle are shown on the shot tab', (tester) async {
    await _pumpSolved(tester);
    expect(find.byKey(ScopeDialKeys.elevationDrum), findsOneWidget);
    expect(find.byKey(ScopeDialKeys.windageDrum), findsOneWidget);
    expect(find.byKey(ScopeDialKeys.reticle), findsOneWidget);
    // Wind is still not modelled.
    expect(find.text('KİLİTLİ'), findsOneWidget);
  });

  testWidgets('dialling the solution centres the impact; reset drops it', (
    tester,
  ) async {
    await _pumpSolved(tester);
    // At 100 m with a 25 m zero the impact is below the crosshair.
    expect(_impact(tester), contains('aşağı'));

    await tester.ensureVisible(find.byKey(ScopeDialKeys.dialSolution));
    await tester.tap(find.byKey(ScopeDialKeys.dialSolution));
    await tester.pumpAndSettle();
    expect(_impact(tester), 'Vuruş noktası: artı işaretinde');

    await tester.tap(find.byKey(ScopeDialKeys.reset));
    await tester.pumpAndSettle();
    expect(_impact(tester), contains('aşağı'));
  });

  testWidgets('windage clicks move the impact sideways', (tester) async {
    await _pumpSolved(tester);
    await tester.ensureVisible(find.byKey(ScopeDialKeys.dialSolution));
    await tester.tap(find.byKey(ScopeDialKeys.dialSolution));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Rüzgâr kulesi 1 klik sağa'));
    await tester.pumpAndSettle();
    // 0.1 mrad at 100 m = 1.0 cm to the right.
    expect(_impact(tester), contains('1.0 cm sağ'));
  });

  testWidgets('dragging the elevation drum changes the dialled clicks', (
    tester,
  ) async {
    await _pumpSolved(tester);
    final drum = find.byKey(ScopeDialKeys.elevationDrum);
    await tester.ensureVisible(drum);
    expect(find.textContaining('Kule: 0 klik'), findsOneWidget);
    await tester.drag(drum, const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kule: 0 klik'), findsNothing);
    expect(find.textContaining('klik yukarı'), findsOneWidget);
  });
}
