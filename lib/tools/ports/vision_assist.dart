import 'dart:typed_data';

/// Result of an optional visual-assistance service (for example a Qwen
/// vision backend in a later version).
sealed class VisionResult {
  const VisionResult();
}

/// No service is connected. This is the ONLY production state in M1: no
/// photo leaves the device and no AI result is ever fabricated.
class VisionUnavailable extends VisionResult {
  final String reason;
  const VisionUnavailable(this.reason);
}

/// Reserved for a future, user-consented backend.
class VisionSuggestion extends VisionResult {
  final String description;
  const VisionSuggestion(this.description);
}

abstract interface class VisionAssist {
  /// True only when a real service is configured AND the user has consented
  /// to sending photos off the device.
  bool get isConnected;

  Future<VisionResult> analyze(Uint8List photo);
}

/// Production implementation for M1: not connected, uploads nothing.
class DisconnectedVisionAssist implements VisionAssist {
  const DisconnectedVisionAssist();

  @override
  bool get isConnected => false;

  @override
  Future<VisionResult> analyze(Uint8List photo) async =>
      const VisionUnavailable('Görsel yardım servisi bağlı değil.');
}
