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

  testWidgets('Üst kule klik sayısı: ⓘ, optional, whole clicks', (
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

    expect(find.text('Üst kule klik sayısı'), findsOneWidget);
    expect(find.byTooltip('Bilgi: Üst kule klik sayısı'), findsOneWidget);
    // Only one question: no separate side-turret field.
    expect(find.byKey(const Key('scope-travel-windage')), findsNothing);
    // Empty is allowed: it never appears in the missing list.
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-missing'))).data,
      isNot(contains('Üst kule')),
    );

    await enterRifleField(tester, 'scope-travel-elevation', '5');
    expect(find.text('10–3000 arasında bir değer girin.'), findsOneWidget);
    await enterRifleField(tester, 'scope-travel-elevation', '120,5');
    expect(find.text('Tam sayı girin.'), findsOneWidget);
    await enterRifleField(tester, 'scope-travel-elevation', '240');
    expect(find.text('Tam sayı girin.'), findsNothing);
  });
}
