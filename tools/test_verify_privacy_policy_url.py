import io
import unittest
from email.message import Message
from urllib.error import URLError
from verify_privacy_policy_url import _SafeRedirectHandler, verify


class FakeResponse:
    def __init__(self, body, *, status=200, url="https://sniperturk.com/privacy", content_type="text/html; charset=utf-8"):
        self._body = io.BytesIO(body)
        self.status = status
        self._url = url
        self.headers = Message()
        self.headers["Content-Type"] = content_type
    def __enter__(self): return self
    def __exit__(self, *args): return False
    def getcode(self): return self.status
    def geturl(self): return self._url
    def read(self, size=-1): return self._body.read(size)


def opener_for(response):
    def opener(request, timeout=0):
        return response
    return opener


class PrivacyPolicyLiveCheckTest(unittest.TestCase):
    def test_valid_https_policy_passes(self):
        body = ("Gizlilik Politikası — SNIPER TÜRK kişisel veriler ve privacy uygulamalarını açıklar. " * 4).encode()
        self.assertEqual([], verify("https://sniperturk.com/privacy", opener_for(FakeResponse(body))))

    def test_dead_url_fails(self):
        def dead(request, timeout=0): raise URLError("offline")
        self.assertTrue(any("not reachable" in e for e in verify("https://sniperturk.com/privacy", dead)))

    def test_private_initial_url_fails_before_opener_is_called(self):
        called = False
        def should_not_open(request, timeout=0):
            nonlocal called
            called = True
            raise AssertionError("private URL must be rejected before network access")
        errors = verify("https://127.0.0.1/privacy", should_not_open)
        self.assertTrue(any("public HTTPS host" in e for e in errors))
        self.assertFalse(called)

    def test_default_redirect_handler_blocks_private_target_before_following(self):
        handler = _SafeRedirectHandler()
        request = __import__('urllib.request').request.Request("https://sniperturk.com/privacy")
        with self.assertRaises(URLError):
            handler.redirect_request(
                request, None, 302, "Found", Message(), "https://127.0.0.1/private"
            )

    def test_private_https_redirect_fails(self):
        body = ("Privacy policy and personal data handling. " * 8).encode()
        errors = verify(
            "https://sniperturk.com/privacy",
            opener_for(FakeResponse(body, url="https://127.0.0.1/privacy")),
        )
        self.assertTrue(any("non-public HTTPS" in e for e in errors))

    def test_non_https_redirect_fails(self):
        body = ("Privacy policy and personal data handling. " * 8).encode()
        errors = verify("https://sniperturk.com/privacy", opener_for(FakeResponse(body, url="http://sniperturk.com/privacy")))
        self.assertTrue(any("non-public HTTPS" in e for e in errors))

    def test_alternate_ipv4_spellings_and_numeric_tlds_are_rejected(self):
        from verify_privacy_policy_url import _is_public_https_url
        for bad in ("https://0x7f.1/p", "https://127.1/p", "https://2130706433/p",
                    "https://0x7f.0x0.0x0.0x1/p", "https://10.0.0.1/p", "https://example.123/p"):
            self.assertFalse(_is_public_https_url(bad), bad)
        for good in ("https://sniperturk.com/privacy", "https://93.184.216.34/p",
                     "https://gizlilik.çözüm.com/p", "https://a.xn--p1ai/p"):
            self.assertTrue(_is_public_https_url(good), good)

    def test_wrong_content_or_placeholder_body_fails(self):
        response = FakeResponse(b"coming soon", content_type="application/json")
        errors = verify("https://sniperturk.com/privacy", opener_for(response))
        self.assertTrue(any("content type" in e for e in errors))
        self.assertTrue(any("too short" in e for e in errors))
        self.assertTrue(any("recognizable" in e for e in errors))


if __name__ == "__main__": unittest.main()
