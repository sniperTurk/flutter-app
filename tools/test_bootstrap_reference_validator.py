#!/usr/bin/env python3
"""Offline regression tests for the reference-validator bootstrap contract."""
from __future__ import annotations

import hashlib
import tempfile
import unittest
import urllib.error
from pathlib import Path
from unittest.mock import patch

import bootstrap_reference_validator as bootstrap


class MatchingWheelTest(unittest.TestCase):
    def test_accepts_py2_py3_universal_wheel_when_hash_matches(self) -> None:
        expected = "a" * 64
        payload = {
            "urls": [
                {
                    "packagetype": "bdist_wheel",
                    "filename": "Deprecated-1.2.18-py2.py3-none-any.whl",
                    "digests": {"sha256": expected},
                    "url": "https://example.invalid/Deprecated.whl",
                }
            ]
        }
        response = unittest.mock.MagicMock()
        response.__enter__.return_value = response
        response.__exit__.return_value = False
        with patch.object(bootstrap, "_trusted_urlopen", return_value=response), patch(
            "json.load", return_value=payload
        ):
            wheel = bootstrap._matching_wheel("Deprecated", "1.2.18", expected)
        self.assertEqual(wheel["filename"], "Deprecated-1.2.18-py2.py3-none-any.whl")

    def test_rejects_same_version_wheel_with_wrong_hash(self) -> None:
        expected = "a" * 64
        payload = {
            "urls": [
                {
                    "packagetype": "bdist_wheel",
                    "filename": "pkg-1.0-py3-none-any.whl",
                    "digests": {"sha256": "b" * 64},
                    "url": "https://example.invalid/pkg.whl",
                }
            ]
        }
        response = unittest.mock.MagicMock()
        response.__enter__.return_value = response
        response.__exit__.return_value = False
        with patch.object(bootstrap, "_trusted_urlopen", return_value=response), patch(
            "json.load", return_value=payload
        ), self.assertRaises(SystemExit):
            bootstrap._matching_wheel("pkg", "1.0", expected)

    def test_metadata_network_failure_is_fail_closed_without_traceback(self) -> None:
        with patch.object(
            bootstrap, "_trusted_urlopen",
            side_effect=urllib.error.URLError("offline"),
        ), self.assertRaises(SystemExit) as caught:
            bootstrap._matching_wheel("pkg", "1.0", "a" * 64)
        self.assertEqual(caught.exception.code, 2)

    def test_download_requires_https_url(self) -> None:
        wheel = {"filename": "pkg-1.0-py3-none-any.whl", "url": "http://example.invalid/pkg.whl"}
        with self.assertRaises(SystemExit) as caught:
            bootstrap._download_verified(wheel, "a" * 64, bootstrap.ROOT)
        self.assertEqual(caught.exception.code, 2)

    def test_cached_verified_selects_wheel_by_policy_hash(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            cache = Path(td)
            good = cache / "validator-py3-none-any.whl"
            bad = cache / "other-py3-none-any.whl"
            good.write_bytes(b"trusted-wheel")
            bad.write_bytes(b"wrong-wheel")
            expected = hashlib.sha256(good.read_bytes()).hexdigest()
            self.assertEqual(bootstrap._cached_verified(cache, expected, "validator==1"), good)

    def test_cached_verified_fails_closed_when_policy_wheel_missing(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            cache = Path(td)
            (cache / "wrong.whl").write_bytes(b"wrong")
            with self.assertRaises(SystemExit) as caught:
                bootstrap._cached_verified(cache, "a" * 64, "validator==1")
            self.assertEqual(caught.exception.code, 2)


class TrustedRedirectTest(unittest.TestCase):
    def test_redirect_rejects_untrusted_host(self) -> None:
        handler = bootstrap._TrustedPyPIRedirect()
        request = unittest.mock.MagicMock()
        request.full_url = "https://files.pythonhosted.org/pkg.whl"
        with self.assertRaises(urllib.error.HTTPError):
            handler.redirect_request(
                request,
                None,
                302,
                "Found",
                {},
                "https://evil.example/pkg.whl",
            )

    def test_trusted_url_requires_default_https_port(self) -> None:
        self.assertTrue(bootstrap._trusted_pypi_url("https://pypi.org/x"))
        self.assertTrue(bootstrap._trusted_pypi_url("https://files.pythonhosted.org:443/x"))
        self.assertFalse(bootstrap._trusted_pypi_url("https://pypi.org:8443/x"))
        self.assertFalse(bootstrap._trusted_pypi_url("https://pypi.org:bad/x"))

    def test_redirect_accepts_trusted_https_host(self) -> None:
        handler = bootstrap._TrustedPyPIRedirect()
        request = urllib.request.Request("https://pypi.org/start")
        redirected = handler.redirect_request(
            request,
            None,
            302,
            "Found",
            {},
            "https://files.pythonhosted.org/pkg.whl",
        )
        self.assertEqual(redirected.full_url, "https://files.pythonhosted.org/pkg.whl")


if __name__ == "__main__":
    unittest.main()
