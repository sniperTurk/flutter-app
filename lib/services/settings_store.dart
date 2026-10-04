import 'package:shared_preferences/shared_preferences.dart';

/// Persistence boundary for user settings. Keeping SharedPreferences behind a
/// small interface makes read/write failures explicit and testable.
abstract class SettingsPreferences {
  bool? getBool(String key);
  Future<bool> setBool(String key, bool value);
}

class SharedPreferencesSettingsPreferences implements SettingsPreferences {
  final SharedPreferences preferences;
  SharedPreferencesSettingsPreferences(this.preferences);

  @override
  bool? getBool(String key) => preferences.getBool(key);

  @override
  Future<bool> setBool(String key, bool value) => preferences.setBool(key, value);
}

class SettingsStore {
  static const metricKey = 'sniper_turk.settings.metric';
  final SettingsPreferences preferences;

  const SettingsStore(this.preferences);

  bool loadMetric() => preferences.getBool(metricKey) ?? true;

  Future<void> saveMetric(bool value) async {
    final saved = await preferences.setBool(metricKey, value);
    if (!saved) {
      throw StateError('Ayar kaydedilemedi.');
    }
  }

  static Future<SettingsStore> open() async {
    final preferences = await SharedPreferences.getInstance();
    return SettingsStore(SharedPreferencesSettingsPreferences(preferences));
  }
}
