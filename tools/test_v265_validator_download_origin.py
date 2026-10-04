import pathlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
SRC=(ROOT/'tools/bootstrap_reference_validator.py').read_text()
class T(unittest.TestCase):
 def test_trusted_hosts_are_explicit(self):
  self.assertIn('PYPI_HOSTS = {"pypi.org", "files.pythonhosted.org"}', SRC)
 def test_download_url_host_is_checked(self):
  self.assertIn('parsed.hostname not in PYPI_HOSTS', SRC)
  self.assertIn('parsed.username or parsed.password', SRC)
 def test_hash_verification_remains(self):
  self.assertIn('actual_hash = hashlib.sha256(path.read_bytes()).hexdigest()', SRC)
  self.assertIn('if actual_hash != expected_hash:', SRC)
if __name__=='__main__': unittest.main()
