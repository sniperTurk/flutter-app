// Velocity-dependent BC (çoklu BC), owner 2026-10-09.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/aerodynamic_trajectory_solver.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
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
  group('GA removed', () {
    test('only G1/G7 and the BRL/RA4/GS laws remain', () {
      expect(
        BallisticModel.values.map((m) => m.name),
        isNot(contains('ga')),
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
    test('G1 records and their bands are read unchanged', () {
      final cat = UserCatalog.fromManualEntries([
        _ammo({
          'bcModel': 'G1',
          'bcBands': [
            {'mps': 240.0, 'bc': 0.033},
            {'mps': 0.0, 'bc': 0.029},
          ],
        }),
      ]);
      final a = cat.ammunition.single;
      expect(a.ballisticModel, BallisticModel.g1);
      expect(a.ballisticCoefficient, 0.033);
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
          'bcModel': 'g1',
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
