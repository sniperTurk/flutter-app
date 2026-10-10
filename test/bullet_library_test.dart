import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/bullet_library.dart';
import 'package:sniper_turk/features/profiles/bullet_library_screen.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  test('library entries are complete and sourced', () {
    expect(BulletLibrary.all.length, greaterThan(150));
    for (final b in BulletLibrary.all) {
      expect(b.sourceUrl, startsWith('https://'), reason: b.title);
      expect(b.grain, greaterThan(0), reason: b.title);
      expect(b.bc, inInclusiveRange(0.005, 1.5), reason: b.title);
      expect(b.caliberMm, inInclusiveRange(4.0, 13.0), reason: b.title);
      if (b.platform == WeaponPlatform.firearm) {
        expect(b.type, AmmunitionType.bullet, reason: b.title);
      }
      for (var i = 1; i < b.bands.length; i++) {
        expect(b.bands[i].$1, lessThan(b.bands[i - 1].$1), reason: b.title);
      }
    }
    // The data PRs (#74 firearm, #75 PCP) are in.
    for (final brand in ['Peregrine', 'Woodleigh', 'Swift', 'NSA', 'Zan Projectiles']) {
      expect(BulletLibrary.all.any((b) => b.brand == brand), isTrue, reason: brand);
    }
    expect(
      BulletLibrary.all.any((b) => b.type == AmmunitionType.slug),
      isTrue,
    );
    // Both rifle types are covered.
    expect(
      BulletLibrary.all.any((b) => b.platform == WeaponPlatform.pcp),
      isTrue,
    );
  });

  testWidgets('"Kütüphaneden seç" fills the ammunition', (tester) async {
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
    // Firearm.
    await tester.ensureVisible(find.text('PCP Tüfek'));
    await tester.tap(find.text('PCP Tüfek'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ateşli Tüfek').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('ammo-library')));
    await tester.tap(find.byKey(const Key('ammo-library')));
    await tester.pumpAndSettle();
    expect(find.text('Mermi kütüphanesi'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('library-search')),
      'ELD Match',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('library-item-0')));
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
    expect(text('ammo-brand'), contains('ELD Match'));
    expect(text('ammo-grain'), isNotEmpty);
    expect(text('ammo-bc'), isNotEmpty);
  });

  testWidgets('a caliber with no record lists nothing and says so', (
    tester,
  ) async {
    Future<void> open(double cal) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: BulletLibraryScreen(
            platform: WeaponPlatform.firearm,
            caliberMm: cal,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open(7.0);
    expect(find.byKey(const Key('library-no-caliber')), findsOneWidget);
    expect(find.byKey(const Key('library-item-0')), findsNothing);

    await open(7.82);
    expect(find.byKey(const Key('library-no-caliber')), findsNothing);
    expect(find.byKey(const Key('library-item-0')), findsOneWidget);
  });
}
