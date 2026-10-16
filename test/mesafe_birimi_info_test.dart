// Mesafe birimi ⓘ (owner, 2026-10-15 23:04 / 23:06;
// docs/reports/mesafe_birimi_info.md): right after the first sentence the
// text says to enter Sıfırlama mesafesi in the chosen unit, metre first.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profile_field_info.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/rifle_form.dart';

const _first = 'Mesafelerin birimi: metre veya yard (1 yard = 0,9144 m).';
const _added =
    'Metre seçtiyseniz Sıfırlama mesafesini metre olarak, Yard seçtiyseniz '
    'yard olarak girin.';

void main() {
  test('new sentence follows the first one, metre before yard', () {
    const t = ProfileFieldInfo.distanceUnit;
    expect(t, startsWith('$_first $_added '));
    expect(
      t.indexOf('Metre seçtiyseniz'),
      lessThan(t.indexOf('Yard seçtiyseniz')),
    );
    // The rest of the text is kept.
    expect(
      t,
      endsWith(
        'Yard seçilirse sıfırlama mesafesi, Hedef sayfası, dürbün içindeki '
        'mesafe sayıları ve tablo yard ile gösterilir. Dürbününüzün odak '
        'düğmesi yard ile yazılıysa yard seçin.',
      ),
    );
  });

  testWidgets('Mesafe birimi ⓘ opens and shows the sentence', (tester) async {
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
    final button = find.byTooltip('Bilgi: Mesafe birimi');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining(_added),
      ),
      findsOneWidget,
    );
  });
}
