/// Deployment configuration for the tools. Nothing here is a secret.
abstract final class ToolsConfig {
  /// MET Norway requires an identifying User-Agent WITH contact information
  /// (https://api.met.no/doc/TermsOfService). The contact below is a
  /// PLACEHOLDER: replace `CONTACT_REQUIRED` with a real e-mail or website
  /// before release. While the placeholder is present the weather adapter
  /// refuses to call the service (fail closed) instead of violating the terms.
  ///
  /// The contact can be supplied at build time without editing code:
  ///   flutter build ios --dart-define=METNO_CONTACT=ornek@alanadi.com
  static const metNoUserAgent =
      _metNoContact == '' ? 'SniperTurk/1.0 CONTACT_REQUIRED' : 'SniperTurk/1.0 $_metNoContact';

  static const _metNoContact = String.fromEnvironment('METNO_CONTACT');

  static const metNoPlaceholderMarker = 'CONTACT_REQUIRED';
}
