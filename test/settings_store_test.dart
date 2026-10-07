import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/services/settings_store.dart';

class FakeSettingsPreferences implements SettingsPreferences {
  final Map<String, bool> values = {};
  bool writeSucceeds = true;

  @override
  bool? getBool(String key) => values[key];

  @override
  Future<bool> setBool(String key, bool value) async {
    if (writeSucceeds) values[key] = value;
    return writeSucceeds;
  }
}

void main() {
  test('metric setting defaults to true when no value is stored', () {
    final preferences = FakeSettingsPreferences();
    expect(SettingsStore(preferences).loadMetric(), isTrue);
  });

  test('V380: a stored imperial choice is ignored (metric only)', () async {
    final preferences = FakeSettingsPreferences();
    final store = SettingsStore(preferences);
    await store.saveMetric(false);
    expect(store.loadMetric(), isTrue);
  });

  test('failed preference write is surfaced instead of accepted', () async {
    final preferences = FakeSettingsPreferences()..writeSucceeds = false;
    final store = SettingsStore(preferences);
    expect(() => store.saveMetric(false), throwsStateError);
    expect(store.loadMetric(), isTrue);
  });
}
