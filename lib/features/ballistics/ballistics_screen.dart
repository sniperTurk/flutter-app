import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../core/atmosphere.dart';
import '../../core/ballistic_engine.dart';
import '../../core/ballistic_input.dart';
import '../../core/beaufort.dart';
import '../../core/input_error_text.dart';
import '../../core/dope_ranges.dart';
import '../../core/drag_safety.dart';
import '../../core/drag_table.dart';
import '../../core/estimated_bc.dart';
import '../../core/gravity.dart';
import '../../core/pcp_pressure.dart';
import '../../core/powder_temperature.dart';
import '../../core/production_limits.dart';
import '../../core/reticle_holds.dart';
import '../../core/scope_dial.dart';
import '../../core/stability.dart';
import '../../core/unit_system.dart';
import '../../core/wez.dart';
import '../../core/wind_clock.dart';
import '../../core/wind_zone_shares.dart';
import '../../data/profile_catalog_integrity.dart';
import '../../data/reticle_catalog.dart';
import '../../models/domain.dart';
import '../../services/settings_store.dart';
import '../../services/shot_settings_store.dart';
import '../../services/watch/watch_bridge.dart';
import '../../services/watch/watch_solution.dart';
import '../../tools/domain/field_calc.dart';
import '../../tools/domain/shot_angle_math.dart';
import '../../tools/ports/clock.dart';
import '../../tools/ports/elevation_provider.dart';
import '../../tools/ports/heading_provider.dart';
import '../../tools/ports/location_provider.dart';
import '../../tools/ports/pressure_sensor.dart';
import '../../tools/ports/weather_provider.dart';
import '../../tools/tools_services.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import '../tools/cold_bore_hint.dart';
import '../tools/map_distance_screen.dart';
import '../tools/parallax_screen.dart';
import 'dope_card.dart';
import '../profiles/profile_field_info.dart';
import 'environment_field_info.dart';
import 'fetch_date_text.dart';
import 'flight_warnings.dart';
import 'incline_measure_screen.dart';
import 'pro_info_sheet.dart';
import 'pro_section_info.dart';
import 'scope_cant_screen.dart';
import 'scope_dial_view.dart';
import 'wind_clock_picker.dart';
import 'wind_guide.dart';

part 'ballistics_shared_rows.dart';
part 'hava_durumu_view.dart';
part 'hedef_view.dart';
part 'pro_ayarlar_view.dart';

/// Which part of the ballistic workspace is shown.
///
/// The Menzil shell shows [shot], [table] and [environment] as separate tabs
/// over ONE state object, so inputs and the last validated solve are shared
/// between them. [all] is the stand-alone route (every section on one page).
/// [pro]: Pro Ayarlar (shot incline, scope cant, Coriolis) — owner, 2026-10-08.
enum BallisticsView { all, shot, table, environment, pro }

/// Seams for widget tests (never set in the app).
abstract final class BallisticsScreenTestHooks {
  /// Replaces the system share sheet for the DOPE card PDF.
  static Future<void> Function(List<int> bytes, String filename)? sharePdf;
}

/// Stable keys for the ballistic inputs (used by widget tests).
abstract final class BallisticsFieldKeys {
  static const velocity = ValueKey('ballistics-velocity');
  static const grain = ValueKey('ballistics-grain');
  static const zero = ValueKey('ballistics-zero');
  static const sight = ValueKey('ballistics-sight');
  static const wind = ValueKey('ballistics-wind');
  static const windDirection = ValueKey('ballistics-wind-direction');
  static const temperature = ValueKey('ballistics-temperature');
  static const pressure = ValueKey('ballistics-pressure');
  static const humidity = ValueKey('ballistics-humidity');

  /// İrtifa card → Telefondan irtifa (the former single İrtifa box; owner,
  /// 2026-10-14).
  static const altitude = ValueKey('ballistics-altitude');

  /// İrtifa card → Haritadan irtifa.
  static const mapAltitude = ValueKey('ballistics-map-altitude');
  static const ranges = ValueKey('ballistics-ranges');
}

class BallisticsScreen extends StatefulWidget {
  final RifleProfile? profile;
  final BallisticsView view;

  /// Fill Hava Durumu from the location's live weather the first time the
  /// environment view opens (owner, 2026-10-08). Off by default so tests and
  /// embeddings never reach the network unless they ask for it.
  final bool autoWeather;

  /// Shell navigation: Hava Durumu → Pro Ayarlar → Atış.
  final VoidCallback? onContinueToPro;
  final VoidCallback? onContinueToShot;

  /// Shell only, no profile yet: Hava Durumu stays usable and offers this
  /// (owner, 2026-10-10).
  final VoidCallback? onCreateProfile;

  /// Shell only: keeps the Hava Durumu values (atmosphere, wind, wind hour)
  /// when the workspace is built again — the first profile is created, a
  /// tool (Hız Doğrulama, Sight Height) or Profil rewrites the profile, or
  /// another profile is chosen. Null: nothing is carried.
  final EnvironmentCarry? environmentCarry;

  const BallisticsScreen({
    super.key,
    this.profile,
    this.view = BallisticsView.all,
    this.autoWeather = false,
    this.onContinueToPro,
    this.onContinueToShot,
    this.onCreateProfile,
    this.environmentCarry,
  });

  @override
  State<BallisticsScreen> createState() => _BallisticsScreenState();
}

/// Inputs of the last successful, fully validated solve. The shot view
/// re-evaluates the same validated inputs at the selected range; it never
/// re-parses the (possibly edited, not yet submitted) text fields.
class _ShotBasis {
  final double velocityMps, grain, zeroRangeM, sightHeightMm;

  /// Velocity on the zeroing day when today's differs (barut sıcaklığı or
  /// PCP tube pressure).
  final double? zeroVelocityMps;
  final EnvironmentData environment;

  /// Both set (drag solve) or both null (vacuum baseline).
  final double? ballisticCoefficient;
  final BallisticModel? ballisticModel;

  /// Velocity-dependent BC steps (çoklu BC); empty = single BC.
  final List<BcBand> bcBands;

  /// Local gravity of the shooting place (m/s²).
  final double gravityMps2;

  /// Özel sürüklenme eğrisi of the ammunition; null = standard table.
  final DragTable? dragTable;
  const _ShotBasis({
    required this.velocityMps,
    required this.grain,
    required this.zeroRangeM,
    required this.sightHeightMm,
    required this.environment,
    this.ballisticCoefficient,
    this.ballisticModel,
    this.bcBands = const [],
    this.dragTable,
    this.zeroVelocityMps,
    this.gravityMps2 = Gravity.standard,
  });

  bool get drag => ballisticCoefficient != null && ballisticModel != null;

  /// [inclineDeg]/[cantDeg] are per-shot values (Atış); the DOPE table is
  /// always solved level.
  BallisticInput input(
    List<double> rangesM, {
    double inclineDeg = 0,
    double cantDeg = 0,
    double? latitudeDeg,
    double? azimuthDeg,
    double? windMps,
    double? windDirectionDeg,
    WindZones? windZones,
    double? shotVelocityMps,
    double? gravity,
  }) => BallisticInput(
    // A shot-to-shot velocity change (SD) keeps the zero of the nominal
    // velocity.
    muzzleVelocityMps: shotVelocityMps ?? velocityMps,
    grain: grain,
    zeroRangeM: zeroRangeM,
    sightHeightMm: sightHeightMm,
    rangesM: rangesM,
    environment: windMps == null && windDirectionDeg == null
        ? environment
        : EnvironmentData(
            temperatureC: environment.temperatureC,
            pressureHpa: environment.pressureHpa,
            humidityPercent: environment.humidityPercent,
            altitudeM: environment.altitudeM,
            windMps: windMps ?? environment.windMps,
            windDirectionDeg: windDirectionDeg ?? environment.windDirectionDeg,
          ),
    windZones: windZones,
    ballisticCoefficient: ballisticCoefficient,
    ballisticModel: ballisticModel,
    bcBands: bcBands,
    dragTable: dragTable,
    inclineDeg: inclineDeg,
    cantDeg: cantDeg,
    latitudeDeg: latitudeDeg,
    azimuthDeg: azimuthDeg,
    gravityMps2: gravity ?? gravityMps2,
    zeroMuzzleVelocityMps: shotVelocityMps == null
        ? zeroVelocityMps
        : (zeroVelocityMps ?? velocityMps),
  );
}

