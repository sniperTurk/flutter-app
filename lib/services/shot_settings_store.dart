import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/wez.dart';

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

  /// Yerçekimi: on/off and the local value (m/s², as typed or computed).
  final bool gravityOn;
  final String gravityText;
  final String windMaxText;

  /// The shooter cleared En yüksek rüzgâr: no wind bracket, no automatic
  /// value until "Otomatik doldur" (owner, 2026-10-10).
  final bool windMaxOff;
  final String targetSpeedText;

  /// Moving-target direction; null = not chosen yet ("Seçiniz").
  final bool? targetMovesRight;

  /// Spin drift on/off and the bullet length (mm, as typed); powder
  /// temperature sensitivity (% per 15 °C) and the temperature the profile
  /// velocity was measured at (°C), as typed.
  final bool spinDriftOn;
  final String bulletLengthText;
  final String powderCoefText;
  final String powderTempText;

  /// Mühimmat sıcaklığı (firearms, Hava Durumu): the cartridge temperature
  /// in the shown unit, as typed; empty = the air temperature.
  final String ammoTempText;

  /// Rüzgâr bölgeleri: wind at mid-range and at the target (shown unit, as
  /// typed); empty = the Hava Durumu wind everywhere.
  final String windMidText;
  final String windFarText;

  /// Sıfır ofseti: where the group centre sat at the zero range, cm (in on
  /// imperial), + = high / right.
  final String zeroUpText;
  final String zeroRightText;

  /// İsabet olasılığı: group size at the zero range (cm / in) and muzzle
  /// velocity SD (fps).
  final String groupText;
  final String sdText;

  /// WEZ: target diameter, range error (±) and BC error (± %), as typed.
  final String targetSizeText;
  final String rangeErrorText;
  final String bcErrorText;

  /// PCP: tube pressure left in the field, bar, as typed (2026-10-12).
  final String tubePressureText;

  /// WEZ Atış sayısı for "en az bir isabet" (one of [Wez.shotCounts]).
  final int wezShotCount;

  /// The box was filled by its button (Konumdan al, Pusuladan al, Konumdan
  /// hesapla, Rüzgâr düzeltmesi al), so it reopens orange "…alındı"
  /// (owner, 2026-10-12).
  final bool latitudeFromGps;
  final bool azimuthFromCompass;
  final bool gravityFromLocation;
  final bool windMaxFromWind;

  const ShotSettings({
    this.inclineDeg = 0,
    this.cantDeg = 0,
    this.coriolisOn = false,
    this.latitudeText = '',
    this.azimuthText = '',
    this.turretScaleText = '',
    this.gravityOn = false,
    this.gravityText = '',
    this.windMaxText = '',
    this.windMaxOff = false,
    this.targetSpeedText = '',
    this.targetMovesRight,
    this.spinDriftOn = false,
    this.bulletLengthText = '',
    this.powderCoefText = '',
    this.powderTempText = '',
    this.ammoTempText = '',
    this.windMidText = '',
    this.windFarText = '',
    this.zeroUpText = '',
    this.zeroRightText = '',
    this.groupText = '',
    this.sdText = '',
    this.targetSizeText = '',
    this.rangeErrorText = '',
    this.bcErrorText = '',
    this.tubePressureText = '',
    this.wezShotCount = Wez.defaultShotCount,
    this.latitudeFromGps = false,
    this.azimuthFromCompass = false,
    this.gravityFromLocation = false,
    this.windMaxFromWind = false,
  });

  Map<String, dynamic> toJson() => {
    'incline': inclineDeg,
    'cant': cantDeg,
    'coriolis': coriolisOn,
    'latitude': latitudeText,
    'azimuth': azimuthText,
    'turretScale': turretScaleText,
    'gravityOn': gravityOn,
    'gravity': gravityText,
    'windMax': windMaxText,
    'windMaxOff': windMaxOff,
    'targetSpeed': targetSpeedText,
    'targetRight': targetMovesRight,
    'spinDrift': spinDriftOn,
    'bulletLength': bulletLengthText,
    'powderCoef': powderCoefText,
    'powderTemp': powderTempText,
    'ammoTemp': ammoTempText,
    'windMid': windMidText,
    'windFar': windFarText,
    'zeroUp': zeroUpText,
    'zeroRight': zeroRightText,
    'group': groupText,
    'sd': sdText,
    'targetSize': targetSizeText,
    'rangeError': rangeErrorText,
    'bcError': bcErrorText,
    'tubePressure': tubePressureText,
    'wezShots': wezShotCount,
    'latGps': latitudeFromGps,
    'aziCompass': azimuthFromCompass,
    'gravGps': gravityFromLocation,
    'windMaxFill': windMaxFromWind,
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
      gravityOn: json['gravityOn'] == true,
      gravityText: text(json['gravity']),
      windMaxText: text(json['windMax']),
      targetSpeedText: text(json['targetSpeed']),
      windMaxOff: json['windMaxOff'] == true,
      // Older saves stored "left to right" even when nothing was chosen;
      // without a target speed that default is dropped.
      targetMovesRight:
          json['targetRight'] is bool && text(json['targetSpeed']).isNotEmpty
          ? json['targetRight'] as bool
          : null,
      spinDriftOn: json['spinDrift'] == true,
      bulletLengthText: text(json['bulletLength']),
      powderCoefText: text(json['powderCoef']),
      powderTempText: text(json['powderTemp']),
      ammoTempText: text(json['ammoTemp']),
      windMidText: text(json['windMid']),
      windFarText: text(json['windFar']),
      zeroUpText: text(json['zeroUp']),
      zeroRightText: text(json['zeroRight']),
      groupText: text(json['group']),
      sdText: text(json['sd']),
      targetSizeText: text(json['targetSize']),
      rangeErrorText: text(json['rangeError']),
      bcErrorText: text(json['bcError']),
      tubePressureText: text(json['tubePressure']),
      wezShotCount: Wez.shotCounts.contains(json['wezShots'])
          ? json['wezShots'] as int
          : Wez.defaultShotCount,
      latitudeFromGps: json['latGps'] == true,
      azimuthFromCompass: json['aziCompass'] == true,
      gravityFromLocation: json['gravGps'] == true,
      windMaxFromWind: json['windMaxFill'] == true,
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

  /// Bumped when a page other than the Atış workspace wrote settings
  /// (Kronograf → Hız farkı SD, 2026-10-12). The workspace stays alive in
  /// the shell while a tool is open, so it reloads on this instead of
  /// writing its older values back.
  static final ValueNotifier<int> externalWrites = ValueNotifier(0);
  static void notifyExternalWrite() => externalWrites.value++;

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

  /// Bumped when a tool page writes Pro values from outside the Atış
  /// workspace (Sıfır Grubu -> Sıfır ofseti). The open workspace reloads,
  /// so it neither shows nor writes back the old value.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Writes only Sıfır ofseti (as text, cm at the zero range); every other
  /// Pro value of the profile stays as stored.
  Future<void> updateZeroOffset(
    String profileId, {
    required String upText,
    required String rightText,
  }) async {
    final current = await load(profileId) ?? const ShotSettings();
    final next = ShotSettings.fromJson({
      ...current.toJson(),
      'zeroUp': upText,
      'zeroRight': rightText,
    });
    await save(profileId, next);
    changes.value++;
  }
}
