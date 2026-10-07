/// One place found by a name search.
class PlaceResult {
  /// Human readable name/address as returned by the service.
  final String name;
  final double latitude;
  final double longitude;
  const PlaceResult(this.name, this.latitude, this.longitude);
}

enum PlaceSearchFailureKind { notConfigured, offline, timeout, server }

class PlaceSearchFailure implements Exception {
  final PlaceSearchFailureKind kind;
  final String message;
  const PlaceSearchFailure(this.kind, this.message);
  @override
  String toString() => message;
}

/// Port for place-name search (geocoding). The typed text is sent to an
/// external service only when the user submits a search.
abstract interface class PlaceSearch {
  /// Name of the data source for attribution.
  String get sourceName;

  /// Returns up to a few matches, best first. Throws [PlaceSearchFailure].
  Future<List<PlaceResult>> search(String query);
}
