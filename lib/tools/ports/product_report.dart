enum ProductReportFailureKind { offline, timeout, server }

class ProductReportFailure implements Exception {
  final ProductReportFailureKind kind;
  final String message;
  const ProductReportFailure(this.kind, this.message);
  @override
  String toString() => message;
}

/// Port for "Aradığın mühimmat listede yok mu?" (owner, 2026-10-17): sends
/// a product the user did not find in the lists to our catalog inbox, so it
/// can be added later from the manufacturer's data. Nothing is sent unless
/// the user taps Gönder; the profile is never changed.
abstract interface class ProductReportSender {
  /// Sends [body] (already built, see `ammoReportBody`). Completes on
  /// success; throws [ProductReportFailure] otherwise.
  Future<void> send(Map<String, Object?> body);
}
