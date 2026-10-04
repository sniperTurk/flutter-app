import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/tilt_math.dart';
import '../ports/tilt_provider.dart';

/// Drives the Su Terazisi screen.
///
/// The "reference offset" is a user-set zero for an imperfect surface held
/// in memory only. It is NOT a sensor calibration.
class LevelController extends ChangeNotifier {
  final TiltProvider provider;
  final GravityFilter _filter;

  LevelController({required this.provider, double smoothing = 0.15})
      : _filter = GravityFilter(alpha: smoothing);

  StreamSubscription<TiltState>? _sub;
  bool _disposed = false;
  bool _started = false;

  TiltMode _mode = TiltMode.flat;
  GravityVector? _gravity;
  TiltUnavailableReason? _unavailable;
  TiltAngles? _offset;

  TiltMode get mode => _mode;
  bool get hasReading => _gravity != null && _unavailable == null;
  TiltUnavailableReason? get unavailableReason => _unavailable;
  bool get hasOffset => _offset != null;

  /// Raw (offset-free) angles of the smoothed gravity, or null.
  TiltAngles? get rawAngles =>
      _gravity == null ? null : TiltMath.angles(_gravity!, _mode);

  /// Angles shown to the user: raw minus the reference offset.
  TiltAngles? get angles {
    final raw = rawAngles;
    if (raw == null) return null;
    final o = _offset;
    return o == null ? raw : TiltAngles(raw.xDeg - o.xDeg, raw.yDeg - o.yDeg);
  }

  void start() {
    if (_started) return;
    _started = true;
    _sub = provider.tilts().listen(_onState, onError: (Object _) {
      _onState(const TiltUnavailable(TiltUnavailableReason.error));
    });
  }

  void _onState(TiltState s) {
    switch (s) {
      case TiltAvailable(:final gravity):
        _unavailable = null;
        _gravity = _filter.add(gravity);
      case TiltUnavailable(:final reason):
        _unavailable = reason;
        _gravity = null;
        _filter.reset();
    }
    if (!_disposed) notifyListeners();
  }

  void setMode(TiltMode m) {
    if (m == _mode) return;
    _mode = m;
    // A reference set in one orientation is meaningless in the other.
    _offset = null;
    _filter.reset();
    _gravity = null;
    if (!_disposed) notifyListeners();
  }

  /// Takes the current raw angles as the reference zero.
  void setReferenceHere() {
    final raw = rawAngles;
    if (raw == null) return;
    _offset = raw;
    if (!_disposed) notifyListeners();
  }

  void clearReference() {
    _offset = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
