import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show SystemSound, SystemSoundType;

import '../domain/tilt_math.dart';
import '../ports/level_calibration_store.dart';
import '../ports/tilt_provider.dart';

/// Drives the Su Terazisi screen.
///
/// The "reference offset" is a user-set zero for an imperfect surface held
/// in memory only. It is NOT a sensor calibration.
class LevelController extends ChangeNotifier {
  final TiltProvider provider;

  /// Remembers the flip calibration between launches; null = this screen
  /// only.
  final LevelCalibrationStore? calibrationStore;
  final GravityFilter _filter;

  /// [smoothing] fixes the filter share (tests use 1 for raw readings);
  /// left null, the filter is adaptive: steady while still, quick while
  /// moving.
  LevelController({
    required this.provider,
    this.calibrationStore,
    double? smoothing,
    this.calibrationSamples = 100,
    this.calibrationSettleSamples = 15,
    this.displayDeadbandDeg = 0.05,
  }) : _filter = smoothing == null
           ? GravityFilter.adaptive()
           : GravityFilter(alpha: smoothing);

  /// Raw samples averaged for one calibration reading (~2 s at the ~50 Hz
  /// game rate) and samples skipped first to let the tap settle.
  final int calibrationSamples;
  final int calibrationSettleSamples;

  /// The shown angles only move once the filtered reading is this far from
  /// what is on screen. Sensor noise of a few hundredths of a degree then no
  /// longer flickers the 0.01° read-out or nudges the bubbles; a real change
  /// of this size or more shows at once. 0 disables it.
  final double displayDeadbandDeg;
  double? _shownX, _shownY;

  /// Forgets the shown value so the next read shows the live one exactly
  /// (used after a reference, calibration or pose change).
  void _resetShown() => _shownX = _shownY = null;

  StillAverager? _averager;
  bool _averagerFlipped = false;
  int _averagerFed = 0;
  Completer<bool>? _captureDone;

  /// True while an averaged calibration reading is being collected.
  bool get capturingCalibration => _averager != null;

  /// 0..1 progress of the running averaged reading, null when idle.
  double? get calibrationProgress => _averager?.progress;

  /// Times the running reading restarted because the phone moved.
  int get calibrationRestarts => _averager?.restarts ?? 0;

  /// True after a calibration could not be written to storage.
  bool get calibrationSaveFailed => _saveFailed;
  bool _saveFailed = false;

  StreamSubscription<TiltState>? _sub;
  bool _disposed = false;
  bool _started = false;

  TiltMode _mode = TiltMode.flat;
  bool _autoMode = true;
  bool _locked = false;
  TiltAngles? _lockedAngles;
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

  /// True while the pose (flat / upright) follows the gravity vector.
  bool get autoMode => _autoMode;

  /// True while the display is frozen ("Kilitle").
  bool get locked => _locked;
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
  ///
  /// Each axis follows the live value through a [displayDeadbandDeg] dead
  /// band, so a still phone shows a still number.
  TiltAngles? get angles {
    if (_locked && _lockedAngles != null) return _lockedAngles;
    final live = liveAngles;
    if (live == null) {
      _resetShown();
      return null;
    }
    double follow(double? shown, double now) =>
        (shown == null || (now - shown).abs() >= displayDeadbandDeg)
        ? now
        : shown;
    _shownX = follow(_shownX, live.xDeg);
    _shownY = follow(_shownY, live.yDeg);
    return TiltAngles(_shownX!, _shownY!);
  }

  /// Same as [angles] but never frozen by the lock.
  TiltAngles? get liveAngles {
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
    _restoreCalibration();
    _sub = provider.tilts().listen(
      _onState,
      onError: (Object _) {
        _onState(const TiltUnavailable(TiltUnavailableReason.error));
      },
    );
  }

