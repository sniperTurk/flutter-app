import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../core/atmosphere.dart';
import '../../core/ballistic_engine.dart';
import '../../core/ballistic_input.dart';
import '../../core/dope_ranges.dart';
import '../../core/drag_safety.dart';
import '../../core/gravity.dart';
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
import 'dope_card.dart';
import 'environment_field_info.dart';
import 'incline_measure_screen.dart';
import 'pro_section_info.dart';
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

  /// Shell only, no profile yet: Hava Durumu stays usable and offers this
  /// (owner, 2026-10-10).
  final VoidCallback? onCreateProfile;

  const BallisticsScreen({
    super.key,
    this.profile,
    this.view = BallisticsView.all,
    this.autoWeather = false,
    this.onContinueToPro,
    this.onContinueToShot,
    this.onCreateProfile,
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

  /// Local gravity of the shooting place (m/s²).
  final double gravityMps2;
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
        _gravityOn = s.gravityOn;
        gravityCtl.text = s.gravityText;
        latitudeCtl.text = s.latitudeText;
        azimuthCtl.text = s.azimuthText;
        turretScaleCtl.text = s.turretScaleText;
        _windMaxAuto = s.windMaxText.isEmpty && !s.windMaxOff;
        windMaxCtl.text = s.windMaxText;
        _autoWindMax();
        targetSpeedCtl.text = s.targetSpeedText;
        _targetMovesRight = s.targetMovesRight;
        _spinDriftOn = s.spinDriftOn;
        bulletLengthCtl.text = s.bulletLengthText;
        powderCoefCtl.text = s.powderCoefText;
        powderTempCtl.text = s.powderTempText;
        windMidCtl.text = s.windMidText;
        windFarCtl.text = s.windFarText;
        zeroUpCtl.text = s.zeroUpText;
        zeroRightCtl.text = s.zeroRightText;
        groupCtl.text = s.groupText;
        sdCtl.text = s.sdText;
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
      gravityOn: _gravityOn,
      gravityText: gravityCtl.text.trim(),
      latitudeText: latitudeCtl.text.trim(),
      azimuthText: azimuthCtl.text.trim(),
      turretScaleText: turretScaleCtl.text.trim(),
      windMaxText: _windMaxAuto ? '' : windMaxCtl.text.trim(),
      windMaxOff: !_windMaxAuto && windMaxCtl.text.trim().isEmpty,
      targetSpeedText: targetSpeedCtl.text.trim(),
      targetMovesRight: _targetMovesRight,
      spinDriftOn: _spinDriftOn,
      bulletLengthText: bulletLengthCtl.text.trim(),
      powderCoefText: powderCoefCtl.text.trim(),
      powderTempText: powderTempCtl.text.trim(),
      windMidText: windMidCtl.text.trim(),
      windFarText: windFarCtl.text.trim(),
      zeroUpText: zeroUpCtl.text.trim(),
      zeroRightText: zeroRightCtl.text.trim(),
      groupText: groupCtl.text.trim(),
      sdText: sdCtl.text.trim(),
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
  /// 2026-10-09) until the shooter types a value. Clearing it turns the
  /// bracket off (owner, 2026-10-10: the shooter must be able to delete an
  /// automatic value); "Otomatik doldur" switches back. An automatic value
  /// is not saved.
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
  bool? _targetMovesRight;
  bool _spinDriftOn = false;
  final TextEditingController bulletLengthCtl = TextEditingController();
  final TextEditingController powderCoefCtl = TextEditingController();
  final TextEditingController powderTempCtl = TextEditingController();
  final TextEditingController windMidCtl = TextEditingController();
  final TextEditingController windFarCtl = TextEditingController();
  final TextEditingController zeroUpCtl = TextEditingController();
  final TextEditingController zeroRightCtl = TextEditingController();
  final TextEditingController groupCtl = TextEditingController();
  final TextEditingController sdCtl = TextEditingController();

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
  /// Gyroscopic stability (Miller) with the bullet length and length in
  /// calibres, or null when spin drift is off or data is missing.
  ({double sg, double lCal, TwistDirection dir})? _stability(_ShotBasis basis) {
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
    return (sg: sg, lCal: lCal, dir: dir);
  }

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

  /// Pro → Yerçekimi (owner, 2026-10-10): off = standard gravity; on =
  /// the local value in [gravityCtl] (computed from the location).
  bool _gravityOn = false;
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
      // Altitude: the Hava Durumu value, else the GPS height.
      final typedAlt = _parsed(altitude);
      final altM = typedAlt != null
          ? (metric ? typedAlt : UnitSystem.feetToMeters(typedAlt))
          : (fix.altitudeM ?? 0);
      final g = Gravity.at(latitudeDeg: fix.latitude, altitudeM: altM);
      gravityCtl.text = g.toStringAsFixed(4);
      _gravityStatus =
          'Konumdan hesaplandı: ${fix.latitude.abs().toStringAsFixed(1)}° '
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
    _EnvironmentCarry.apply(this);
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
          gravityMps2: input.gravityMps2,
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
    // Weather typed before the first profile carries over to the profile's
    // workspace (owner, 2026-10-10: "bu değerler hesaba otomatik girer").
    if (widget.profile == null && widget.onCreateProfile != null) {
      _EnvironmentCarry.save(this);
    }
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
    proRangeCtl.dispose();
    for (final c in [
      windMidCtl,
      windFarCtl,
      zeroUpCtl,
      zeroRightCtl,
      groupCtl,
      sdCtl,
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

  Widget _environmentWithoutProfile(BuildContext context) {
    final c = MenzilColors.of(context);
    return MenzilPage(
      key: const PageStorageKey('ballistics-environment-empty'),
      children: [
        MenzilCard(
          key: const Key('environment-no-profile'),
          background: c.amberSoft,
          child: Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: c.amberInk, size: 28),
              const SizedBox(width: MenzilSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hava hazır, sıra tüfekte',
                      style: MenzilType.heading(c.ink, size: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Profil oluşturunca bu değerler her atışın hesabına '
                      'otomatik girer.',
                      style: MenzilType.caption(c.amberInk),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MenzilSpace.sm),
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
        MenzilPrimaryButton(
          key: const Key('environment-create-profile'),
          label: 'Profil oluştur',
          icon: Icons.add,
          amber: true,
          onPressed: widget.onCreateProfile,
        ),
      ],
    );
  }

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
      final jump = _aeroJumpMrad(basis);
      final jm = jump == null ? 0.0 : math.tan(jump.abs() / 1000) * _shotRangeM;
      final jLen = metric
          ? '${(jm * 100).toStringAsFixed(1)} cm'
          : '${UnitSystem.millimetersToInches(jm * 1000).toStringAsFixed(1)} in';
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
    final hit = _hitProbability(shot, basis);
    if (hit != null) {
      lines.add(
        Text(
          'İsabet olasılığı: %${(hit * 100).round()} '
          '(Ø${metric ? '10 cm' : '3.9 in'} hedef, $_shotDisplay $_distanceUnit).',
          key: const Key('shot-hit-probability'),
          style: MenzilType.body(c.ink),
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
          ? '${(leadM * 100).toStringAsFixed(0)} cm'
          : '${UnitSystem.millimetersToInches(leadM * 1000).toStringAsFixed(1)} in';
      lines.add(
        Text(
          'Hareketli hedef (${_windLabel(speed)} ${metric ? 'm/s' : 'mph'}, '
          '${movesRight ? 'soldan sağa' : 'sağdan sola'}): '
          '$len · ${clicks(mrad)} ${movesRight ? 'sağına' : 'soluna'} '
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

  /// DOPE kartı rows for the active profile in today's conditions: level,
  /// no Coriolis; clicks include the zero offset and the turret scale.
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
    String num1(double v) => v.toStringAsFixed(unit.moaFamily ? 1 : 2);
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
            '${basis.ballisticCoefficient} '
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
        ('Dürbün', '${unit.label}, $click ${unit.label}/klik'),
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
        'Tık',
        'Yan rüzgâr ${metric ? '3 m/s' : '5 mph'} (tık)',
        'Hız (fps)',
      ],
      rows: rows,
      notes: [
        'Değerler yukarıdaki hava koşullarıyla hesaplandı; sıcaklık ve basınç '
            'değişirse uzak mesafede kayar.',
        'Yan rüzgâr sütunu saat 3 veya 9 yönünden tam yan rüzgâr içindir: '
            'rüzgâr sağdan esiyorsa sağa, soldan esiyorsa sola çevirin.',
        if (zeroOff.up != 0 || zeroOff.right != 0)
          'Sıfır ofseti tıklara dahildir.',
        if (scale != 1) 'Kule ölçek katsayısı ($scale) tıklara dahildir.',
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
        regular: await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
        bold: await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
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
  double? _hitProbability(TrajectoryPoint shot, _ShotBasis basis) {
    final zero = widget.profile?.zeroRangeM;
    final g = _parsed(groupCtl);
    if (zero == null || zero <= 0 || g == null || g <= 0 || g > 100) {
      return null;
    }
    final groupM = metric ? g / 100 : UnitSystem.inchesToMillimeters(g) / 1000;
    final sigmaG = math.atan(groupM / zero) * 1000 / 3.067;
    var sigmaV = 0.0;
    final sdFps = _parsed(sdCtl);
    if (sdFps != null && sdFps > 0 && sdFps <= 200) {
      try {
        final args = _coriolisArgs;
        final fast = const BallisticEngine()
            .solve(
              basis.input(
                [_shotRangeM],
                inclineDeg: _inclineDeg,
                cantDeg: _cantDeg,
                latitudeDeg: args.lat,
                azimuthDeg: args.az,
                shotVelocityMps: basis.velocityMps + UnitSystem.fpsToMps(sdFps),
              ),
            )
            .single;
        sigmaV = (fast.correctionMrad - shot.correctionMrad).abs();
      } on ArgumentError {
        sigmaV = 0;
      } on StateError {
        sigmaV = 0;
      }
    }
    var sigmaH = 0.0;
    final windMax = _windMaxMps;
    final mpsPerMil = basis.drag ? _evalShot().mpsPerMil : null;
    final wind = basis.environment.windMps;
    if (windMax != null &&
        windMax > wind &&
        mpsPerMil != null &&
        mpsPerMil > 0) {
      sigmaH = (windMax - wind) / 2 / mpsPerMil;
    }
    final sx = math.sqrt(sigmaG * sigmaG + sigmaH * sigmaH);
    final sy = math.sqrt(sigmaG * sigmaG + sigmaV * sigmaV);
    final r = math.atan(0.05 / _shotRangeM) * 1000;
    return (1 - math.exp(-r * r / (2 * sx * sy))).clamp(0.0, 1.0).toDouble();
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

  /// One Pro Ayarlar box: a tappable header with a short summary; the
  /// content (explanation first) shows only while it is the open box
  /// (owner, 2026-10-09: all boxes start closed, one open at a time).
  Widget _proBox({
    required String id,
    required String title,
    required String summary,
    required List<Widget> children,
  }) {
    final c = MenzilColors.of(context);
    final open = _proOpen == id;
    return MenzilCard(
      key: Key('pro-box-$id'),
      margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              key: Key('pro-section-$id'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _proOpen = open ? null : id),
              // 44 pt minimum tap target (VoiceOver / HIG).
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: MenzilType.heading(c.ink, size: 18),
                      ),
                    ),
                    if (!open)
                      Flexible(
                        child: Text(
                          summary,
                          key: Key('pro-summary-$id'),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MenzilType.caption(c.ink2),
                        ),
                      ),
                    const SizedBox(width: MenzilSpace.xs),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      color: c.ink2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open) ...[const SizedBox(height: MenzilSpace.sm), ...children],
        ],
      ),
    );
  }

  /// Ne? / Neden önemli? / Nasıl? block of one setting.
  Widget _explain(ProExplain e, {String? note}) {
    final c = MenzilColors.of(context);
    TextSpan part(String label, String text) => TextSpan(
      children: [
        TextSpan(
          text: '$label ',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        TextSpan(text: '$text\n'),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(
        top: MenzilSpace.sm,
        bottom: MenzilSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            e.title,
            style: MenzilType.body(c.ink).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: MenzilSpace.xxs),
          Text.rich(
            TextSpan(
              children: [
                part('Ne?', e.what),
                part('Neden önemli?', e.why),
                part('Nasıl?', e.how),
              ],
            ),
            style: MenzilType.caption(c.ink2).copyWith(height: 1.35),
          ),
          if (note != null)
            Text(
              note,
              key: const Key('pro-spin-pcp-note'),
              style: MenzilType.caption(c.amberInk),
            ),
        ],
      ),
    );
  }

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

  String _summaryAngle() {
    final i = _inclineDeg.round(), k = _cantDeg.round();
    return i == 0 && k == 0 ? 'düz' : '$i° / $k°';
  }

  String _summaryWind() {
    if (_windZones != null) return 'bölgeli';
    final m = _windMaxMps;
    return m == null
        ? 'kapalı'
        : 'en çok ${_windLabel(m)} ${metric ? 'm/s' : 'mph'}';
  }

  String _summaryTarget() {
    final on = [
      if (_targetSpeedMps != null) 'hareketli',
      if ((_parsed(groupCtl) ?? 0) > 0) 'isabet',
    ];
    return on.isEmpty ? 'kapalı' : on.join(' · ');
  }

  String _summaryRifle() {
    final zero = _zeroOffsetMrad;
    final n = [
      turretScaleCtl.text.trim().isNotEmpty,
      zero.up != 0 || zero.right != 0,
      _spinDriftOn,
      _isFirearm &&
          powderCoefCtl.text.trim().isNotEmpty &&
          powderTempCtl.text.trim().isNotEmpty,
    ].where((x) => x).length;
    return n == 0 ? 'kapalı' : '$n ayar açık';
  }

  List<Widget> _proSection(BuildContext context) {
    final c = MenzilColors.of(context);
    final effect = _coriolisEffect();
    final windUnit = metric ? 'm/s' : 'mph';
    final lenUnit = metric ? 'cm' : 'in';
    const signed = TextInputType.numberWithOptions(decimal: true, signed: true);
    String len(double m) => metric
        ? '${(m.abs() * 100).toStringAsFixed(1)} cm'
        : '${UnitSystem.millimetersToInches(m.abs() * 1000).toStringAsFixed(1)} in';
    return [
      MenzilCard(
        key: const Key('pro-range-card'),
        margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenzilInput(
              key: const Key('pro-shot-range'),
              controller: proRangeCtl,
              label: 'Atış mesafesi',
              unit: _distanceUnit,
              info: EnvironmentFieldInfo.proShotRange,
              hintText: _yards ? '110' : '100',
              errorText:
                  proRangeCtl.text.trim().isNotEmpty && _proRangeM == null
                  ? '1 ile ${_displayMaxRange.toStringAsFixed(0)} '
                        '$_distanceUnit arasında olmalı.'
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            MenzilSecondaryButton(
              key: const Key('pro-range-map'),
              label: 'Haritadan ölç',
              icon: Icons.map_outlined,
              expand: true,
              onPressed: _proRangeFromMap,
            ),
            const SizedBox(height: MenzilSpace.xs),
            Text(
              'Mesafeyi bilmiyorsan haritadan ölç. Hedef\'e geçince dürbün '
              'bu mesafeye kurulmuş gelir. Boş bırakırsan Hedef '
              '${_yards ? '100 yd' : '100 m'} ile açılır.',
              style: MenzilType.caption(c.ink2),
            ),
          ],
        ),
      ),
      _proBox(
        id: 'angle',
        title: 'Açı',
        summary: _summaryAngle(),
        children: [
          _angleTiles(context),
          _explain(ProSectionInfo.incline),
          _explain(ProSectionInfo.cant),
        ],
      ),
      _proBox(
        id: 'wind',
        title: 'Rüzgâr',
        summary: _summaryWind(),
        children: [
          _explain(ProSectionInfo.windMax),
          MenzilInput(
            key: const Key('pro-wind-max'),
            controller: windMaxCtl,
            label: 'En yüksek rüzgâr',
            unit: windUnit,
            info: EnvironmentFieldInfo.windMax,
            helperText: _windMaxAuto
                ? 'Otomatik: rüzgâr hızı × 1,5'
                : windMaxCtl.text.trim().isEmpty
                ? 'Boş: rüzgâr aralığı gösterilmez.'
                : null,
            onChanged: (v) {
              _windMaxAuto = false;
              _coriolisChanged();
            },
          ),
          if (!_windMaxAuto)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('pro-wind-max-auto'),
                onPressed: () {
                  _windMaxAuto = true;
                  _autoWindMax();
                  _coriolisChanged();
                },
                icon: const Icon(Icons.autorenew, size: 18),
                label: const Text('Otomatik doldur'),
              ),
            ),
          _explain(ProSectionInfo.windZones),
          MenzilFieldGrid(
            children: [
              MenzilInput(
                key: const Key('pro-wind-mid'),
                controller: windMidCtl,
                label: 'Yol ortası',
                unit: windUnit,
                info: EnvironmentFieldInfo.windMid,
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilInput(
                key: const Key('pro-wind-far'),
                controller: windFarCtl,
                label: 'Hedefte',
                unit: windUnit,
                info: EnvironmentFieldInfo.windFar,
                onChanged: (_) => _coriolisChanged(),
              ),
            ],
          ),
        ],
      ),
      _proBox(
        id: 'coriolis',
        title: 'Coriolis',
        summary: _coriolisOn ? 'açık' : 'kapalı',
        children: [
          _explain(ProSectionInfo.coriolis),
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
              keyboardType: signed,
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
      _proBox(
        id: 'gravity',
        title: 'Yerçekimi',
        summary: _gravityOn ? 'açık' : 'kapalı',
        children: [
          _explain(ProSectionInfo.gravity),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Yerçekimi etkisini ekle',
                  style: MenzilType.body(c.ink),
                ),
              ),
              const MenzilInfoButton(
                title: 'Yerçekimi',
                text: EnvironmentFieldInfo.gravity,
              ),
              Semantics(
                label: 'Yerçekimi etkisini ekle',
                child: Switch(
                  key: const Key('pro-gravity-switch'),
                  value: _gravityOn,
                  onChanged: (v) {
                    _gravityOn = v;
                    _gravityChanged();
                  },
                ),
              ),
            ],
          ),
          if (_gravityOn) ...[
            const SizedBox(height: MenzilSpace.sm),
            MenzilInput(
              key: const Key('pro-gravity'),
              controller: gravityCtl,
              label: 'Yerçekimi',
              unit: 'm/s²',
              info: EnvironmentFieldInfo.gravity,
              helperText: 'Enlem ve irtifaya göre',
              errorText: gravityCtl.text.isNotEmpty && _gravityTyped == null
                  ? '9,7 ile 9,9 arasında olmalı.'
                  : null,
              onChanged: (_) => _gravityChanged(),
            ),
            MenzilSecondaryButton(
              key: const Key('pro-gravity-gps'),
              label: 'Konumdan hesapla',
              icon: Icons.my_location,
              expand: true,
              onPressed: _gravityFromLocation,
            ),
            if (_gravityStatus != null) ...[
              const SizedBox(height: MenzilSpace.xs),
              Text(_gravityStatus!, style: MenzilType.caption(c.ink2)),
            ],
            const SizedBox(height: MenzilSpace.sm),
            Builder(
              builder: (context) {
                final e = _gravityEffect();
                final mm = e == null ? null : e * 1000;
                String mmText(double v) =>
                    v.abs().toStringAsFixed(1).replaceAll('.', ',');
                return Text(
                  mm == null
                      ? 'Etkiyi görmek için "Konumdan hesapla"ya dokunun.'
                      : mm.abs() < 0.05
                      ? '$_shotDisplay $_distanceUnit\'de yerçekimi farkı '
                            'yok denecek kadar az (sıfır mesafesinde etkisi '
                            'sıfırdır; uzak mesafede büyür).'
                      : '$_shotDisplay $_distanceUnit\'de yerçekimi: mermi '
                            '${mmText(mm)} mm '
                            '${mm >= 0 ? 'daha az' : 'daha çok'} düşer '
                            '(standart 9,80665 m/s²\'ye göre). Kule klikleri '
                            'bunu içerir.',
                  key: const Key('pro-gravity-effect'),
                  style: MenzilType.body(c.ink),
                );
              },
            ),
          ],
        ],
      ),
      _proBox(
        id: 'target',
        title: 'Hareketli hedef',
        summary: _summaryTarget(),
        children: [
          _explain(ProSectionInfo.movingTarget),
          MenzilFieldGrid(
            children: [
              MenzilInput(
                key: const Key('pro-target-speed'),
                controller: targetSpeedCtl,
                label: 'Hedef hızı',
                unit: windUnit,
                info: EnvironmentFieldInfo.targetSpeed,
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilSelect<bool>(
                key: ValueKey('pro-target-direction-$_targetMovesRight'),
                label: 'Yönü',
                info: EnvironmentFieldInfo.targetDirection,
                initialValue: _targetMovesRight,
                // "Seçiniz" stays in the list so a choice can be taken back
                // (owner, 2026-10-10).
                items: const [
                  DropdownMenuItem<bool>(child: Text('Seçiniz')),
                  DropdownMenuItem(value: true, child: Text('Soldan sağa')),
                  DropdownMenuItem(value: false, child: Text('Sağdan sola')),
                ],
                onChanged: (v) {
                  _targetMovesRight = v;
                  _coriolisChanged();
                },
              ),
            ],
          ),
          _explain(ProSectionInfo.hitProbability),
          MenzilFieldGrid(
            children: [
              MenzilInput(
                key: const Key('pro-group'),
                controller: groupCtl,
                label: 'Grup çapı',
                unit: lenUnit,
                info: EnvironmentFieldInfo.group,
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilInput(
                key: const Key('pro-sd'),
                controller: sdCtl,
                label: 'Hız farkı (SD)',
                unit: 'fps',
                info: EnvironmentFieldInfo.sd,
                onChanged: (_) => _coriolisChanged(),
              ),
            ],
          ),
        ],
      ),
      _proBox(
        id: 'rifle',
        title: 'Tüfek düzeltmeleri',
        summary: _summaryRifle(),
        children: [
          _explain(ProSectionInfo.turretScale),
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
          _explain(ProSectionInfo.zeroOffset),
          MenzilFieldGrid(
            children: [
              MenzilInput(
                key: const Key('pro-zero-up'),
                controller: zeroUpCtl,
                label: 'Yukarı (+) / aşağı (−)',
                unit: lenUnit,
                info: EnvironmentFieldInfo.zeroUp,
                keyboardType: signed,
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilInput(
                key: const Key('pro-zero-right'),
                controller: zeroRightCtl,
                label: 'Sağ (+) / sol (−)',
                unit: lenUnit,
                info: EnvironmentFieldInfo.zeroRight,
                keyboardType: signed,
                onChanged: (_) => _coriolisChanged(),
              ),
            ],
          ),
          _explain(
            ProSectionInfo.spinDrift,
            note: _isFirearm ? null : ProSectionInfo.spinDriftPcpNote,
          ),
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
          if (_isFirearm) ...[
            _explain(ProSectionInfo.powder),
            MenzilFieldGrid(
              children: [
                MenzilInput(
                  key: const Key('pro-powder-coef'),
                  controller: powderCoefCtl,
                  label: 'Katsayı (%/15 °C)',
                  info: EnvironmentFieldInfo.powderCoef,
                  keyboardType: signed,
                  onChanged: (_) => _coriolisChanged(),
                ),
                MenzilInput(
                  key: const Key('pro-powder-temp'),
                  controller: powderTempCtl,
                  label: 'Ölçüm sıcaklığı',
                  unit: '°C',
                  info: EnvironmentFieldInfo.powderTemp,
                  keyboardType: signed,
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
        ],
      ),
      const SizedBox(height: MenzilSpace.md),
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
      if (_basis != null)
        Padding(
          padding: const EdgeInsets.only(bottom: MenzilSpace.md),
          child: MenzilSecondaryButton(
            key: const Key('shot-dope-pdf'),
            label: 'DOPE kartını paylaş (PDF)',
            icon: Icons.picture_as_pdf_outlined,
            expand: true,
            onPressed: _shareDopeCard,
          ),
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

/// Hava Durumu values entered before any profile existed, in SI units, for
/// the first profile workspace that opens afterwards.
abstract final class _EnvironmentCarry {
  static Map<String, double>? _si;
  static Set<String> _edited = {};

  static void save(_BallisticsScreenState s) {
    double? n(TextEditingController c) =>
        double.tryParse(c.text.trim().replaceAll(',', '.'));
    final t = n(s.temperature), p = n(s.pressure), h = n(s.humidity);
    final a = n(s.altitude), w = n(s.wind), d = n(s.windDirection);
    if (t == null || p == null || h == null || a == null || w == null) return;
    final m = s.metric;
    _si = {
      'temperature': m ? t : UnitSystem.fahrenheitToCelsius(t),
      'pressure': m ? p : UnitSystem.inHgToHpa(p),
      'humidity': h,
      'altitude': m ? a : UnitSystem.feetToMeters(a),
      'wind': m ? w : UnitSystem.mphToMps(w),
      if (d != null) 'windDirection': d,
    };
    _edited = {
      if (s._userEdited.contains(s.temperature)) 'temperature',
      if (s._userEdited.contains(s.pressure)) 'pressure',
      if (s._userEdited.contains(s.humidity)) 'humidity',
      if (s._userEdited.contains(s.altitude)) 'altitude',
      if (s._userEdited.contains(s.wind)) 'wind',
    };
  }

  /// Fields start in SI; the unit preference converts them afterwards.
  static void apply(_BallisticsScreenState s) {
    final si = _si;
    if (si == null) return;
    String f(double v) => v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : double.parse(v.toStringAsFixed(2)).toString();
    final fields = {
      'temperature': s.temperature,
      'pressure': s.pressure,
      'humidity': s.humidity,
      'altitude': s.altitude,
      'wind': s.wind,
      'windDirection': s.windDirection,
    };
    for (final MapEntry(:key, :value) in fields.entries) {
      final v = si[key];
      if (v == null) continue;
      value.text = f(v);
      if (_edited.contains(key)) s._userEdited.add(value);
    }
    // A profile workspace takes the values over; a later no-profile page
    // starts from them again only until then.
    if (s.widget.profile != null) {
      _si = null;
      _edited = {};
    }
  }
}
