import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/scope_library.dart';

void main() {
  test('the manufacturer scope list is in the catalog and sourced', () {
    expect(ScopeLibrary.all.length, greaterThan(300));
    final ids = CatalogRepository.scopes.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'scope ids are unique');
    for (final s in ScopeLibrary.all) {
      expect(s.sourceDocument, startsWith('https://'), reason: s.id);
      expect(s.clickValue, greaterThan(0), reason: s.id);
      expect(s.objectiveDiameterMm, greaterThan(0), reason: s.id);
      expect(CatalogRepository.scopes, contains(s));
    }
    for (final brand in [
      'Vortex',
      'Athlon',
      'Vector Optics',
      'Kahles',
      'Discovery Optics',
      'Element Optics',
      'Barska',
    ]) {
      expect(
        ScopeLibrary.all.any((s) => s.brand == brand),
        isTrue,
        reason: brand,
      );
    }
  });
}
