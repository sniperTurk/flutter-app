import pathlib, re, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
SRC=(ROOT/'lib/data/catalog_repository.dart').read_text(encoding='utf-8')
class V196MkeFirearmAmmunition(unittest.TestCase):
    def test_verified_mke_records_are_firearm_only(self):
        for rid in ('mke-556x45-polymer','mke-556x45-m193'):
            m=re.search(r"Ammunition\(id:'%s'.*?\)," % re.escape(rid), SRC)
            self.assertIsNotNone(m, rid)
            self.assertIn('platform:WeaponPlatform.firearm',m.group(0))
            self.assertIn("sourceName:'MKE'",m.group(0))
    def test_projectile_mass_conversions_are_locked(self):
        self.assertIn("id:'mke-556x45-polymer'",SRC); self.assertIn('grain:49.38',SRC)
        self.assertIn("id:'mke-556x45-m193'",SRC); self.assertIn('grain:54.78',SRC)
    def test_no_ballistic_coefficient_is_invented(self):
        for rid in ('mke-556x45-polymer','mke-556x45-m193'):
            m=re.search(r"Ammunition\(id:'%s'.*?\)," % re.escape(rid), SRC)
            self.assertNotIn('ballisticCoefficient:',m.group(0))
    def test_manual_firearm_template_is_preserved(self):
        self.assertIn("id:'firearm-manual'",SRC)
if __name__=='__main__': unittest.main()
