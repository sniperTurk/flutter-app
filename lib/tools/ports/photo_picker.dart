import 'dart:typed_data';

enum PhotoPickFailureReason {
  /// Access refused or restricted by the system.
  denied,
  error,
}

class PhotoPickFailure implements Exception {
  final PhotoPickFailureReason reason;
  final String message;
  const PhotoPickFailure(this.reason, this.message);
  @override
  String toString() => 'PhotoPickFailure($reason): $message';
}

/// Port for choosing ONE existing photo from the device (Sight Height
/// "Galeriden seç"). The photo is returned as bytes only; the adapter must
/// not copy it into app storage or the photo library.
abstract interface class PhotoPicker {
  /// Returns null when the user cancels. Throws [PhotoPickFailure].
  Future<Uint8List?> pickPhoto();
}
