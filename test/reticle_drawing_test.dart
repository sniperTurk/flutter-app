import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/reticle.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/reticle_catalog.dart';
import 'package:sniper_turk/data/reticle_library.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

/// Paints [spec] the way the Hedef screen does, with hold and wind labels.
Widget _painted(BuildContext context, ReticleSpec? spec, {bool labels = true}) {
  final moa = spec != null && spec.unit.moaFamily;
  return CustomPaint(
    size: const Size(320, 320),
    painter: ScopeReticlePainter(
      colors: MenzilColors.of(context),
      halfField: 10,
      markStep: 1,
      unitLabel: 'mrad',
      impactUp: -1.5,
      impactRight: 0.4,
      holdLabels: const [(1.0, '200'), (2.0, '300'), (3.0, '380')],
      windLabels: const [(1.0, '2,5'), (2.0, '5,0'), (3.0, '7,5')],
      headline: 'Hedef: 300 m',
      showLabels: labels,
      reticle: spec,
      reticleToView: moa ? 0.2909 : 1,
    ),
  );
}

void main() {
  test('the generated library holds the PR #82 records', () {
    expect(ReticleLibrary.all.length, greaterThanOrEqualTo(81));
    final ids = {for (final r in ReticleLibrary.all) r.id};
    expect(ids.length, ReticleLibrary.all.length, reason: 'unique ids');
    for (final r in ReticleLibrary.all) {
      expect(const {'mil', 'moa'}, contains(r.unit), reason: r.id);
      expect(r.name.trim(), isNotEmpty, reason: r.id);
    }
  });

  // The rules are tested on records written here, not on the library:
  // the brand branches fill the library's nulls over time.
  test('null fields are never guessed', () {
    Map<String, Object?> rec(Map<String, Object?> over) => {
      'name': 'Kısmi MIL',
      'brand': 'Test',
      'unit': 'mil',
      'family': 'tree',
      'hash_step': 0.2,
      'major_every': null,
      'numbers_every': null,
      'extent_h': null,
      'extent_v_up': null,
      'extent_v_down': 10,
      'tree': {
        'rows': [
          {'y': 1, 'half_width': 1, 'dot_step': null},
          {'y': 10, 'half_width': 4, 'dot_step': null},
        ],
      },
      'posts_start': null,
      'center_dot': true,
      'floating_center': true,
      ...over,
    };
    // Family unknown -> no data drawing (generic grid).
    expect(ReticleData.fromJson(rec({'family': null}))!.toSpec(), isNull);
    // Mark spacing unknown -> no data drawing.
    expect(ReticleData.fromJson(rec({'hash_step': null}))!.toSpec(), isNull);

    // Known parts drawn, unknown listed.
    final part = ReticleData.fromJson(rec({}))!.toSpec()!;
    expect(part.fromData, isTrue);
    expect(part.complete, isFalse);
    expect(part.family, ReticleFamily.tree);
    expect(part.hashStep, 0.2);
    expect(part.extentDown, 10);
    expect(part.majorEvery, 0, reason: 'unknown major marks are not drawn');
    expect(part.numbersEvery, isNull);
    expect(part.postsStart, isNull);
    expect(part.centerDot, isTrue);
    expect(part.floatingCenter, isTrue);
    // Rows keep their known ends; the unknown dot spacing stays null.
    expect(part.tree.map((r) => (r.y, r.halfWidth, r.dotStep)), [
      (1.0, 1.0, null),
      (10.0, 4.0, null),
    ]);
    expect(
      part.genericParts,
      containsAll([
        'extent_h',
        'extent_v_up',
        'major_every',
        'numbers_every',
        'posts_start',
        'tree.dot_step',
      ]),
    );
    expect(part.genericParts, isNot(contains('extent_v_down')));
    // Unknown extents follow the generic MIL tree grid.
    expect(part.extentH, Reticles.generic(Reticles.treeMil).extentH);

    // A record with every field known is complete.
    final full = ReticleData.fromJson(
      rec({
        'major_every': 1,
        'numbers_every': 2,
        'extent_h': 8,
        'extent_v_up': 4,
        'extent_v_down': 9,
        'tree': {
          'rows': [
            {'y': 2, 'half_width': 1, 'dot_step': 0.5},
          ],
        },
        'posts_start': 10,
        'center_dot': false,
        'line_width': 0.04,
        'post_width': 0.4,
      }),
    )!.toSpec()!;
    expect(full.complete, isTrue);
    expect(full.lineWidth, 0.04);
    expect(full.postWidth, 0.4);
    expect(full.extentUp, 4);
  });

  test('a scope reticle name finds its data record', () {
    const library = [
      ReticleData(
        id: 'a14',
        brand: 'Athlon Optics',
        name: 'APRS14 FFP MIL',
        unit: 'mil',
      ),
      ReticleData(
        id: 'tor',
        brand: 'Arken Optics',
        name: 'TOR MIL',
        unit: 'mil',
      ),
      ReticleData(id: 'milc', brand: 'Nightforce', name: 'MIL-C', unit: 'mil'),
      ReticleData(
        id: 'l2mil',
        brand: 'Athlon Optics',
        name: 'APLR2 FFP IR MIL',
        unit: 'mil',
      ),
      ReticleData(
        id: 'l2moa',
        brand: 'Athlon Optics',
        name: 'APLR2 FFP IR MOA',
        unit: 'moa',
      ),
      ReticleData(id: 'md', brand: 'Nightforce', name: 'Mil-Dot', unit: 'mil'),
    ];
    String? find(String name, String brand, AngularUnit u) =>
        ReticleCatalog.find(name, u, brand: brand, library: library)?.id;
    expect(find('APRS14', 'Athlon', AngularUnit.mrad), 'a14');
    expect(find('TOR-MIL', 'Arken Optics', AngularUnit.mrad), 'tor');
    expect(find('MIL-C F1', 'Nightforce Optics', AngularUnit.mrad), 'milc');
    // Two APLR2 records: the turret unit decides.
    expect(find('APLR2', 'Athlon', AngularUnit.mrad), 'l2mil');
    expect(find('APLR2', 'Athlon', AngularUnit.moa), 'l2moa');
    // The name's own unit wins over the turret.
    expect(find('APLR2 MOA', 'Athlon', AngularUnit.mrad), 'l2moa');
    // Another brand's reticle of the same name is not used.
    expect(find('Mil-Dot', 'Athlon', AngularUnit.mrad), isNull);
    // A brand only leads: "Athlon CRONUS …" is Athlon, "Athlonx" is not.
    expect(find('APRS14', 'Athlon CRONUS BTR', AngularUnit.mrad), 'a14');
    expect(find('APRS14', 'Athlonx', AngularUnit.mrad), isNull);
    // A bare unit is no reticle name.
    expect(find('MRAD', 'Arken Optics', AngularUnit.mrad), isNull);
    expect(find('APRS14', '', AngularUnit.mrad), isNull);

    // Hedef: data drawing when drawable, else the generic grid.
    final spec = ReticleCatalog.forScope(
      'APRS14',
      AngularUnit.mrad,
      brand: 'Athlon',
    )!;
    expect(spec.fromData, isTrue);
    expect(spec.name, 'APRS14');
    final generic = ReticleCatalog.forScope(
      'XYZ-9 MOA',
      AngularUnit.moa,
      brand: 'Test Marka',
    )!;
    expect(generic.fromData, isFalse);
    expect(generic.unit, AngularUnit.moa);
    expect(ReticleCatalog.forScope(null, AngularUnit.mrad), isNull);
  });

  testWidgets('every data reticle paints, with and without labels', (
    tester,
  ) async {
    for (final r in ReticleLibrary.all) {
      final spec = r.toSpec();
      if (spec == null) continue;
      for (final labels in const [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: MenzilTheme.light(),
            home: Builder(
              builder: (context) => _painted(context, spec, labels: labels),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: r.id);
      }
    }
  });

  testWidgets('the Hedef screen draws the scope\'s own reticle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryProfileStore();
    await store.save(
      const RifleProfile(
        id: 'p1',
        name: 'Bir',
        rifleId: 'hatsan-hercules-635',
        ammunitionId: 'gmaz-51',
        scopeId: 'lib-athlon-midas-tac-gen2-hd-6-24x50-aprs14-ffp-mil',
        muzzleVelocityMps: 270,
        zeroRangeM: 25,
        sightHeightMm: 60,
        pressureBar: 200,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: HomeScreen(
          profileStore: store,
          activeProfileStore: MemoryActiveProfileStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hedef'));
    await tester.pumpAndSettle();
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byKey(ScopeDialKeys.reticle),
        matching: find.byType(CustomPaint),
      ),
    );
    final spec = (paint.painter! as ScopeReticlePainter).reticle!;
    expect(spec.fromData, isTrue);
    expect(spec.name, 'APRS14');
    expect(tester.takeException(), isNull);
  });

  test('a scope saved from the Profil form keeps its data reticle', () {
    addTearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries(const [
        {
          'id': 'manual_scope_1',
          'kind': 'scope',
          'platform': 'pcp',
          // The Profil form saves the series with the brand.
          'brand': 'Athlon CRONUS BTR GEN2 UHD IR MIL',
          'model': '4,5-29x56 FFP',
          'objectiveMm': 56.0,
          'click': 0.1,
          'clickUnit': 'mrad',
          'focal': 'ffp',
          'minMag': 4.5,
          'maxMag': 29.0,
          'reticle': 'APRS1',
        },
      ]),
    );
    final scope = CatalogRepository.allScopes.firstWhere(
      (s) => s.id == 'manual_scope_1',
    );
    expect(scope.reticle, 'APRS1');
    final spec = ReticleCatalog.forScope(
      scope.reticle,
      scope.clickUnit,
      brand: scope.brand,
    )!;
    expect(spec.fromData, isTrue);
    expect(spec.name, 'APRS1');
  });
}
