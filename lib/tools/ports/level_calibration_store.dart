/// Device-constant tilt bias of one level pose, in degrees.
///
/// It is what a two-point flip calibration measures: the phone's own
/// accelerometer offset plus anything fixed to the phone, such as the
/// camera bump lifting one end when it lies screen-up.
typedef LevelBias = ({double xDeg, double yDeg});

/// Port for remembering the Su Terazisi flip calibration between launches.
/// Keys are pose names ('flat', 'upright').
abstract interface class LevelCalibrationStore {
  /// Stored biases by pose name. Never throws for a missing value; an
  /// unreadable store may throw and is then treated as empty.
  Future<Map<String, LevelBias>> load();

  /// Stores [bias] for [pose], or removes it when [bias] is null.
  Future<void> save(String pose, LevelBias? bias);
}

/// Keeps the calibration for the current app session only.
class InMemoryLevelCalibrationStore implements LevelCalibrationStore {
  final Map<String, LevelBias> _values = {};

  @override
  Future<Map<String, LevelBias>> load() async => Map.of(_values);

  @override
  Future<void> save(String pose, LevelBias? bias) async {
    if (bias == null) {
      _values.remove(pose);
    } else {
      _values[pose] = bias;
    }
  }
}
