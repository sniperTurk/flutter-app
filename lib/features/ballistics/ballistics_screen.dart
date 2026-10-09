import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/atmosphere.dart';
import '../../core/ballistic_engine.dart';
import '../../core/ballistic_input.dart';
import '../../core/dope_ranges.dart';
import '../../core/drag_safety.dart';
import '../../core/powder_temperature.dart';
import '../../core/production_limits.dart';
import '../../core/reticle_holds.dart';
import '../../core/scope_dial.dart';
import '../../core/unit_system.dart';
import '../../core/wind_clock.dart';
import '../../data/profile_catalog_integrity.dart';
import '../../models/domain.dart';
import '../../services/settings_store.dart';
import '../../services/shot_settings_store.dart';
import '../../tools/domain/field_calc.dart';
import '../../tools/domain/shot_angle_math.dart';
import '../../tools/ports/heading_provider.dart';
import '../../tools/ports/location_provider.dart';
import '../../tools/ports/weather_provider.dart';
import '../../tools/tools_services.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import '../tools/map_distance_screen.dart';
import '../tools/weather_screen.dart';
import 'environment_field_info.dart';
import 'incline_measure_screen.dart';
import 'scope_cant_screen.dart';
import 'scope_dial_view.dart';
import 'wind_clock_picker.dart';

/// Which part of the ballistic workspace is shown.
///
/// The Menzil shell shows [shot], [table] and [environment] as separate tabs
/// over ONE state object, so inputs and the last validated solve are shared
/// between them. [all] is the stand-alone route (every section on one page).
/// [pro]: Pro Ayarlar (shot incline, scope cant, Coriolis) — owner, 2026-10-08.
enum BallisticsView { all, shot, table, environment, pro }

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
  static const altitude = ValueKey('ballistics-altitude');
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
  const BallisticsScreen({
    super.key,
    this.profile,
    this.view = BallisticsView.all,
    this.autoWeather = false,
    this.onContinueToPro,
    this.onContinueToShot,
  });

  @override
  State<BallisticsScreen> createState() => _BallisticsScreenState();
}

/// Inputs of the last successful, fully validated solve. The shot view
/// re-evaluates the same validated inputs at the selected range; it never
/// re-parses the (possibly edited, not yet submitted) text fields.
class _ShotBasis {
  final double velocityMps, grain, zeroRangeM, sightHeightMm;

  /// Velocity on the zeroing day when today's differs (barut sıcaklığı).
  final double? zeroVelocityMps;
  final EnvironmentData environment;

  /// Both set (drag solve) or both null (vacuum baseline).
  final double? ballisticCoefficient;
  final BallisticModel? ballisticModel;

  /// Velocity-dependent BC steps (çoklu BC); empty = single BC.
  final List<BcBand> bcBands;
  const _ShotBasis({
    required this.velocityMps,
    required this.grain,
    required this.zeroRangeM,
    required this.sightHeightMm,
    required this.environment,
    this.ballisticCoefficient,
    this.ballisticModel,
    this.bcBands = const [],
    this.zeroVelocityMps,
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
  }) => BallisticInput(
    muzzleVelocityMps: velocityMps,
    grain: grain,
    zeroRangeM: zeroRangeM,
    sightHeightMm: sightHeightMm,
    rangesM: rangesM,
    environment: windMps == null
        ? environment
        : EnvironmentData(
            temperatureC: environment.temperatureC,
            pressureHpa: environment.pressureHpa,
            humidityPercent: environment.humidityPercent,
            altitudeM: environment.altitudeM,
            windMps: windMps,
            windDirectionDeg: environment.windDirectionDeg,
          ),
    ballisticCoefficient: ballisticCoefficient,
    ballisticModel: ballisticModel,
    bcBands: bcBands,
    inclineDeg: inclineDeg,
    cantDeg: cantDeg,
    latitudeDeg: latitudeDeg,
    azimuthDeg: azimuthDeg,
    zeroMuzzleVelocityMps: zeroVelocityMps,
  );
}

class _BallisticsScreenState extends State<BallisticsScreen> {
  late final TextEditingController velocity;
  late final TextEditingController grain;
  late final TextEditingController zero;
  late final TextEditingController sight;
  late final TextEditingController wind;
  late final TextEditingController windDirection;
  late final TextEditingController temperature;
  late final TextEditingController pressure;
  late final TextEditingController humidity;
  late final TextEditingController altitude;
  late final TextEditingController ranges;

  List<TrajectoryPoint> points = [];
  double? airDensityKgM3;
  double? densityRatio;
  double? speedOfSoundMps;
  double? muzzleMach;
  ScopeOptic? scope;
  Ammunition? ammunition;
  ProfileCatalogResolution? profileResolution;
  bool metric = true;

  _ShotBasis? _basis;
  double _shotRangeM = 100;

