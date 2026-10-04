import 'package:flutter/widgets.dart';

import 'settings_store.dart';

/// Single in-memory view of the persisted unit preference.
///
/// The persisted truth stays [SettingsStore.metricKey]; this object only
/// shares it with every widget that needs it, so new screens never keep a
/// second unit flag of their own. `metric == true` means SI (m, m/s, °C, hPa),
/// `false` means imperial (yd, mph, °F, inHg), exactly like the Ayarlar switch.
class AppSettings extends ChangeNotifier {
  bool _metric;
  AppSettings({bool metric = true}) : _metric = metric;

  bool get metric => _metric;

  /// Updates the in-memory value (the Ayarlar screen persists it first).
  void applyMetric(bool value) {
    if (value == _metric) return;
    _metric = value;
    notifyListeners();
  }

  /// Best-effort initial load. Fails closed to SI.
  Future<void> load([Future<SettingsStore> Function()? open]) async {
    try {
      final store = await (open ?? SettingsStore.open)();
      applyMetric(store.loadMetric());
    } catch (_) {
      // Keep canonical SI when settings cannot be read.
    }
  }
}

/// Provides [AppSettings] to the tree.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({super.key, required AppSettings settings, required super.child})
      : super(notifier: settings);

  /// Returns null when no scope is installed (isolated widget tests).
  static AppSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()?.notifier;

  /// Convenience: current unit system, SI when no scope exists.
  static bool metricOf(BuildContext context) => maybeOf(context)?.metric ?? true;
}
