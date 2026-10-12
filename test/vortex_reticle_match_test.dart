import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/reticle_catalog.dart';
import 'package:sniper_turk/data/scope_library.dart';

void main() {
  test('every Vortex scope in the list finds its Vortex reticle record', () {
    final vortex = ScopeLibrary.all.where((s) => s.brand == 'Vortex').toList();
    expect(vortex.length, greaterThanOrEqualTo(85));
    for (final s in vortex) {
      final r = ReticleCatalog.find(s.reticle, s.clickUnit, brand: s.brand);
      expect(r, isNotNull, reason: '${s.id}: ${s.reticle}');
      expect(r!.brand, 'Vortex Optics', reason: s.id);
    }
  });
}
