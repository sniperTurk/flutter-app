# V332

- `verify_privacy_policy_url.py`: the V331 SSRF guard accepted alternate IPv4 spellings such as `https://0x7f.1/` or `https://127.1/`. They are not parsed by `ipaddress`, pass the hostname-label regex, and the OS resolver turns them into 127.0.0.1. The last label must now be alphabetic (or punycode); numeric/hex TLDs are rejected. Non-ASCII hostnames are IDNA-encoded first so legitimate Turkish IDN domains still pass.
- Added a regression test for alternate IPv4 spellings, numeric TLDs and IDN hosts.
- Known limit: a public-looking hostname that DNS-resolves to a private address is not detected (no DNS lookup is done here).
