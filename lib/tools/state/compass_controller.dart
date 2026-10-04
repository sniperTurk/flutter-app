import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/compass_math.dart';
import '../ports/heading_provider.dart';

/// Drives the Pusula screen. Never invents a heading: when the provider has
/// nothing, the state is [HeadingUnavailable].
class CompassController extends ChangeNotifier {
  final HeadingProvider provider;
  final Duration noDataTimeout;
  final CircularSmoother _smoother;

  CompassController({
    required this.provider,
    this.noDataTimeout = const Duration(seconds: 4),
    double smoothing = 0.25,
  }) : _smoother = CircularSmoother(alpha: smoothing);

  StreamSubscription<HeadingState>? _sub;
  Timer? _timer;
  bool _disposed = false;
  bool _started = false;
  bool _hadReading = false;

  HeadingState _state = const HeadingUnavailable(HeadingUnavailableReason.noData);
  double? _smoothedDeg;

  HeadingState get state => _state;

  /// Smoothed heading in degrees, or null when unavailable.
  double? get degrees => _state is HeadingAvailable ? _smoothedDeg : null;

  double? get accuracyDeg => switch (_state) {
        HeadingAvailable(:final reading) => reading.accuracyDeg,
        _ => null,
      };

  void start() {
    if (_started) return;
    _started = true;
    _armTimer();
    _sub = provider.headings().listen(_onState, onError: (Object _) {
      _onState(const HeadingUnavailable(HeadingUnavailableReason.error));
    });
  }

  void _onState(HeadingState s) {
    _timer?.cancel();
    switch (s) {
      case HeadingAvailable(:final reading):
        _smoothedDeg = _smoother.add(reading.degrees);
        _hadReading = true;
      case HeadingUnavailable():
        _smoother.reset();
        _smoothedDeg = null;
    }
    _state = s;
    if (!_disposed) notifyListeners();
  }

  /// The timeout only detects a sensor that never delivers. iOS sends
  /// heading events only when the heading changes (filter 0.1°), so a phone
  /// lying still legitimately goes silent; the last bearing must stay.
  void _armTimer() {
    _timer?.cancel();
    if (_hadReading) return;
    _timer = Timer(noDataTimeout, () {
      _smoother.reset();
      _smoothedDeg = null;
      _state = const HeadingUnavailable(HeadingUnavailableReason.noData);
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