class _BallisticsScreenState extends State<BallisticsScreen>
    with WidgetsBindingObserver {
  late final TextEditingController velocity;
  late final TextEditingController grain;
  late final TextEditingController zero;
  late final TextEditingController sight;
  late final TextEditingController wind;
  late final TextEditingController windDirection;

  /// Rüzgâr yönü box (owner, 2026-10-11): the clock hour the wind comes
  /// from, typed by the user. It starts empty so no direction is assumed;
  /// a valid 1…12 is mirrored into [windDirection] in solver degrees.
  late final TextEditingController windHour;

  int? get _windHourValue {
    final h = int.tryParse(windHour.text.trim());
    return h != null && h >= 1 && h <= 12 ? h : null;
  }

  /// When the Rüzgâr yönü was set (dial tap or typed hour; owner,
  /// 2026-10-14), saved with the weather state.
  int? _windDirAtMs;

  void _windDirectionSet() {
    _windDirAtMs = _windHourValue == null
        ? null
        : _clock.now().millisecondsSinceEpoch;
    _weatherChanged();
  }

  void _syncWindHour() {
    final h = _windHourValue;
    if (h != null) {
      windDirection.text = WindClock.toDegrees(h).toStringAsFixed(0);
    }
  }

  late final TextEditingController temperature;
  late final TextEditingController pressure;
  late final TextEditingController humidity;

  /// Telefondan irtifa (owner, 2026-10-14; the former İrtifa box, so an
  /// older saved İrtifa comes back here).
  late final TextEditingController altitude;

  /// Haritadan irtifa (Google Maps Elevation API).
  late final TextEditingController mapAltitude;
  late final TextEditingController ranges;

  List<TrajectoryPoint> points = [];
  double? airDensityKgM3;
  double? densityRatio;
  double? speedOfSoundMps;
  double? muzzleMach;

  /// The last solve took the station pressure from İrtifa (Basınç empty,
  /// denetim F1); Hedef says so.
  bool _pressureEstimated = false;
  ScopeOptic? scope;
  Ammunition? ammunition;

  /// True when [ammunition]'s BC is [EstimatedBc]'s, not the user's.
  bool _bcEstimated = false;
  ProfileCatalogResolution? profileResolution;
  bool metric = true;

  _ShotBasis? _basis;
  double _shotRangeM = 100;

  /// Opens the right (windage) turret after "Çözümü kulelere kur".
  int _windageRevealToken = 0;

  /// Hedef always opens at 100 m (100 yd on a yard profile) (owner,
  /// 2026-10-09).
  double get _defaultShotRangeM =>
      _profileYards ? UnitSystem.yardsToMeters(100) : 100;

  /// Atış: shot incline (+ up, − down) and scope cant (+ clockwise), degrees.
  double _inclineDeg = 0;
  double _cantDeg = 0;

  void _setAngles({double? incline, double? cant}) {
    setState(() {
      if (incline != null) _inclineDeg = incline;
      if (cant != null) _cantDeg = cant;
      // Every cached shot and hold curve belongs to the old angles.
      _shotCache.clear();
      _holdSamples = null;
    });
    _saveShotSettings();
  }

  // ---- Pro Ayarlar persistence (owner, 2026-10-09) -----------------------

  static const _shotStore = ShotSettingsStore();

  /// False until the saved values were read: nothing is written before, so
  /// an early default can never overwrite what the user had.
  bool _shotSettingsReady = false;

  Future<void> _loadShotSettings() async {
    final id = widget.profile?.id;
    if (id == null) return;
    ShotSettings? saved;
    try {
      saved = await _shotStore.load(id);
    } catch (_) {
      saved = null; // No storage (e.g. tests): keep the defaults.
    }
    if (!mounted) return;
    final s = saved;
    if (s != null) {
      setState(() {
        _inclineDeg = s.inclineDeg;
        _cantDeg = s.cantDeg;
        // No on/off switches (owner, 2026-10-11): the fields are always
        // shown; an effect applies once its data is entered.
        gravityCtl.text = s.gravityText;
        latitudeCtl.text = s.latitudeText;
        azimuthCtl.text = s.azimuthText;
        // A box a button filled reopens orange "…alındı" (owner, 2026-10-12).
        _gravFilled = s.gravityFromLocation && s.gravityText.isNotEmpty;
        _latFilled = s.latitudeFromGps && s.latitudeText.isNotEmpty;
        _aziFilled = s.azimuthFromCompass && s.azimuthText.isNotEmpty;
        turretScaleCtl.text = s.turretScaleText;
        // No automatic value any more (owner, 2026-10-12): the box starts
        // empty and is filled only by "Rüzgâr düzeltmesi al" or by hand.
        windMaxCtl.text = s.windMaxText;
        _windMaxFilled = s.windMaxFromWind && s.windMaxText.isNotEmpty;
        _windMaxAtMs = _windMaxFilled ? s.windMaxAtMs : null;
        targetSpeedCtl.text = s.targetSpeedText;
        _targetMovesRight = s.targetMovesRight;
        bulletLengthCtl.text = s.bulletLengthText;
        powderCoefCtl.text = s.powderCoefText;
        tubePressureCtl.text = s.tubePressureText;
        powderTempCtl.text = s.powderTempText;
        final ammoC = double.tryParse(s.ammoTempText.replaceAll(',', '.'));
        ammoTempCtl.text = ammoC == null || !ammoC.isFinite
            ? ''
            : metric
            ? _twoDecimals(ammoC)
            : UnitSystem.celsiusToFahrenheit(ammoC).toStringAsFixed(1);
        windMidCtl.text = s.windMidText;
        windFarCtl.text = s.windFarText;
        zeroUpCtl.text = s.zeroUpText;
        zeroRightCtl.text = s.zeroRightText;
        groupCtl.text = s.groupText;
        sdCtl.text = s.sdText;
        targetSizeCtl.text = s.targetSizeText;
        rangeErrorCtl.text = s.rangeErrorText;
        bcErrorCtl.text = s.bcErrorText;
        if (s.weatherSaved) _applyWeatherSi(s);
        _wezShotCount = s.wezShotCount;
        _wezShotChosen = s.wezShotCount != Wez.defaultShotCount;
        _shotCache.clear();
        _holdSamples = null;
      });
      _scheduleFreshnessCheck();
      // ATM-1 (audit 2026-10-14b): the first automatic solve ran before the
      // saved values arrived; solve again with the restored boxes, the same
      // way an edit does, so Hedef, WEZ and the F1 note use them.
      _quietSolve();
    }
    _shotSettingsReady = true;
  }

  void _reloadShotSettings() => unawaited(_loadShotSettings());

  /// Off while the boxes are rewritten in another unit or restored, so a
  /// half-converted form is never stored.
  bool _weatherSaveOff = false;

  bool _weatherSavePending = false;

  void _weatherChanged() {
    if (_weatherSaveOff || _weatherSavePending) return;
    // After the current step, so "…alındı" / Sıfırla flags set next to the
    // text are stored with it.
    _weatherSavePending = true;
    scheduleMicrotask(() {
      _weatherSavePending = false;
      if (mounted) _saveShotSettings();
    });
  }

  /// Hava Durumu boxes in SI for [ShotSettings.weatherSi]; empty or
  /// unreadable boxes are left out.
  Map<String, double> _weatherSi() {
    double? n(TextEditingController c) {
      final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
      return v != null && v.isFinite ? v : null;
    }

    final m = metric;
    final t = n(temperature), p = n(pressure), h = n(humidity);
    final a = n(altitude), w = n(wind), d = n(windDirection);
    final ma = n(mapAltitude);
    return {
      if (t != null) 'temperature': m ? t : UnitSystem.fahrenheitToCelsius(t),
      if (p != null) 'pressure': m ? p : UnitSystem.inHgToHpa(p),
      if (h != null) 'humidity': h,
      if (a != null) 'altitude': m ? a : UnitSystem.feetToMeters(a),
      if (ma != null) 'mapAltitude': m ? ma : UnitSystem.feetToMeters(ma),
      if (w != null) 'wind': m ? w : UnitSystem.mphToMps(w),
      if (d != null && _windHourValue != null) 'windDirection': d,
    };
  }

  /// Puts a profile's saved Hava Durumu back, in the shown unit; a box not
  /// in the map comes back empty (owner, 2026-10-12).
  void _applyWeatherSi(ShotSettings s) {
    _weatherSaveOff = true;
    try {
      _putWeatherSi(s);
    } finally {
      _weatherSaveOff = false;
    }
  }

  void _putWeatherSi(ShotSettings s) {
    final si = s.weatherSi;
    final m = metric;
    String show(String key, double Function(double) toImperial) {
      final v = si[key];
      if (v == null) return '';
      return _twoDecimals(m ? v : toImperial(v));
    }

    temperature.text = show('temperature', UnitSystem.celsiusToFahrenheit);
    pressure.text = show('pressure', UnitSystem.hpaToInHg);
    humidity.text = show('humidity', (v) => v);
    // An older save's single İrtifa is the 'altitude' key: it comes back
    // as Telefondan irtifa (owner, 2026-10-14).
    altitude.text = show('altitude', UnitSystem.metersToFeet);
    mapAltitude.text = show('mapAltitude', UnitSystem.metersToFeet);
    wind.text = show('wind', UnitSystem.mpsToMph);
    for (final c in [
      temperature,
      pressure,
      humidity,
      altitude,
      mapAltitude,
      wind,
    ]) {
      if (c.text.isNotEmpty) _userEdited.add(c);
    }
    final wd = si['windDirection'];
    if (wd != null) {
      windDirection.text = _twoDecimals(wd);
      windHour.text = '${WindClock.fromDegrees(wd)}';
    }
    _weatherFilled = s.weatherFromLocation;
    _pressureFilled = s.pressureFromPhone && pressure.text.isNotEmpty;
    // No time (older saves) = old: never orange (owner, 2026-10-14).
    _weatherFetchedAtMs = s.weatherFetchedAtMs;
    _pressureFetchedAtMs = s.pressureFetchedAtMs;
    // The altitude buttons stay orange while their box holds the fetch.
    _altPhoneAtMs = altitude.text.isEmpty ? null : s.altitudePhoneAtMs;
    _altMapAtMs = mapAltitude.text.isEmpty ? null : s.altitudeMapAtMs;
    _windDirAtMs = wd == null ? null : s.windDirectionAtMs;
  }

  void _saveShotSettings() {
    final id = widget.profile?.id;
    if (id == null || !_shotSettingsReady) return;
    final settings = ShotSettings(
      inclineDeg: _inclineDeg,
      cantDeg: _cantDeg,
      coriolisOn: _coriolisOn,
      gravityOn: _gravityOn,
      gravityText: gravityCtl.text.trim(),
      latitudeText: latitudeCtl.text.trim(),
      // Which boxes a button filled, so they reopen orange (2026-10-12).
      latitudeFromGps: _latFilled,
      azimuthFromCompass: _aziFilled,
      gravityFromLocation: _gravFilled,
      windMaxFromWind: _windMaxFilled,
      weatherSaved: true,
      weatherSi: _weatherSi(),
      weatherFromLocation: _weatherFilled,
      pressureFromPhone: _pressureFilled,
      weatherFetchedAtMs: _weatherFilled ? _weatherFetchedAtMs : null,
      pressureFetchedAtMs: _pressureFilled ? _pressureFetchedAtMs : null,
      altitudePhoneAtMs: altitude.text.trim().isEmpty ? null : _altPhoneAtMs,
      altitudeMapAtMs: mapAltitude.text.trim().isEmpty ? null : _altMapAtMs,
      windDirectionAtMs: _windHourValue == null ? null : _windDirAtMs,
      windMaxAtMs: _windMaxFilled ? _windMaxAtMs : null,
      azimuthText: azimuthCtl.text.trim(),
      turretScaleText: turretScaleCtl.text.trim(),
      windMaxText: windMaxCtl.text.trim(),
      windMaxOff: windMaxCtl.text.trim().isEmpty,
      targetSpeedText: targetSpeedCtl.text.trim(),
      targetMovesRight: _targetMovesRight,
      spinDriftOn: _spinDriftOn,
      bulletLengthText: bulletLengthCtl.text.trim(),
      powderCoefText: powderCoefCtl.text.trim(),
      tubePressureText: tubePressureCtl.text.trim(),
      powderTempText: powderTempCtl.text.trim(),
      ammoTempText: _ammoTempC == null ? '' : _twoDecimals(_ammoTempC!),
      windMidText: windMidCtl.text.trim(),
      windFarText: windFarCtl.text.trim(),
      zeroUpText: zeroUpCtl.text.trim(),
      zeroRightText: zeroRightCtl.text.trim(),
      groupText: groupCtl.text.trim(),
      sdText: sdCtl.text.trim(),
      targetSizeText: targetSizeCtl.text.trim(),
      rangeErrorText: rangeErrorCtl.text.trim(),
      bcErrorText: bcErrorCtl.text.trim(),
      wezShotCount: _wezShotCount,
    );
    unawaited(
      _shotStore.save(id, settings).catchError((Object _) {
        // A convenience only: the screen keeps its in-memory values.
      }),
    );
  }

  /// Pro Ayarlar → Coriolis: always on (no switches since 2026-10-11; the
  /// value is still saved as coriolisOn); it applies once latitude (+N) and
  /// shot azimuth (° from north) are typed or taken from GPS / compass.
  final bool _coriolisOn = true;
  final TextEditingController latitudeCtl = TextEditingController();
  final TextEditingController azimuthCtl = TextEditingController();

  /// Al + Sıfırla state of Konumdan al / Pusuladan al / Konumdan hesapla
  /// (owner, 2026-10-12: the same layout as Hava Durumu).
  bool _latFilled = false, _latWasReset = false;
  bool _aziFilled = false, _aziWasReset = false;
  bool _gravFilled = false, _gravWasReset = false;

  void _resetLatitude() {
    setState(() {
      latitudeCtl.text = '';
      _latFilled = false;
      _latWasReset = true;
      _coriolisStatus = null;
    });
    _coriolisChanged();
  }

  void _resetAzimuth() {
    setState(() {
      azimuthCtl.text = '';
      _aziFilled = false;
      _aziWasReset = true;
      _coriolisStatus = null;
    });
    _coriolisChanged();
  }

  void _resetGravity() {
    setState(() {
      gravityCtl.text = '';
      _gravFilled = false;
      _gravWasReset = true;
      _gravityStatus = null;
    });
    _gravityChanged();
  }

  /// Pro Ayarlar extras (owner, 2026-10-09).
  final TextEditingController turretScaleCtl = TextEditingController();
  final TextEditingController windMaxCtl = TextEditingController();

  /// "Rüzgâr düzeltmesi al" state (owner, 2026-10-12), as on Hava Durumu.
  bool _windMaxFilled = false;
  bool _windMaxWasReset = false;

  /// When En çok rüzgâr was written from Rüzgâr hızı (UTC epoch ms).
  int? _windMaxAtMs;

  void _fillWindMax() {
    if (!_putWindMaxFromWind()) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Önce Hava Durumu\'nda rüzgâr hızını girin.'),
        ),
      );
    }
  }

  /// En çok rüzgâr = Rüzgâr hızı × 1,5 (as "Düzeltme al" always did).
  /// False when there is no usable Rüzgâr hızı.
  bool _putWindMaxFromWind() {
    final w = double.tryParse(wind.text.trim().replaceAll(',', '.'));
    if (w == null || !w.isFinite || w <= 0) return false;
    setState(() {
      windMaxCtl.text = (w * windGustFactor).toStringAsFixed(1);
      _windMaxFilled = true;
      _windMaxWasReset = false;
      _windMaxAtMs = _clock.now().millisecondsSinceEpoch;
      _shotCache.clear();
      _holdSamples = null;
    });
    _coriolisChanged();
    return true;
  }

  /// A weather fill brought a new Rüzgâr hızı (owner, 2026-10-14): En çok
  /// rüzgâr follows it when the box holds a "Düzeltme al" value; a typed
  /// value (or an emptied box) is never overwritten.
  void _windMaxFollowsWind() {
    if (_windMaxFilled) _putWindMaxFromWind();
  }

  void _resetWindMax() {
    setState(() {
      windMaxCtl.text = '';
      _windMaxAtMs = null;
      // Yol ortası and Hedefte are cleared too (owner, 2026-10-12).
      windMidCtl.text = '';
      windFarCtl.text = '';
      _windMaxFilled = false;
      _windMaxWasReset = true;
      _shotCache.clear();
      _holdSamples = null;
    });
    _coriolisChanged();
  }

  /// Typical gust factor over land: the bracket top is 1.5 × the wind.
  static const windGustFactor = 1.5;

  /// Rüzgâr gözlemi is hidden (owner, 2026-10-13: "gizle, silme"): its
  /// class middle overwrote a fetched or measured Rüzgâr hızı. The
  /// "Rüzgârı gözle tahmin et" popup (link below the Rüzgâr card) replaces
  /// it and writes nothing. Build with --dart-define=WIND_OBSERVATION=true to show
  /// the old select again.
  static const bool _showWindObservation = bool.fromEnvironment(
    'WIND_OBSERVATION',
  );

  /// Rüzgâr gözlemi (Ö2): the chosen Beaufort force, null = "Seçiniz".
  /// Not saved; the wind values it writes are. A typed wind clears it.
  int? _windObservation;
  int _windObservationToken = 0;

  void _pickWindObservation(int? force) {
    final b = force == null ? null : Beaufort.classes[force];
    setState(() {
      _windObservation = force;
      if (b == null) return;
      String v(double mps) =>
          (metric ? mps : UnitSystem.mpsToMph(mps)).toStringAsFixed(1);
      // The weather button stays orange (owner, 2026-10-13).
      // Only Rüzgâr hızı (owner, 2026-10-12): Rüzgâr düzeltmesi is filled
      // by its own button.
      wind.text = v(b.midMps);
      _userEdited.add(wind);
      _shotCache.clear();
      _holdSamples = null;
    });
    _saveShotSettings();
  }

  final TextEditingController targetSpeedCtl = TextEditingController();
  bool? _targetMovesRight;
  final bool _spinDriftOn = true;
  final TextEditingController bulletLengthCtl = TextEditingController();
  final TextEditingController powderCoefCtl = TextEditingController();

  /// PCP: tube pressure left, bar (Pro > Tüfek düzeltmeleri). The box is
  /// shown and used only with PRO_TUBE_PRESSURE; otherwise the profile's
  /// Tüp basıncı is used (see [_pcpVelocity]).
  final TextEditingController tubePressureCtl = TextEditingController();
  final TextEditingController powderTempCtl = TextEditingController();

  /// Mühimmat sıcaklığı (Hava Durumu, firearms; Ö1 2026-10-12), in the shown
  /// unit. Empty = the air temperature, as before the field existed.
  final TextEditingController ammoTempCtl = TextEditingController();

  /// [ammoTempCtl] in °C; null when empty or unreadable.
  double? get _ammoTempC {
    final v = double.tryParse(ammoTempCtl.text.trim().replaceAll(',', '.'));
    if (v == null || !v.isFinite) return null;
    return metric ? v : UnitSystem.fahrenheitToCelsius(v);
  }

  /// Settings written by another page (Kronograf → SD) while this
  /// workspace stayed alive: read them again instead of saving old values.
  void _onExternalShotSettings() => unawaited(_loadShotSettings());
  final TextEditingController windMidCtl = TextEditingController();
  final TextEditingController windFarCtl = TextEditingController();
  final TextEditingController zeroUpCtl = TextEditingController();
  final TextEditingController zeroRightCtl = TextEditingController();
  final TextEditingController groupCtl = TextEditingController();
  final TextEditingController sdCtl = TextEditingController();

  /// WEZ (owner, 2026-10-10): target diameter (cm/in, empty = 10 cm / 4 in),
  /// range error (± m/yd, empty = ±1) and BC error (± %, empty = 0).
  final TextEditingController targetSizeCtl = TextEditingController();
  final TextEditingController rangeErrorCtl = TextEditingController();
  final TextEditingController bcErrorCtl = TextEditingController();

  /// WEZ Atış sayısı (owner, 2026-10-11): Hedef shows the first-shot
  /// probability and, for more than one shot, the chance of at least one hit.
  int _wezShotCount = Wez.defaultShotCount;

  /// Atış sayısı starts on "Seçiniz" (owner, 2026-10-12); unchosen means
  /// the default single shot.
  bool _wezShotChosen = false;
  int _targetClearToken = 0;

  /// Hareketli hedef → "Verileri sil" (owner, 2026-10-12): empties every
  /// box of the card.
  void _clearTargetBox() {
    setState(() {
      for (final c in [
        targetSpeedCtl,
        groupCtl,
        sdCtl,
        targetSizeCtl,
        rangeErrorCtl,
        bcErrorCtl,
      ]) {
        c.text = '';
      }
      _targetMovesRight = null;
      _wezShotCount = Wez.defaultShotCount;
      _wezShotChosen = false;
      _targetClearToken++;
    });
    _coriolisChanged();
  }

  /// Which Pro Ayarlar box is open (one at a time; all closed at first).
  String? _proOpen;

  /// Atış mesafesi typed on Pro (profile distance unit) (owner,
  /// 2026-10-09): Hedef then opens at it with the solution already dialled
  /// and the right turret open. Empty = Hedef opens at 100.
  final TextEditingController proRangeCtl = TextEditingController();

  double? get _proRangeM {
    final v = _parsed(proRangeCtl);
    if (v == null || v <= 0 || v > _displayMaxRange) return null;
    return math.min(_fromDisplayRange(v), ProductionLimits.maxRangeM);
  }

  /// Set when Hedef opens with a Pro distance; consumed by the next scope
  /// build once that distance has been solved.
  bool _autoDialArmed = false;

  /// Paralaks Mesafesi (PCP, owner 2026-10-12): the distance read from the
  /// side-focus wheel table is written to Atış mesafesi; still editable.
  Future<void> _proRangeFromParallax() async {
    final p = widget.profile;
    if (p == null) return;
    final meters = await Navigator.push<double>(
      context,
      MaterialPageRoute<double>(
        builder: (_) => ParallaxScreen(profile: p, returnDistance: true),
      ),
    );
    if (!mounted || meters == null || !meters.isFinite || meters <= 0) return;
    setState(
      () => proRangeCtl.text = _toDisplayRange(meters).round().toString(),
    );
  }

  Future<void> _proRangeFromMap() async {
    final meters = await Navigator.push<double>(
      context,
      MaterialPageRoute<double>(
        builder: (_) => const MapDistanceScreen(returnDistance: true),
      ),
    );
    if (!mounted || meters == null || !meters.isFinite || meters <= 0) return;
    setState(
      () => proRangeCtl.text = _toDisplayRange(meters).round().toString(),
    );
  }

  /// Wind zones for the shot at [_shotRangeM], or null when both are empty.
  WindZones? get _windZones {
    double? w(TextEditingController c) {
      final v = _parsed(c);
      if (v == null || v < 0 || v > 60) return null;
      return metric ? v : UnitSystem.mphToMps(v);
    }

    final mid = w(windMidCtl), far = w(windFarCtl);
    if (mid == null && far == null) return null;
    final near = _basis?.environment.windMps ?? 0;
    return WindZones(
      rangeM: _shotRangeM,
      midMps: mid ?? near,
      farMps: far ?? mid ?? near,
    );
  }

  /// Sıfır ofseti as angles (mrad; + = the group sat high / right), zero
  /// when empty.
  ({double up, double right}) get _zeroOffsetMrad {
    final z = widget.profile?.zeroRangeM;
    double a(TextEditingController c) {
      final v = _parsed(c);
      if (z == null || z <= 0 || v == null || v.abs() > 100) return 0;
      final m = metric ? v / 100 : UnitSystem.inchesToMillimeters(v) / 1000;
      return math.atan(m / z) * 1000;
    }

    return (up: a(zeroUpCtl), right: a(zeroRightCtl));
  }

  bool get _isFirearm =>
      profileResolution?.rifle.platform == WeaponPlatform.firearm;

  /// Barut sıcaklığı of this profile: Profil > Mühimmat, else the values
  /// an older version kept on Pro Ayarlar ([powderCoefCtl], [powderTempCtl],
  /// no longer shown). Null on PCP.
  ({double? coef, double? referenceC, bool fromProfile}) get _powder =>
      PowderTemperature.forProfile(
        profile: widget.profile,
        platform: profileResolution?.rifle.platform,
        legacyCoefText: powderCoefCtl.text,
        legacyTempText: powderTempCtl.text,
      );

  /// Today's velocity from the profile velocity measured at the reference
  /// temperature and the sensitivity (% per 15 °C); firearms only. The
  /// cartridge temperature is used when entered, else the air [todayC].
  /// Without a coefficient nothing changes (no default is assumed).
  double _powderAdjusted(double mps, double todayC) {
    if (!_isFirearm) return mps;
    final p = _powder;
    return mps *
        PowderTemperature.factor(
          coefPercentPer15C: p.coef,
          referenceTempC: p.referenceC,
          todayTempC: PowderTemperature.effectiveTempC(
            airC: todayC,
            ammoC: _ammoTempC,
          ),
        );
  }

  bool get _isPcp => profileResolution?.rifle.platform == WeaponPlatform.pcp;

  /// Pro "Kalan tüp basıncı", hidden (owner, 2026-10-14: "kalan basınç diye
  /// bir şey olmaz", "her atışta basınç mı girecek"; hidden, not removed).
  /// The tube pressure is asked once, on Profil > Mühimmat "Tüp basıncı".
  static const bool _showProTubePressure = bool.fromEnvironment(
    'PRO_TUBE_PRESSURE',
  );

  /// PCP tüp ve regülatör basıncı (owner, 2026-10-12): the velocity at the
  /// profile's Tüp basıncı, from its regulator pressure and basınca göre hız
  /// table. A tube pressure saved on Pro before is ignored unless
  /// PRO_TUBE_PRESSURE is on. Null on a firearm (never applies there).
  PcpVelocity? _pcpVelocity(double profileMps) {
    if (!_isPcp) return null;
    final p = widget.profile;
    final tube = _showProTubePressure
        ? _parsed(tubePressureCtl)
        : p?.tubePressureBar;
    return PcpPressure.velocity(
      profileMps: profileMps,
      regulatorBar: p?.pressureBar,
      tubeBar: tube != null && tube <= ProductionLimits.maxPcpPressureBar
          ? tube
          : null,
      table: p?.pressureVelocityTable ?? const [],
    );
  }

  /// Gyroscopic stability (Miller), length in calibres and twist direction,
  /// or null when data is missing (no BC, Pro bullet length or twist).
  ///
  /// Not for a diabolo pellet (formula audit 2026-10-13): a pellet is
  /// drag-stabilised (its centre of pressure sits behind the centre of
  /// mass), so the Miller gyroscopic rule and Litz's spin-drift and jump
  /// fits, both made for spin-stabilised bullets, do not describe it. The
  /// PCP note ([ProSectionInfo.spinDriftPcpNote]) already limited it to
  /// slugs; the code still applied it to pellets when a length was typed.
  ({double sg, double lCal, TwistDirection dir})? _stability(_ShotBasis basis) {
    if (!_spinDriftOn || !basis.drag) return null;
    if (ammunition?.type == AmmunitionType.pellet) return null;
    final rifle = profileResolution?.rifle;
    final dir = rifle?.twistDirection;
    final sg = _muzzleSg(basis);
    final lengthMm = _bulletLengthMm;
    if (rifle == null || dir == null || sg == null || lengthMm == null) {
      return null;
    }
    final lCal = lengthMm / 25.4 / (rifle.caliberMm / 25.4);
    return (sg: sg, lCal: lCal, dir: dir);
  }

  /// Bullet length for Sg (mm): only the Pro "Mermi uzunluğu" box. The
  /// Profil > Mühimmat length fallback (formula audit 2026-10-13, #264) was
  /// withdrawn by the owner (2026-10-13 23:32): that box is hidden, so a
  /// saved profile length the user cannot see must never change spin
  /// drift or Sg. Null when the box is empty or not plausible (0–100 mm).
  double? get _bulletLengthMm {
    final v = _parsed(bulletLengthCtl);
    return v != null && v.isFinite && v > 0 && v <= 100 ? v : null;
  }

  /// Miller Sg at the muzzle (Ö5), or null without bullet length or twist.
  double? _muzzleSg(_ShotBasis basis) {
    final rifle = profileResolution?.rifle;
    final twist = rifle?.twistRateIn;
    final lengthMm = _bulletLengthMm;
    if (rifle == null || twist == null || twist <= 0 || lengthMm == null) {
      return null;
    }
    return Stability.millerSg(
      grain: basis.grain,
      caliberMm: rifle.caliberMm,
      twistIn: twist,
      lengthMm: lengthMm,
      velocityMps: basis.velocityMps,
      temperatureC: basis.environment.temperatureC,
      pressureHpa: basis.environment.pressureHpa,
    );
  }

  /// Kararlılık and transonik notices for the shot (Ö5); firearms only.
  List<Widget> _flightWarnings(TrajectoryPoint shot, _ShotBasis basis) {
    if (!_isFirearm) return const [];
    final env = basis.environment;
    double? mach(double v) {
      try {
        return Atmosphere.machNumber(velocityMps: v, environment: env);
      } on ArgumentError {
        return null;
      }
    }

    return FlightWarnings.notices(
      sg: _muzzleSg(basis),
      muzzleMach: mach(basis.velocityMps),
      targetMach: mach(shot.velocityMps),
    );
  }

  /// Spin drift (Litz) as a sideways angle in mrad, + = to the right; null
  /// when [_stability] is null. Stability from the Miller formula.
  double? _spinDriftMrad(TrajectoryPoint shot, _ShotBasis basis) {
    final st = _stability(basis);
    if (st == null) return null;
    final driftIn = 1.25 * (st.sg + 1.2) * math.pow(shot.timeOfFlightS, 1.83);
    final m = driftIn * 0.0254 * (st.dir == TwistDirection.right ? 1 : -1);
    return math.atan(m / _shotRangeM) * 1000;
  }

  /// Aerodynamic jump (Litz): a crosswind at the muzzle tips a spinning
  /// bullet up or down. Vertical shift in mrad, + = impact moves UP; null
  /// when spin drift is off. Right-hand twist: wind from the right lifts,
  /// from the left drops (mirrored for left-hand twist).
  double? _aeroJumpMrad(_ShotBasis basis) {
    final st = _stability(basis);
    if (st == null) return null;
    final env = basis.environment;
    // Internal wind degrees: 90° = from the LEFT, 270° = from the right.
    final fromRightMph =
        -UnitSystem.mpsToMph(env.windMps) *
        math.sin(env.windDirectionDeg * math.pi / 180);
    final moaPerMph = 0.01 * st.sg - 0.0024 * st.lCal + 0.032;
    final moa =
        moaPerMph * fromRightMph * (st.dir == TwistDirection.right ? 1 : -1);
    return moa * math.pi / 10800 * 1000;
  }

  /// Real / marked turret travel; 1 when empty or implausible (0.8–1.2).
  double get _turretScale {
    final v = _parsed(turretScaleCtl);
    return v != null && v >= 0.8 && v <= 1.2 ? v : 1.0;
  }

  /// Highest wind of the bracket in m/s (shown unit converted), or null.
  double? get _windMaxMps {
    final v = _parsed(windMaxCtl);
    if (v == null || v <= 0 || v > 60) return null;
    return metric ? v : UnitSystem.mphToMps(v);
  }

  /// Moving target speed in m/s, or null.
  double? get _targetSpeedMps {
    final v = _parsed(targetSpeedCtl);
    if (v == null || v <= 0 || v > 30) return null;
    return metric ? v : UnitSystem.mphToMps(v);
  }

  String? _coriolisStatus;

  double? _parsed(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    return v != null && v.isFinite ? v : null;
  }

  double? get _latitude {
    final v = _parsed(latitudeCtl);
    return v != null && v >= -90 && v <= 90 ? v : null;
  }

  /// Pro → Yerçekimi: always on (no switches since 2026-10-11; still saved
  /// as gravityOn); the local value in [gravityCtl] (computed from the
  /// location), standard gravity while it is empty or out of range.
  final bool _gravityOn = true;
  final TextEditingController gravityCtl = TextEditingController();
  String? _gravityStatus;

  double? get _gravityTyped {
    final v = _parsed(gravityCtl);
    return v != null && v >= 9.7 && v <= 9.9 ? v : null;
  }

  /// Gravity handed to the solver (m/s²).
  double get _gravity =>
      _gravityOn ? (_gravityTyped ?? Gravity.standard) : Gravity.standard;

  void _gravityChanged() {
    setState(() {
      _shotCache.clear();
      _holdSamples = null;
    });
    _saveShotSettings();
    _quietSolve();
  }

  Future<void> _gravityFromLocation() async {
    final services = ToolsServicesScope.of(context);
    setState(() => _gravityStatus = 'Konum alınıyor…');
    final fix = await services.location.current();
    if (!mounted) return;
    if (fix is LocationFix) {
      // Altitude: the İrtifa card (Telefondan, else Haritadan; owner,
      // 2026-10-14), else the GPS height.
      final typedAlt = _parsed(_altitudeCtl);
      final altM = typedAlt != null
          ? (metric ? typedAlt : UnitSystem.feetToMeters(typedAlt))
          : (fix.altitudeM ?? 0);
      final g = Gravity.at(latitudeDeg: fix.latitude, altitudeM: altM);
      gravityCtl.text = g.toStringAsFixed(4);
      _gravFilled = true;
      _gravWasReset = false;
      _gravityStatus =
          'Konumdan hesaplandı: ${fix.latitude.abs().toStringAsFixed(1).replaceAll('.', ',')}° '
          '${fix.latitude >= 0 ? 'K' : 'G'} · ${altM.round()} m.';
    } else {
      _gravityStatus = 'Konum alınamadı; yerçekimini elle girin.';
    }
    _gravityChanged();
  }

  double? get _azimuth {
    final v = _parsed(azimuthCtl);
    return v != null && v >= 0 && v <= 360 ? v : null;
  }

  /// Latitude/azimuth handed to the solver: both or neither.
  ({double? lat, double? az}) get _coriolisArgs =>
      _coriolisOn && _latitude != null && _azimuth != null
      ? (lat: _latitude, az: _azimuth)
      : (lat: null, az: null);

  void _coriolisChanged() {
    setState(() {
      _shotCache.clear();
      _holdSamples = null;
    });
    _saveShotSettings();
  }

  /// Drag-mode extras of the last solve (empty in vacuum mode).
  List<DragWarning> _warnings = [];
  List<double> _unreachableM = [];

  /// Turret clicks dialled on the interactive scope (U/R positive). Kept
  /// with the workspace so they survive tab switches; a new profile starts
  /// a fresh workspace with both turrets at zero.
  int _elevationClicks = 0;
  int _windageClicks = 0;

  /// Magnification shown on the interactive scope; null = the scope's
  /// highest power (the usual SFP calibration).
  double? _magnification;

  /// Angular unit of the scope view: the unit chosen in the profile
  /// ("Dürbün birimi") wins, so a MRAD profile shows a MRAD reticle and MRAD
  /// turret clicks, and a MOA profile shows MOA throughout.
  AngularUnit get _scopeUnit =>
      widget.profile?.angularUnit ?? scope?.clickUnit ?? AngularUnit.mrad;

  /// Click size in [_scopeUnit]: the catalog value when the catalog turret
  /// is in the same unit, otherwise the standard click of that unit
  /// (0.1 mrad / ¼ MOA).
  double? get _scopeClickValue {
    final s = scope;
    if (s == null || !s.clickValue.isFinite || s.clickValue <= 0) return null;
    return s.clickUnit == _scopeUnit
        ? s.clickValue
        : ScopeDialMath.standardClick(_scopeUnit);
  }

  /// Correction-vs-range curve of the current basis (drag or vacuum), used
  /// to label the reticle's hold marks. Sampled once per solve.
  List<TrajectoryPoint>? _holdSamples;
  _ShotBasis? _holdSamplesBasis;
  final Map<double, ({TrajectoryPoint? shot, double? mpsPerMil})> _shotCache =
      {};

  /// True when the entered ammunition carries a BC + drag law AND the grain
  /// field still equals that ammunition's weight (a BC belongs to one mass).
  bool _bcApplies() {
    final a = ammunition;
    if (a == null ||
        a.ballisticCoefficient == null ||
        a.ballisticModel == null) {
      return false;
    }
    final g = double.tryParse(grain.text.trim().replaceAll(',', '.'));
    return g != null && (g - a.grain).abs() < 1e-9;
  }

  /// Whether results shown (or about to be computed) use the drag solver.
  bool get _dragMode => _basis != null ? _basis!.drag : _bcApplies();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ShotSettingsStore.externalWrites.addListener(_onExternalShotSettings);
    final p = widget.profile;
    profileResolution = p == null
        ? null
        : const ProfileCatalogIntegrity().resolve(p);
    final ammo = profileResolution?.ammunition;
    // PCP without a BC: an estimated G1 BC so drag and wind are solved
    // (owner, 2026-10-13); the notice says it is an estimate.
    ammunition = ammo == null ? null : EstimatedBc.fill(ammo);
    _bcEstimated = ammo != null && !identical(ammunition, ammo);
    scope = profileResolution?.scope;

    velocity = TextEditingController(
      // Namlu çıkış hızı is always fps (owner rule), like on Profil.
      text: UnitSystem.mpsToFps(p?.muzzleVelocityMps ?? 270).toStringAsFixed(1),
    );
    grain = TextEditingController(text: (ammo?.grain ?? 51).toString());
    // A yard profile shows (and takes) its zero in yards, and its shot
    // range starts at a round 100 yd.
    _shotRangeM = _defaultShotRangeM;
    if (p != null) {
      _watchRanges = WatchBridge.instance.rangeRequests.listen(_onWatchRange);
      // Refresh the shown solution's time so an open, unchanged Atış is
      // never marked stale on the watch (the bridge sends at most 1/min).
      _watchTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        final s = _watchLast;
        if (s != null && mounted) {
          unawaited(WatchBridge.instance.publish(s.withTime(DateTime.now())));
        }
      });
    }
    final zeroM = p?.zeroRangeM ?? 25;
    zero = TextEditingController(
      text: p?.distanceUnit == DistanceUnit.yard
          ? UnitSystem.metersToYards(zeroM).toStringAsFixed(1)
          : zeroM.toString(),
    );
    sight = TextEditingController(text: (p?.sightHeightMm ?? 65).toString());
    // Hava Durumu boxes start empty (owner, 2026-10-12: "Konum verisi
    // alınmadan kutular dolu geliyor"); an empty box is solved with the
    // standard atmosphere and no wind.
    wind = TextEditingController();
    windDirection = TextEditingController(text: '90');
    windHour = TextEditingController()..addListener(_syncWindHour);
    temperature = TextEditingController();
    pressure = TextEditingController();
    humidity = TextEditingController();
    altitude = TextEditingController();
    mapAltitude = TextEditingController();
    ranges = TextEditingController(
      text: '25, 50, 75, 100, 125, 150, 175, 200, 250, 300, 400',
    );
    widget.environmentCarry?._apply(this);
    // Every Hava Durumu change is kept for this profile until Sıfırla
    // (owner, 2026-10-12).
    for (final c in [
      temperature,
      pressure,
      humidity,
      altitude,
      mapAltitude,
      wind,
    ]) {
      c.addListener(_weatherChanged);
    }
    windDirection.addListener(_weatherChanged);
    _loadUnitPreference();
    unawaited(_loadShotSettings());
    // Sıfır Grubu can write Sıfır ofseti while this workspace stays open.
    ShotSettingsStore.changes.addListener(_reloadShotSettings);
    // Solve the profile as soon as the workspace opens, so the scope's
    // reticle, hold labels and point of impact are ready at once. The fields are still SI here; a later switch to
    // imperial only converts the fields, the stored basis stays SI.
    // Failures stay silent (the shot view says why).
    if (widget.view == BallisticsView.environment) {
      _maybeAutoWeather();
      _warmUpPhoneAltitude();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.profile != null && _basis == null) {
        _silentErrors = true;
        try {
          solve();
        } finally {
          _silentErrors = false;
        }
      }
    });
  }

  /// True while the automatic first solve runs: errors are not shown as
  /// snack bars then.
  bool _silentErrors = false;

  // ---- Live weather fill (Hava Durumu) ----------------------------------

  /// Fields the user typed into: an automatic fill never overwrites them.
  final Set<TextEditingController> _userEdited = {};
  bool _autoWeatherDone = false;
  bool _weatherBusy = false;
  String? _weatherStatus;
  bool _weatherFailed = false;

  /// The weather button turns orange ("…alındı") after a successful fill
  /// and offers "Sıfırla" (owner, 2026-10-12). Typing into a field it
  /// filled turns it back: the values on screen are no longer the service's.
  bool _weatherFilled = false;

  /// The weather button is orange while its boxes hold the fetched values
  /// (owner, 2026-10-13): fetched, and Sıcaklık and Bağıl nem not emptied.
  bool get _weatherOrange => _weatherHolds && _isFresh(_weatherFetchedAtMs);

  /// The boxes still hold a fetch, but it is older than 30 minutes (or of
  /// unknown age): "Hava verisi eski · Yenile" (owner, 2026-10-14).
  bool get _weatherStale => _weatherHolds && !_isFresh(_weatherFetchedAtMs);

  bool get _weatherHolds =>
      _weatherFilled &&
      temperature.text.trim().isNotEmpty &&
      humidity.text.trim().isNotEmpty;

  /// The same for "Basıncı telefondan al".
  bool _pressureFilled = false;
  bool get _pressureOrange => _pressureFilled && _isFresh(_pressureFetchedAtMs);
  bool get _pressureStale => _pressureFilled && !_isFresh(_pressureFetchedAtMs);

  /// When the weather / pressure button last filled its boxes (UTC epoch
  /// ms, from [_clock]); null = unknown (older saves), which counts as old.
  int? _weatherFetchedAtMs;
  int? _pressureFetchedAtMs;

  /// A fetched value counts as current this long (owner, 2026-10-14:
  /// "Hava verisi alındı turuncu ama tuşa bastım başka veriler geldi").
  static const _freshFor = Duration(minutes: 30);

  /// Time source (ToolsServices.clock) so tests can move time.
  Clock _clock = const SystemClock();

  /// Rebuilds the page when a fresh fetch turns old while it is open.
  Timer? _freshnessTimer;

  /// Fresh = fetched at most 30 minutes ago. A fetch time in the future
  /// (the phone clock was set back) is not trusted: old.
  bool _isFresh(int? atMs) {
    if (atMs == null) return false;
    final age = _clock.now().millisecondsSinceEpoch - atMs;
    return age >= 0 && age <= _freshFor.inMilliseconds;
  }

  /// The date row under a fetch button: the fetch's date and time, or
  /// today's date before any fetch (owner, 2026-10-14).
  String _whenText(int? atMs) =>
      atMs == null ? fetchDateText(_clock.now()) : fetchDateTimeText(atMs);

  /// One timer for the earliest moment a fresh fetch turns old; it fires
  /// just after the 30-minute mark, rebuilds and arms the next one.
  void _scheduleFreshnessCheck() {
    _freshnessTimer?.cancel();
    _freshnessTimer = null;
    final now = _clock.now().millisecondsSinceEpoch;
    int? next;
    for (final (filled, at) in [
      (_weatherFilled, _weatherFetchedAtMs),
      (_pressureFilled, _pressureFetchedAtMs),
    ]) {
      if (!filled || at == null) continue;
      final age = now - at;
      if (age < 0 || age > _freshFor.inMilliseconds) continue;
      final left = _freshFor.inMilliseconds - age + 1;
      if (next == null || left < next) next = left;
    }
    if (next == null) return;
    _freshnessTimer = Timer(Duration(milliseconds: next), () {
      _freshnessTimer = null;
      if (!mounted) return;
      setState(() {});
      _scheduleFreshnessCheck();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not ToolsServicesScope.of: without a scope the system clock is
    // enough, no need to build the production services here.
    _clock =
        context
            .dependOnInheritedWidgetOfExactType<ToolsServicesScope>()
            ?.services
            .clock ??
        const SystemClock();
    _scheduleFreshnessCheck();
  }

  /// Back from the background (e.g. after an update, the owner's case):
  /// re-check freshness at once.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Background: the silent altitude warm-up is dropped (owner, 2026-10-14).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _cancelPhoneAltitudeWarmUp();
    }
    if (state != AppLifecycleState.resumed || !mounted) return;
    setState(() {});
    _scheduleFreshnessCheck();
  }

  /// After "Sıfırla" the reset button stays, orange, as "Veriler sıfırlandı"
  /// (owner, 2026-10-12) until the next fetch or a typed value.
  bool _weatherWasReset = false;
  bool _pressureWasReset = false;

  /// Sıfırla of the weather row: empties the boxes it fills.
  void _resetWeather() {
    setState(() {
      // Sıfırla empties the boxes (owner, 2026-10-12); an empty box is
      // calculated with the standard atmosphere (15 °C, 1013,25 hPa, %50,
      // 0 m, no wind).
      temperature.text = '';
      humidity.text = '';
      wind.text = '';
      for (final c in [temperature, humidity, wind]) {
        _userEdited.remove(c);
      }
      _weatherFilled = false;
      _weatherWasReset = true;
      _weatherStatus = null;
      _weatherFailed = false;
      _shotCache.clear();
      _holdSamples = null;
    });
    if (widget.profile != null) _quietSolve();
  }

  void _resetPressure() {
    setState(() {
      // Pressure only: İrtifa has its own card (owner, 2026-10-14).
      pressure.text = '';
      _userEdited.remove(pressure);
      _pressureFilled = false;
      _pressureWasReset = true;
      _pressureStatus = null;
      _pressureFailed = false;
      _shotCache.clear();
      _holdSamples = null;
    });
    if (widget.profile != null) _quietSolve();
  }

  @override
  void didUpdateWidget(covariant BallisticsScreen old) {
    super.didUpdateWidget(old);
    if (_isShotView(old.view) && !_isShotView(widget.view)) _withdrawWatch();
    if (widget.view == BallisticsView.environment &&
        old.view != BallisticsView.environment) {
      _maybeAutoWeather();
      _warmUpPhoneAltitude();
    }
    // Atış has no Hesapla button any more (owner, 2026-10-08): it is solved
    // with the current Hava Durumu / Pro values whenever it opens.
    final toShot =
        widget.view == BallisticsView.shot ||
        widget.view == BallisticsView.table;
    final proRange = _proRangeM;
    final enteringShot =
        widget.view == BallisticsView.shot && old.view != BallisticsView.shot;
    if (enteringShot) {
      _shotRangeM = proRange ?? _defaultShotRangeM;
    }
    if (toShot && widget.view != old.view) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _quietSolve();
        // Pro distance: dial the fresh solution and open the right turret.
        if (enteringShot && proRange != null) {
          setState(() => _autoDialArmed = true);
        }
      });
    }
  }

  /// Solve without snack bars (Atış says why when there is no value).
  void _quietSolve() {
    if (widget.profile == null) return;
    _silentErrors = true;
    try {
      solve();
    } finally {
      _silentErrors = false;
    }
  }

  /// Warns when the typed pressure cannot be the real (station) pressure at
  /// the typed altitude — usually a sea-level (QNH) value typed by mistake
  /// (owner, 2026-10-09). Weather keeps sea-level pressure between about
  /// 950 and 1050 hPa; reduced to the altitude that gives the plausible band.
  String? get _pressureWarning {
    double? parse(TextEditingController c) =>
        double.tryParse(c.text.trim().replaceAll(',', '.'));
    // An empty İrtifa is solved as 0 m, so the check uses 0 m too. The
    // effective İrtifa: Telefondan, else Haritadan (owner, 2026-10-14).
    final alt = _altitudeCtl;
    final p = parse(pressure);
    final a = alt.text.trim().isEmpty ? 0.0 : parse(alt);
    if (p == null || a == null || !p.isFinite || !a.isFinite) return null;
    final pHpa = metric ? p : UnitSystem.inHgToHpa(p);
    final aM = metric ? a : UnitSystem.feetToMeters(a);
    if (aM < -500 || aM > 9000) return null;
    final high = FieldCalc.stationPressureHpa(1050, aM);
    final low = FieldCalc.stationPressureHpa(950, aM);
    final typical = FieldCalc.stationPressureHpa(1013.25, aM);
    if (pHpa > high + 1) {
      return '${aM.round()} m irtifada gerçek basınç yaklaşık '
          '${typical.round()} hPa olur; girilen değer deniz seviyesi basıncı '
          'olabilir. Hava durumu uygulamasındaki basıncı istasyon basıncına '
          'çevirin ya da "Basınç al" düğmesini kullanın.';
    }
    if (pHpa < low - 1) {
      return '${aM.round()} m irtifa için basınç çok düşük (yaklaşık '
          '${typical.round()} hPa beklenir). Basıncı ve irtifayı kontrol edin.';
    }
    return null;
  }

  void _maybeAutoWeather() {
    if (!widget.autoWeather || _autoWeatherDone) return;
    _autoWeatherDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fillWeather();
    });
  }

  /// Location → weather service → Hava Durumu fields. With [overwrite] the
  /// user's own edits are replaced too (the "Konumdan canlı hava verisi al"
  /// button);
  /// otherwise only untouched fields are filled.
  Future<void> _fillWeather({bool overwrite = false}) async {
    if (_weatherBusy) return;
    final services = ToolsServicesScope.of(context);
    setState(() {
      _weatherBusy = true;
      _weatherFailed = false;
      _weatherStatus = 'Konumdan hava verisi alınıyor…';
    });
    String status;
    var failed = false;
    String? windBefore;
    try {
      final fix = await services.location.current();
      if (fix is! LocationFix) {
        failed = true;
        status = switch (fix) {
          LocationDenied() => 'Konum izni yok; hava değerlerini elle girin.',
          LocationServiceOff() =>
            'Konum Servisleri kapalı; hava değerlerini elle girin.',
          _ => 'Konum alınamadı; hava değerlerini elle girin.',
        };
      } else {
        final obs = await services.weather.fetch(fix.latitude, fix.longitude);
        if (!mounted) return;
        if (overwrite) _userEdited.clear();
        windBefore = wind.text;
        void put(TextEditingController c, String v) {
          if (!_userEdited.contains(c)) c.text = v;
        }

        put(
          temperature,
          (metric
                  ? obs.temperatureC
                  : UnitSystem.celsiusToFahrenheit(obs.temperatureC))
              .toStringAsFixed(1),
        );
        put(humidity, obs.humidityPercent.round().toString());
        put(
          wind,
          (metric ? obs.windSpeedMps : UnitSystem.mpsToMph(obs.windSpeedMps))
              .toStringAsFixed(1),
        );
        // Pressure and altitude come only from "Basıncı telefondan al"
        // (owner, 2026-10-12: each box is filled by its own button).
        final t = obs.validAt.toLocal();
        final hh = t.hour.toString().padLeft(2, '0');
        final mm = t.minute.toString().padLeft(2, '0');
        status =
            'Hava verisi konumdan dolduruldu (${obs.sourceName}, $hh:$mm). '
            'Basınç için "Basınç al", irtifa için İrtifa kartı. Rüzgâr '
            'yönünü siz seçin.';
      }
    } on WeatherFailure {
      failed = true;
      status = 'Hava servisine ulaşılamadı; değerleri elle girin.';
    } catch (_) {
      failed = true;
      status = 'Hava verisi alınamadı; değerleri elle girin.';
    }
    if (!mounted) return;
    setState(() {
      _weatherBusy = false;
      _weatherFailed = failed;
      _weatherStatus = status;
      if (!failed) {
        _weatherFilled = true;
        _weatherWasReset = false;
        _weatherFetchedAtMs = _clock.now().millisecondsSinceEpoch;
      }
    });
    if (!failed) {
      // Stored even when the values came back the same (no text change).
      _weatherChanged();
      _scheduleFreshnessCheck();
      // A new Rüzgâr hızı updates En çok rüzgâr (owner, 2026-10-14).
      if (windBefore != null && wind.text != windBefore) _windMaxFollowsWind();
    }
    // Re-solve with the new conditions (quietly: Atış says why if not).
    if (!failed && widget.profile != null) {
      _silentErrors = true;
      try {
        solve();
      } finally {
        _silentErrors = false;
      }
    }
  }

  // ---- Phone barometer (Ö4) ---------------------------------------------

  bool _pressureBusy = false;
  String? _pressureStatus;
  bool _pressureFailed = false;

  /// "Basınç al": reads the phone barometer once, ONLY on this button
  /// (owner rule), and writes it into İstasyon basıncı as the user's own
  /// value. The weather fill never writes Basınç, and since 2026-10-14 this
  /// button no longer writes İrtifa (the İrtifa card has its own buttons).
  Future<void> _readPhonePressure() async {
    if (_pressureBusy) return;
    final services = ToolsServicesScope.of(context);
    final sensor = services.pressure;
    setState(() {
      _pressureBusy = true;
      _pressureStatus = null;
    });
    PressureReading reading;
    try {
      reading = await sensor.read();
    } catch (_) {
      reading = const PressureUnavailable();
    }
    if (!mounted) return;
    setState(() {
      _pressureBusy = false;
      if (reading is PressureRead) {
        pressure.text = _pressureText(reading.hpa);
        _userEdited.add(pressure);
        _pressureFailed = false;
        _pressureFilled = true;
        _pressureWasReset = false;
        _pressureFetchedAtMs = _clock.now().millisecondsSinceEpoch;
        // The date row under the button says when (owner, 2026-10-14).
        _pressureStatus = null;
      } else {
        _pressureFailed = true;
        final u = reading as PressureUnavailable;
        _pressureStatus = switch (u.reason) {
          PressureFailure.noSensor =>
            'Basınç okunamadı: telefonun basınç sensörüne erişilemedi. '
                'Ayarlar > Gizlilik ve Güvenlik > Hareket ve Fitness\'ta '
                'SNIPER TÜRK\'e izin verin ya da basıncı elle girin.',
          PressureFailure.noSample =>
            'Basınç okunamadı: sensör 5 saniyede değer vermedi. Tekrar '
                'deneyin ya da basıncı elle girin.',
          PressureFailure.outOfRange =>
            'Basınç okunamadı: sensör geçersiz bir değer verdi'
                '${u.lastValue == null ? '' : ' (${u.lastValue!.toStringAsFixed(1)})'}'
                '. Basıncı elle girin.',
        };
      }
    });
    if (reading is PressureRead) {
      _weatherChanged();
      _scheduleFreshnessCheck();
    }
    if (reading is PressureRead && widget.profile != null) _quietSolve();
  }

  // ---- İrtifa card (owner, 2026-10-14) -----------------------------------

  /// When "Telefondan" / "Haritadan" wrote their box (UTC epoch ms); null =
  /// typed, reset or never fetched. The buttons stay orange while set (no
  /// 30-minute rule for altitude).
  int? _altPhoneAtMs;
  int? _altMapAtMs;
  bool _altPhoneBusy = false;
  bool _altMapBusy = false;

  /// One short note under the İrtifa rows (failures only).
  String? _altitudeStatus;

  /// After Sıfırla, as on the other cards.
  bool _altitudeWasReset = false;

  /// The İrtifa used by the calculation: Telefondan irtifa when it holds a
  /// value, else Haritadan irtifa (owner, 2026-10-14).
  TextEditingController get _altitudeCtl =>
      altitude.text.trim().isNotEmpty ? altitude : mapAltitude;

  /// Silent GPS warm-up: one high-accuracy request when Hava Durumu opens,
  /// exactly as if "Telefondan" were pressed, but its result is dropped
  /// (nothing written, nothing shown). Bumping the token drops it too
  /// (page closed, app in the background).
  int _altWarmUpToken = 0;
  Future<LocationResult>? _altWarmUp;

  void _warmUpPhoneAltitude() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _altWarmUp != null) return;
      final provider = ToolsServicesScope.of(context).phoneAltitude;
      if (provider == null) return;
      final token = ++_altWarmUpToken;
      bool granted;
      try {
        granted = await provider.permissionGranted();
      } catch (_) {
        granted = false;
      }
      // Never the permission prompt from here: the button asks as today.
      if (!granted || !mounted || token != _altWarmUpToken) return;
      final request = provider.current().catchError(
        (Object _) => const LocationFailure('Konum alınamadı.'),
      );
      _altWarmUp = request;
      await request;
      if (token == _altWarmUpToken) _altWarmUp = null;
    });
  }

  void _cancelPhoneAltitudeWarmUp() {
    _altWarmUpToken++;
    _altWarmUp = null;
  }

  String _altitudeShown(double meters) =>
      (metric ? meters : UnitSystem.metersToFeet(meters)).toStringAsFixed(0);

  /// "Telefondan": a fresh (GPS already warmed) reading, written at once.
  Future<void> _readPhoneAltitude() async {
    if (_altPhoneBusy) return;
    final services = ToolsServicesScope.of(context);
    // A warm-up still running is this very request: wait for it instead of
    // starting a second one.
    final running = _altWarmUp;
    _cancelPhoneAltitudeWarmUp();
    setState(() {
      _altPhoneBusy = true;
      _altitudeStatus = null;
    });
    LocationResult fix;
    try {
      fix =
          await (running ??
              (services.phoneAltitude?.current() ??
                  services.location.current()));
    } catch (_) {
      fix = const LocationFailure('Konum alınamadı.');
    }
    if (!mounted) return;
    final meters = fix is LocationFix ? fix.altitudeM : null;
    setState(() {
      _altPhoneBusy = false;
      if (meters != null && meters.isFinite) {
        altitude.text = _altitudeShown(meters);
        _userEdited.add(altitude);
        _altPhoneAtMs = _clock.now().millisecondsSinceEpoch;
        _altitudeWasReset = false;
      } else {
        // No usable altitude (0–50 m vertical accuracy rule): the box is
        // emptied so the map value, if any, is used.
        altitude.text = '';
        _userEdited.remove(altitude);
        _altPhoneAtMs = null;
        _altitudeStatus = mapAltitude.text.trim().isNotEmpty
            ? 'Telefon irtifası alınamadı; hesapta haritadan gelen irtifa '
                  'kullanılıyor.'
            : 'İrtifa alınamadı, elle girin.';
      }
    });
    _altitudeChanged();
  }

  /// "Haritadan": the phone's position → Google Maps Elevation API.
  Future<void> _readMapAltitude() async {
    if (_altMapBusy) return;
    final services = ToolsServicesScope.of(context);
    final elevationService = services.elevation;
    setState(() {
      _altMapBusy = true;
      _altitudeStatus = null;
    });
    String? failure;
    double? meters;
    if (elevationService == null) {
      failure = 'Harita irtifası bu derlemede yok; irtifayı elle girin.';
    } else {
      LocationResult fix;
      try {
        fix = await services.location.current();
      } catch (_) {
        fix = const LocationFailure('Konum alınamadı.');
      }
      if (fix is! LocationFix) {
        failure = switch (fix) {
          LocationDenied() => 'Konum izni yok; irtifayı elle girin.',
          LocationServiceOff() =>
            'Konum Servisleri kapalı; irtifayı elle girin.',
          _ => 'Konum alınamadı; irtifayı elle girin.',
        };
      } else {
        ElevationResult result;
        try {
          result = await elevationService.elevation(
            fix.latitude,
            fix.longitude,
          );
        } catch (_) {
          result = const ElevationUnavailable(ElevationFailure.error);
        }
        switch (result) {
          case ElevationRead(meters: final m):
            meters = m;
          case ElevationUnavailable(:final reason):
            failure = switch (reason) {
              ElevationFailure.noKey =>
                'Harita irtifası bu derlemede yok; irtifayı elle girin.',
              ElevationFailure.offline =>
                'İnternet yok; harita irtifası alınamadı.',
              ElevationFailure.error =>
                'Harita irtifası alınamadı; irtifayı elle girin.',
            };
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _altMapBusy = false;
      final m = meters;
      if (failure == null && m != null) {
        mapAltitude.text = _altitudeShown(m);
        _userEdited.add(mapAltitude);
        _altMapAtMs = _clock.now().millisecondsSinceEpoch;
        _altitudeWasReset = false;
      } else {
        mapAltitude.text = '';
        _userEdited.remove(mapAltitude);
        _altMapAtMs = null;
        _altitudeStatus = failure ?? 'Harita irtifası alınamadı.';
      }
    });
    _altitudeChanged();
  }

  /// Sıfırla of the İrtifa card: empties both boxes.
  void _resetAltitude() {
    setState(() {
      altitude.text = '';
      mapAltitude.text = '';
      _userEdited
        ..remove(altitude)
        ..remove(mapAltitude);
      _altPhoneAtMs = null;
      _altMapAtMs = null;
      _altitudeStatus = null;
      _altitudeWasReset = true;
    });
    _altitudeChanged();
  }

  void _altitudeChanged() {
    setState(() {
      _shotCache.clear();
      _holdSamples = null;
    });
    // Stored even when the value came back the same (no text change).
    _weatherChanged();
    if (widget.profile != null) _quietSolve();
  }

  /// The İrtifa date row: the latest of the two altitude fetches.
  int? get _altitudeAtMs {
    final a = _altPhoneAtMs, b = _altMapAtMs;
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }

  Future<void> _loadUnitPreference() async {
    try {
      final loadedMetric = (await SettingsStore.open()).loadMetric();
      if (!mounted || loadedMetric == metric) return;
      if (!loadedMetric) {
        _weatherSaveOff = true;
        try {
          _convertControllersToImperial();
        } finally {
          _weatherSaveOff = false;
        }
      }
      setState(() => metric = loadedMetric);
    } catch (_) {
      // Fail closed to the canonical SI representation if settings cannot load.
    }
  }

  void _convertControllersToImperial() {
    // Parse every field before mutating any controller. Settings are loaded
    // asynchronously, so the user can begin editing while this conversion is
    // pending. A late parse failure must never leave half the form converted
    // to imperial while `metric` still says the form is SI.
    double value(TextEditingController c) =>
        double.parse(c.text.trim().replaceAll(',', '.'));
    final zeroM = value(zero);
    final sightMm = value(sight);
    // Hava Durumu boxes may be empty after Sıfırla: they stay empty.
    double? maybe(TextEditingController c) =>
        c.text.trim().isEmpty ? null : value(c);
    final windMps = maybe(wind);
    final temperatureC = maybe(temperature);
    final ammoC = double.tryParse(ammoTempCtl.text.trim().replaceAll(',', '.'));
    final pressureHpa = maybe(pressure);
    final altitudeM = maybe(altitude);
    final mapAltitudeM = maybe(mapAltitude);
    final metricRanges = DopeRanges.parse(ranges.text);

    // Commit only after the complete source form has been validated. A
    // yard profile's distances already are in yards.
    if (!_profileYards) {
      zero.text = UnitSystem.metersToYards(zeroM).toStringAsFixed(1);
    }
    sight.text = UnitSystem.millimetersToInches(sightMm).toStringAsFixed(2);
    if (windMps != null) {
      wind.text = UnitSystem.mpsToMph(windMps).toStringAsFixed(1);
    }
    if (temperatureC != null) {
      temperature.text = UnitSystem.celsiusToFahrenheit(
        temperatureC,
      ).toStringAsFixed(1);
    }
    if (ammoC != null && ammoC.isFinite) {
      ammoTempCtl.text = UnitSystem.celsiusToFahrenheit(
        ammoC,
      ).toStringAsFixed(1);
    }
    if (pressureHpa != null) {
      pressure.text = UnitSystem.hpaToInHg(pressureHpa).toStringAsFixed(2);
    }
    if (altitudeM != null) {
      altitude.text = UnitSystem.metersToFeet(altitudeM).toStringAsFixed(0);
    }
    if (mapAltitudeM != null) {
      mapAltitude.text = UnitSystem.metersToFeet(
        mapAltitudeM,
      ).toStringAsFixed(0);
    }
    if (!_profileYards) {
      ranges.text = metricRanges
          .map((e) => UnitSystem.metersToYards(e).toStringAsFixed(1))
          .join(', ');
    }
  }

  void solve() {
    // Never leave previously calculated DOPE visible after a new request starts.
    // If parsing/validation/solver execution fails, stale values could otherwise
    // be mistaken for the current inputs.
    setState(() {
      points = [];
      airDensityKgM3 = null;
      densityRatio = null;
      speedOfSoundMps = null;
      muzzleMach = null;
      _pressureEstimated = false;
      _basis = null;
      _warnings = [];
      _unreachableM = [];
      _shotCache.clear();
    });

    double? number(TextEditingController c) =>
        double.tryParse(c.text.trim().replaceAll(',', '.'));
    final rawVelocity = number(velocity);
    final rawGrain = number(grain);
    final rawZero = number(zero);
    final rawSight = number(sight);
    // An empty Hava Durumu box (after Sıfırla) means the standard
    // atmosphere, in the shown unit.
    double? env(
      TextEditingController c,
      double metricStd,
      double imperialStd,
    ) => c.text.trim().isEmpty ? (metric ? metricStd : imperialStd) : number(c);
    final rawWind = env(wind, 0, 0);
    final rawWindDirection = number(windDirection);
    final rawTemperature = env(temperature, 15, 59);
    final rawPressure = env(pressure, 1013.25, 29.92);
    final rawHumidity = env(humidity, 50, 50);
    // İrtifa: Telefondan, else Haritadan (owner, 2026-10-14).
    final altitudeBox = _altitudeCtl;
    final rawAltitude = env(altitudeBox, 0, 0);

    if ([
      rawVelocity,
      rawGrain,
      rawZero,
      rawSight,
      rawWind,
      rawWindDirection,
      rawTemperature,
      rawPressure,
      rawHumidity,
      rawAltitude,
    ].any((x) => x == null)) {
      _error('Sayısal alanları kontrol edin.');
      return;
    }

    // Every field above has been null-checked; bind to non-nullable locals
    // once here instead of sprinkling `!` at each call site. The previous
    // version of this file used `v` (double?) directly at two call sites
    // below without unwrapping it, which is a null-safety type error.
    // Namlu çıkış hızı is entered in fps in every unit system.
    final v = UnitSystem.fpsToMps(rawVelocity!);
    final g = rawGrain!;
    final z = _yards ? UnitSystem.yardsToMeters(rawZero!) : rawZero!;
    final s = metric ? rawSight! : UnitSystem.inchesToMillimeters(rawSight!);
    final w = metric ? rawWind! : UnitSystem.mphToMps(rawWind!);
    // With wind, the direction must be typed: no silent default.
    if (w > 0 && _windHourValue == null) {
      _error(
        'Rüzgâr yönünü girin: rüzgârın geldiği saat, 1–12 (hedef saat 12).',
      );
      return;
    }
    final wd = rawWindDirection!;
    final temp = metric
        ? rawTemperature!
        : UnitSystem.fahrenheitToCelsius(rawTemperature!);
    final hum = rawHumidity!;
    final alt = metric ? rawAltitude! : UnitSystem.feetToMeters(rawAltitude!);
    // Denetim F1 (2026-10-14): an empty Basınç with a typed İrtifa is the
    // ISA station pressure at that altitude, not 1013,25 hPa. A typed
    // pressure always wins; both empty stays the standard atmosphere.
    final pressureFromAltitude =
        pressure.text.trim().isEmpty && altitudeBox.text.trim().isNotEmpty;
    final pres = pressureFromAltitude
        ? FieldCalc.stationPressureHpa(1013.25, alt)
        : metric
        ? rawPressure!
        : UnitSystem.inHgToHpa(rawPressure!);

    if (v <= 0 ||
        g <= 0 ||
        z <= 0 ||
        s < 0 ||
        w < 0 ||
        wd < 0 ||
        wd > 360 ||
        !pres.isFinite ||
        pres <= 0 ||
        hum < 0 ||
        hum > 100 ||
        temp <= -273.15) {
      _error(
        'Balistik ve atmosfer alanlarını kontrol edin; nem %0–100, rüzgâr yönü saat 1–12 olmalı.',
      );
      return;
    }

    try {
      // DopeRanges receives values in the unit currently shown by the UI.
      // Keep its guardrail equivalent to the canonical 3000 m production
      // limit instead of accidentally treating 2000/3000 yards as metres.
      final displayMaxRange = _displayMaxRange;
      final enteredRanges = DopeRanges.parse(
        ranges.text,
        maxRangeM: displayMaxRange,
      );
      final requestedRanges = _yards
          ? enteredRanges.map(UnitSystem.yardsToMeters).toList()
          : enteredRanges;
      final environment = EnvironmentData(
        temperatureC: temp,
        pressureHpa: pres,
        humidityPercent: hum,
        altitudeM: alt,
        windMps: w,
        windDirectionDeg: wd,
      );
      // Barut sıcaklığı (firearms): today's velocity from the profile
      // velocity; the zero stays solved with the zeroing-day velocity.
      // PCP tüp basıncı: the velocity at the profile's Tüp basıncı (the Pro
      // box only with PRO_TUBE_PRESSURE); a firearm never changes here.
      final vPowder = _powderAdjusted(v, temp);
      final pcp = _pcpVelocity(vPowder);
      final vToday = pcp?.mps ?? vPowder;
      // Denetim F3 (2026-10-14): an unregulated PCP whose table gives the
      // velocity at the Profil tube pressure (#284) is zeroed and shot with
      // that same velocity, so it is on zero at its own zero range. The Pro
      // "Kalan tüp basıncı" (PRO_TUBE_PRESSURE, hidden) keeps the old split.
      final pcpTableAtProfilePressure =
          !_showProTubePressure &&
          pcp != null &&
          pcp.fromTable &&
          !pcp.regulatorBypassed;
      final double? vZero = pcpTableAtProfilePressure || vToday == v ? null : v;
      final density = Atmosphere.densityKgM3(environment);
      final ratio = Atmosphere.densityRatio(environment);
      final sound = Atmosphere.speedOfSoundMps(environment);
      final mach = Atmosphere.machNumber(
        velocityMps: vToday,
        environment: environment,
      );

      // A BC is consumed only together with its drag law and only while the
      // grain still matches the ammunition it was entered for. Otherwise the
      // labelled vacuum baseline runs and says so.
      final ammo = ammunition;
      final useBc = _bcApplies();
      final bc = useBc ? ammo!.ballisticCoefficient : null;
      final model = useBc ? ammo!.ballisticModel : null;
      final bands = useBc ? ammo!.bcBands : const <BcBand>[];
      final dragTable = useBc ? ammo!.dragTable : null;
      final input = BallisticInput(
        muzzleVelocityMps: vToday,
        grain: g,
        zeroRangeM: z,
        sightHeightMm: s,
        rangesM: requestedRanges,
        environment: environment,
        ballisticCoefficient: bc,
        ballisticModel: model,
        bcBands: bands,
        dragTable: dragTable,
        zeroMuzzleVelocityMps: vZero,
        gravityMps2: _gravity,
      );
      final solved = const BallisticEngine().solveReachable(input);
      if (solved.points.isEmpty) {
        _error(
          'Bu girdilerle çözüm bulunamadı: mermi sıfır mesafesine veya '
          'istenen mesafelere ulaşamıyor. Hız, BC ve mesafeleri kontrol edin.',
        );
        return;
      }
      final warnings = bc == null
          ? <DragWarning>[]
          : DragSafety.assess(
              muzzleVelocityMps: vToday,
              environment: environment,
              ballisticCoefficient: bc,
              ballisticModel: model,
              platform: ammo!.platform,
            );

      setState(() {
        points = solved.points;
        _unreachableM = solved.unreachableM;
        _warnings = warnings;
        airDensityKgM3 = density;
        densityRatio = ratio;
        speedOfSoundMps = sound;
        muzzleMach = mach;
        _pressureEstimated = pressureFromAltitude;
        _basis = _ShotBasis(
          velocityMps: vToday,
          grain: g,
          zeroRangeM: z,
          sightHeightMm: s,
          environment: environment,
          ballisticCoefficient: bc,
          ballisticModel: model,
          bcBands: bands,
          dragTable: dragTable,
          zeroVelocityMps: vZero,
          gravityMps2: input.gravityMps2,
        );
      });
    } on FormatException catch (e) {
      _error(e.message);
    } on ArgumentError catch (e) {
      // The validators' messages are English developer text: show the
      // Turkish field name only.
      _error(InputErrorText.of(e, fallback: 'Balistik girdileri geçersiz.'));
    } on UnsupportedError {
      _error('Bu balistik model henüz desteklenmiyor.');
    } on StateError {
      _error(
        'Sürtünmeli çözüm bulunamadı; hız, sıfır mesafesi ve BC uyumsuz olabilir.',
      );
    }
  }

  @override
  void deactivate() {
    // Hava Durumu values carry over to the next workspace (owner,
    // 2026-10-10: "bu değerler hesaba otomatik girer"; 2026-10-12: the wind
    // must not come back empty). Saved here, not in dispose: a re-keyed
    // workspace is deactivated before its successor's initState, but
    // disposed only after it.
    widget.environmentCarry?._save(this);
    super.deactivate();
  }

  @override
  void dispose() {
    ShotSettingsStore.changes.removeListener(_reloadShotSettings);
    WidgetsBinding.instance.removeObserver(this);
    _freshnessTimer?.cancel();
    _cancelPhoneAltitudeWarmUp();
    unawaited(_watchRanges?.cancel());
    _watchTimer?.cancel();
    velocity.dispose();
    grain.dispose();
    zero.dispose();
    sight.dispose();
    wind.dispose();
    windDirection.dispose();
    windHour.dispose();
    temperature.dispose();
    pressure.dispose();
    humidity.dispose();
    altitude.dispose();
    mapAltitude.dispose();
    ranges.dispose();
    latitudeCtl.dispose();
    azimuthCtl.dispose();
    turretScaleCtl.dispose();
    bulletLengthCtl.dispose();
    powderCoefCtl.dispose();
    tubePressureCtl.dispose();
    powderTempCtl.dispose();
    ShotSettingsStore.externalWrites.removeListener(_onExternalShotSettings);
    ammoTempCtl.dispose();
    proRangeCtl.dispose();
    for (final c in [
      windMidCtl,
      windFarCtl,
      zeroUpCtl,
      zeroRightCtl,
      groupCtl,
      sdCtl,
      targetSizeCtl,
      rangeErrorCtl,
      bcErrorCtl,
    ]) {
      c.dispose();
    }
    windMaxCtl.dispose();
    targetSpeedCtl.dispose();
    gravityCtl.dispose();
    super.dispose();
  }

  void _error(String message) {
    if (_silentErrors) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // -------------------------------------------------------------------------
  // Shot (single range) evaluation of the last validated inputs.
  // -------------------------------------------------------------------------

  /// Distances in yards: a yard profile (owner, 2026-10-09) or the legacy
  /// imperial setting. Everything is still solved in metres.
  bool get _profileYards => widget.profile?.distanceUnit == DistanceUnit.yard;
  bool get _yards => !metric || _profileYards;

  String get _distanceUnit => _yards ? 'yd' : 'm';

  double get _displayMaxRange => _yards
      ? UnitSystem.metersToYards(ProductionLimits.maxRangeM)
      : ProductionLimits.maxRangeM;

  double _toDisplayRange(double meters) =>
      _yards ? UnitSystem.metersToYards(meters) : meters;
  double _fromDisplayRange(double value) =>
      _yards ? UnitSystem.yardsToMeters(value) : value;

  int get _shotDisplay => _toDisplayRange(_shotRangeM).round();

  void _setShotDisplay(num display) {
    final clamped = display
        .toDouble()
        .clamp(1.0, _displayMaxRange.floorToDouble())
        .toDouble();
    setState(
      () => _shotRangeM = math.min(
        _fromDisplayRange(clamped),
        ProductionLimits.maxRangeM,
      ),
    );
  }

  /// Same engine call as the table, evaluated at one range. Returns null
  /// until a solve has succeeded (fail closed: no basis, no numbers). In drag
  /// mode it also yields the crosswind (m/s) that moves the impact 1 mil at
  /// this range. Results are cached per range because the build method asks
  /// for them on every frame (slider drags).
  ({TrajectoryPoint? shot, double? mpsPerMil}) _evalShot() {
    final basis = _basis;
    if (basis == null) return (shot: null, mpsPerMil: null);
    final cached = _shotCache[_shotRangeM];
    if (cached != null) return cached;
    _zoneShares.remove(_shotRangeM);
    TrajectoryPoint? shot;
    double? mpsPerMil;
    try {
      final input = basis.input(
        [_shotRangeM],
        inclineDeg: _inclineDeg,
        cantDeg: _cantDeg,
        latitudeDeg: _coriolisArgs.lat,
        azimuthDeg: _coriolisArgs.az,
        windZones: basis.drag ? _windZones : null,
      );
      shot = const BallisticEngine().solve(input).first;
      if (basis.drag) {
        mpsPerMil = ReticleHolds.crosswindForMil(
          base: input,
          rangeM: _shotRangeM,
          mil: 1,
        );
      }
    } on ArgumentError {
      shot = null;
    } on UnsupportedError {
      shot = null;
    } on StateError {
      shot = null;
    }
    if (_shotCache.length > 24) _shotCache.clear();
    return _shotCache[_shotRangeM] = (shot: shot, mpsPerMil: mpsPerMil);
  }

  TrajectoryPoint? _shotPoint() => _evalShot().shot;

  /// Rüzgâr etkisi shares per range; an entry is dropped whenever
  /// [_evalShot] solves that range again (inputs changed).
  final Map<double, WindZoneShares?> _zoneShares = {};

  WindZoneShares? _windZoneSharesAt(_ShotBasis basis) {
    _evalShot();
    if (_zoneShares.containsKey(_shotRangeM)) return _zoneShares[_shotRangeM];
    WindZoneShares? s;
    try {
      s = WindZoneShares.compute(
        basis.input([_shotRangeM], inclineDeg: _inclineDeg),
        _shotRangeM,
      );
    } on ArgumentError {
      s = null;
    }
    if (_zoneShares.length > 24) _zoneShares.clear();
    return _zoneShares[_shotRangeM] = s;
  }

  Future<void> _editShotRange() async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _RangeDialog(initial: _shotDisplay, unit: _distanceUnit),
    );
    if (!mounted || result == null) return;
    if (!result.isFinite || result <= 0 || result > _displayMaxRange) {
      _error(
        'Mesafe 0 ile ${_displayMaxRange.toStringAsFixed(0)} $_distanceUnit arasında olmalı.',
      );
      return;
    }
    _setShotDisplay(result.round());
  }

  // -------------------------------------------------------------------------
  // Fail-closed states
  // -------------------------------------------------------------------------

  Widget _blocked(String message) {
    final body = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
    if (widget.view != BallisticsView.all) return body;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Balistik / DOPE'),
      body: body,
    );
  }

  /// Rüzgâr aralığı and hareketli hedef lines under the scope (owner,
  /// 2026-10-09). Empty unless set on Pro Ayarlar.
  List<Widget> _extraShotNotes(TrajectoryPoint? shot) {
    final basis = _basis;
    final click = _scopeClickValue;
    if (shot == null || basis == null) return const [];
    final c = MenzilColors.of(context);
    final unit = _scopeUnit;
    String clicks(double mrad) => click == null
        ? '${unit.fromMrad(mrad.abs()).toStringAsFixed(2).replaceAll('.', ',')} ${unit.label}'
        : '${(unit.fromMrad(mrad.abs()) / click / _turretScale).round()} klik';
    final lines = <Widget>[..._flightWarnings(shot, basis)];
    final windMax = _windMaxMps;
    final wind = basis.environment.windMps;
    if (basis.drag && windMax != null && windMax > wind) {
      final args = _coriolisArgs;
      // With wind zones the gust is taken to strengthen every zone by the
      // same ratio, so the bracket stays consistent with the shot itself.
      final z = _windZones;
      final gust = wind > 0 ? windMax / wind : null;
      try {
        final hi = const BallisticEngine()
            .solve(
              basis.input(
                [_shotRangeM],
                inclineDeg: _inclineDeg,
                cantDeg: _cantDeg,
                latitudeDeg: args.lat,
                azimuthDeg: args.az,
                windMps: windMax,
                windZones: z == null || gust == null
                    ? null
                    : WindZones(
                        rangeM: z.rangeM,
                        midMps: math.min(z.midMps * gust, 60.0),
                        farMps: math.min(z.farMps * gust, 60.0),
                      ),
              ),
            )
            .single;
        // windMrad > 0: dial RIGHT (the shot went left). Same windage as
        // the turret: spin drift and the right zero offset are taken off
        // (audit 2026-10-11).
        String side(double m) => m.abs() < 1e-9 ? '' : (m > 0 ? ' R' : ' L');
        final off = (_spinDriftMrad(shot, basis) ?? 0) + _zeroOffsetMrad.right;
        final lo = shot.windMrad - off, up = hi.windMrad - off;
        lines.add(
          Text(
            'Rüzgâr ${_windLabel(wind)}–${_windLabel(windMax)} '
            '${metric ? 'm/s' : 'mph'}: yan düzeltme '
            '${clicks(lo)}${side(lo)} – '
            '${clicks(up)}${side(up)}.',
            key: const Key('shot-wind-bracket'),
            style: MenzilType.body(c.ink),
          ),
        );
      } on ArgumentError {
        // Out-of-range wind: no bracket line.
      } on StateError {
        // Unreachable at that wind: no bracket line.
      }
    }
    // Ö2: where along the path the wind matters (a result, not help text).
    final shares = basis.drag ? _windZoneSharesAt(basis) : null;
    if (shares != null) {
      lines.add(
        Text(
          'Rüzgâr etkisi: yakın %${shares.nearPct} · '
          'orta %${shares.midPct} · uzak %${shares.farPct}',
          key: const Key('shot-wind-zone-shares'),
          style: MenzilType.body(c.ink),
        ),
      );
    }
    final spin = _spinDriftMrad(shot, basis);
    if (spin != null) {
      final m = math.tan(spin.abs() / 1000) * _shotRangeM;
      final len = metric
          ? '${(m * 100).toStringAsFixed(1).replaceAll('.', ',')} cm'
          : '${UnitSystem.millimetersToInches(m * 1000).toStringAsFixed(1).replaceAll('.', ',')} in';
      final jump = _aeroJumpMrad(basis);
      final jm = jump == null ? 0.0 : math.tan(jump.abs() / 1000) * _shotRangeM;
      final jLen = metric
          ? '${(jm * 100).toStringAsFixed(1).replaceAll('.', ',')} cm'
          : '${UnitSystem.millimetersToInches(jm * 1000).toStringAsFixed(1).replaceAll('.', ',')} in';
      lines.add(
        Text(
          'Spin drift: $len ${spin >= 0 ? 'sağa' : 'sola'}'
          '${jump == null || jm < 0.0005 ? '' : '; rüzgâr sıçraması: $jLen ${jump >= 0 ? 'yukarı' : 'aşağı'}'}'
          '. Kule klikleri bunu içerir.',
          key: const Key('shot-spin-drift'),
          style: MenzilType.body(c.ink),
        ),
      );
    }
    final wez = _hitProbability(shot, basis);
    if (wez != null) {
      final pct = (wez.result.probability * 100).round();
      final pctN =
          (Wez.seriesHitProbability(
                    sources: wez.sources,
                    targetRadiusMrad: wez.radiusMrad,
                    shotCount: _wezShotCount,
                  ) *
                  100)
              .round();
      lines.add(
        Row(
          key: const Key('shot-wez'),
          children: [
            SizedBox.square(
              dimension: 120,
              child: CustomPaint(
                key: const Key('shot-wez-target'),
                painter: _WezPainter(
                  impacts: wez.result.impacts,
                  radiusMrad: wez.radiusMrad,
                  colors: c,
                ),
              ),
            ),
            const SizedBox(width: MenzilSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('%$pct', style: MenzilType.display(c.amber, size: 34)),
                  Text(
                    'İlk atış isabet olasılığı: %$pct '
                    '(Ø${wez.sizeText} hedef, $_shotDisplay $_distanceUnit).',
                    key: const Key('shot-hit-probability'),
                    style: MenzilType.body(c.ink),
                  ),
                  if (_wezShotCount > 1)
                    Text(
                      '$_wezShotCount atışta en az bir isabet: %$pctN.',
                      key: const Key('shot-hit-probability-n'),
                      style: MenzilType.body(c.ink),
                    ),
                  if (wez.result.dominant != null)
                    Text(
                      'En büyük etken: ${wez.result.dominant!.name}.',
                      key: const Key('shot-wez-dominant'),
                      style: MenzilType.caption(c.ink2),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final speed = _targetSpeedMps;
    final movesRight = _targetMovesRight;
    if (speed != null && movesRight == null) {
      lines.add(
        Text(
          'Hareketli hedef: Pro Ayarlar\'da hedefin yönünü seçin.',
          key: const Key('shot-lead'),
          style: MenzilType.body(c.ink),
        ),
      );
    }
    if (speed != null && movesRight != null) {
      final leadM = speed * shot.timeOfFlightS;
      final mrad = math.atan(leadM / _shotRangeM) * 1000;
      final len = metric
          ? '${(leadM * 100).toStringAsFixed(0).replaceAll('.', ',')} cm'
          : '${UnitSystem.millimetersToInches(leadM * 1000).toStringAsFixed(1).replaceAll('.', ',')} in';
      lines.add(
        Text(
          'Hareketli hedef (${_windLabel(speed)} ${metric ? 'm/s' : 'mph'}, '
          '${movesRight ? 'soldan sağa' : 'sağdan sola'}): '
          '$len · ${clicks(mrad)} ${movesRight ? 'sağına' : 'soluna'} '
          'nişan alın (uçuş ${shot.timeOfFlightS.toStringAsFixed(2).replaceAll('.', ',')} s).',
          key: const Key('shot-lead'),
          style: MenzilType.body(c.ink),
        ),
      );
    }
    if (lines.isEmpty) return const [];
    return [
      const SizedBox(height: MenzilSpace.sm),
      for (final l in lines) ...[l, const SizedBox(height: MenzilSpace.xs)],
    ];
  }

  /// DOPE kartı rows for the active profile in today's conditions: level,
  /// no Coriolis; clicks include the zero offset and the turret scale.
  /// [v] with [digits] decimals, without a minus on a value that rounds to
  /// zero ("-0.00" at the zero range read as a wrong-way correction).
  static String _fixed(double v, int digits) {
    final s = v.toStringAsFixed(digits);
    final t = s.startsWith('-') && double.parse(s) == 0 ? s.substring(1) : s;
    return t.replaceAll('.', ',');
  }

  DopeCardData? _dopeCardData() {
    final basis = _basis;
    final s = scope;
    final click = _scopeClickValue;
    final p = widget.profile;
    if (basis == null || s == null || click == null || p == null) return null;
    final unit = _scopeUnit;
    final firearm = _isFirearm;
    final shown = firearm
        ? [for (var r = 100; r <= 1000; r += 50) r.toDouble()]
        : [for (var r = 10; r <= 150; r += 10) r.toDouble()];
    final ranges = [
      for (final r in shown)
        if (_fromDisplayRange(r) <= ProductionLimits.maxRangeM)
          _fromDisplayRange(r),
    ];
    const engine = BallisticEngine();
    final solved = engine.solveReachable(basis.input(ranges));
    if (solved.points.isEmpty) return null;
    final windMps = metric ? 3.0 : UnitSystem.mphToMps(5);
    final windByRange = <double, double>{};
    if (basis.drag) {
      try {
        final w = engine.solveReachable(
          basis.input(ranges, windMps: windMps, windDirectionDeg: 90),
        );
        for (final pt in w.points) {
          windByRange[pt.rangeM] = pt.windMrad;
        }
      } on ArgumentError {
        // No wind column.
      }
    }
    final zeroOff = _zeroOffsetMrad;
    final scale = _turretScale;
    String num1(double v) => _fixed(v, unit.moaFamily ? 1 : 2);
    final rows = <List<String>>[];
    for (final pt in solved.points) {
      final up = unit.fromMrad(pt.correctionMrad - zeroOff.up) / scale;
      final clicks = (up / click).round();
      final w = windByRange[pt.rangeM];
      final wClicks = w == null
          ? '—'
          : (unit.fromMrad(w.abs()) / click / scale).round().toString();
      rows.add([
        _toDisplayRange(pt.rangeM).round().toString(),
        num1(up),
        '${clicks >= 0 ? '↑' : '↓'} ${clicks.abs()}',
        wClicks,
        UnitSystem.mpsToFps(pt.velocityMps).toStringAsFixed(0),
      ]);
    }
    final ammo = ammunition;
    final env = basis.environment;
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return DopeCardData(
      title: p.name,
      info: [
        ('Tüfek', profileResolution?.rifle.displayName ?? '—'),
        ('Mühimmat', ammo?.displayName ?? '—'),
        if (basis.drag)
          (
            'BC',
            '${_decimal(basis.ballisticCoefficient)} '
                '${basis.ballisticModel!.name.toUpperCase()}',
          ),
        (
          'Hız',
          '${UnitSystem.mpsToFps(basis.velocityMps).toStringAsFixed(0)} fps',
        ),
        (
          'Sıfır',
          '${_toDisplayRange(basis.zeroRangeM).round()} $_distanceUnit',
        ),
        ('Dürbün', '${unit.label}, ${_decimal(click)} ${unit.label}/klik'),
        (
          'Hava',
          '${metric ? '${env.temperatureC.toStringAsFixed(0)} °C' : '${UnitSystem.celsiusToFahrenheit(env.temperatureC).toStringAsFixed(0)} °F'}, '
              '${env.pressureHpa.toStringAsFixed(0)} hPa, '
              'nem %${env.humidityPercent.toStringAsFixed(0)}',
        ),
        (
          'Tarih',
          '${two(now.day)}.${two(now.month)}.${now.year} '
              '${two(now.hour)}:${two(now.minute)}',
        ),
      ],
      headers: [
        'Mesafe ($_distanceUnit)',
        'Yukarı (${unit.label})',
        'Klik',
        'Yan rüzgâr ${metric ? '3 m/s' : '5 mph'} (klik)',
        'Hız (fps)',
      ],
      rows: rows,
      notes: [
        'Değerler yukarıdaki hava koşullarıyla hesaplandı; sıcaklık ve basınç '
            'değişirse uzak mesafede kayar.',
        'Yan rüzgâr sütunu saat 3 veya 9 yönünden tam yan rüzgâr içindir: '
            'rüzgâr sağdan esiyorsa sağa, soldan esiyorsa sola çevirin.',
        if (zeroOff.up != 0 || zeroOff.right != 0)
          'Sıfır ofseti kliklere dahildir.',
        if (scale != 1)
          'Kule ölçek katsayısı (${_decimal(scale)}) kliklere dahildir.',
        if (!basis.drag)
          'BC girilmediği için hava direnci yok sayıldı; uzak mesafede gerçek '
              'düşüş daha fazladır.',
        if (solved.unreachableM.isNotEmpty)
          'Mermi ${_toDisplayRange(solved.unreachableM.first).round()} '
              '$_distanceUnit ve ötesine ulaşamıyor.',
        'İlk atışta mutlaka canlı atışla doğrulayın.',
      ],
    );
  }

  Future<void> _shareDopeCard() async {
    final data = _dopeCardData();
    if (data == null) {
      _error('DOPE kartı için önce bir çözüm gerekiyor.');
      return;
    }
    try {
      final bytes = await buildDopeCardPdf(
        data,
        // The PDF keeps Oswald (owner, 2026-10-11; the screens use the
        // system font since 2026-10-13); DejaVu only for the arrows Oswald
        // lacks. The logo heads the card and fades behind it.
        regular: await rootBundle.load('assets/fonts/Oswald-Regular.ttf'),
        bold: await rootBundle.load('assets/fonts/Oswald-Medium.ttf'),
        fallback: await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
        logo: (await rootBundle.load(
          'assets/branding/logo_line.png',
        )).buffer.asUint8List(),
      );
      final name =
          'sniper-turk-dope-${widget.profile!.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.pdf';
      final share = BallisticsScreenTestHooks.sharePdf;
      if (share != null) {
        await share(bytes, name);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: name);
      }
    } catch (_) {
      if (mounted) _error('DOPE kartı oluşturulamadı.');
    }
  }

  /// Chance that one shot lands inside the 10 cm target ring (owner,
  /// 2026-10-09): rifle group (5-shot extreme spread at the zero range,
  /// sigma = ES / 3.067), velocity SD (vertical, from a solve at v + SD) and
  /// the wind bracket (horizontal, half the bracket as one sigma). Elliptic
  /// Gaussian approximated by P = 1 − exp(−R² / (2·σx·σy)). Null without a
  /// group size.
  /// WEZ: every error source as a spread on the target, then [Wez.simulate].
  ({
    WezResult result,
    List<WezSource> sources,
    double radiusMrad,
    String sizeText,
  })?
  _hitProbability(TrajectoryPoint shot, _ShotBasis basis) {
    final zero = widget.profile?.zeroRangeM;
    final g = _parsed(groupCtl);
    if (zero == null || zero <= 0 || g == null || g <= 0 || g > 100) {
      return null;
    }
    double lenM(double v) =>
        metric ? v / 100 : UnitSystem.inchesToMillimeters(v) / 1000;
    final sources = <WezSource>[];
    final sigmaG = Wez.groupSigmaMrad(lenM(g), zero);
    sources.add(
      WezSource('grup (tüfek ve nişancı)', sigmaX: sigmaG, sigmaY: sigmaG),
    );
    final args = _coriolisArgs;
    // Vertical correction (mrad) with one input changed; null = unsolvable.
    double? corr({double? range, double? velocity, double? bcScale}) {
      try {
        var input = basis.input(
          [range ?? _shotRangeM],
          inclineDeg: _inclineDeg,
          cantDeg: _cantDeg,
          latitudeDeg: args.lat,
          azimuthDeg: args.az,
          shotVelocityMps: velocity,
        );
        if (bcScale != null && input.ballisticCoefficient != null) {
          input = input.withBallisticCoefficient(
            input.ballisticCoefficient! * bcScale,
          );
        }
        return const BallisticEngine().solve(input).single.correctionMrad;
      } on ArgumentError {
        return null;
      } on StateError {
        return null;
      }
    }

    final base = corr();
    final sdFps = _parsed(sdCtl);
    if (base != null && sdFps != null && sdFps > 0 && sdFps <= 200) {
      final fast = corr(
        velocity: basis.velocityMps + UnitSystem.fpsToMps(sdFps),
      );
      if (fast != null) {
        sources.add(WezSource('hız farkı (SD)', sigmaY: (fast - base).abs()));
      }
    }
    final typedRangeErr = _parsed(rangeErrorCtl);
    final rangeErr = typedRangeErr == null
        ? 1.0
        : (_yards ? UnitSystem.yardsToMeters(typedRangeErr) : typedRangeErr);
    if (base != null && rangeErr > 0 && rangeErr < 100) {
      final far = corr(range: _shotRangeM + Wez.sigmaOfPlusMinus(rangeErr));
      if (far != null) {
        sources.add(
          WezSource('mesafe hatası', sigmaY: (far - base).abs(), shared: true),
        );
      }
    }
    final bcErr = _parsed(bcErrorCtl);
    if (base != null &&
        basis.drag &&
        bcErr != null &&
        bcErr > 0 &&
        bcErr < 50) {
      final low = corr(bcScale: 1 - Wez.sigmaOfPlusMinus(bcErr) / 100);
      if (low != null) {
        sources.add(
          WezSource('BC hatası', sigmaY: (low - base).abs(), shared: true),
        );
      }
    }
    final windMax = _windMaxMps;
    final mpsPerMil = basis.drag ? _evalShot().mpsPerMil : null;
    final wind = basis.environment.windMps;
    if (windMax != null &&
        windMax > wind &&
        mpsPerMil != null &&
        mpsPerMil > 0) {
      sources.add(
        WezSource(
          'rüzgâr belirsizliği',
          sigmaX: (windMax - wind) / 2 / mpsPerMil,
          shared: true,
        ),
      );
    }
    final typedSize = _parsed(targetSizeCtl);
    final size = typedSize != null && typedSize > 0 && typedSize < 1000
        ? typedSize
        : (metric ? 10.0 : 4.0);
    final radius = math.atan(lenM(size) / 2 / _shotRangeM) * 1000;
    final sizeText =
        '${size % 1 == 0 ? size.toStringAsFixed(0) : _decimal(size)} '
        '${metric ? 'cm' : 'in'}';
    return (
      result: Wez.simulate(sources: sources, targetRadiusMrad: radius),
      sources: List<WezSource>.unmodifiable(sources),
      radiusMrad: radius,
      sizeText: sizeText,
    );
  }

  String _windLabel(double mps) => (metric ? mps : UnitSystem.mpsToMph(mps))
      .toStringAsFixed(1)
      .replaceAll('.', ',');

  /// Half of the scope's total adjustment travel, in clicks, or null when
  /// the travel is not known. No travel is ever guessed: the old 30 mrad
  /// fallback made "Kule yetmez" appear far too late.
  int? _halfTravelClicks(double clickValue, double? totalTravelMrad) {
    if (totalTravelMrad == null || totalTravelMrad <= 0) return null;
    final mrad = totalTravelMrad / 2;
    final inUnit = _scopeUnit.fromMrad(mrad);
    return math.max(1, (inUnit / clickValue).floor());
  }

  /// Drum limit when the travel is unknown: the turret simply keeps turning.
  static const int _unknownTravelClicks = 100000;

  _ShotBasis? _zeroAngleBasis;
  double? _zeroAngleMradCache;

  /// The zero's bore angle above the sight line in whole turret clicks
  /// (nearest; denetim F2). Solved once per basis; 0 when it cannot be.
  int _zeroAngleClicks(_ShotBasis basis, double click, AngularUnit unit) {
    if (!identical(basis, _zeroAngleBasis)) {
      _zeroAngleBasis = basis;
      try {
        _zeroAngleMradCache = const BallisticEngine().zeroAngleMrad(
          basis.input([basis.zeroRangeM]),
        );
      } on ArgumentError {
        _zeroAngleMradCache = null;
      } on StateError {
        _zeroAngleMradCache = null;
      }
    }
    final mrad = _zeroAngleMradCache;
    if (mrad == null || !mrad.isFinite) return 0;
    return (unit.fromMrad(mrad) / click).round();
  }

  /// Elevation correction from 1 m out to the farthest reachable range of
  /// the current basis (drag or vacuum), sampled once per solve.
  /// Hold-label samples on the turret's scale (audit 2026-10-11): the
  /// reticle labels must agree with the turret solution, which subtracts the
  /// zero offset and aerodynamic jump ([offsetMrad]) and divides by the
  /// turret scale. A mark m holds where the true correction equals
  /// scale × dialled + m, i.e. where the sample below equals dialled + m.
  List<CorrectionSample> _holdSamplesFor(
    _ShotBasis basis,
    AngularUnit unit, {
    double offsetMrad = 0,
    double scale = 1,
    double dialedUp = 0,
  }) {
    if (!identical(basis, _holdSamplesBasis) || _holdSamples == null) {
      List<TrajectoryPoint> points;
      try {
        points = ReticleHolds.sample(
          basis.input(
            const [1],
            inclineDeg: _inclineDeg,
            cantDeg: _cantDeg,
            latitudeDeg: _coriolisArgs.lat,
            azimuthDeg: _coriolisArgs.az,
          ),
        );
      } on ArgumentError {
        points = const [];
      } on UnsupportedError {
        points = const [];
      }
      _holdSamples = points;
      _holdSamplesBasis = basis;
    }
    final shift = unit.fromMrad(offsetMrad) + (scale - 1) * dialedUp;
    return [
      for (final p in _holdSamples!)
        if (shift == 0)
          ScopeDialMath.sampleOf(p, unit)
        else
          CorrectionSample(
            p.rangeM,
            ScopeDialMath.sampleOf(p, unit).correction - shift,
          ),
    ];
  }

  // ---- Saat (owner, 2026-10-11) -----------------------------------------
  // The watch only shows what Atış shows; it never computes. Nothing
  // happens without a watch (WatchBridge is silent then).

  StreamSubscription<int>? _watchRanges;
  Timer? _watchTimer;

  /// Last solution sent from Atış; null while Atış is not shown.
  WatchSolution? _watchLast;

  bool _isShotView(BallisticsView v) =>
      v == BallisticsView.shot || v == BallisticsView.all;

  /// Atış is not showing a turret correction: the watch shows "Çözüm yok"
  /// instead of old clicks (inputs may be changing on Hava/Pro).
  void _withdrawWatch() {
    final p = widget.profile;
    _watchLast = null;
    if (p == null) return;
    final s = WatchSolution.none(profile: p.name, at: DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(WatchBridge.instance.publish(s));
    });
  }

  /// Sends the Atış turret correction (scope unit, + up / + right) to the
  /// watch after this frame. [up] is null without a solved shot.
  void _publishWatch(double? up, double right, double click) {
    final s = _watchSolution(up, right, click);
    if (s == null) return;
    _watchLast = s.ok ? s : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(WatchBridge.instance.publish(s));
    });
  }

  WatchSolution? _watchSolution(double? up, double right, double click) {
    final p = widget.profile;
    if (p == null) return null;
    final now = DateTime.now();
    if (up == null || !up.isFinite || !right.isFinite) {
      return WatchSolution.none(profile: p.name, at: now);
    }
    final basis = _basis;
    final windMps = basis != null && basis.drag
        ? basis.environment.windMps
        : 0.0;
    try {
      return WatchSolution(
        ok: true,
        profile: p.name,
        range: _shotDisplay,
        rangeUnit: _distanceUnit,
        rangeStep: _isFirearm ? 10 : 5,
        up: ScopeDialMath.clicksFor(up, click),
        right: ScopeDialMath.clicksFor(right, click),
        upAngle: up,
        rightAngle: right,
        unit: _scopeUnit.label,
        click: click,
        windSpeed: windMps > 0
            ? (metric ? windMps : UnitSystem.mpsToMph(windMps))
            : null,
        windUnit: metric ? 'm/s' : 'mph',
        windClock: windMps > 0 && basis != null
            ? WindClock.fromDegrees(basis.environment.windDirectionDeg)
            : null,
        at: now,
      );
    } on ArgumentError {
      return WatchSolution.none(profile: p.name, at: now);
    }
  }

  /// A distance picked on the watch: same path as the Hedef slider. The
  /// new solution goes back when Atış rebuilds (the scope view is where
  /// the turret correction is computed).
  void _onWatchRange(int display) {
    if (mounted) _setShotDisplay(display);
  }

  /// Interactive scope: turrets change the dialled clicks and the reticle
  /// shows where the shot lands at the selected range. In drag mode the
  /// required windage and the crosswind labels come from the drag solver;
  /// the vacuum baseline has no wind model, so its required windage is 0.
  Widget _scopeDial(TrajectoryPoint? shot) {
    final s = scope;
    final click = _scopeClickValue;
    if (s == null || click == null) {
      _withdrawWatch();
      return const MenzilNotice(
        tone: MenzilNoticeTone.warning,
        message:
            'Bu dürbünün klik değeri katalogda yok; kule simülasyonu '
            'gösterilemiyor. Dürbünü Profil sekmesinden kontrol edin.',
      );
    }
    final unit = _scopeUnit;
    final basis = _basis;
    double inUnit(double mrad) => unit.fromMrad(mrad);
    // Sıfır ofseti: a group that sat high/right at the zero lands
    // high/right everywhere, so less up / more left is needed. Aerodynamic
    // jump lifts or drops the shot the same way (owner, 2026-10-09).
    final zeroOff = _zeroOffsetMrad;
    final jump = shot == null || basis == null ? null : _aeroJumpMrad(basis);
    final requiredUp = shot == null
        ? null
        : inUnit(shot.correctionMrad - zeroOff.up - (jump ?? 0)) / _turretScale;
    // windMrad = atan2(-z, range): the correction toward the RIGHT turret
    // direction, with the solver's +z drawn to the right of the crosshair.
    // Without drag (!basis.drag) it holds only the scope-cant part (wind is
    // not modelled there), so it is 0.0 unless the scope is canted.
    // Kule ölçek katsayısı: a turret that moves 0.98 of its marking needs
    // 1/0.98 of the clicks (owner, 2026-10-09).
    final scale = _turretScale;
    // Spin drift (Pro, owner 2026-10-09): a drift to the right needs LEFT.
    final spin = shot == null || basis == null
        ? null
        : _spinDriftMrad(shot, basis);
    final requiredRight = (shot == null || basis == null)
        ? 0.0
        : inUnit(shot.windMrad - (spin ?? 0) - zeroOff.right) / scale;
    // Saat: the same numbers go to the watch (it never computes).
    _publishWatch(requiredUp, requiredRight, click);

    final mpsPerMil = basis != null && basis.drag
        ? _evalShot().mpsPerMil
        : null;
    final windMpsPerUnit = mpsPerMil == null
        ? null
        : mpsPerMil * unit.mradPerUnit;
    // What one reticle unit spans at the selected range.
    final unitSpanM = ScopeDialMath.linearAtRange(1, _shotRangeM, unit);
    final span = metric
        ? '${(unitSpanM * 100).toStringAsFixed(1).replaceAll('.', ',')} cm'
        : '${UnitSystem.millimetersToInches(unitSpanM * 1000).toStringAsFixed(1).replaceAll('.', ',')} in';
    final scaleNote =
        '1 ${unit.label} = $span '
        '($_shotDisplay $_distanceUnit).';
    String? windNote;
    final windMps = basis?.environment.windMps ?? 0;
    if (basis != null && basis.drag && windMps > 0) {
      final dir = basis.environment.windDirectionDeg;
      final hour = WindClock.fromDegrees(dir);
      final from = 'saat $hour, ${WindClock.side(hour)}';
      windNote =
          'Rüzgâr ${_windLabel(windMps)} ${metric ? 'm/s' : 'mph'}, '
          '($from) ile hesaplandı.';
    }

    final minMag = s.minMagnification ?? 0, maxMag = s.maxMagnification ?? 0;
    final zoom = minMag > 0 && maxMag >= minMag;
    final unitName = unit.label;
    final catalogName = s.clickUnit.label;
    final unitNote = s.clickUnit == unit
        ? null
        : 'Profilde dürbün birimi $unitName seçili; katalogdaki '
              '${s.displayName} kulesi $catalogName '
              '(${s.clickValue} $catalogName/klik). Retikül ve kule $unitName '
              'olarak, $click $unitName/klik ile gösteriliyor. Dürbününüz '
              '$catalogName ise profilde birimi $catalogName yapın.';
    // Dürbün ayağı: a canted mount moves the zeroed turret down in its
    // travel. The required correction is unchanged; only the room to dial
    // UP grows (and the room to dial DOWN shrinks) by the mount's clicks.
    final halfUp = _halfTravelClicks(click, s.elevationRangeMrad);
    final mountCantMoa = widget.profile?.mountCantMoa ?? 0;
    final mountClicks = mountCantMoa > 0
        ? ScopeDialMath.mountCantClicks(mountCantMoa, click, unit)
        : 0;
    // Denetim F2 (2026-10-14): on a 0 MOA mount the zeroed turret is not
    // mid-travel: it already holds the zero angle (bore above the sight
    // line), dialled UP when zeroing. That angle comes off the UP travel
    // and adds to the DOWN travel. Limits only; the required clicks stay.
    final zeroClicks = basis == null ? 0 : _zeroAngleClicks(basis, click, unit);
    // Known travel: the mount moves the zero down inside the SAME travel,
    // so UP can never exceed the whole travel and DOWN never goes below 0.
    final upClicks = halfUp == null
        ? _unknownTravelClicks
        : math.max(0, math.min(halfUp + mountClicks - zeroClicks, 2 * halfUp));
    final downClicks = halfUp == null
        ? _unknownTravelClicks
        : math.max(0, halfUp - mountClicks + zeroClicks);
    final maxWindage =
        _halfTravelClicks(click, s.windageRangeMrad) ?? _unknownTravelClicks;
    if (_autoDialArmed && requiredUp != null) {
      _autoDialArmed = false;
      int within(int v, int lo, int hi) => math.max(lo, math.min(hi, v));
      final up = within(
        ScopeDialMath.clicksFor(requiredUp, click),
        -downClicks,
        upClicks,
      );
      final right = within(
        ScopeDialMath.clicksFor(requiredRight, click),
        -maxWindage,
        maxWindage,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _elevationClicks = up;
          _windageClicks = right;
          _windageRevealToken++;
        });
      });
    }
    return ScopeDialView(
      firearm: _isFirearm,
      reticle: ReticleCatalog.forScope(
        scope?.reticle,
        unit,
        brand: scope?.brand,
        model: scope?.model,
        source: scope?.sourceDocument,
      ),
      unit: unit,
      clickValue: click,
      elevationClicks: _elevationClicks,
      windageClicks: _windageClicks,
      maxElevationClicks: upClicks,
      maxElevationDownClicks: downClicks,
      mountCantMoa: mountCantMoa,
      mountCantClicks: mountClicks,
      zeroAngleClicks: zeroClicks,
      travelKnown: (s.elevationRangeMrad ?? 0) > 0,
      halfElevationClicks: halfUp,
      // The side turret's limit only matters for the drum; it is never
      // asked on Profil, so without catalog data the drum turns freely.
      maxWindageClicks: maxWindage,
      onElevationChanged: (v) => setState(() => _elevationClicks = v),
      onWindageChanged: (v) => setState(() => _windageClicks = v),
      windageRevealToken: _windageRevealToken,
      onSolutionDialed: () => setState(() => _windageRevealToken++),
      requiredUp: requiredUp,
      requiredRight: requiredRight,
      windMpsPerUnit: windMpsPerUnit,
      windText: _windLabel,
      firstFocalPlane: s.firstFocalPlane,
      minMagnification: zoom ? minMag : null,
      maxMagnification: zoom ? maxMag : null,
      magnification: zoom
          // Starts 15 % under the scope's highest magnification, rounded
          // (owner, 2026-10-12: a fixed 20x drew too small; "yüzde 15
          // aşağı hesaplasın"), never under the lowest magnification.
          ? (_magnification ?? (maxMag * 0.85).roundToDouble())
                .clamp(minMag, maxMag)
                .toDouble()
          : null,
      onMagnificationChanged: zoom
          ? (v) => setState(() => _magnification = v)
          : null,
      unitNote: unitNote,
      windNote: windNote == null ? scaleNote : '$scaleNote $windNote',
      rangeM: _shotRangeM,
      inclineDeg: _inclineDeg,
      cantDeg: _cantDeg,
      samples: basis == null
          ? const []
          : _holdSamplesFor(
              basis,
              unit,
              offsetMrad: zeroOff.up + (jump ?? 0),
              scale: scale,
              dialedUp: ScopeDialMath.clicksToAngle(_elevationClicks, click),
            ),
      toDisplayRange: _toDisplayRange,
      distanceUnit: _distanceUnit,
      metric: metric,
      targetDiameterM: _targetDiameterM,
    );
  }

  /// The Pro "Hedef çapı" in metres (10 cm / 4 in when empty).
  double get _targetDiameterM {
    final typed = _parsed(targetSizeCtl);
    final size = typed != null && typed > 0 && typed < 1000
        ? typed
        : (metric ? 10.0 : 4.0);
    return metric ? size / 100 : UnitSystem.inchesToMillimeters(size) / 1000;
  }

  /// Lateral wind drift at the point's range, in cm (metric) or inches.
  /// windMrad is the angle atan2(-z, range); this recovers |z| exactly.
  double _windDrift(TrajectoryPoint point) {
    final meters = point.rangeM * math.tan(point.windMrad.abs() / 1000);
    return metric
        ? meters * 100
        : UnitSystem.millimetersToInches(meters * 1000);
  }

  String get _driftUnit => metric ? 'cm' : 'in';

  @override
  Widget build(BuildContext context) {
    if (widget.profile == null &&
        widget.view == BallisticsView.environment &&
        widget.onCreateProfile != null) {
      return _environmentWithoutProfile(context);
    }
    if (widget.profile == null) {
      return _blocked(
        'DOPE oluşturmak için önce bir tüfek profili oluşturup aktif profil olarak seçin.',
      );
    }
    if (profileResolution == null) {
      return _blocked(
        'Aktif profil katalogla artık eşleşmiyor. Tüfek, mühimmat ve dürbün seçimini Profiller ekranından yeniden doğrulayın.',
      );
    }

    switch (widget.view) {
      case BallisticsView.shot:
        return _hedefPage(context);
      case BallisticsView.table:
        return MenzilPage(
          key: const PageStorageKey('ballistics-table'),
          // DOPE mode of the Hedef tab: justified like Atış Çözümü.
          justify: true,
          children: [
            ..._tableHeader(context),
            _bcNotice(),
            _rangesInput(),
            MenzilPrimaryButton(
              label: 'DOPE oluştur',
              onPressed: solve,
              icon: Icons.table_rows_outlined,
            ),
            const SizedBox(height: MenzilSpace.md),
            ..._tableResults(context),
            _vacuumFootnote(context),
          ],
        );
      case BallisticsView.environment:
        return _havaDurumuPage(context);
      case BallisticsView.pro:
        return _proAyarlarPage(context);
      case BallisticsView.all:
        return Scaffold(
          appBar: const MenzilSubPageBar(title: 'Balistik / DOPE'),
          bottomNavigationBar: _bottomAction(context),
          body: MenzilPage(
            children: [
              _profileCard(context),
              _bcNotice(),
              ..._environmentInputs(context, collapseShotInputs: false),
              _rangesInput(),
              _atmosphereResult(context),
              ..._tableResults(context),
              _vacuumFootnote(context),
            ],
          ),
        );
    }
  }

  // -------------------------------------------------------------------------
  // Shared pieces
  // -------------------------------------------------------------------------

  Widget _bottomAction(BuildContext context) {
    final c = MenzilColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MenzilSpace.gutter,
            MenzilSpace.sm,
            MenzilSpace.gutter,
            MenzilSpace.sm,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: MenzilSpace.maxContentWidth,
              ),
              child: MenzilPrimaryButton(
                label: 'DOPE oluştur',
                onPressed: solve,
                icon: Icons.table_rows_outlined,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context) {
    final c = MenzilColors.of(context);
    return MenzilCard(
      padding: const EdgeInsets.symmetric(
        horizontal: MenzilSpace.lg,
        vertical: MenzilSpace.md,
      ),
      child: Row(
        children: [
          Icon(Icons.person_pin_circle_outlined, color: c.ink),
          const SizedBox(width: MenzilSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.profile!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MenzilType.heading(c.ink, size: 20),
                ),
                Text(
                  'Aktif profil • ${scope?.displayName ?? widget.profile!.scopeId}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MenzilType.caption(c.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bcNotice() {
    final a = ammunition;
    if (a?.ballisticCoefficient == null || a?.ballisticModel == null) {
      return const MenzilNotice(
        tone: MenzilNoticeTone.warning,
        message:
            'Vakum temel hesap (yalnızca yerçekimi). Bu mühimmat için doğrulanmış BC/model yok; G1/G7 ve rüzgâr düzeltmesi hesaplanmaz. Özel mermi kaydına BC ve G1/G7 ekleyerek sürtünmeli hesabı açabilirsiniz.',
      );
    }
    if (_bcEstimated && _bcApplies()) {
      // A model other than G1 picked without a BC cannot be used: the
      // estimate is a G1 BC (owner, 2026-10-14).
      final est = a!;
      final picked = est.modelWithoutBc;
      final otherModel = picked != null && picked != BallisticModel.g1
          ? ' Seçtiğiniz ${picked.label} modeli BC olmadan kullanılamaz; '
                'tahmin G1 ile yapıldı.'
          : '';
      return MenzilNotice(
        key: const Key('ballistics-bc-estimated'),
        tone: MenzilNoticeTone.warning,
        message:
            'BC girilmediği için tahmini G1 BC '
            '${_decimal(est.ballisticCoefficient)} kullanılıyor (ağırlık ve '
            'kalibreden). Uzak mesafede sapabilir; BC\'yi biliyorsanız '
            'Profil\'de girin.$otherModel',
      );
    }
    final name = a!.ballisticModel!.name.toUpperCase();
    final curve = a.dragCurve;
    if (curve != null) {
      return MenzilNotice(
        tone: MenzilNoticeTone.info,
        message: _bcApplies()
            ? 'Sürtünmeli hesap: özel sürüklenme eğrisi (${curve.length} '
                  'nokta, Mach ${curve.last.mach.toStringAsFixed(1).replaceAll('.', ',')}\'e kadar). '
                  'İlk atışta canlı atışla doğrulayın.'
            : 'Özel eğri ${_decimal(a.grain)} gr mermi içindir. Grain değiştirildiği '
                  'için kullanılmıyor; vakum temel hesap yapılır.',
      );
    }
    // Describes the inputs as they are now (the profile is solved on open,
    // so the last solve may predate a grain edit).
    if (!_bcApplies()) {
      return MenzilNotice(
        tone: MenzilNoticeTone.warning,
        message:
            'Kayıtlı $name BC ${_decimal(a.ballisticCoefficient)}, ${_decimal(a.grain)} gr mermi içindir. '
            'Grain değiştirildiği için BC kullanılmıyor; vakum temel hesap yapılır.',
      );
    }
    return MenzilNotice(
      tone: MenzilNoticeTone.info,
      message:
          'Sürtünmeli hesap: $name BC ${_decimal(a.ballisticCoefficient)}'
          '${a.bcBands.isEmpty ? '' : ' (hıza göre ${a.bcBands.length} BC)'}. '
          'BC sizin girdiğiniz değerdir; '
          'gerçek mermiden farklıysa sonuç da kayar. İlk atışta canlı atışla doğrulayın.',
    );
  }

  /// Safety warnings of the last drag solve plus ranges the projectile cannot
  /// reach. Empty in vacuum mode.
  List<Widget> _dragNotices() => [
    for (final w in _warnings)
      Padding(
        padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
        child: MenzilNotice(
          tone: w.level == DragWarningLevel.caution
              ? MenzilNoticeTone.danger
              : MenzilNoticeTone.info,
          message: w.message,
        ),
      ),
    if (_unreachableM.isNotEmpty)
      Padding(
        padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
        child: MenzilNotice(
          tone: MenzilNoticeTone.warning,
          message:
              'Bu mermi şu mesafelere ulaşamıyor, tabloda yok: '
              '${_unreachableM.map((m) => _toDisplayRange(m).toStringAsFixed(0)).join(', ')} $_distanceUnit.',
        ),
      ),
  ];

  Widget _vacuumFootnote(BuildContext context) {
    final c = MenzilColors.of(context);
    if (_dragMode) {
      return Padding(
        padding: const EdgeInsets.only(
          top: MenzilSpace.xs,
          bottom: MenzilSpace.md,
        ),
        child: Text(
          'Hesap seçili sürtünme yasası (G1/G7) ve girilen BC ile yapılır; sabit rüzgâr '
          'tüm menzil boyunca uygulanır. Mermi gerçekte BC değerinden farklı uçabilir, '
          'bu yüzden klik değerleri ilk atışta canlı atışla teyit edilmelidir.',
          style: MenzilType.caption(c.ink2),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(
        top: MenzilSpace.xs,
        bottom: MenzilSpace.md,
      ),
      child: Text(
        '* Vakum hesabı hava direncini hesaplamaz: rüzgâr düzeltmesi güvenlik gereği 0,00 gösterilir, '
        'enerji sütunu her mesafede sabit namlu enerjisidir (mesafedeki enerji değildir) ve '
        'yüzlerce metrede düşüş değerleri gerçek atıştakinden yaklaşık %20–45 KÜÇÜK çıkabilir — yani '
        'MOA/MRAD yükseklik kliki de gerçekte gerekenden daha AZ görünebilir. Bu nedenle buradaki klik '
        'değerleri bir başlangıç tahminidir; doğrulanmış sürüklenme modeli gelmeden kesin değildir ve ilk '
        'atışta canlı atışla teyit edilmelidir. Rüzgâr düzeltmesi/kliki hiç üretilmez (KİLİTLİ).',
        style: MenzilType.caption(c.ink2),
      ),
    );
  }

  Widget _rangesInput() => MenzilInput(
    key: BallisticsFieldKeys.ranges,
    controller: ranges,
    label: 'DOPE mesafeleri',
    info: EnvironmentFieldInfo.ranges,
    unit: _distanceUnit,
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.done,
  );

  // -------------------------------------------------------------------------
  // Tablo
  // -------------------------------------------------------------------------

  List<Widget> _tableHeader(BuildContext context) => [
    MenzilSectionHeader(
      'Balistik tablo',
      subtitle:
          '${widget.profile!.name} • ${scope?.displayName ?? widget.profile!.scopeId}',
      padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
    ),
  ];

  List<Widget> _tableResults(BuildContext context) {
    if (points.isEmpty) return const [];
    final c = MenzilColors.of(context);
    final zeroM = _basis?.zeroRangeM;
    final drag = _basis?.drag ?? false;
    return [
      ..._dragNotices(),
      DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(MenzilRadius.table),
          border: Border.all(color: c.line),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MenzilRadius.table),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: drag
                  ? [
                      DataColumn(label: Text(_distanceUnit)),
                      DataColumn(
                        label: Text(metric ? 'Düşüş cm' : 'Düşüş in'),
                        numeric: true,
                      ),
                      const DataColumn(
                        label: Text('Yükseklik MOA'),
                        numeric: true,
                      ),
                      const DataColumn(
                        label: Text('Yükseklik MRAD'),
                        numeric: true,
                      ),
                      const DataColumn(
                        label: Text('Rüzgâr MRAD'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text('Rüzgâr sapması $_driftUnit'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(metric ? 'Hız m/s' : 'Hız fps'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          metric
                              ? 'Mesafe enerjisi J'
                              : 'Mesafe enerjisi ft·lbf',
                        ),
                        numeric: true,
                      ),
                      const DataColumn(label: Text('TOF'), numeric: true),
                    ]
                  : [
                      DataColumn(label: Text(_distanceUnit)),
                      DataColumn(
                        label: Text(
                          metric ? 'Vakum düşüşü cm*' : 'Vakum düşüşü in*',
                        ),
                        numeric: true,
                      ),
                      const DataColumn(
                        label: Text('Yükseklik MOA*'),
                        numeric: true,
                      ),
                      const DataColumn(
                        label: Text('Yükseklik MRAD*'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          metric
                              ? 'Namlu enerjisi J*'
                              : 'Namlu enerjisi ft·lbf*',
                        ),
                        numeric: true,
                      ),
                      const DataColumn(label: Text('TOF'), numeric: true),
                    ],
              rows: points.map((p) {
                final displayRange = _toDisplayRange(p.rangeM);
                final displayEnergy = metric
                    ? p.energyJ
                    : UnitSystem.joulesToFootPounds(p.energyJ);
                final displayDrop = metric
                    ? p.dropM * 100
                    : UnitSystem.millimetersToInches(p.dropM * 1000);
                final isZero = zeroM != null && (p.rangeM - zeroM).abs() < 0.05;
                return DataRow(
                  color: isZero ? WidgetStatePropertyAll(c.amberSoft) : null,
                  cells: [
                    DataCell(Text(_fixed(displayRange, _yards ? 1 : 0))),
                    DataCell(Text(_fixed(displayDrop, 1))),
                    DataCell(Text(_fixed(p.correctionMoa, 2))),
                    DataCell(Text(_fixed(p.correctionMrad, 2))),
                    if (drag) ...[
                      DataCell(Text(_fixed(p.windMrad.abs(), 2))),
                      DataCell(Text(_fixed(_windDrift(p), 1))),
                      DataCell(
                        Text(
                          (metric
                                  ? p.velocityMps
                                  : UnitSystem.mpsToFps(p.velocityMps))
                              .toStringAsFixed(0),
                        ),
                      ),
                    ],
                    DataCell(Text(_fixed(displayEnergy, 1))),
                    DataCell(Text(_fixed(p.timeOfFlightS, 3))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
      if (zeroM != null)
        Padding(
          padding: const EdgeInsets.only(top: MenzilSpace.xs),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: c.amberSoft,
                  border: Border.all(color: c.amber),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: MenzilSpace.xs),
              Expanded(
                child: Text(
                  'Sıfırlama mesafesi ${_fixed(_toDisplayRange(zeroM), _yards ? 1 : 0)} $_distanceUnit',
                  style: MenzilType.caption(c.ink2),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  // -------------------------------------------------------------------------
  // Atış
  // -------------------------------------------------------------------------

  /// Yerçekimi effect at the shot distance: how much less (or more) the
  /// bullet drops than with standard gravity, metres (+ = less drop).
  Object? _gravityEffectKey;
  double? _gravityEffectValue;

  double? _gravityEffect() {
    final basis = _basis;
    if (basis == null || !_gravityOn || _gravityTyped == null) return null;
    final key = (basis, _shotRangeM, _inclineDeg, _cantDeg);
    if (key == _gravityEffectKey) return _gravityEffectValue;
    _gravityEffectKey = key;
    try {
      const engine = BallisticEngine();
      TrajectoryPoint at(double g) => engine
          .solve(
            basis.input(
              [_shotRangeM],
              inclineDeg: _inclineDeg,
              cantDeg: _cantDeg,
              gravity: g,
            ),
          )
          .single;
      final std = at(Gravity.standard);
      final local = at(basis.gravityMps2);
      return _gravityEffectValue = std.dropM - local.dropM;
    } on ArgumentError {
      return _gravityEffectValue = null;
    } on StateError {
      return _gravityEffectValue = null;
    }
  }

  /// Where Coriolis moves the impact at the shot range: (up, right) in
  /// metres, from two solves with and without it. Null when off/unknown.
  // Last Coriolis effect and what it was computed for: the Pro page rebuilds
  // on every keystroke, and each effect costs two full solves.
  Object? _coriolisEffectKey;
  ({double up, double right})? _coriolisEffectValue;

  ({double up, double right})? _coriolisEffect() {
    final basis = _basis;
    final args = _coriolisArgs;
    // The vacuum model has no Coriolis (nor wind): drag mode only.
    if (basis == null || args.lat == null || !_dragMode) return null;
    final key = (basis, _shotRangeM, _inclineDeg, _cantDeg, args.lat, args.az);
    if (key == _coriolisEffectKey) return _coriolisEffectValue;
    _coriolisEffectKey = key;
    return _coriolisEffectValue = _computeCoriolisEffect(basis, args);
  }

  ({double up, double right})? _computeCoriolisEffect(
    _ShotBasis basis,
    ({double? lat, double? az}) args,
  ) {
    try {
      const engine = BallisticEngine();
      final base = engine
          .solve(
            basis.input(
              [_shotRangeM],
              inclineDeg: _inclineDeg,
              cantDeg: _cantDeg,
            ),
          )
          .single;
      final withC = engine
          .solve(
            basis.input(
              [_shotRangeM],
              inclineDeg: _inclineDeg,
              cantDeg: _cantDeg,
              latitudeDeg: args.lat,
              azimuthDeg: args.az,
            ),
          )
          .single;
      // dropM is positive down; windMrad > 0 means the shot went LEFT.
      double lateral(TrajectoryPoint point) =>
          -_shotRangeM * math.tan(point.windMrad / 1000);
      return (
        up: base.dropM - withC.dropM,
        right: lateral(withC) - lateral(base),
      );
    } on ArgumentError {
      return null;
    } on StateError {
      return null;
    }
  }

  Future<void> _latitudeFromGps() async {
    final services = ToolsServicesScope.of(context);
    setState(() => _coriolisStatus = 'Konum alınıyor…');
    final fix = await services.location.current();
    if (!mounted) return;
    if (fix is LocationFix) {
      latitudeCtl.text = fix.latitude.toStringAsFixed(2);
      _coriolisStatus = 'Enlem konumdan alındı.';
      _latFilled = true;
      _latWasReset = false;
    } else {
      _coriolisStatus = 'Konum alınamadı; enlemi elle girin.';
    }
    _coriolisChanged();
  }

  Future<void> _azimuthFromCompass() async {
    final services = ToolsServicesScope.of(context);
    setState(
      () => _coriolisStatus = 'Telefonu hedefe doğru tutun; pusula okunuyor…',
    );
    HeadingState? state;
    try {
      state = await services.heading
          .headings()
          .firstWhere((s) => s is HeadingAvailable)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      state = null;
    }
    if (!mounted) return;
    if (state is HeadingAvailable) {
      azimuthCtl.text = state.reading.degrees.round().toString();
      _coriolisStatus = 'Atış yönü pusuladan alındı.';
      _aziFilled = true;
      _aziWasReset = false;
    } else {
      _coriolisStatus = 'Pusula okunamadı; atış yönünü elle girin.';
    }
    _coriolisChanged();
  }

  Future<void> _editIncline() async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _InclineDialog(initial: _inclineDeg, firearm: _isFirearm),
    );
    if (!mounted || result == null) return;
    _setAngles(incline: result);
  }

  Future<void> _editCant() async {
    final result = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (_) =>
            ScopeCantScreen(initialDeg: _cantDeg, firearm: _isFirearm),
      ),
    );
    if (!mounted || result == null) return;
    _setAngles(cant: result);
  }

  /// PCP with the tube pressure (the profile's, or Pro's with
  /// PRO_TUBE_PRESSURE) below the regulator pressure.
  bool get _pcpRegulatorBypassed {
    final v0 = widget.profile?.muzzleVelocityMps;
    if (v0 == null) return false;
    return _pcpVelocity(v0)?.regulatorBypassed ?? false;
  }

}

/// Owns its controller so it is disposed only after the dialog route is gone
/// (disposing right after `showDialog` returns would break the exit animation).
class _RangeDialog extends StatefulWidget {
  final int initial;
  final String unit;
  const _RangeDialog({required this.initial, required this.unit});

  @override
  State<_RangeDialog> createState() => _RangeDialogState();
}

class _RangeDialogState extends State<_RangeDialog> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initial.toString(),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _fromMap() async {
    final meters = await Navigator.push<double>(
      context,
      MaterialPageRoute<double>(
        builder: (_) => const MapDistanceScreen(returnDistance: true),
      ),
    );
    if (!mounted || meters == null || !meters.isFinite || meters <= 0) return;
    final shown = widget.unit == 'm' ? meters : meters / 0.9144;
    setState(() => controller.text = shown.round().toString());
  }

  void _apply() => Navigator.pop(
    context,
    double.tryParse(controller.text.trim().replaceAll(',', '.')),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Mesafe'),
    content: MenzilInput(
      controller: controller,
      label: 'Atış mesafesi',
      info: EnvironmentFieldInfo.shotRange,
      unit: widget.unit,
      textInputAction: TextInputAction.done,
    ),
    actions: [
      TextButton(
        key: const Key('range-from-map'),
        onPressed: _fromMap,
        child: const Text('Haritadan'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('İptal'),
      ),
      FilledButton(onPressed: _apply, child: const Text('Uygula')),
    ],
  );
}

/// Tüfek eğimi: typed by hand or measured with the camera.
class _InclineDialog extends StatefulWidget {
  final double initial;
  final bool firearm;
  const _InclineDialog({required this.initial, required this.firearm});

  @override
  State<_InclineDialog> createState() => _InclineDialogState();
}

class _InclineDialogState extends State<_InclineDialog> {
  late final TextEditingController _c = TextEditingController(
    text: _text(widget.initial),
  );

  static String _text(double v) {
    final r = (v * 10).round() / 10;
    return r == r.roundToDouble()
        ? r.toStringAsFixed(0)
        : r.toStringAsFixed(1).replaceAll('.', ',');
  }

  double? get _value {
    final v = double.tryParse(_c.text.trim().replaceAll(',', '.'));
    if (v == null || !v.isFinite) return null;
    return v.abs() <= ProductionLimits.maxInclineDeg ? v : null;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _measure() async {
    final v = await Navigator.of(context).push<double>(
      MaterialPageRoute(builder: (_) => const InclineMeasureScreen()),
    );
    if (!mounted || v == null) return;
    setState(() => _c.text = _text(v));
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    final max = ProductionLimits.maxInclineDeg.toStringAsFixed(0);
    return AlertDialog(
      title: const Text('Tüfek eğimi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MenzilInput(
            key: const Key('incline-field'),
            controller: _c,
            label: 'Tüfek eğimi açısı',
            unit: '°',
            info: EnvironmentFieldInfo.inclineFor(firearm: widget.firearm),
            errorText: value == null ? '−$max ile $max arasında olmalı.' : null,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          MenzilSecondaryButton(
            key: const Key('incline-measure'),
            label: 'Kamerayla ölç',
            icon: Icons.photo_camera_outlined,
            expand: true,
            onPressed: _measure,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(0.0),
          child: const Text('0° (düz)'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        TextButton(
          key: const Key('incline-done'),
          onPressed: value == null
              ? null
              : () => Navigator.of(context).pop(value),
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}

/// Hava Durumu values of the last workspace, in SI units, for the next
/// workspace the shell builds (no profile → first profile, a profile
/// rewritten by Profil or a tool, another profile chosen). One per shell.
class EnvironmentCarry {
  Map<String, double>? _si;
  Set<String> _edited = {};

  /// Boxes the user emptied with Sıfırla (owner, 2026-10-12): they come
  /// back empty, not with the starting values.
  Set<String> _empty = {};

  /// The fetch buttons' state, so a tab switch keeps "…alındı" orange
  /// (owner, 2026-10-12).
  bool _weatherFilled = false;
  bool _pressureFilled = false;

  /// Their fetch times (UTC epoch ms), so a tab switch never makes an old
  /// fetch look new (owner, 2026-10-14).
  int? _weatherFetchedAtMs;
  int? _pressureFetchedAtMs;

  /// İrtifa card fetch times and the Rüzgâr yönü time (owner, 2026-10-14).
  int? _altPhoneAtMs;
  int? _altMapAtMs;
  int? _windDirAtMs;

  /// The profile the snapshot came from: Rüzgâr yönü depends on where the
  /// shooter faces, so it never moves to another (or a new) profile (owner,
  /// 2026-10-13: "rüzgâr yönü kurulu gelmemesi lazım").
  String? _profileId;

  void _save(_BallisticsScreenState s) {
    _profileId = s.widget.profile?.id;
    _weatherFilled = s._weatherFilled;
    _pressureFilled = s._pressureFilled;
    _weatherFetchedAtMs = s._weatherFetchedAtMs;
    _pressureFetchedAtMs = s._pressureFetchedAtMs;
    _altPhoneAtMs = s._altPhoneAtMs;
    _altMapAtMs = s._altMapAtMs;
    _windDirAtMs = s._windDirAtMs;
    bool blank(TextEditingController c) => c.text.trim().isEmpty;
    double? n(TextEditingController c) =>
        double.tryParse(c.text.trim().replaceAll(',', '.'));
    final boxes = {
      'temperature': s.temperature,
      'pressure': s.pressure,
      'humidity': s.humidity,
      'altitude': s.altitude,
      'mapAltitude': s.mapAltitude,
      'wind': s.wind,
    };
    // An unreadable (not empty) value keeps the last good snapshot.
    for (final c in boxes.values) {
      if (!blank(c) && n(c) == null) return;
    }
    final m = s.metric;
    final t = n(s.temperature), p = n(s.pressure), h = n(s.humidity);
    final a = n(s.altitude), w = n(s.wind), d = n(s.windDirection);
    final ma = n(s.mapAltitude);
    _si = {
      if (t != null) 'temperature': m ? t : UnitSystem.fahrenheitToCelsius(t),
      if (p != null) 'pressure': m ? p : UnitSystem.inHgToHpa(p),
      if (h != null) 'humidity': h,
      if (a != null) 'altitude': m ? a : UnitSystem.feetToMeters(a),
      if (ma != null) 'mapAltitude': m ? ma : UnitSystem.feetToMeters(ma),
      if (w != null) 'wind': m ? w : UnitSystem.mphToMps(w),
      if (d != null && s._windHourValue != null) 'windDirection': d,
    };
    _empty = {
      for (final MapEntry(:key, :value) in boxes.entries)
        if (blank(value)) key,
    };
    _edited = {
      if (s._userEdited.contains(s.temperature)) 'temperature',
      if (s._userEdited.contains(s.pressure)) 'pressure',
      if (s._userEdited.contains(s.humidity)) 'humidity',
      if (s._userEdited.contains(s.altitude)) 'altitude',
      if (s._userEdited.contains(s.mapAltitude)) 'mapAltitude',
      if (s._userEdited.contains(s.wind)) 'wind',
    };
  }

  /// Fields start in SI; the unit preference converts them afterwards.
  void _apply(_BallisticsScreenState s) {
    final si = _si;
    if (si == null) return;
    // Without a profile on both sides it is the same workspace.
    final sameProfile = _profileId == s.widget.profile?.id;
    s._weatherFilled = _weatherFilled;
    s._pressureFilled = _pressureFilled;
    s._weatherFetchedAtMs = _weatherFetchedAtMs;
    s._pressureFetchedAtMs = _pressureFetchedAtMs;
    s._altPhoneAtMs = _altPhoneAtMs;
    s._altMapAtMs = _altMapAtMs;
    if (sameProfile) s._windDirAtMs = _windDirAtMs;
    final fields = {
      'temperature': s.temperature,
      'pressure': s.pressure,
      'humidity': s.humidity,
      'altitude': s.altitude,
      'mapAltitude': s.mapAltitude,
      'wind': s.wind,
      'windDirection': s.windDirection,
    };
    for (final MapEntry(:key, :value) in fields.entries) {
      if (_empty.contains(key)) {
        value.text = '';
        continue;
      }
      if (key == 'windDirection' && !sameProfile) continue;
      final v = si[key];
      if (v == null) continue;
      value.text = _twoDecimals(v);
      if (_edited.contains(key)) s._userEdited.add(value);
    }
    final wd = si['windDirection'];
    if (wd != null && sameProfile) {
      s.windHour.text = '${WindClock.fromDegrees(wd)}';
    }
  }
}

/// WEZ picture: the target at its size and the simulated impacts (orange
/// inside, grey outside), scaled so the target fills about half the box.
class _WezPainter extends CustomPainter {
  final List<(double, double)> impacts;
  final double radiusMrad;
  final MenzilColors colors;
  _WezPainter({
    required this.impacts,
    required this.radiusMrad,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rPx = size.shortestSide * 0.36;
    final k = radiusMrad <= 0 ? 0.0 : rPx / radiusMrad;
    Paint ring(Color col, double w) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    canvas.drawCircle(c, rPx, Paint()..color = colors.paperFace);
    canvas.drawCircle(c, rPx * 0.66, ring(colors.paperRingSoft, 1));
    canvas.drawCircle(c, rPx * 0.33, ring(colors.paperRingSoft, 1));
    canvas.drawCircle(c, rPx, ring(colors.paperRing, 2));
    final inside = Paint()..color = colors.amber;
    final outside = Paint()..color = colors.ink2;
    final limit = size.shortestSide / 2 - 2;
    // Every 4th impact keeps the picture readable.
    for (var i = 0; i < impacts.length; i += 4) {
      final (x, y) = impacts[i];
      final at = c + Offset(x * k, -y * k);
      if ((at - c).distance > limit) continue;
      canvas.drawCircle(
        at,
        2.2,
        x * x + y * y <= radiusMrad * radiusMrad ? inside : outside,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WezPainter old) =>
      old.impacts != impacts ||
      old.radiusMrad != radiusMrad ||
      old.colors != colors;
}

/// [v] as shown to the user: decimal comma, no trailing ".0"; "—" when
/// there is no value.
String _decimal(num? v) => v == null
    ? '—'
    : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString()).replaceAll('.', ',');

/// A stored SI value (°C, hPa, m/s …) back into a box: no trailing ".0",
/// at most two decimals, decimal point (the boxes accept both).
String _twoDecimals(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : double.parse(v.toStringAsFixed(2)).toString();
