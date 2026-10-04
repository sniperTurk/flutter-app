#!/usr/bin/env python3
"""Verify that the configured App Store privacy-policy URL is actually reachable.

Source preflight validates URL shape. This gate performs the network check that
source inspection cannot: HTTPS reachability, safe redirects, HTML/text content,
and enough policy-like body text to avoid shipping a dead/placeholder page.
"""
from __future__ import annotations
import argparse
import ipaddress
import re
import sys
import urllib.error
import urllib.request
from urllib.parse import urlparse

MAX_BYTES = 512_000
MIN_TEXT_CHARS = 120
POLICY_TERMS = ("privacy", "gizlilik", "personal data", "kişisel veri", "kişisel veriler")
RESERVED_HOSTS = {"localhost"}
RESERVED_TLDS = (".test", ".invalid", ".example", ".localhost")


def _is_public_https_url(value: str) -> bool:
    """Reject non-public redirect targets before release CI follows them."""
    try:
        parsed = urlparse(value)
        host = (parsed.hostname or "").rstrip(".").lower()
        if parsed.scheme.lower() != "https" or not host or parsed.username or parsed.password:
            return False
        if host in RESERVED_HOSTS or host.endswith(RESERVED_TLDS) or "." not in host:
            return False
        try:
            address = ipaddress.ip_address(host)
        except ValueError:
            try:
                host = host.encode("idna").decode("ascii")
            except UnicodeError:
                return False
            labels = host.split(".")
            if any(
                not re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?", label)
                for label in labels
            ):
                return False
            # Real TLDs are alphabetic (or punycode). A numeric/hex last label
            # such as "0x7f.1" or "127.1" is an alternate IPv4 spelling that the
            # OS resolver turns into 127.0.0.1, bypassing the literal-IP check.
            return bool(re.fullmatch(r"[a-z]{2,63}|xn--[a-z0-9-]{1,59}", labels[-1]))
        return address.is_global
    except ValueError:
        return False


class _SafeRedirectHandler(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if not _is_public_https_url(newurl):
            raise urllib.error.URLError(
                f"refusing non-public HTTPS privacy-policy redirect: {newurl}"
            )
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def _default_opener(request, timeout=15):
    return urllib.request.build_opener(_SafeRedirectHandler()).open(
        request, timeout=timeout
    )


def verify(url: str, opener=None) -> list[str]:
    errors: list[str] = []
    if not url:
        return ["privacy policy URL is empty"]
    if not _is_public_https_url(url):
        return ["privacy policy URL must use a public HTTPS host"]
    opener = opener or _default_opener
    try:
        request = urllib.request.Request(
            url,
            headers={"User-Agent": "SNIPER-TURK-AppStore-Preflight/1.0", "Accept": "text/html,text/plain;q=0.9"},
        )
        with opener(request, timeout=15) as response:
            status = getattr(response, "status", None) or response.getcode()
            final_url = response.geturl()
            if status != 200:
                errors.append(f"privacy policy returned HTTP {status}, expected 200")
            if not _is_public_https_url(final_url):
                errors.append(
                    f"privacy policy redirected to non-public HTTPS URL: {final_url}"
                )
            content_type = (response.headers.get("Content-Type") or "").lower()
            if not (content_type.startswith("text/html") or content_type.startswith("text/plain")):
                errors.append(f"privacy policy content type must be text/html or text/plain, got {content_type or 'missing'}")
            body = response.read(MAX_BYTES + 1)
            if len(body) > MAX_BYTES:
                errors.append("privacy policy response exceeds 512000-byte verification limit")
            charset = response.headers.get_content_charset() or "utf-8"
            text = body[:MAX_BYTES].decode(charset, errors="replace").strip()
            if len(text) < MIN_TEXT_CHARS:
                errors.append(f"privacy policy page is too short ({len(text)} chars; need at least {MIN_TEXT_CHARS})")
            lowered = text.lower()
            if not any(term in lowered for term in POLICY_TERMS):
                errors.append("privacy policy page does not contain a recognizable privacy-policy term")
    except (urllib.error.URLError, TimeoutError, OSError, ValueError) as exc:
        errors.append(f"privacy policy URL is not reachable: {exc}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True)
    args = parser.parse_args()
    errors = verify(args.url)
    if errors:
        print("PRIVACY POLICY LIVE CHECK: BLOCKED")
        for error in errors:
            print(f"- {error}")
        return 1
    print("PRIVACY POLICY LIVE CHECK: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
