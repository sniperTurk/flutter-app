/// What kind of product a user typed in because it was not in the lists.
/// [wireName] is the worker's `tur` value.
enum ProductReportKind {
  tufek('tufek'),
  muhimmat('muhimmat'),
  durbun('durbun');

  final String wireName;
  const ProductReportKind(this.wireName);
}

/// One product the user typed in: only its technical values (brand, model,
/// numbers). Never a profile name, location, device id or personal data.
class ProductReport {
  final ProductReportKind kind;

  /// The entered values only (empty ones left out). Keys `[A-Za-z0-9_]`,
  /// values a string or a number.
  final Map<String, Object> fields;

  const ProductReport(this.kind, this.fields);
}

class ProductReportFailure implements Exception {
  final String message;
  const ProductReportFailure(this.message);
  @override
  String toString() => message;
}

/// Port for the product box (owner, 2026-10-17 22:11: what the user typed is
/// saved to our Cloudflare box; the product is added to the catalog later,
/// from manufacturer data). Shared by every product kind.
abstract interface class ProductReportService {
  /// Sends [report] once and returns the record id the box gave it.
  /// Throws [ProductReportFailure] on any failure (offline, timeout, server).
  Future<String> send(ProductReport report);
}
