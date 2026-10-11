import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/reticle.dart';
import 'package:sniper_turk/data/reticle_catalog.dart';
import 'package:sniper_turk/data/reticle_library.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

ReticleData _record(String id) =>
    ReticleLibrary.all.firstWhere((r) => r.id == id);

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

  test('null fields are never guessed', () {
    // VSE-3 MOA: family unknown -> no data drawing (generic grid).
    expect(_record('vector-optics-vse-3-moa').toSpec(), isNull);
    // MPR-4 MIL: mark spacing unknown -> no data drawing.
    expect(_record('vector-optics-mpr-4-mil').toSpec(), isNull);

    // APRS14: known parts drawn, unknown listed.
    final aprs = _record('athlon-optics-aprs14-ffp-mil').toSpec()!;
    expect(aprs.fromData, isTrue);
    expect(aprs.complete, isFalse);
    expect(aprs.family, ReticleFamily.tree);
    expect(aprs.hashStep, 0.2);
    expect(aprs.extentDown, 10);
    expect(aprs.majorEvery, 0, reason: 'unknown major marks are not drawn');
    expect(aprs.numbersEvery, isNull);
    expect(aprs.postsStart, isNull);
    expect(aprs.centerDot, isTrue);
    expect(aprs.floatingCenter, isTrue);
    // Rows keep their known ends; the unknown dot spacing stays null.
    expect(aprs.tree.map((r) => (r.y, r.halfWidth, r.dotStep)), [
      (1.0, 1.0, null),
      (10.0, 4.0, null),
    ]);
    expect(
      aprs.genericParts,
      containsAll([
        'extent_h',
        'extent_v_up',
        'major_every',
        'numbers_every',
        'posts_start',
        'tree.dot_step',
      ]),
    );
    expect(aprs.genericParts, isNot(contains('extent_v_down')));
    // Unknown extents follow the generic MIL tree grid.
    expect(aprs.extentH, Reticles.generic(Reticles.treeMil).extentH);

    // A record with every field known is complete.
    final full = ReticleData.fromJson({
      'name': 'Tam',
      'unit': 'mil',
      'family': 'tree',
      'hash_step': 0.2,
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
      'floating_center': true,
      'line_width': 0.04,
      'post_width': 0.4,
    })!.toSpec()!;
    expect(full.complete, isTrue);
    expect(full.lineWidth, 0.04);
    expect(full.postWidth, 0.4);
    expect(full.extentUp, 4);
  });

  test('a scope reticle name finds its data record', () {
    ReticleData? find(String name, String brand, AngularUnit u) =>
        ReticleCatalog.find(name, u, brand: brand);
    expect(
      find('APRS14', 'Athlon', AngularUnit.mrad)?.id,
      'athlon-optics-aprs14-ffp-mil',
    );
    expect(find('TOR-MIL', 'Arken Optics', AngularUnit.mrad)?.id,
        'arken-tor-mil');
    expect(
      find('MIL-C F1', 'Nightforce Optics', AngularUnit.mrad)?.id,
      'nightforce-mil-c',
    );
    // Two APLR2 records: the turret unit decides.
    expect(
      find('APLR2', 'Athlon', AngularUnit.mrad)?.id,
      'athlon-optics-aplr2-ffp-ir-mil',
    );
    expect(
      find('APLR2', 'Athlon', AngularUnit.moa)?.id,
      'athlon-optics-aplr2-ffp-ir-moa',
    );
    // Another brand's reticle of the same name is not used.
    expect(find('Mil-Dot', 'Athlon', AngularUnit.mrad), isNull);
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
      'VSE-3 MOA',
      AngularUnit.moa,
      brand: 'Vector Optics',
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
    expect(spec.family, ReticleFamily.tree);
    expect(tester.takeException(), isNull);
  });
}
