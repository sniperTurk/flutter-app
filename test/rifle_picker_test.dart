import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/features/profiles/rifle_picker_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  test('firearm bores map to the bullet-diameter Kalibre list', () {
    Rifle byId(String id) =>
        CatalogRepository.rifles.firstWhere((r) => r.id == id);
    expect(RiflePickerScreen.profileCaliber(byId('ata-turqua-308')), 7.82);
    expect(RiflePickerScreen.profileCaliber(byId('ata-turqua-65cm')), 6.71);
    expect(RiflePickerScreen.profileCaliber(byId('ata-asr-338lm')), 8.59);
    expect(RiflePickerScreen.profileCaliber(byId('sarsilmaz-sar56-11')), 5.7);
  });

  testWidgets('"Listeden seç" fills brand, model and Kalibre', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
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

    await tester.ensureVisible(find.byKey(const Key('rifle-library')));
    await tester.tap(find.byKey(const Key('rifle-library')));
    await tester.pumpAndSettle();
    expect(find.text('Tüfek listesi'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('rifle-picker-search')),
      'Reximex',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rifle-picker-item-0')));
    await tester.pumpAndSettle();

    String text(String key) => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(TextField),
          ),
        )
        .controller!
        .text;
    expect(text('rifle-brand'), 'Reximex');
    expect(text('rifle-model'), isNotEmpty);
  });
}
