import 'dart:typed_data';

import 'package:flutter/widgets.dart';

enum CameraUnavailableReason {
  /// Camera permission refused once (the system may prompt again).
  denied,

  /// Refused permanently or restricted by the system (Settings required).
  deniedPermanently,

  /// No camera on this device (for example the Simulator).
  noCamera,
  error,
}

class CameraUnavailable implements Exception {
  final CameraUnavailableReason reason;
  final String message;
  const CameraUnavailable(this.reason, this.message);
  @override
  String toString() => 'CameraUnavailable($reason): $message';
}

/// An opened camera session. Photos are returned as bytes only; the adapter
/// must not leave image files behind.
abstract interface class CameraSession {
  Widget buildPreview(BuildContext context);
  Future<Uint8List> capture();
  Future<void> dispose();
}

/// Port for the camera used by Sight Height.
abstract interface class CameraService {
  /// Opens the back camera. Throws [CameraUnavailable].
  Future<CameraSession> open();
  Future<bool> openSettings();
}
