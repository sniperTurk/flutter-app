import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/reticle.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/features/profiles/scope_picker_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  test('catalog reticle names map to a family and unit', () {
    expect(Reticles.forName(null, AngularUnit.mrad), isNull);
    final tree = Reticles.forName('VPR-MIL', AngularUnit.mrad)!;
    expect(tree.family, ReticleFamily.tree);
    expect(tree.name, 'VPR-MIL');
    final moa = Reticles.forName('VSE-3 MOA', AngularUnit.mrad)!;
    expect(moa.family, ReticleFamily.hash);
    expect(moa.unit, AngularUnit.moa);
    expect(
      Reticles.forName('Mil-Dot', AngularUnit.mrad)!.family,
      ReticleFamily.milDot,
    );
    expect(
      Reticles.forName('VFD-2 Etched Glass', AngularUnit.moa)!.family,
      ReticleFamily.duplex,
    );
    // Every catalog reticle resolves.
    for (final s in CatalogRepository.scopes) {
      if (s.reticle == null) continue;
      expect(Reticles.forName(s.reticle, s.clickUnit), isNotNull);
    }
  });

  test('a data-file reticle is read', () {
    final r = Reticles.fromJson({
      'name': 'Test MIL',
      'unit': 'mil',
      'family': 'tree',
      'hash_step': 0.2,
      'major_every': 1,
      'numbers_every': 2,
      'extent_h': 10,
      'extent_v_up': 5,
      'extent_v_down': 10,
      'tree': {
        'rows': [
          {'y': 2, 'half_width': 2, 'dot_step': 1},
        ],
      },
      'posts_start': 12,
      'center_dot': true,
    })!;
    expect(r.family, ReticleFamily.tree);
    expect(r.tree.single.halfWidth, 2);
    expect(r.extentUp, 5);
    expect(r.centerDot, isTrue);
    expect(Reticles.fromJson({'unit': 'mil'}), isNull);
  });

  test('series name drops the designation', () {
    final s = CatalogRepository.scopes.firstWhere(
      (s) => s.id == 'vector-sentinel-6-24-scff57',
    );
    expect(ScopePickerScreen.seriesName(s), 'Sentinel (SCFF-57)');
  });

  testWidgets('every family paints', (tester) async {
    for (final name in Reticles.genericNames) {
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: Builder(
            builder: (context) => CustomPaint(
              size: const Size(300, 300),
              painter: ScopeReticlePainter(
                colors: MenzilColors.of(context),
                halfField: 10,
                markStep: 1,
                unitLabel: 'mrad',
                impactUp: 2,
                impactRight: 0.5,
                holdLabels: const [(1.0, '200'), (2.0, '300')],
                headline: 'Hedef: 300 m',
                reticle: Reticles.generic(name),
                reticleToView: name == Reticles.hashMoa ? 0.2909 : 1,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: name);
    }
  });

  testWidgets('"Listeden seç" fills the scope', (tester) async {
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

    await tester.ensureVisible(find.byKey(const Key('scope-library')));
    await tester.tap(find.byKey(const Key('scope-library')));
    await tester.pumpAndSettle();
    expect(find.text('Dürbün listesi'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('scope-picker-search')),
      'SCFF-57',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scope-picker-item-0')));
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
    expect(text('scope-brand'), contains('Sentinel'));
    expect(text('scope-min-mag'), '6');
    expect(text('scope-max-mag'), '24');
    expect(text('scope-objective'), '50');
  });
}
