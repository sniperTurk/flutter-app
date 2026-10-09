import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Pro Ayarlar values of one profile that should survive closing the app
/// (owner, 2026-10-09): Tüfek eğimi, Dürbün eğimi and Coriolis.
class ShotSettings {
  final double inclineDeg;
  final double cantDeg;
  final bool coriolisOn;

  /// As typed (kept as text so an unfinished entry is not lost or altered).
  final String latitudeText;
  final String azimuthText;

  /// Kule ölçek katsayısı, Rüzgâr aralığı (en yüksek), hareketli hedef hızı
  /// (as typed) and its direction.
  final String turretScaleText;
  final String windMaxText;
  final String targetSpeedText;
  final bool targetMovesRight;

  const ShotSettings({
    this.inclineDeg = 0,
    this.cantDeg = 0,
    this.coriolisOn = false,
    this.latitudeText = '',
    this.azimuthText = '',
    this.turretScaleText = '',
    this.windMaxText = '',
    this.targetSpeedText = '',
    this.targetMovesRight = true,
  });

  Map<String, dynamic> toJson() => {
    'incline': inclineDeg,
    'cant': cantDeg,
    'coriolis': coriolisOn,
    'latitude': latitudeText,
    'azimuth': azimuthText,
    'turretScale': turretScaleText,
    'windMax': windMaxText,
    'targetSpeed': targetSpeedText,
    'targetRight': targetMovesRight,
  };

  /// Unknown or damaged values fall back to the neutral default (level,
  /// no Coriolis) instead of inventing an angle.
  static ShotSettings fromJson(Object? json) {
    if (json is! Map) return const ShotSettings();
    double angle(Object? v) {
      final d = v is num ? v.toDouble() : 0.0;
      return d.isFinite && d.abs() <= 180 ? d : 0;
    }

    String text(Object? v) => v is String && v.length <= 20 ? v : '';
    return ShotSettings(
      inclineDeg: angle(json['incline']),
      cantDeg: angle(json['cant']),
      coriolisOn: json['coriolis'] == true,
      latitudeText: text(json['latitude']),
      azimuthText: text(json['azimuth']),
      turretScaleText: text(json['turretScale']),
      windMaxText: text(json['windMax']),
      targetSpeedText: text(json['targetSpeed']),
      targetMovesRight: json['targetRight'] != false,
    );
  }
}

/// Stores [ShotSettings] per profile id in SharedPreferences. Failures are
/// silent by design: these are conveniences, the screen keeps working with
/// its in-memory values.
class ShotSettingsStore {
  static String keyFor(String profileId) =>
      'sniper_turk.shot_settings.$profileId';

  const ShotSettingsStore();

  Future<ShotSettings?> load(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyFor(profileId));
    if (raw == null) return null;
    try {
      return ShotSettings.fromJson(jsonDecode(raw));
    } on FormatException {
      return const ShotSettings();
    }
  }

  Future<void> save(String profileId, ShotSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyFor(profileId), jsonEncode(settings.toJson()));
  }
}
