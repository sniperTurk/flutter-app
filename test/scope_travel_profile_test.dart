// Kule ayar aralığı on Profil: typed in the scope's unit, converted when the
// unit changes, and mapped from the personal record to the scope.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/rifle_form.dart';

void main() {
  test('personal scope records carry the turret travel', () {
    final catalog = UserCatalog.fromManualEntries([
      {
        'id': 's1',
        'kind': 'scope',
        'platform': 'pcp',
        'brand': 'Optik',
        'model': '6-24x50 FFP',
        'objectiveMm': 50,
        'click': 0.1,
        'clickUnit': 'mrad',
        'focal': 'ffp',
        'minMag': 6,
        'maxMag': 24,
        'elevationRangeMrad': 17,
        'windageRangeMrad': 15,
      },
    ]);
    final scope = catalog.scopes.single;
    expect(scope.elevationRangeMrad, 17);
    expect(scope.windageRangeMrad, 15);
  });

  testWidgets('travel field: ⓘ, optional, converted with the unit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
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

    final field = find.descendant(
      of: find.byKey(const Key('scope-travel-elevation')),
      matching: find.byType(TextField),
    );
    expect(field, findsOneWidget);
    expect(
      find.byTooltip('Bilgi: Kule ayar aralığı (yükseklik)'),
      findsOneWidget,
    );
    // Empty is allowed: it never appears in the missing list.
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-missing'))).data,
      isNot(contains('Kule aralığı')),
    );

    await enterRifleField(tester, 'scope-travel-elevation', '17');
    // MRAD → MOA keeps the angle: 17 mrad = 58.4 MOA.
    await chooseInSelect(tester, 'profile-angular-unit-mrad', 'MOA');
    expect(tester.widget<TextField>(field).controller!.text, '58,4');

    // An implausible value is flagged.
    await enterRifleField(tester, 'scope-travel-elevation', '1');
    expect(find.text('3–400 arasında bir değer girin.'), findsWidgets);
  });
}
