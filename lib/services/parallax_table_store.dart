import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/parallax_range.dart';

/// Paralaks mesafe tablosu per profile (a profile is one rifle with one
/// scope). Distances are stored in metres. Failures are silent: damaged
/// entries are dropped instead of inventing a distance.
class ParallaxTableStore {
  static String keyFor(String profileId) => 'sniper_turk.parallax.$profileId';

  /// Distances accepted from storage (metres).
  static const double maxDistanceM = 3000;

  const ParallaxTableStore();

  Future<List<ParallaxPoint>> load(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyFor(profileId));
    if (raw == null) return const [];
    Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (json is! List) return const [];
    var points = <ParallaxPoint>[];
    for (final e in json) {
      if (e is! Map) continue;
      final mark = e['mark'], m = e['m'];
      if (mark is! num || m is! num) continue;
      final md = mark.toDouble(), d = m.toDouble();
      if (!md.isFinite || !d.isFinite || d <= 0 || d > maxDistanceM) continue;
      points = ParallaxRange.upsert(
        points,
        ParallaxPoint(mark: md, distanceM: d),
      );
    }
    return points;
  }

  Future<void> save(String profileId, List<ParallaxPoint> points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      keyFor(profileId),
      jsonEncode([
        for (final p in points) {'mark': p.mark, 'm': p.distanceM},
      ]),
    );
  }
}