  /// Opens the right (windage) turret after "Çözümü kuleye kur".
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
        _coriolisOn = s.coriolisOn;
        latitudeCtl.text = s.latitudeText;
        azimuthCtl.text = s.azimuthText;
        turretScaleCtl.text = s.turretScaleText;
        _windMaxAuto = s.windMaxText.isEmpty;
        if (!_windMaxAuto) windMaxCtl.text = s.windMaxText;
        _autoWindMax();
        targetSpeedCtl.text = s.targetSpeedText;
        _targetMovesRight = s.targetMovesRight;
        _spinDriftOn = s.spinDriftOn;
        bulletLengthCtl.text = s.bulletLengthText;
        powderCoefCtl.text = s.powderCoefText;
        powderTempCtl.text = s.powderTempText;
        _shotCache.clear();
        _holdSamples = null;
      });
    }
    _shotSettingsReady = true;
  }

  void _saveShotSettings() {
    final id = widget.profile?.id;
    if (id == null || !_shotSettingsReady) return;
    final settings = ShotSettings(
      inclineDeg: _inclineDeg,
      cantDeg: _cantDeg,
      coriolisOn: _coriolisOn,
      latitudeText: latitudeCtl.text.trim(),
      azimuthText: azimuthCtl.text.trim(),
      turretScaleText: turretScaleCtl.text.trim(),
      windMaxText: _windMaxAuto ? '' : windMaxCtl.text.trim(),
      targetSpeedText: targetSpeedCtl.text.trim(),
      targetMovesRight: _targetMovesRight,
      spinDriftOn: _spinDriftOn,
      bulletLengthText: bulletLengthCtl.text.trim(),
      powderCoefText: powderCoefCtl.text.trim(),
      powderTempText: powderTempCtl.text.trim(),
    );
    unawaited(
      _shotStore.save(id, settings).catchError((Object _) {
        // A convenience only: the screen keeps its in-memory values.
      }),
    );
  }

  /// Pro Ayarlar → Coriolis: off until switched on; latitude (+N) and shot
  /// azimuth (° from north) as typed or taken from GPS / compass.
  bool _coriolisOn = false;
  final TextEditingController latitudeCtl = TextEditingController();
  final TextEditingController azimuthCtl = TextEditingController();

  /// Pro Ayarlar extras (owner, 2026-10-09).
  final TextEditingController turretScaleCtl = TextEditingController();
  final TextEditingController windMaxCtl = TextEditingController();

  /// En yüksek rüzgâr is filled automatically from Rüzgâr hızı (owner,
  /// 2026-10-09) until the shooter types a value; clearing it switches back
  /// to automatic. An automatic value is not saved.
  bool _windMaxAuto = true;

  /// Typical gust factor over land: the bracket top is 1.5 × the wind.
  static const windGustFactor = 1.5;

  void _autoWindMax() {
    if (!_windMaxAuto) return;
    final w = double.tryParse(wind.text.trim().replaceAll(',', '.'));
    final text = w == null || !w.isFinite || w <= 0
        ? ''
        : (w * windGustFactor).toStringAsFixed(1);
    if (windMaxCtl.text == text) return;
    windMaxCtl.text = text;
    _shotCache.clear();
    _holdSamples = null;
  }

  final TextEditingController targetSpeedCtl = TextEditingController();
  bool _targetMovesRight = true;
  bool _spinDriftOn = false;
  final TextEditingController bulletLengthCtl = TextEditingController();
  final TextEditingController powderCoefCtl = TextEditingController();
  final TextEditingController powderTempCtl = TextEditingController();

  bool get _isFirearm =>
      profileResolution?.rifle.platform == WeaponPlatform.firearm;

  /// Today's velocity from the profile velocity measured at [powderTempCtl]
  /// and the sensitivity [powderCoefCtl] (% per 15 °C); firearms only.
  double _powderAdjusted(double mps, double todayC) {
    if (!_isFirearm) return mps;
    return mps *
        PowderTemperature.factor(
          coefPercentPer15C: _parsed(powderCoefCtl),
          referenceTempC: _parsed(powderTempCtl),
          todayTempC: todayC,
        );
  }

  /// Spin drift (Litz) as a sideways angle in mrad, + = to the right; null
  /// when off or data is missing. Stability from the Miller formula.
  double? _spinDriftMrad(TrajectoryPoint shot, _ShotBasis basis) {
    if (!_spinDriftOn || !basis.drag) return null;
    final rifle = profileResolution?.rifle;
    final twist = rifle?.twistRateIn, dir = rifle?.twistDirection;
    final lengthMm = _parsed(bulletLengthCtl);
    if (rifle == null || twist == null || dir == null || lengthMm == null) {
      return null;
    }
    if (lengthMm <= 0 || lengthMm > 100) return null;
    final dIn = rifle.caliberMm / 25.4;
    final tCal = twist / dIn, lCal = lengthMm / 25.4 / dIn;
    final vFps = UnitSystem.mpsToFps(basis.velocityMps);
    final tF = basis.environment.temperatureC * 9 / 5 + 32;
    final pInHg = basis.environment.pressureHpa * 0.0295299830714;
    final sg =
        30 *
        basis.grain /
        (tCal * tCal * dIn * dIn * dIn * lCal * (1 + lCal * lCal)) *
        math.pow(vFps / 2800, 1 / 3) *
        ((tF + 460) / 519) *
        (29.92 / pInHg);
    final driftIn = 1.25 * (sg + 1.2) * math.pow(shot.timeOfFlightS, 1.83);
    final m = driftIn * 0.0254 * (dir == TwistDirection.right ? 1 : -1);
    return math.atan(m / _shotRangeM) * 1000;
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
    final p = widget.profile;
    profileResolution = p == null
        ? null
        : const ProfileCatalogIntegrity().resolve(p);
    final ammo = profileResolution?.ammunition;
    ammunition = ammo;
    scope = profileResolution?.scope;

    velocity = TextEditingController(
      // Namlu çıkış hızı is always fps (owner rule), like on Profil.
      text: UnitSystem.mpsToFps(p?.muzzleVelocityMps ?? 270).toStringAsFixed(1),
    );
    grain = TextEditingController(text: (ammo?.grain ?? 51).toString());
    // A yard profile shows (and takes) its zero in yards, and its shot
    // range starts at a round 100 yd.
    _shotRangeM = _defaultShotRangeM;
    final zeroM = p?.zeroRangeM ?? 25;
    zero = TextEditingController(
      text: p?.distanceUnit == DistanceUnit.yard
          ? UnitSystem.metersToYards(zeroM).toStringAsFixed(1)
          : zeroM.toString(),
    );
    sight = TextEditingController(text: (p?.sightHeightMm ?? 65).toString());
    wind = TextEditingController(text: '0')..addListener(_autoWindMax);
    windDirection = TextEditingController(text: '90');
    temperature = TextEditingController(text: '15');
    pressure = TextEditingController(text: '1013.25');
    humidity = TextEditingController(text: '50');
    altitude = TextEditingController(text: '0');
    ranges = TextEditingController(
      text: '25, 50, 75, 100, 125, 150, 175, 200, 250, 300, 400',
    );
    _loadUnitPreference();
    unawaited(_loadShotSettings());
    // Solve the profile as soon as the workspace opens, so the scope's
    // reticle, hold labels and point of impact are ready at once. The fields are still SI here; a later switch to
    // imperial only converts the fields, the stored basis stays SI.
    // Failures stay silent (the shot view says why).
    if (widget.view == BallisticsView.environment) _maybeAutoWeather();
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

  @override
  void didUpdateWidget(covariant BallisticsScreen old) {
    super.didUpdateWidget(old);
    if (widget.view == BallisticsView.environment &&
        old.view != BallisticsView.environment) {
      _maybeAutoWeather();
    }
    // Atış has no Hesapla button any more (owner, 2026-10-08): it is solved
    // with the current Hava Durumu / Pro values whenever it opens.
    final toShot =
        widget.view == BallisticsView.shot ||
        widget.view == BallisticsView.table;
    if (widget.view == BallisticsView.shot && old.view != BallisticsView.shot) {
      _shotRangeM = _defaultShotRangeM;
    }
    if (toShot && widget.view != old.view) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _quietSolve();
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
    final p = parse(pressure), a = parse(altitude);
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
          'çevirin ya da "Konumdan yeniden doldur"u kullanın.';
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
  /// user's own edits are replaced too (the "Yeniden doldur" button);
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
        // Station pressure needs the altitude: from GPS, or from a value
        // the user typed. Sea-level pressure is never used as station
        // pressure (that was the audit's density trap).
        final gpsAlt = fix.altitudeM;
        if (gpsAlt != null) {
          put(
            altitude,
            (metric ? gpsAlt : UnitSystem.metersToFeet(gpsAlt)).toStringAsFixed(
              0,
            ),
          );
        }
        final typedAlt = double.tryParse(
          altitude.text.trim().replaceAll(',', '.'),
        );
        // A typed altitude wins over GPS: it is the one shown in the field,
        // so the pressure must be converted with it too.
        final altM = _userEdited.contains(altitude) && typedAlt != null
            ? (metric ? typedAlt : UnitSystem.feetToMeters(typedAlt))
            : gpsAlt;
        String pressureNote;
        if (obs.pressureKind == PressureKind.station) {
          put(pressure, _pressureText(obs.pressureHpa));
          pressureNote = 'basınç istasyon basıncı';
        } else if (altM != null) {
          put(
            pressure,
            _pressureText(
              FieldCalc.stationPressureHpa(
                obs.pressureHpa,
                altM,
                temperatureC: obs.temperatureC,
              ),
            ),
          );
          pressureNote =
              'basınç ${altM.round()} m irtifaya göre istasyon basıncına '
              'çevrildi';
        } else {
          pressureNote =
              'irtifa bilinmediği için basınç doldurulmadı (İrtifa girin, '
              'sonra Yeniden doldur)';
        }
        final t = obs.validAt.toLocal();
        final hh = t.hour.toString().padLeft(2, '0');
        final mm = t.minute.toString().padLeft(2, '0');
        status =
            'Hava verisi otomatik dolduruldu (${obs.sourceName}, $hh:$mm; '
            '$pressureNote). Rüzgâr yönünü siz seçin. Değerleri '
            'değiştirebilirsiniz; değiştirdikleriniz korunur.';
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
    });
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

  String _pressureText(double hpa) => metric
      ? hpa.toStringAsFixed(1)
      : UnitSystem.hpaToInHg(hpa).toStringAsFixed(2);

  Widget _weatherFillCard(BuildContext context) {
    final status = _weatherStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status != null)
          MenzilNotice(
            key: const Key('environment-weather-status'),
            tone: _weatherFailed
                ? MenzilNoticeTone.warning
                : MenzilNoticeTone.info,
            message: status,
          ),
        const SizedBox(height: MenzilSpace.xs),
        MenzilSecondaryButton(
          key: const Key('environment-fill-weather'),
          label: _weatherBusy ? 'Alınıyor…' : 'Konumdan yeniden doldur',
          icon: Icons.my_location,
          expand: true,
          onPressed: _weatherBusy ? null : () => _fillWeather(overwrite: true),
        ),
        const SizedBox(height: MenzilSpace.md),
      ],
    );
  }

  Future<void> _loadUnitPreference() async {
    try {
      final loadedMetric = (await SettingsStore.open()).loadMetric();
      if (!mounted || loadedMetric == metric) return;
      if (!loadedMetric) {
        _convertControllersToImperial();
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
    final windMps = value(wind);
    final temperatureC = value(temperature);
    final pressureHpa = value(pressure);
    final altitudeM = value(altitude);
    final metricRanges = DopeRanges.parse(ranges.text);

    // Commit only after the complete source form has been validated. A
    // yard profile's distances already are in yards.
    if (!_profileYards) {
      zero.text = UnitSystem.metersToYards(zeroM).toStringAsFixed(1);
    }
    sight.text = UnitSystem.millimetersToInches(sightMm).toStringAsFixed(2);
    wind.text = UnitSystem.mpsToMph(windMps).toStringAsFixed(1);
    temperature.text = UnitSystem.celsiusToFahrenheit(
      temperatureC,
    ).toStringAsFixed(1);
    pressure.text = UnitSystem.hpaToInHg(pressureHpa).toStringAsFixed(2);
    altitude.text = UnitSystem.metersToFeet(altitudeM).toStringAsFixed(0);
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
    final rawWind = number(wind);
    final rawWindDirection = number(windDirection);
    final rawTemperature = number(temperature);
    final rawPressure = number(pressure);
    final rawHumidity = number(humidity);
    final rawAltitude = number(altitude);

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
    final wd = rawWindDirection!;
    final temp = metric
        ? rawTemperature!
        : UnitSystem.fahrenheitToCelsius(rawTemperature!);
    final pres = metric ? rawPressure! : UnitSystem.inHgToHpa(rawPressure!);
    final hum = rawHumidity!;
    final alt = metric ? rawAltitude! : UnitSystem.feetToMeters(rawAltitude!);

    if (v <= 0 ||
        g <= 0 ||
        z <= 0 ||
        s < 0 ||
        w < 0 ||
        wd < 0 ||
        wd > 360 ||
        pres <= 0 ||
        hum < 0 ||
        hum > 100 ||
        temp <= -273.15) {
      _error(
        'Balistik ve atmosfer alanlarını kontrol edin; nem %0–100, rüzgâr yönü 0–360° olmalı.',
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
      // Barut sıcaklığı (Pro, firearms): today's velocity from the profile
      // velocity; the zero stays solved with the zeroing-day velocity.
      final vToday = _powderAdjusted(v, temp);
      final double? vZero = vToday == v ? null : v;
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
        zeroMuzzleVelocityMps: vZero,
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
        _basis = _ShotBasis(
          velocityMps: vToday,
          grain: g,
          zeroRangeM: z,
          sightHeightMm: s,
          environment: environment,
          ballisticCoefficient: bc,
          ballisticModel: model,
          bcBands: bands,
          zeroVelocityMps: vZero,
        );
      });
    } on FormatException catch (e) {
      _error(e.message);
    } on ArgumentError catch (e) {
      _error(e.message?.toString() ?? 'Balistik girdileri geçersiz.');
    } on UnsupportedError catch (e) {
      _error(
        e.message?.toString() ?? 'Bu balistik model henüz desteklenmiyor.',
      );
    } on StateError {
      _error(
        'Sürtünmeli çözüm bulunamadı; hız, sıfır mesafesi ve BC uyumsuz olabilir.',
      );
    }
  }

  @override
  void dispose() {
    velocity.dispose();
    grain.dispose();
    zero.dispose();
    sight.dispose();
    wind.dispose();
    windDirection.dispose();
    temperature.dispose();
    pressure.dispose();
    humidity.dispose();
    altitude.dispose();
    ranges.dispose();
    latitudeCtl.dispose();
    azimuthCtl.dispose();
    turretScaleCtl.dispose();
    bulletLengthCtl.dispose();
    powderCoefCtl.dispose();
    powderTempCtl.dispose();
    windMaxCtl.dispose();
    targetSpeedCtl.dispose();
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
    TrajectoryPoint? shot;
    double? mpsPerMil;
    try {
      final input = basis.input(
        [_shotRangeM],
        inclineDeg: _inclineDeg,
        cantDeg: _cantDeg,
        latitudeDeg: _coriolisArgs.lat,
        azimuthDeg: _coriolisArgs.az,
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

  Widget _referenceShotPanel(TrajectoryPoint? shot) {
    // "Hedef Görünümü" is the page title in the top bar (owner, 2026-10-08);
    // the Yukarı/Aşağı and Rüzgâr boxes were removed: the scope below shows
    // the clicks and the point of impact.
    return MenzilCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_scopeDial(shot), ..._extraShotNotes(shot)],
      ),
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
        ? '${unit.fromMrad(mrad.abs()).toStringAsFixed(2)} ${unit.label}'
        : '${(unit.fromMrad(mrad.abs()) / click / _turretScale).round()} klik';
    final lines = <Widget>[];
    final windMax = _windMaxMps;
    final wind = basis.environment.windMps;
    if (basis.drag && windMax != null && windMax > wind) {
      final args = _coriolisArgs;
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
              ),
            )
            .single;
        // windMrad > 0: dial RIGHT (the shot went left).
        String side(double m) => m.abs() < 1e-9 ? '' : (m > 0 ? ' R' : ' L');
        lines.add(
          Text(
            'Rüzgâr ${_windLabel(wind)}–${_windLabel(windMax)} '
            '${metric ? 'm/s' : 'mph'}: yan düzeltme '
            '${clicks(shot.windMrad)}${side(shot.windMrad)} – '
            '${clicks(hi.windMrad)}${side(hi.windMrad)}.',
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
    final spin = _spinDriftMrad(shot, basis);
    if (spin != null) {
      final m = math.tan(spin.abs() / 1000) * _shotRangeM;
      final len = metric
          ? '${(m * 100).toStringAsFixed(1)} cm'
          : '${UnitSystem.millimetersToInches(m * 1000).toStringAsFixed(1)} in';
      lines.add(
        Text(
          'Spin drift: $len ${spin >= 0 ? 'sağa' : 'sola'}; kule klikleri '
          'bunu içerir.',
          key: const Key('shot-spin-drift'),
          style: MenzilType.body(c.ink),
        ),
      );
    }
    final speed = _targetSpeedMps;
    if (speed != null) {
      final leadM = speed * shot.timeOfFlightS;
      final mrad = math.atan(leadM / _shotRangeM) * 1000;
      final len = metric
          ? '${(leadM * 100).toStringAsFixed(0)} cm'
          : '${UnitSystem.millimetersToInches(leadM * 1000).toStringAsFixed(1)} in';
      lines.add(
        Text(
          'Hareketli hedef (${_windLabel(speed)} ${metric ? 'm/s' : 'mph'}, '
          '${_targetMovesRight ? 'soldan sağa' : 'sağdan sola'}): '
          '$len · ${clicks(mrad)} ${_targetMovesRight ? 'sağına' : 'soluna'} '
          'nişan alın (uçuş ${shot.timeOfFlightS.toStringAsFixed(2)} s).',
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

  String _windLabel(double mps) =>
      (metric ? mps : UnitSystem.mpsToMph(mps)).toStringAsFixed(1);

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

  /// Elevation correction from 1 m out to the farthest reachable range of
  /// the current basis (drag or vacuum), sampled once per solve.
  List<CorrectionSample> _holdSamplesFor(_ShotBasis basis, AngularUnit unit) {
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
    return [for (final p in _holdSamples!) ScopeDialMath.sampleOf(p, unit)];
  }

  /// Interactive scope: turrets change the dialled clicks and the reticle
  /// shows where the shot lands at the selected range. In drag mode the
  /// required windage and the crosswind labels come from the drag solver;
  /// the vacuum baseline has no wind model, so its required windage is 0.
  Widget _scopeDial(TrajectoryPoint? shot) {
    final s = scope;
    final click = _scopeClickValue;
    if (s == null || click == null) {
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
    final requiredUp = shot == null
        ? null
        : inUnit(shot.correctionMrad) / _turretScale;
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
        : inUnit(shot.windMrad - (spin ?? 0)) / scale;

    final mpsPerMil = basis != null && basis.drag
        ? _evalShot().mpsPerMil
        : null;
    final windMpsPerUnit = mpsPerMil == null
        ? null
        : mpsPerMil * unit.mradPerUnit;
    // What one reticle unit spans at the selected range.
    final unitSpanM = ScopeDialMath.linearAtRange(1, _shotRangeM, unit);
    final span = metric
        ? '${(unitSpanM * 100).toStringAsFixed(1)} cm'
        : '${UnitSystem.millimetersToInches(unitSpanM * 1000).toStringAsFixed(1)} in';
    final scaleNote =
        '${unit == AngularUnit.mrad ? '1 mil' : '1 ${unit.label}'} = $span '
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
    // Known travel: the mount moves the zero down inside the SAME travel,
    // so UP can never exceed the whole travel and DOWN never goes below 0.
    final upClicks = halfUp == null
        ? _unknownTravelClicks
        : math.min(halfUp + mountClicks, 2 * halfUp);
    final downClicks = halfUp == null
        ? _unknownTravelClicks
        : math.max(0, halfUp - mountClicks);
    return ScopeDialView(
      unit: unit,
      clickValue: click,
      elevationClicks: _elevationClicks,
      windageClicks: _windageClicks,
      maxElevationClicks: upClicks,
      maxElevationDownClicks: downClicks,
      mountCantMoa: mountCantMoa,
      mountCantClicks: mountClicks,
      travelKnown: (s.elevationRangeMrad ?? 0) > 0,
      halfElevationClicks: halfUp,
      // The side turret's limit only matters for the drum; it is never
      // asked on Profil, so without catalog data the drum turns freely.
      maxWindageClicks:
          _halfTravelClicks(click, s.windageRangeMrad) ?? _unknownTravelClicks,
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
          ? (_magnification ?? maxMag).clamp(minMag, maxMag).toDouble()
          : null,
      onMagnificationChanged: zoom
          ? (v) => setState(() => _magnification = v)
          : null,
      unitNote: unitNote,
      windNote: windNote == null ? scaleNote : '$scaleNote $windNote',
      rangeM: _shotRangeM,
      inclineDeg: _inclineDeg,
      cantDeg: _cantDeg,
      samples: basis == null ? const [] : _holdSamplesFor(basis, unit),
      toDisplayRange: _toDisplayRange,
      distanceUnit: _distanceUnit,
      metric: metric,
    );
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
        return MenzilPage(
          key: const PageStorageKey('ballistics-shot'),
          children: _shotSection(context),
        );
      case BallisticsView.table:
        return MenzilPage(
          key: const PageStorageKey('ballistics-table'),
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
        return MenzilPage(
          key: const PageStorageKey('ballistics-environment'),
          children: [
            // Live service data one tap away before shooting. It is shown
            // for reading only; nothing is copied into these inputs.
            MenzilSecondaryButton(
              key: const Key('environment-open-weather'),
              label: 'Konumdan canlı hava verisi',
              icon: Icons.cloud_outlined,
              expand: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const WeatherScreen()),
              ),
            ),
            const SizedBox(height: MenzilSpace.md),
            _weatherFillCard(context),
            ..._environmentInputs(context, collapseShotInputs: true),
            if (widget.onContinueToPro != null)
              MenzilPrimaryButton(
                key: const Key('environment-continue-pro'),
                label: 'Pro Ayarlara Geç',
                icon: Icons.arrow_forward,
                onPressed: () {
                  _quietSolve();
                  widget.onContinueToPro!();
                },
              )
            else
              MenzilPrimaryButton(
                label: 'Hesapla',
                onPressed: solve,
                icon: Icons.calculate_outlined,
              ),
            const SizedBox(height: MenzilSpace.md),
            _atmosphereResult(context),
          ],
        );
      case BallisticsView.pro:
        return MenzilPage(
          key: const PageStorageKey('ballistics-pro'),
          children: _proSection(context),
        );
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
            'Deterministik vacuum/gravity temel solver. Bu mühimmat için doğrulanmış BC/model yok; G1/G7 ve rüzgâr düzeltmesi hesaplanmaz. Özel mermi kaydına BC ve G1/G7/GA ekleyerek sürtünmeli hesabı açabilirsiniz.',
      );
    }
    final name = a!.ballisticModel!.name.toUpperCase();
    // Describes the inputs as they are now (the profile is solved on open,
    // so the last solve may predate a grain edit).
    if (!_bcApplies()) {
      return MenzilNotice(
        tone: MenzilNoticeTone.warning,
        message:
            'Kayıtlı $name BC ${a.ballisticCoefficient}, ${a.grain} gr mermi içindir. '
            'Grain değiştirildiği için BC kullanılmıyor; vacuum temel hesap yapılır.',
      );
    }
    return MenzilNotice(
      tone: MenzilNoticeTone.info,
      message:
          'Sürtünmeli hesap: $name BC ${a.ballisticCoefficient}'
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
        '* Vacuum solver hava direncini hesaplamaz: rüzgâr düzeltmesi güvenlik gereği 0,00 gösterilir, '
        'enerji sütunu her mesafede sabit namlu enerjisidir (mesafedeki enerji değildir) ve '
        'yüzlerce metrede düşüş değerleri gerçek atıştakinden yaklaşık %20–45 KÜÇÜK çıkabilir — yani '
        'MOA/mrad yükseklik kliki de gerçekte gerekenden daha AZ görünebilir. Bu nedenle buradaki klik '
        'değerleri bir başlangıç tahminidir; doğrulanmış drag modeli gelmeden kesin değildir ve ilk '
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
    helperText:
        'Virgülle ayırın, en fazla ${_displayMaxRange.toStringAsFixed(0)} $_distanceUnit.',
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.done,
  );

  // -------------------------------------------------------------------------
  // Ortam
  // -------------------------------------------------------------------------

  List<Widget> _environmentInputs(
    BuildContext context, {
    required bool collapseShotInputs,
  }) {
    // Only the full "Balistik / DOPE" view shows (and edits) these; the
    // shell takes them from Profil.
    final shotInputs = MenzilFieldGrid(
      children: [
        MenzilInput(
          key: BallisticsFieldKeys.velocity,
          controller: velocity,
          label: 'Namlu çıkış hızı',
          unit: 'fps',
        ),
        MenzilInput(
          key: BallisticsFieldKeys.grain,
          controller: grain,
          label: 'Mühimmat ağırlığı',
          unit: 'grain',
          onChanged: (_) => setState(() {}),
        ),
        MenzilInput(
          key: BallisticsFieldKeys.zero,
          controller: zero,
          label: 'Sıfır mesafesi',
          unit: _distanceUnit,
        ),
        MenzilInput(
          key: BallisticsFieldKeys.sight,
          controller: sight,
          label: 'Sight height',
          unit: metric ? 'mm' : 'in',
        ),
      ],
    );

    return [
      const MenzilSectionHeader(
        'Atmosfer',
        padding: EdgeInsets.only(bottom: MenzilSpace.sm),
      ),
      MenzilCard(
        padding: const EdgeInsets.fromLTRB(
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.xxs,
        ),
        child: MenzilFieldGrid(
          children: [
            MenzilInput(
              key: BallisticsFieldKeys.temperature,
              controller: temperature,
              label: 'Sıcaklık',
              // A typed value is the user's: auto fill keeps it.
              onChanged: (_) => _userEdited.add(temperature),
              info: EnvironmentFieldInfo.temperature,
              unit: metric ? '°C' : '°F',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            MenzilInput(
              key: BallisticsFieldKeys.pressure,
              controller: pressure,
              label: 'İstasyon basıncı',
              // A typed value is the user's: auto fill keeps it.
              onChanged: (_) => setState(() => _userEdited.add(pressure)),
              info: EnvironmentFieldInfo.pressure,
              unit: metric ? 'hPa' : 'inHg',
            ),
            MenzilInput(
              key: BallisticsFieldKeys.humidity,
              controller: humidity,
              label: 'Bağıl nem',
              // A typed value is the user's: auto fill keeps it.
              onChanged: (_) => _userEdited.add(humidity),
              info: EnvironmentFieldInfo.humidity,
              unit: '%',
            ),
            MenzilInput(
              key: BallisticsFieldKeys.altitude,
              controller: altitude,
              label: 'İrtifa',
              // A typed value is the user's: auto fill keeps it.
              onChanged: (_) => setState(() => _userEdited.add(altitude)),
              info: EnvironmentFieldInfo.altitude,
              unit: metric ? 'm' : 'ft',
              helperText: 'Bilgi amaçlı; hesap basıncı kullanır',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ],
        ),
      ),
      // Outside the field grid on purpose: inserting it between the fields
      // re-parented them and a typed value could be lost.
      if (_pressureWarning != null)
        MenzilNotice(
          key: const Key('environment-pressure-warning'),
          tone: MenzilNoticeTone.warning,
          message: _pressureWarning!,
        ),
      const MenzilSectionHeader(
        'Rüzgâr',
        padding: EdgeInsets.only(top: MenzilSpace.xxs, bottom: MenzilSpace.sm),
      ),
      MenzilCard(
        padding: const EdgeInsets.fromLTRB(
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.xxs,
        ),
        child: MenzilFieldGrid(
          children: [
            MenzilInput(
              key: BallisticsFieldKeys.wind,
              controller: wind,
              label: 'Rüzgâr hızı',
              // A typed value is the user's: auto fill keeps it.
              onChanged: (_) => _userEdited.add(wind),
              info: EnvironmentFieldInfo.windSpeed,
              unit: metric ? 'm/s' : 'mph',
            ),
            // Clock face like ChairGun/Strelok/Kestrel: the hour the wind
            // comes from (12 = from the front, 3 = from the right). The
            // solver's degrees stay in [windDirection].
            MenzilFullWidth(
              child: WindClockPicker(
                key: BallisticsFieldKeys.windDirection,
                info: EnvironmentFieldInfo.windDirection,
                hour: WindClock.fromDegrees(
                  double.tryParse(
                        windDirection.text.trim().replaceAll(',', '.'),
                      ) ??
                      90,
                ),
                onChanged: (h) => setState(
                  () => windDirection.text = WindClock.toDegrees(
                    h,
                  ).toStringAsFixed(0),
                ),
              ),
            ),
          ],
        ),
      ),
      // Hava Durumu no longer shows "Atış girdileri" (owner, 2026-10-08):
      // they come from Profil and are edited there.
      if (!collapseShotInputs) ...[
        const MenzilSectionHeader(
          'Atış girdileri',
          padding: EdgeInsets.only(
            top: MenzilSpace.xxs,
            bottom: MenzilSpace.sm,
          ),
        ),
        MenzilCard(
          padding: const EdgeInsets.fromLTRB(
            MenzilSpace.lg,
            MenzilSpace.lg,
            MenzilSpace.lg,
            MenzilSpace.xxs,
          ),
          child: shotInputs,
        ),
      ],
    ];
  }

  Widget _atmosphereResult(BuildContext context) {
    final c = MenzilColors.of(context);
    if (airDensityKgM3 == null) return const SizedBox.shrink();
    return MenzilCard(
      background: c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hava', style: MenzilType.heading(c.ink, size: 20)),
          const SizedBox(height: MenzilSpace.xs),
          Text(
            'Hava yoğunluğu: ${airDensityKgM3!.toStringAsFixed(4)} kg/m³ • '
            'yoğunluk oranı: ${densityRatio!.toStringAsFixed(3)} • '
            'ses hızı: ${speedOfSoundMps!.toStringAsFixed(1)} m/s • '
            'namlu Mach: ${muzzleMach!.toStringAsFixed(3)}',
            style: MenzilType.body(
              c.ink,
            ).copyWith(fontFeatures: MenzilType.tabular),
          ),
        ],
      ),
    );
  }

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
                        label: Text('Yükseklik mrad'),
                        numeric: true,
                      ),
                      const DataColumn(
                        label: Text('Rüzgâr mrad'),
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
                              : 'Mesafe enerjisi ft-lb',
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
                        label: Text('Yükseklik mrad*'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          metric
                              ? 'Namlu enerjisi J*'
                              : 'Namlu enerjisi ft-lb*',
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
                    DataCell(
                      Text(displayRange.toStringAsFixed(_yards ? 1 : 0)),
                    ),
                    DataCell(Text(displayDrop.toStringAsFixed(1))),
                    DataCell(Text(p.correctionMoa.toStringAsFixed(2))),
                    DataCell(Text(p.correctionMrad.toStringAsFixed(2))),
                    if (drag) ...[
                      DataCell(Text(p.windMrad.abs().toStringAsFixed(2))),
                      DataCell(Text(_windDrift(p).toStringAsFixed(1))),
                      DataCell(
                        Text(
                          (metric
                                  ? p.velocityMps
                                  : UnitSystem.mpsToFps(p.velocityMps))
                              .toStringAsFixed(0),
                        ),
                      ),
                    ],
                    DataCell(Text(displayEnergy.toStringAsFixed(1))),
                    DataCell(Text(p.timeOfFlightS.toStringAsFixed(3))),
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
                  'Sıfır mesafesi ${_toDisplayRange(zeroM).toStringAsFixed(_yards ? 1 : 0)} $_distanceUnit',
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

  // -------------------------------------------------------------------------
  // Pro Ayarlar
  // -------------------------------------------------------------------------

  List<Widget> _proSection(BuildContext context) {
    final c = MenzilColors.of(context);
    final effect = _coriolisEffect();
    String len(double m) => metric
        ? '${(m.abs() * 100).toStringAsFixed(1)} cm'
        : '${UnitSystem.millimetersToInches(m.abs() * 1000).toStringAsFixed(1)} in';
    return [
      const MenzilSectionHeader(
        'Eğim',
        padding: EdgeInsets.only(bottom: MenzilSpace.sm),
      ),
      _angleTiles(context),
      const MenzilSectionHeader(
        'Coriolis',
        padding: EdgeInsets.only(top: MenzilSpace.lg, bottom: MenzilSpace.sm),
      ),
      MenzilCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Coriolis etkisini ekle',
                    style: MenzilType.body(c.ink),
                  ),
                ),
                const MenzilInfoButton(
                  title: 'Coriolis',
                  text: EnvironmentFieldInfo.coriolis,
                ),
                // VoiceOver reads the switch with its name.
                Semantics(
                  label: 'Coriolis etkisini ekle',
                  child: Switch(
                    key: const Key('pro-coriolis-switch'),
                    value: _coriolisOn,
                    onChanged: (v) {
                      _coriolisOn = v;
                      _coriolisChanged();
                    },
                  ),
                ),
              ],
            ),
            if (_coriolisOn) ...[
              const SizedBox(height: MenzilSpace.sm),
              MenzilInput(
                key: const Key('pro-latitude'),
                controller: latitudeCtl,
                label: 'Enlem',
                unit: '°',
                info: EnvironmentFieldInfo.latitude,
                helperText: 'Kuzey +, güney −',
                errorText: latitudeCtl.text.isNotEmpty && _latitude == null
                    ? '−90 ile 90 arasında olmalı.'
                    : null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilSecondaryButton(
                key: const Key('pro-latitude-gps'),
                label: 'Konumdan al',
                icon: Icons.my_location,
                expand: true,
                onPressed: _latitudeFromGps,
              ),
              const SizedBox(height: MenzilSpace.md),
              MenzilInput(
                key: const Key('pro-azimuth'),
                controller: azimuthCtl,
                label: 'Atış yönü (azimut)',
                unit: '°',
                info: EnvironmentFieldInfo.azimuth,
                helperText: 'Kuzey 0 · doğu 90 · güney 180 · batı 270',
                errorText: azimuthCtl.text.isNotEmpty && _azimuth == null
                    ? '0 ile 360 arasında olmalı.'
                    : null,
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilSecondaryButton(
                key: const Key('pro-azimuth-compass'),
                label: 'Pusuladan al',
                icon: Icons.explore_outlined,
                expand: true,
                onPressed: _azimuthFromCompass,
              ),
              if (_coriolisStatus != null) ...[
                const SizedBox(height: MenzilSpace.xs),
                Text(_coriolisStatus!, style: MenzilType.caption(c.ink2)),
              ],
              const SizedBox(height: MenzilSpace.sm),
              Text(
                effect == null
                    ? !_dragMode
                          ? 'Coriolis, BC değeri olan mühimmatla hesaplanır.'
                          : 'Etkiyi görmek için enlem ve atış yönünü girin.'
                    : '$_shotDisplay $_distanceUnit\'de Coriolis: '
                          '${len(effect.up)} ${effect.up >= 0 ? 'yukarı' : 'aşağı'} · '
                          '${len(effect.right)} ${effect.right >= 0 ? 'sağa' : 'sola'}. '
                          'Kule klikleri bunu içerir.',
                key: const Key('pro-coriolis-effect'),
                style: MenzilType.body(c.ink),
              ),
            ],
          ],
        ),
      ),
      const MenzilSectionHeader(
        'Kule ölçek katsayısı',
        padding: EdgeInsets.only(top: MenzilSpace.lg, bottom: MenzilSpace.sm),
      ),
      MenzilInput(
        key: const Key('pro-turret-scale'),
        controller: turretScaleCtl,
        label: 'Gerçek / yazan',
        info: EnvironmentFieldInfo.turretScale,
        hintText: '1.00',
        errorText:
            turretScaleCtl.text.trim().isNotEmpty &&
                (_parsed(turretScaleCtl) == null ||
                    _parsed(turretScaleCtl)! < 0.8 ||
                    _parsed(turretScaleCtl)! > 1.2)
            ? '0,80 ile 1,20 arasında olmalı.'
            : null,
        onChanged: (_) => _coriolisChanged(),
      ),
      const MenzilSectionHeader(
        'Rüzgâr aralığı',
        padding: EdgeInsets.only(top: MenzilSpace.md, bottom: MenzilSpace.sm),
      ),
      MenzilInput(
        key: const Key('pro-wind-max'),
        controller: windMaxCtl,
        label: 'En yüksek rüzgâr',
        unit: metric ? 'm/s' : 'mph',
        info: EnvironmentFieldInfo.windMax,
        helperText: _windMaxAuto ? 'Otomatik: rüzgâr hızı × 1,5' : null,
        onChanged: (v) {
          _windMaxAuto = v.trim().isEmpty;
          _autoWindMax();
          _coriolisChanged();
        },
      ),
      const MenzilSectionHeader(
        'Hareketli hedef',
        padding: EdgeInsets.only(top: MenzilSpace.md, bottom: MenzilSpace.sm),
      ),
      MenzilFieldGrid(
        children: [
          MenzilInput(
            key: const Key('pro-target-speed'),
            controller: targetSpeedCtl,
            label: 'Hedef hızı',
            unit: metric ? 'm/s' : 'mph',
            info: EnvironmentFieldInfo.targetSpeed,
            onChanged: (_) => _coriolisChanged(),
          ),
          MenzilSelect<bool>(
            key: ValueKey('pro-target-direction-$_targetMovesRight'),
            label: 'Yönü',
            info: EnvironmentFieldInfo.targetDirection,
            initialValue: _targetMovesRight,
            items: const [
              DropdownMenuItem(value: true, child: Text('Soldan sağa')),
              DropdownMenuItem(value: false, child: Text('Sağdan sola')),
            ],
            onChanged: (v) {
              _targetMovesRight = v ?? true;
              _coriolisChanged();
            },
          ),
        ],
      ),
      const MenzilSectionHeader(
        'Spin drift',
        padding: EdgeInsets.only(top: MenzilSpace.md, bottom: MenzilSpace.sm),
      ),
      MenzilCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Spin drift ekle', style: MenzilType.body(c.ink)),
                ),
                const MenzilInfoButton(
                  title: 'Spin drift',
                  text: EnvironmentFieldInfo.spinDrift,
                ),
                Semantics(
                  label: 'Spin drift ekle',
                  child: Switch(
                    key: const Key('pro-spin-switch'),
                    value: _spinDriftOn,
                    onChanged: (v) {
                      _spinDriftOn = v;
                      _coriolisChanged();
                    },
                  ),
                ),
              ],
            ),
            if (_spinDriftOn) ...[
              MenzilInput(
                key: const Key('pro-bullet-length'),
                controller: bulletLengthCtl,
                label: 'Mermi uzunluğu',
                unit: 'mm',
                info: EnvironmentFieldInfo.bulletLength,
                onChanged: (_) => _coriolisChanged(),
              ),
              if (profileResolution?.rifle.twistRateIn == null ||
                  profileResolution?.rifle.twistDirection == null)
                const MenzilNotice(
                  tone: MenzilNoticeTone.warning,
                  message:
                      'Profilde yiv yönü veya yiv oranı yok; spin drift '
                      'hesaplanamaz.',
                ),
            ],
          ],
        ),
      ),
      if (_isFirearm) ...[
        const MenzilSectionHeader(
          'Barut sıcaklığı',
          padding: EdgeInsets.only(top: MenzilSpace.md, bottom: MenzilSpace.sm),
        ),
        MenzilFieldGrid(
          children: [
            MenzilInput(
              key: const Key('pro-powder-coef'),
              controller: powderCoefCtl,
              label: 'Katsayı (%/15 °C)',
              info: EnvironmentFieldInfo.powderCoef,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              onChanged: (_) => _coriolisChanged(),
            ),
            MenzilInput(
              key: const Key('pro-powder-temp'),
              controller: powderTempCtl,
              label: 'Ölçüm sıcaklığı',
              unit: '°C',
              info: EnvironmentFieldInfo.powderTemp,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              onChanged: (_) => _coriolisChanged(),
            ),
          ],
        ),
        Builder(
          builder: (context) {
            final v0 = widget.profile?.muzzleVelocityMps;
            final t = _parsed(temperature);
            if (v0 == null || t == null) return const SizedBox.shrink();
            final today = _powderAdjusted(
              v0,
              metric ? t : UnitSystem.fahrenheitToCelsius(t),
            );
            if (today == v0) return const SizedBox.shrink();
            return Text(
              'Bugünkü hız: ${UnitSystem.mpsToFps(today).toStringAsFixed(0)} '
              'fps (profil ${UnitSystem.mpsToFps(v0).toStringAsFixed(0)} fps).',
              key: const Key('pro-powder-today'),
              style: MenzilType.body(c.ink),
            );
          },
        ),
      ],
      const SizedBox(height: MenzilSpace.lg),
      if (widget.onContinueToShot != null)
        MenzilPrimaryButton(
          key: const Key('pro-continue-shot'),
          label: 'Hedef\'e geç',
          icon: Icons.arrow_forward,
          onPressed: widget.onContinueToShot,
        ),
    ];
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
    } else {
      _coriolisStatus = 'Pusula okunamadı; atış yönünü elle girin.';
    }
    _coriolisChanged();
  }

  /// Tüfek eğimi and Dürbün eğimi, side by side (Pro Ayarlar).
  Widget _angleTiles(BuildContext context) {
    final c = MenzilColors.of(context);
    Widget tile({
      required Key key,
      required String title,
      required String value,
      required String info,
      required IconData icon,
      required VoidCallback onTap,
    }) => Expanded(
      child: MenzilCard(
        margin: EdgeInsets.zero,
        background: c.surface2,
        padding: const EdgeInsets.fromLTRB(
          MenzilSpace.md,
          MenzilSpace.xs,
          MenzilSpace.xxs,
          MenzilSpace.sm,
        ),
        child: InkWell(
          key: key,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: c.ink2),
                  const SizedBox(width: MenzilSpace.xxs),
                  Expanded(
                    child: Text(title, style: MenzilType.caption(c.ink2)),
                  ),
                  MenzilInfoButton(title: title, text: info),
                ],
              ),
              Text(value, style: MenzilType.number(c.ink, size: 22)),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        tile(
          key: const Key('shot-incline'),
          title: 'Tüfek eğimi',
          value: '∠ ${ShotAngleMath.degrees(_inclineDeg)}',
          info: EnvironmentFieldInfo.incline,
          icon: Icons.terrain_outlined,
          onTap: _editIncline,
        ),
        const SizedBox(width: MenzilSpace.sm),
        tile(
          key: const Key('shot-cant'),
          title: 'Dürbün eğimi',
          value: _cantDeg == 0
              ? 'Yok'
              : '${ShotAngleMath.degrees(_cantDeg)} '
                    '${_cantDeg > 0 ? 'sağa' : 'sola'}',
          info: EnvironmentFieldInfo.cant,
          icon: Icons.rotate_right,
          onTap: _editCant,
        ),
      ],
    );
  }

  Future<void> _editIncline() async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _InclineDialog(initial: _inclineDeg),
    );
    if (!mounted || result == null) return;
    _setAngles(incline: result);
  }

  Future<void> _editCant() async {
    final result = await Navigator.of(context).push<double>(
      MaterialPageRoute(builder: (_) => ScopeCantScreen(initialDeg: _cantDeg)),
    );
    if (!mounted || result == null) return;
    _setAngles(cant: result);
  }

  List<Widget> _shotSection(BuildContext context) {
    final c = MenzilColors.of(context);
    final shot = _shotPoint();
    final display = _shotDisplay;
    // The shot range may be anything up to the production limit; it is not
    // tied to the last range of the DOPE table (that made the dial stop at
    // the default table's 400 m).
    final sliderMax = math.max(
      display.toDouble(),
      _displayMaxRange.floorToDouble(),
    );

    return [
      // Range dial: −5 −1 [value] +1 +5, slider below.
      Row(
        children: [
          MenzilStepButton(
            label: '−5',
            semanticLabel: '5 azalt',
            onPressed: () => _setShotDisplay(display - 5),
          ),
          const SizedBox(width: MenzilSpace.xs),
          MenzilStepButton(
            label: '−1',
            semanticLabel: '1 azalt',
            small: true,
            onPressed: () => _setShotDisplay(display - 1),
          ),
          Expanded(
            child: Semantics(
              button: true,
              label:
                  'Atış mesafesi $display $_distanceUnit, değiştirmek için dokunun',
              child: ExcludeSemantics(
                child: InkWell(
                  borderRadius: BorderRadius.circular(MenzilRadius.button),
                  onTap: _editShotRange,
                  child: SizedBox(
                    height: 64,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$display',
                            style: MenzilType.display(
                              c.ink,
                              size: display >= 1000 ? 48 : 60,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _distanceUnit,
                            style: MenzilType.number(c.ink2, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          MenzilStepButton(
            label: '+1',
            semanticLabel: '1 artır',
            small: true,
            onPressed: () => _setShotDisplay(display + 1),
          ),
          const SizedBox(width: MenzilSpace.xs),
          MenzilStepButton(
            label: '+5',
            semanticLabel: '5 artır',
            onPressed: () => _setShotDisplay(display + 5),
          ),
        ],
      ),
      Slider(
        value: display.toDouble().clamp(1.0, sliderMax).toDouble(),
        min: 1,
        max: sliderMax,
        label: '$display $_distanceUnit',
        semanticFormatterCallback: (v) => '${v.round()} $_distanceUnit',
        onChanged: (v) => _setShotDisplay(v.round()),
      ),
      const SizedBox(height: MenzilSpace.sm),
      if (shot == null)
        MenzilNotice(
          tone: MenzilNoticeTone.info,
          message: _basis == null
              ? 'Değerler hesaplanamadı. Profil ve Hava Durumu değerlerini kontrol edin.'
              : _dragMode
              ? 'Bu mermi bu mesafeye ulaşamıyor veya değer üretilemedi. Daha kısa bir mesafe deneyin.'
              : 'Bu mesafe için değer üretilemedi. Mesafeyi veya girdileri kontrol edin.',
        ),
      // No Hesapla button (owner, 2026-10-08): Atış is solved automatically
      // whenever it opens, with the Hava Durumu and Pro Ayarlar values.
      const SizedBox(height: MenzilSpace.xs),
      // Without a BC the shot uses the vacuum (no-drag) drop for elevation;
      // wind stays locked — a vacuum model has no aerodynamic coupling, so
      // it cannot produce a real wind value (see BallisticEngine.vacuumDope).
      // With a BC the drag solver (checked against py-ballisticcalc in CI)
      // gives both.
      Padding(
        padding: const EdgeInsets.only(bottom: MenzilSpace.md),
        child: _referenceShotPanel(shot),
      ),
      if (_dragMode) ..._dragNotices(),
      if (!_dragMode)
        const Padding(
          padding: EdgeInsets.only(bottom: MenzilSpace.md),
          child: MenzilNotice(
            tone: MenzilNoticeTone.danger,
            message:
                'Yükseklik kliki, hava direnci YOK sayılan bir vakum düşüşünden hesaplanır — '
                'gerçek mermi menzil arttıkça havadan daha çok yavaşlar, bu nedenle gerçek düşüş '
                'burada gösterilenden FAZLA olur. Rüzgâr düzeltmesi hiç modellenmez (KİLİTLİ). '
                'Bu klik değerini ilk atışta mutlaka canlı atışla (chronograph + deneme atışı) '
                'doğrulayın; tek başına gerçek atış için kullanmayın.',
          ),
        ),
      if (shot != null && _dragMode)
        MenzilMetricGrid(
          metrics: [
            MenzilMetric(
              'Uçuş süresi',
              shot.timeOfFlightS.toStringAsFixed(3),
              's',
            ),
            MenzilMetric(
              'Düşüş',
              (metric
                      ? shot.dropM * 100
                      : UnitSystem.millimetersToInches(shot.dropM * 1000))
                  .toStringAsFixed(1),
              metric ? 'cm' : 'in',
            ),
            MenzilMetric(
              'Hız',
              (metric
                      ? shot.velocityMps
                      : UnitSystem.mpsToFps(shot.velocityMps))
                  .toStringAsFixed(0),
              metric ? 'm/s' : 'fps',
            ),
            MenzilMetric(
              'Enerji',
              (metric
                      ? shot.energyJ
                      : UnitSystem.joulesToFootPounds(shot.energyJ))
                  .toStringAsFixed(1),
              metric ? 'J' : 'ft-lb',
            ),
            if (muzzleMach != null)
              MenzilMetric('Namlu Mach', muzzleMach!.toStringAsFixed(3)),
            if (densityRatio != null)
              MenzilMetric('Yoğunluk oranı', densityRatio!.toStringAsFixed(3)),
          ],
        ),
      if (shot != null && !_dragMode)
        MenzilMetricGrid(
          metrics: [
            MenzilMetric(
              'Uçuş süresi',
              shot.timeOfFlightS.toStringAsFixed(3),
              's',
            ),
            MenzilMetric(
              'Vakum düşüşü*',
              (metric
                      ? shot.dropM * 100
                      : UnitSystem.millimetersToInches(shot.dropM * 1000))
                  .toStringAsFixed(1),
              metric ? 'cm' : 'in',
            ),
            MenzilMetric(
              'Namlu hızı*',
              (metric
                      ? shot.velocityMps
                      : UnitSystem.mpsToFps(shot.velocityMps))
                  .toStringAsFixed(0),
              metric ? 'm/s' : 'fps',
            ),
            MenzilMetric(
              'Namlu enerjisi*',
              (metric
                      ? shot.energyJ
                      : UnitSystem.joulesToFootPounds(shot.energyJ))
                  .toStringAsFixed(1),
              metric ? 'J' : 'ft-lb',
            ),
            if (muzzleMach != null)
              MenzilMetric('Namlu Mach', muzzleMach!.toStringAsFixed(3)),
            if (densityRatio != null)
              MenzilMetric('Yoğunluk oranı', densityRatio!.toStringAsFixed(3)),
          ],
        ),
      Text(
        _dragMode
            ? 'Sürtünmeli hesap (G1/G7 + girilen BC); sabit rüzgâr tüm menzilde uygulanır. '
                  'Klik değerlerini ilk atışta canlı atışla doğrulayın.'
            : '* Vakum temelli (hava direnci modellenmez); rüzgâr düzeltmesi doğrulanmış sürükleme '
                  'modeli gelene kadar hiç gösterilmez. Hız ve enerji namlu değeridir.',
        style: MenzilType.caption(c.ink2),
      ),
    ];
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
  const _InclineDialog({required this.initial});

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
            info: EnvironmentFieldInfo.incline,
            helperText: 'Yukarı +, aşağı −',
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
