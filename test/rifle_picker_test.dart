import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/features/profiles/rifle_picker_screen.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  test('firearm bores map to the bullet-diameter Kalibre list', () {
    Rifle byId(String id) =>
        CatalogRepository.rifles.firstWhere((r) => r.id == id);
    expect(RiflePickerScreen.profileCaliber(byId('ata-turqua-308')), 7.82);
    expect(RiflePickerScreen.profileCaliber(byId('ata-turqua-65cm')), 6.71);
    expect(RiflePickerScreen.profileCaliber(byId('ata-asr-338lm')), 8.59);
    expect(RiflePickerScreen.profileCaliber(byId('sarsilmaz-sar56-11')), 5.7);
  });
}
