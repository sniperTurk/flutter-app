import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/reticle_catalog.dart';
import 'package:sniper_turk/data/scope_library.dart';
import 'package:sniper_turk/models/domain.dart';

/// Scope → reticle record matching (owner, 2026-10-11): every listed
/// scope's reticle names find the record tools/reticle_match_audit.py
/// finds; the fixture is written by that script.
void main() {
  test('every listed scope matches as the audit says', () {
    final fixture =
        jsonDecode(
              File('test/fixtures/reticle_scope_matches.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    var matched = 0;
    for (final s in ScopeLibrary.all) {
      final names = ReticleCatalog.options(s.reticle);
      final want = fixture[s.id] as Map<String, dynamic>?;
      expect(names.length, want?.length ?? 0, reason: s.id);
      for (final n in names) {
        final hit = ReticleCatalog.find(
          n,
          s.clickUnit,
          brand: s.brand,
          model: s.model,
        );
        expect(hit?.id, want![n], reason: '${s.id}: $n');
        if (hit != null) matched++;
      }
    }
    expect(matched, greaterThanOrEqualTo(269));
  });

  test('a record holding several reticle names lists each', () {
    expect(ReticleCatalog.options('APR-1C MOA / APR-2D MOA'), [
      'APR-1C MOA',
      'APR-2D MOA',
    ]);
    expect(ReticleCatalog.options('VPR-MIL / FFP'), ['VPR-MIL']);
    expect(ReticleCatalog.options(null), isEmpty);
  });

  test('glued focal-plane and unit words are not part of the name', () {
    expect(
      ReticleCatalog.find(
        'VCT-34FFP',
        AngularUnit.mrad,
        brand: 'Vector Optics',
      )?.id,
      'vector-optics-vct-34-ffp-mil',
    );
    expect(
      ReticleCatalog.find(
        'VEPG-T MIL',
        AngularUnit.mrad,
        brand: 'Vector Optics',
      )?.id,
      'vector-optics-vepg-tmil-mil',
    );
    expect(ReticleCatalog.nameKey('MOAR').core, 'MOAR');
    expect(ReticleCatalog.nameKey('MIL-C F1').core, 'MILC');
  });

  test('SKMR4+ is not SKMR4', () {
    expect(
      ReticleCatalog.find('SKMR4+', AngularUnit.mrad, brand: 'Kahles')?.id,
      'kahles-skmr4-plus',
    );
    expect(
      ReticleCatalog.find('SKMR4', AngularUnit.mrad, brand: 'Kahles')?.id,
      'kahles-skmr4',
    );
  });

  test('the record unit must be the turret unit', () {
    // RAPTR-1F is a MRAD record; a MOA scope of that name gets none.
    expect(
      ReticleCatalog.find('RAPTR-1F', AngularUnit.moa, brand: 'Element Optics'),
      isNull,
    );
    // The name says MOA, the turret is MRAD: no record.
    expect(
      ReticleCatalog.find(
        'APR-1C MOA',
        AngularUnit.mrad,
        brand: 'Element Optics',
      ),
      isNull,
    );
    expect(
      ReticleCatalog.find(
        'APR-1C MOA',
        AngularUnit.moa,
        brand: 'Element Optics',
      )?.id,
      'element-optics-apr-1c-moa',
    );
  });

  test('two records of one name: the manufacturer scope list decides', () {
    expect(
      ReticleCatalog.find(
        'APRS6',
        AngularUnit.mrad,
        brand: 'Athlon CRONUS BTR GEN2 UHD IR MIL',
        model: '4,5-29x56 FFP',
      )?.id,
      'athlon-optics-aprs6-ffp-ir-mil',
    );
    expect(
      ReticleCatalog.find('APRS6', AngularUnit.mrad, brand: 'Athlon'),
      isNull,
    );
  });

  test('Hedef draws a several-name record as the generic grid', () {
    final spec = ReticleCatalog.forScope(
      'APR-1C MOA / APR-2D MOA',
      AngularUnit.moa,
      brand: 'Element Optics',
    )!;
    expect(spec.fromData, isFalse);
    final one = ReticleCatalog.forScope(
      'APR-2D MOA',
      AngularUnit.moa,
      brand: 'Element Optics',
    )!;
    expect(one.fromData, isTrue);
  });
}
