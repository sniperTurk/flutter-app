# V331 changelog

- Hardened the live App Store privacy-policy verifier against unsafe URL targets.
- The verifier now rejects non-public/non-HTTPS initial URLs before any network access.
- The default redirect handler rejects redirects to private, loopback, localhost, reserved-test, credential-bearing, or non-HTTPS targets before following them.
- Final response URLs are also revalidated so injected/custom openers cannot silently bypass the redirect policy.
- Added regression coverage for private initial URLs, private HTTPS final redirects, and the default redirect handler's pre-follow rejection.
- No Flutter runtime result is claimed; Flutter SDK/Xcode remain unavailable in this environment.