  /// Restores stored biases for poses not calibrated in this session yet.
  Future<void> _restoreCalibration() async {
    final store = calibrationStore;
    if (store == null) return;
    Map<String, LevelBias> stored;
    try {
      stored = await store.load();
    } catch (_) {
      return;
    }
    if (_disposed) return;
    var changed = false;
    for (final mode in TiltMode.values) {
      final b = stored[mode.name];
      final current = _calibration[mode] ?? const FlipCalibration();
      if (b == null || current.normal != null || current.flipped != null) {
        continue;
      }
      _calibration[mode] = FlipCalibration.restored(TiltAngles(b.xDeg, b.yDeg));
      _resetShown();
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> _persist(TiltMode mode) async {
    final store = calibrationStore;
    if (store == null) return;
    final bias = _calibration[mode]?.bias;
    try {
      await store.save(
        mode.name,
        bias == null ? null : (xDeg: bias.xDeg, yDeg: bias.yDeg),
      );
      _saveFailed = false;
    } catch (_) {
      _saveFailed = true;
    }
    if (!_disposed) notifyListeners();
  }

  void _onState(TiltState s) {
    switch (s) {
      case TiltAvailable(:final gravity):
        _unavailable = null;
        if (_autoMode) _followPose(gravity);
        _gravity = _filter.add(gravity);
        _feedAverager(gravity);
      case TiltUnavailable(:final reason):
        _finishCapture(false);
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

  /// Picks flat / upright from how much of gravity lies along the screen
  /// normal, with hysteresis so the pose does not flicker near 45°.
  void _followPose(GravityVector g) {
    final next = TiltMath.poseFor(g, _mode);
    if (next != _mode) _switchMode(next);
  }

  void _switchMode(TiltMode m) {
    _resetShown();
    // A reading half taken flat must not be completed upright.
    _finishCapture(false);
    _mode = m;
    _offset = null;
    _filter.reset();
    _gravity = null;
    _lockedAngles = null;
    _locked = false;
  }

  /// Freezes / releases the displayed values.
  void toggleLock() {
    if (_locked) {
      _locked = false;
      _lockedAngles = null;
    } else {
      // Freeze exactly what is on screen (dead-banded), not the live value.
      final a = angles;
      if (a == null) return;
      _locked = true;
      _lockedAngles = a;
    }
    if (!_disposed) notifyListeners();
  }

  void setAutoMode(bool auto) {
    if (auto == _autoMode) return;
    _autoMode = auto;
    if (!_disposed) notifyListeners();
  }

  void setMode(TiltMode m) {
    _resetShown();
    _autoMode = false;
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
    _resetShown();
    final raw = rawAngles;
    if (raw == null) return;
    _offset = raw;
    if (!_disposed) notifyListeners();
  }

  void clearReference() {
    _resetShown();
    _offset = null;
    if (!_disposed) notifyListeners();
  }

  /// Captures the current raw reading as the "normal" or "flipped" half of
  /// the current mode's two-point calibration (see [FlipCalibration]).
  /// Returns false and captures nothing when there is no current reading.
  bool captureCalibration({required bool flipped}) {
    final raw = rawAngles;
    if (raw == null) return false;
    _applyCapture(raw, flipped: flipped);
    return true;
  }

  /// Starts an averaged calibration reading: ~2 s of RAW (unfiltered)
  /// samples while the phone lies still. Moving the phone restarts the
  /// collection; if it never stays still long enough, or the pose changes
  /// or the sensor stops, the future completes with false and nothing is
  /// stored. Completes with true once the reading is applied.
  Future<bool> startCalibrationCapture({required bool flipped}) {
    _finishCapture(false);
    if (!hasReading) return Future.value(false);
    _averager = StillAverager(
      settleSamples: calibrationSettleSamples,
      samples: calibrationSamples,
    );
    _averagerFlipped = flipped;
    _averagerFed = 0;
    final done = Completer<bool>();
    _captureDone = done;
    if (!_disposed) notifyListeners();
    return done.future;
  }

  void cancelCalibrationCapture() => _finishCapture(false);

  void _feedAverager(GravityVector raw) {
    final avg = _averager;
    if (avg == null) return;
    _averagerFed++;
    if (avg.add(raw)) {
      final angles = TiltMath.angles(avg.mean!, _mode);
      if (angles == null) {
        _finishCapture(false);
        return;
      }
      final flipped = _averagerFlipped;
      _averager = null;
      _applyCapture(angles, flipped: flipped);
      _completeCapture(true);
      return;
    }
    // Give up after the time of ~6 full readings without a still stretch.
    if (_averagerFed > (calibrationSettleSamples + calibrationSamples) * 6) {
      _finishCapture(false);
    }
  }

  void _finishCapture(bool ok) {
    if (_averager == null && _captureDone == null) return;
    _averager = null;
    _completeCapture(ok);
    if (!_disposed) notifyListeners();
  }

  void _completeCapture(bool ok) {
    final done = _captureDone;
    _captureDone = null;
    if (done != null && !done.isCompleted) done.complete(ok);
  }

  void _applyCapture(TiltAngles raw, {required bool flipped}) {
    final existing = _calibration[_mode] ?? const FlipCalibration();
    final next = flipped ? existing.withFlipped(raw) : existing.withNormal(raw);
    _calibration[_mode] = next;
    _resetShown();
    if (!_disposed) notifyListeners();
    // Only a complete NEW pair replaces what is stored; a half-finished
    // recalibration leaves the saved bias alone.
    if (next.normal != null && next.flipped != null) {
      unawaited(_persist(_mode));
    }
  }

  void clearCalibration(TiltMode mode) {
    _calibration[mode] = const FlipCalibration();
    _resetShown();
    if (!_disposed) notifyListeners();
    unawaited(_persist(mode));
  }

  void clearAllCalibration() {
    _resetShown();
    _calibration[TiltMode.flat] = const FlipCalibration();
    _calibration[TiltMode.upright] = const FlipCalibration();
    if (!_disposed) notifyListeners();
    unawaited(_persist(TiltMode.flat));
    unawaited(_persist(TiltMode.upright));
  }

  @override
  void dispose() {
    _disposed = true;
    _averager = null;
    _completeCapture(false);
    _sub?.cancel();
    super.dispose();
  }
}
