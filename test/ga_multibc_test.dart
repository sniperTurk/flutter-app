// GA (ChairGun diabolo pellet) drag law and velocity-dependent BC
// (çoklu BC), owner 2026-10-09.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/aerodynamic_trajectory_solver.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/drag_safety.dart';
import 'package:sniper_turk/core/standard_drag_tables.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';

BallisticInput _pellet({
  BallisticModel model = BallisticModel.g1,
  double bc = 0.03,
  List<BcBand> bands = const [],
  List<double> ranges = const [25, 50, 75],
}) => BallisticInput(
  muzzleVelocityMps: 260,
  grain: 25.39,
  zeroRangeM: 25,
  sightHeightMm: 60,
  rangesM: ranges,
  ballisticCoefficient: bc,
  ballisticModel: model,
  bcBands: bands,
);

const _solver = AerodynamicTrajectorySolver();

Map<String, dynamic> _ammo(Map<String, dynamic> extra) => {
  'id': 'c-ga',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'JSB',
  'model': 'Exact King',
  'caliberMm': 6.35,
  'grain': 25.39,
  'ammoType': 'pellet',
  'bc': 0.033,
  ...extra,
};

void main() {
  group('GA table', () {
    test('keeps the 37 published Cd-vs-Mach pairs verbatim', () {
      final ga = StandardDragTables.ga;
      expect(ga.samples.length, 37);
      expect(ga.coefficientAtMach(0.0), 0.250);
      expect(ga.coefficientAtMach(0.5), 0.189);
      expect(ga.coefficientAtMach(0.8), 0.241);
      expect(ga.coefficientAtMach(1.4), 0.672);
      expect(ga.coefficientAtMach(3.6), 0.503);
      expect(StandardDragTables.gaSourceUrl, contains('527843'));
    });

    test('subsonic pellet: GA drags less than G1 at the same BC', () {
      final g1 = _solver.solve(_pellet());
      final ga = _solver.solve(_pellet(model: BallisticModel.ga));
      expect(ga.last.velocityMps, greaterThan(g1.last.velocityMps));
      expect(ga.last.dropM, lessThan(g1.last.dropM));
    });

    test('GA on a firearm warns; on a PCP it is flagged unverified', () {
      List<DragWarningKind> kinds(WeaponPlatform p) => DragSafety.assess(
        muzzleVelocityMps: 250,
        environment: const EnvironmentData(),
        ballisticCoefficient: 0.03,
        ballisticModel: BallisticModel.ga,
        platform: p,
      ).map((w) => w.kind).toList();
      expect(kinds(WeaponPlatform.pcp), [DragWarningKind.gaUnverified]);
      expect(
        kinds(WeaponPlatform.firearm),
        contains(DragWarningKind.firearmWithGa),
      );
    });
  });

  group('BC bands', () {
    test('picks the band by speed, whatever order they were given in', () {
      final i = _pellet(
        bands: const [BcBand(0, 0.025), BcBand(240, 0.03), BcBand(200, 0.028)],
      );
      expect(i.bcAtSpeed(255), 0.03);
      expect(i.bcAtSpeed(240), 0.03);
      expect(i.bcAtSpeed(220), 0.028);
      expect(i.bcAtSpeed(150), 0.025);
      expect(_pellet().bcAtSpeed(100), 0.03);
    });

    test('bands equal to the single BC change nothing', () {
      final single = _solver.solve(_pellet());
      final banded = _solver.solve(
        _pellet(bands: const [BcBand(240, 0.03), BcBand(0, 0.03)]),
      );
      for (var k = 0; k < single.length; k++) {
        expect(banded[k].dropM, closeTo(single[k].dropM, 1e-12));
      }
    });

    test('a lower BC once slower drops more far out', () {
      final single = _solver.solve(_pellet());
      final banded = _solver.solve(
        _pellet(bands: const [BcBand(240, 0.03), BcBand(0, 0.024)]),
      );
      expect(banded.last.dropM, greaterThan(single.last.dropM));
      expect(banded.last.velocityMps, lessThan(single.last.velocityMps));
    });

    test('truing scales the whole band set', () {
      final i = _pellet(bands: const [BcBand(240, 0.03), BcBand(0, 0.024)]);
      final t = i.withBallisticCoefficient(0.033);
      expect(t.bcAtSpeed(250), closeTo(0.033, 1e-12));
      expect(t.bcAtSpeed(100), closeTo(0.024 * 1.1, 1e-12));
    });

    test('bands without a BC/model are rejected', () {
      expect(
        () => BallisticInput(
          muzzleVelocityMps: 260,
          grain: 25,
          zeroRangeM: 25,
          sightHeightMm: 60,
          rangesM: const [50],
          bcBands: const [BcBand(0, 0.03)],
        ),
        throwsArgumentError,
      );
    });
  });

  group('Storage', () {
    test('GA and bands are read from a personal record', () {
      final cat = UserCatalog.fromManualEntries([
        _ammo({
          'bcModel': 'ga',
          'bcBands': [
            {'mps': 240.0, 'bc': 0.033},
            {'mps': 0.0, 'bc': 0.029},
          ],
        }),
      ]);
      final a = cat.ammunition.single;
      expect(a.ballisticModel, BallisticModel.ga);
      expect(a.bcBands, const [BcBand(240, 0.033), BcBand(0, 0.029)]);
    });

    test('malformed bands fall back to the single BC', () {
      final cat = UserCatalog.fromManualEntries([
        _ammo({
          'bcModel': 'G1',
          'bcBands': [
            {'mps': 'fast', 'bc': 0.03},
          ],
        }),
      ]);
      expect(cat.ammunition.single.bcBands, isEmpty);
    });

    test('the store accepts valid bands and refuses broken ones', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ManualCatalogStore();
      await store.upsert(
        _ammo({
          'bcModel': 'ga',
          'bcBands': [
            {'mps': 240.0, 'bc': 0.033},
            {'mps': 0.0, 'bc': 0.029},
          ],
        }),
      );
      expect((await store.all()).single['bcBands'], hasLength(2));
      expect(
        () => store.upsert(
          _ammo({
            'id': 'c-bad',
            'bcModel': 'g1',
            'bcBands': [
              {'mps': -5, 'bc': 0.03},
            ],
          }),
        ),
        throwsFormatException,
      );
    });
  });
}
