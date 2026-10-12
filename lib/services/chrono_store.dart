import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One saved Kronograf string: when, at which cartridge temperature (°C)
/// and the velocities in shot order (m/s).
class ChronoSession {
  final DateTime date;
  final double tempC;
  final List<double> mps;
  const ChronoSession({
    required this.date,
    required this.tempC,
    required this.mps,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toUtc().toIso8601String(),
    'tempC': tempC,
    'mps': mps,
  };

  /// Null for a damaged record (it is then left out, never guessed).
  static ChronoSession? fromJson(Object? json) {
    if (json is! Map) return null;
    final date = DateTime.tryParse('${json['date']}');
    final t = json['tempC'];
    final list = json['mps'];
    if (date == null || t is! num || !t.isFinite || list is! List) {
      return null;
    }
    final mps = <double>[];
    for (final v in list) {
      if (v is! num || !v.isFinite) return null;
      mps.add(v.toDouble());
    }
    if (mps.isEmpty) return null;
    return ChronoSession(date: date, tempC: t.toDouble(), mps: mps);
  }
}

/// Kronograf strings per profile in SharedPreferences (same pattern as
/// ShotSettingsStore). Used to fit the powder temperature coefficient.
class ChronoStore {
  static String keyFor(String profileId) => 'sniper_turk.chrono.$profileId';

  const ChronoStore();

  Future<List<ChronoSession>> load(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyFor(profileId));
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <ChronoSession>[];
      for (final e in decoded) {
        final s = ChronoSession.fromJson(e);
        if (s != null) out.add(s);
      }
      return out;
    } on FormatException {
      return const [];
    }
  }

  Future<void> _write(String profileId, List<ChronoSession> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      keyFor(profileId),
      jsonEncode([for (final s in list) s.toJson()]),
    );
  }

  Future<void> add(String profileId, ChronoSession session) async =>
      _write(profileId, [...await load(profileId), session]);

  Future<void> removeAt(String profileId, int index) async {
    final list = [...await load(profileId)];
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _write(profileId, list);
  }

  Future<void> deleteProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyFor(profileId));
  }
}
