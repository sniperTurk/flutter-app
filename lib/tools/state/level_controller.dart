import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show SystemSound, SystemSoundType;

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

  LevelViewType _viewType = LevelViewType.all;
  AngleDisplayUnit _unit = AngleDisplayUnit.degrees;
  bool _soundEnabled = false;
  bool _wasLevel = false;
  final Map<TiltMode, FlipCalibration> _calibration = {
    TiltMode.flat: const FlipCalibration(),
    TiltMode.upright: const FlipCalibration(),
  };

  TiltMode get mode => _mode;
  bool get hasReading => _gravity != null && _unavailable == null;
  TiltUnavailableReason? get unavailableReason => _unavailable;
  bool get hasOffset => _offset != null;
  LevelViewType get viewType => _viewType;
  AngleDisplayUnit get unit => _unit;
  bool get soundEnabled => _soundEnabled;

  /// The current mode's two-point flip calibration (see [FlipCalibration]).
  FlipCalibration get calibration =>
      _calibration[_mode] ?? const FlipCalibration();

  FlipCalibration calibrationFor(TiltMode mode) =>
      _calibration[mode] ?? const FlipCalibration();

  /// Raw (offset-free) angles of the smoothed gravity, or null.
  TiltAngles? get rawAngles =>
      _gravity == null ? null : TiltMath.angles(_gravity!, _mode);

  /// Angles shown to the user: raw, minus this mode's flip-calibration bias
  /// (if any), minus the single-point reference offset (if any).
  TiltAngles? get angles {
    final raw = rawAngles;
    if (raw == null) return null;
    final bias = _calibration[_mode]?.bias;
    final calibrated = bias == null
        ? raw
        : TiltAngles(raw.xDeg - bias.xDeg, raw.yDeg - bias.yDeg);
    final o = _offset;
    return o == null
        ? calibrated
        : TiltAngles(calibrated.xDeg - o.xDeg, calibrated.yDeg - o.yDeg);
  }

  void start() {
    if (_started) return;
    _started = true;
    _sub = provider.tilts().listen(
      _onState,
      onError: (Object _) {
        _onState(const TiltUnavailable(TiltUnavailableReason.error));
      },
    );
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
    _maybePlayLevelSound();
    if (!_disposed) notifyListeners();
  }

  /// Optional feedback: plays the platform's built-in UI click
  /// (`SystemSoundType.click`) the instant the reading crosses into
  /// "Seviyede". This is the OS's short system click, not a custom tone —
  /// playing an arbitrary audio file would need a new package, which was
  /// not added here without the project owner's say.
  void _maybePlayLevelSound() {
    if (!_soundEnabled) {
      _wasLevel = false;
      return;
    }
    final a = angles;
    final isLevelNow = a != null && TiltMath.isLevel(a);
    if (isLevelNow && !_wasLevel) {
      SystemSound.play(SystemSoundType.click);
    }
    _wasLevel = isLevelNow;
  }

  void setMode(TiltMode m) {
    if (m == _mode) return;
    _mode = m;
    // A reference set in one orientation is meaningless in the other.
    // Flip calibration is kept per-mode, so it survives the switch.
    _offset = null;
    _filter.reset();
    _gravity = null;
    if (!_disposed) notifyListeners();
  }

  void setViewType(LevelViewType v) {
    if (v == _viewType) return;
    _viewType = v;
    if (!_disposed) notifyListeners();
  }

  void setUnit(AngleDisplayUnit u) {
    if (u == _unit) return;
    _unit = u;
    if (!_disposed) notifyListeners();
  }

  void setSoundEnabled(bool enabled) {
    if (enabled == _soundEnabled) return;
    _soundEnabled = enabled;
    if (!enabled) _wasLevel = false;
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

  /// Captures the current raw reading as the "normal" or "flipped" half of
  /// the current mode's two-point calibration (see [FlipCalibration]).
  /// Returns false and captures nothing when there is no current reading.
  bool captureCalibration({required bool flipped}) {
    final raw = rawAngles;
    if (raw == null) return false;
    final existing = _calibration[_mode] ?? const FlipCalibration();
    _calibration[_mode] = flipped
        ? existing.withFlipped(raw)
        : existing.withNormal(raw);
    if (!_disposed) notifyListeners();
    return true;
  }

  void clearCalibration(TiltMode mode) {
    _calibration[mode] = const FlipCalibration();
    if (!_disposed) notifyListeners();
  }

  void clearAllCalibration() {
    _calibration[TiltMode.flat] = const FlipCalibration();
    _calibration[TiltMode.upright] = const FlipCalibration();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
