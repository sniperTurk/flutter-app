import 'package:geolocator/geolocator.dart';

import '../ports/location_provider.dart';

/// Production [LocationProvider] backed by `geolocator`. Requests a coarse,
/// when-in-use fix and never stores it.
class GeolocatorLocationProvider implements LocationProvider {
  const GeolocatorLocationProvider();

  @override
  Future<LocationResult> current({
    bool precise = false,
    bool askPermission = true,
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationServiceOff();
      }
      var permission = await Geolocator.checkPermission();
      // A silent request ([askPermission] false) never prompts.
      if (permission == LocationPermission.denied && askPermission) {
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
          // A cold, coarse fix rarely carries a usable altitude; the
          // warm-up asks for a GPS-grade fix (this request only).
          accuracy: precise ? LocationAccuracy.high : LocationAccuracy.low,
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
