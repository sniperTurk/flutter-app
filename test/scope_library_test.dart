import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/scope_library.dart';
import 'package:sniper_turk/models/domain.dart';

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

  test('Element Optics: MRAD and MOA versions, reticles from the maker', () {
    final element = [
      for (final s in ScopeLibrary.all)
        if (s.brand == 'Element Optics') s,
    ];
    expect(element.length, greaterThanOrEqualTo(30));
    final models = element.map((s) => s.model).toSet();
    for (final m in [
      'Immersive Series 10x40',
      'Immersive Series 14x50 MOA',
      'Titan 5-25x56 FFP MOA',
      'Nexus 5-20x50 FFP MOA',
      'Theos 6-36x56 FFP MOA',
    ]) {
      expect(models, contains(m));
    }
    final titanMoa = element.firstWhere(
      (s) => s.model == 'Titan 5-25x56 FFP MOA',
    );
    expect(titanMoa.clickUnit, AngularUnit.moa);
    expect(titanMoa.clickValue, 0.25);
    expect(titanMoa.reticle, 'APR-1C MOA / APR-2D MOA');
  });

  test('Vector Optics and Vortex: complete lists, clean model names', () {
    final vector = [
      for (final s in ScopeLibrary.all)
        if (s.brand == 'Vector Optics') s,
    ];
    expect(vector.length, greaterThanOrEqualTo(145));
    for (final s in vector) {
      expect(s.model, isNot(contains('Rifle Scope')), reason: s.id);
    }
    expect(
      ScopeLibrary.all.where((s) => s.brand == 'Vortex').length,
      greaterThanOrEqualTo(85),
    );
  });
}
