import 'package:shared_preferences/shared_preferences.dart';

abstract class ActiveProfileStore {
  Future<String?> getActiveProfileId();
  Future<void> setActiveProfileId(String? id);
}

class PersistentActiveProfileStore implements ActiveProfileStore {
  static const _key = 'sniper_turk.active_profile_id.v1';
  @override
  Future<String?> getActiveProfileId() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> setActiveProfileId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = id == null ? await prefs.remove(_key) : await prefs.setString(_key, id);
    if (!ok) throw StateError('Active profile write failed');
  }
}

class MemoryActiveProfileStore implements ActiveProfileStore {
  String? value;
  @override Future<String?> getActiveProfileId() async => value;
  @override Future<void> setActiveProfileId(String? id) async => value = id;
}
