// Ö11 Atış öncesi kontrol listesi: maddeler dürbüne göre değişir; her
// maddenin ⓘ açıklaması vardır.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/preshot_checklist.dart';

void main() {
  test('FFP scope: no magnification item', () {
    final items = PreShotChecklist.items(
      profileName: 'Tikka',
      unit: AngularUnit.mrad,
      firstFocalPlane: true,
    );
    expect(items.map((i) => i.id), [
      'profile',
      'unit',
      'turret',
      'parallax',
      'level',
    ]);
  });

  test('SFP or unknown focal plane: magnification item last', () {
    for (final ffp in [false, null]) {
      final items = PreShotChecklist.items(firstFocalPlane: ffp);
      expect(items.length, 6);
      expect(items.last.id, 'sfp');
    }
  });

  test('titles name the profile and the turret unit', () {
    final items = PreShotChecklist.items(
      profileName: 'Tikka',
      unit: AngularUnit.moa,
      firstFocalPlane: true,
    );
    expect(items[0].title, 'Doğru profil: Tikka');
    expect(items[1].title, contains('MOA'));
    for (final i in items) {
      expect(i.info, isNotEmpty);
      expect(i.title.contains('('), isFalse);
    }
  });
}
