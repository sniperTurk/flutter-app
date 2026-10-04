import unittest

import offline_solver_crosscheck as xc


class OfflineSolverCrosscheckTest(unittest.TestCase):
    def test_tables_are_read_from_the_dart_source(self):
        tables = xc.load_tables()
        self.assertEqual(79, len(tables["g1"]))
        self.assertEqual(84, len(tables["g7"]))
        self.assertAlmostEqual(0.2629, tables["g1"][0][1])

    def test_constant_cd_decay_matches_closed_form(self):
        self.assertEqual([], xc.check_analytic())

    def test_full_crosscheck_passes_and_never_claims_acceptance(self):
        self.assertEqual(0, xc.main())


    def test_bc_to_retardation_constant_matches_the_published_fps_constant(self):
        # JBM / py-ballisticcalc publish the G-function retardation constant as
        # 2.08551e-04 (fps units). It follows from a = rho*pi*Cd*v^2 / (8*BC_SI)
        # with rho0 = 1.225 kg/m3 and 1 lb/in2 = 703.0696 kg/m2, i.e. the
        # BC convention used by lib/core/aerodynamic_trajectory_solver.dart.
        constant = 1.225 * xc.math.pi / (8 * xc.LB_IN2_TO_KG_M2) * 0.3048
        self.assertAlmostEqual(2.08551e-4, constant, delta=5e-10)

    def test_g7_cases_are_checked_out_to_the_acceptance_minimum_range(self):
        import json
        policy = json.loads((xc.ROOT / 'validation/acceptance.json').read_text(encoding='utf-8'))
        minimum = policy['requirements']['minimum_max_range_m_by_model']
        for model, key in (('g1', 'G1'), ('g7', 'G7')):
            self.assertGreaterEqual(max(xc.RANGES_BY_MODEL[model]), minimum[key])

if __name__ == "__main__":
    unittest.main()
