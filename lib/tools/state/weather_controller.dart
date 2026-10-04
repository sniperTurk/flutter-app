import 'package:flutter/foundation.dart';

import '../domain/weather_policy.dart';
import '../ports/clock.dart';
import '../ports/location_provider.dart';
import '../ports/weather_provider.dart';

enum WeatherPhase {
  idle,
  locating,
  loading,
  ready,
  locationDenied,
  locationOff,
  locationFailed,
  failed,
}

/// Drives the Hava & Rüzgâr screen: location -> service -> observation.
/// The last good observation is kept in memory only (never the position), so
/// when the network drops the screen can still show it WITH its age.
class WeatherController extends ChangeNotifier {
  final LocationProvider location;
  final WeatherProvider provider;
  final Clock clock;

  WeatherController({
    required this.location,
    required this.provider,
    required this.clock,
  });

  WeatherPhase _phase = WeatherPhase.idle;
  WeatherObservation? _last;
  WeatherFailure? _failure;
  bool _deniedPermanently = false;
  bool _busy = false;
  bool _disposed = false;

  WeatherPhase get phase => _phase;
  WeatherObservation? get observation => _last;
  WeatherFailure? get failure => _failure;
  bool get deniedPermanently => _deniedPermanently;

  WeatherFreshness? get freshness =>
      _last == null ? null : WeatherPolicy.freshness(_last!, clock);

  Duration? get age => _last == null ? null : WeatherPolicy.age(_last!, clock);

  Future<bool> openSettings() => location.openSettings();

  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;
    _failure = null;
    _set(WeatherPhase.locating);
    try {
      final fix = await location.current();
      switch (fix) {
        case LocationDenied(:final permanent):
          _deniedPermanently = permanent;
          _set(WeatherPhase.locationDenied);
          return;
        case LocationServiceOff():
          _set(WeatherPhase.locationOff);
          return;
        case LocationFailure():
          _set(WeatherPhase.locationFailed);
          return;
        case LocationFix(:final latitude, :final longitude):
          _set(WeatherPhase.loading);
          try {
            _last = await provider.fetch(latitude, longitude);
            _set(WeatherPhase.ready);
          } on WeatherFailure catch (e) {
            _failure = e;
            _set(WeatherPhase.failed);
          } catch (_) {
            _failure = const WeatherFailure(
              WeatherFailureKind.invalidResponse,
              'Hava verisi alınamadı.',
            );
            _set(WeatherPhase.failed);
          }
      }
    } finally {
      _busy = false;
    }
  }

  void _set(WeatherPhase p) {
    _phase = p;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
