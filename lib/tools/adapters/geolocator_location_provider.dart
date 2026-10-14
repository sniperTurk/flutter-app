import 'package:geolocator/geolocator.dart';

import '../ports/location_provider.dart';
import '../ports/phone_altitude_provider.dart';

/// Production [LocationProvider] backed by `geolocator`. Requests a coarse,
/// when-in-use fix and never stores it.
///
/// [accuracy] is optional: every existing caller keeps the coarse default;
/// Hava Durumu → İrtifa → "Telefondan" uses a high-accuracy instance as its
/// [PhoneAltitudeProvider] (owner, 2026-10-14).
class GeolocatorLocationProvider
    implements LocationProvider, PhoneAltitudeProvider {
  final LocationAccuracy accuracy;

  const GeolocatorLocationProvider({this.accuracy = LocationAccuracy.low});

  /// The İrtifa → "Telefondan" request (high accuracy for it only).
  static const highAccuracy = GeolocatorLocationProvider(
    accuracy: LocationAccuracy.high,
  );

  /// Only checks: never asks, so the silent warm-up on Hava Durumu can never
  /// show the iOS permission prompt.
  @override
  Future<bool> permissionGranted() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationServiceOff();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationDenied(permanent: true);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationDenied(permanent: false);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: const Duration(seconds: 15),
        ),
      );
      // Altitude only when its vertical accuracy is known and usable.
      final vAcc = position.altitudeAccuracy;
      final altitude = vAcc > 0 && vAcc <= 50 && position.altitude.isFinite
          ? position.altitude
          : null;
      return LocationFix(
        position.latitude,
        position.longitude,
        altitudeM: altitude,
      );
    } catch (_) {
      // Includes TimeoutException and plugin errors; never leak details.
      return const LocationFailure('Konum alınamadı.');
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
