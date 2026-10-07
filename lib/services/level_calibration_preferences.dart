import 'package:shared_preferences/shared_preferences.dart';

import '../tools/ports/level_calibration_store.dart';

/// Production [LevelCalibrationStore]: the flip-calibration bias per pose is
/// kept in SharedPreferences (like the unit setting) so it survives an app
/// restart. Only two angles per pose are stored: no location, photo or
/// anything identifying the user. It lives with the other persistent
/// settings stores, outside the tools layer, which persists nothing itself.
class PersistentLevelCalibrationStore implements LevelCalibrationStore {
  const PersistentLevelCalibrationStore();

  static const _prefix = 'sniper_turk.level.bias.';

  static String _key(String pose, String axis) => '$_prefix$pose.$axis';

  @override
  Future<Map<String, LevelBias>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, LevelBias>{};
    for (final pose in const ['flat', 'upright']) {
      final x = prefs.getDouble(_key(pose, 'x'));
      final y = prefs.getDouble(_key(pose, 'y'));
      // A stored bias is only used when both halves are present and sane:
      // a phone accelerometer offset stays well inside ±10°; anything else
      // is a corrupt value and is ignored.
      if (x == null || y == null) continue;
      if (!x.isFinite || !y.isFinite || x.abs() > 10 || y.abs() > 10) {
        continue;
      }
      result[pose] = (xDeg: x, yDeg: y);
    }
    return result;
  }

  @override
  Future<void> save(String pose, LevelBias? bias) async {
    final prefs = await SharedPreferences.getInstance();
    if (bias == null) {
      await prefs.remove(_key(pose, 'x'));
      await prefs.remove(_key(pose, 'y'));
      return;
    }
    final okX = await prefs.setDouble(_key(pose, 'x'), bias.xDeg);
    final okY = await prefs.setDouble(_key(pose, 'y'), bias.yDeg);
    if (!okX || !okY) {
      throw StateError('Kalibrasyon kaydedilemedi.');
    }
  }
}
