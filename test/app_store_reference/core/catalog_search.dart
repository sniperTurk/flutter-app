/// Locale-tolerant catalog search for Turkish users.
///
/// Search is deliberately dependency-free and deterministic: Turkish letters
/// are folded to their ASCII equivalents and query terms may be entered in any
/// order. This lets e.g. `huglu`, `HUGLU` and `Huğlu` find the same catalog
/// record without changing the canonical display data.
class CatalogSearch {
  const CatalogSearch._();

  static String normalize(String value) {
    const folds = <String, String>{
      'ç': 'c',
      'Ç': 'c',
      'ğ': 'g',
      'Ğ': 'g',
      'ı': 'i',
      'İ': 'i',
      'ö': 'o',
      'Ö': 'o',
      'ş': 's',
      'Ş': 's',
      'ü': 'u',
      'Ü': 'u',
    };
    final out = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      out.write(folds[char] ?? char.toLowerCase());
    }
    return out.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool matches(String haystack, String query) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return true;
    final normalizedHaystack = normalize(haystack);
    return normalizedQuery
        .split(' ')
        .where((term) => term.isNotEmpty)
        .every(normalizedHaystack.contains);
  }
}
