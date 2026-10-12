import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/bullet_library.dart';
import 'package:sniper_turk/features/profiles/bullet_library_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  test('library entries are complete and sourced', () {
    expect(BulletLibrary.all.length, greaterThan(150));
    for (final b in BulletLibrary.all) {
      expect(b.sourceUrl, startsWith('https://'), reason: b.title);
      expect(b.grain, greaterThan(0), reason: b.title);
      // A maker that publishes no BC leaves it null (2026-10-12).
      if (b.bc != null) {
        expect(b.bc, inInclusiveRange(0.005, 1.5), reason: b.title);
      }
      expect(b.caliberMm, inInclusiveRange(4.0, 13.0), reason: b.title);
      if (b.platform == WeaponPlatform.firearm) {
        expect(b.type, AmmunitionType.bullet, reason: b.title);
      }
      for (var i = 1; i < b.bands.length; i++) {
        expect(b.bands[i].$1, lessThan(b.bands[i - 1].$1), reason: b.title);
      }
    }
    // The data PRs (#74 firearm, #75 PCP) are in.
    for (final brand in [
      'Peregrine',
      'Woodleigh',
      'Swift',
      'NSA',
      'Zan Projectiles',
    ]) {
      expect(
        BulletLibrary.all.any((b) => b.brand == brand),
        isTrue,
        reason: brand,
      );
    }
    // Zan slug BCs from the 2026-10-11 BC completion (data/bullets-bc).
    final zan = BulletLibrary.all.firstWhere(
      (b) => b.name == 'ZAN .30 68 gr Slug .300',
    );
    expect(zan.bc, 0.134);
    expect(zan.platform, WeaponPlatform.pcp);
    expect(BulletLibrary.all.any((b) => b.type == AmmunitionType.slug), isTrue);
    // Mühimmat tamamlama (2026-10-12): new makers and the BC-less Turkish
    // pellets/slugs are listed; Applied Ballistics BCs are not used.
    for (final brand in [
      'Cutting Edge Bullets',
      'Hammer Bullets',
      'Spoton',
      'Hatsan',
      'My Bullet',
    ]) {
      expect(
        BulletLibrary.all.any((b) => b.brand == brand),
        isTrue,
        reason: brand,
      );
    }
    final spoton = BulletLibrary.all.where((b) => b.brand == 'Spoton');
    expect(spoton.every((b) => b.bc == null), isTrue);
    expect(spoton.every((b) => b.platform == WeaponPlatform.pcp), isTrue);
    final ceb = BulletLibrary.all.firstWhere(
      (b) => b.item == 'MTH 224 78 MAX',
    );
    expect(ceb.g1, 0.442); // Oehler 89, not the A.B. 0.408
    expect(ceb.g7, isNull);
    // Both rifle types are covered.
    expect(
      BulletLibrary.all.any((b) => b.platform == WeaponPlatform.pcp),
      isTrue,
    );
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

  testWidgets('a record without a maker BC says so', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: const BulletLibraryScreen(
          platform: WeaponPlatform.pcp,
          caliberMm: 4.5,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('library-search')),
      'Spoton Match',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('BC yayımlanmıyor'), findsWidgets);
  });
}
