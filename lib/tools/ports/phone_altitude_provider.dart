import 'location_provider.dart';

/// The phone's GPS altitude for Hava Durumu → İrtifa → "Telefondan" (owner,
/// 2026-10-14). A high-accuracy request; the vertical-accuracy rule of the
/// location provider (0–50 m, else no altitude) applies.
abstract interface class PhoneAltitudeProvider {
  /// True when location permission is already granted and Location
  /// Services are on. Never shows the permission prompt.
  Future<bool> permissionGranted();

  /// One high-accuracy fix; asks for permission when needed (button only).
  Future<LocationResult> current();
}
