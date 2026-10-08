import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';

// Gazi Sniper 6–36×56 FFP: 0.1 mrad clicks.
const _profile = RifleProfile(
  id: 'p-drag',
  name: 'Sürtünmeli',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-drag',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _ammo = <String, dynamic>{
  'id': 'c-drag',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.25 pellet',
  'caliberMm': 6.35,
  'grain': 25.4,
  'ammoType': 'pellet',
  'bc': 0.04,
  'bcModel': 'G1',
};

Widget _app(BallisticsView view) => MaterialApp(
  home: Scaffold(
    body: BallisticsScreen(profile: _profile, view: view),
  ),
);

String _impact(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ScopeDialKeys.impactText)).data!;

void main() {
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('drag solve: the scope uses the solver windage', (tester) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_ammo]),
    );

    // Enter a 5 m/s full-value crosswind (90° = from the left) and solve.
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(BallisticsFieldKeys.wind),
        matching: find.byType(TextField),
      ),
      '5',
    );
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();

    // Same workspace, shot view.
    await tester.pumpWidget(_app(BallisticsView.shot));
    await tester.pumpAndSettle();
    expect(find.byKey(ScopeDialKeys.reticle), findsOneWidget);
    expect(find.textContaining('soldan) ile hesaplandı'), findsOneWidget);

    // Undialled: the shot lands low and is pushed right by the wind.
    final undialled = _impact(tester);
    expect(undialled, contains('aşağı'));
    expect(undialled, contains('sağ'));

    // Dialling the solution (elevation AND windage) centres the impact.
    await tester.ensureVisible(find.byKey(ScopeDialKeys.dialSolution));
    await tester.tap(find.byKey(ScopeDialKeys.dialSolution));
    await tester.pumpAndSettle();
    expect(_impact(tester), 'Vuruş noktası: artı işaretinde');
    expect(find.textContaining('klik sol'), findsOneWidget);
  });
}
