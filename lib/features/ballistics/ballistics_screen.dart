import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/atmosphere.dart';
import '../../core/ballistic_engine.dart';
import '../../core/ballistic_input.dart';
import '../../core/dope_ranges.dart';
import '../../core/production_limits.dart';
import '../../core/unit_system.dart';
import '../../data/profile_catalog_integrity.dart';
import '../../models/domain.dart';
import '../../services/settings_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// Which part of the ballistic workspace is shown.
///
/// The Menzil shell shows [shot], [table] and [environment] as separate tabs
/// over ONE state object, so inputs and the last validated solve are shared
/// between them. [all] is the stand-alone route (every section on one page).
enum BallisticsView { all, shot, table, environment }

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
  const BallisticsScreen({
    super.key,
    this.profile,
    this.view = BallisticsView.all,
  });

  @override
  State<BallisticsScreen> createState() => _BallisticsScreenState();
}

/// Inputs of the last successful, fully validated solve. The shot view
/// re-evaluates the same validated inputs at the selected range; it never
/// re-parses the (possibly edited, not yet submitted) text fields.
class _ShotBasis {
  final double velocityMps, grain, zeroRangeM, sightHeightMm;
  final EnvironmentData environment;
  const _ShotBasis({
    required this.velocityMps,
    required this.grain,
    required this.zeroRangeM,
    required this.sightHeightMm,
    required this.environment,
  });
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
      text: (p?.muzzleVelocityMps ?? 270).toStringAsFixed(1),
    );
    grain = TextEditingController(text: (ammo?.grain ?? 51).toString());
    zero = TextEditingController(text: (p?.zeroRangeM ?? 25).toString());
    sight = TextEditingController(text: (p?.sightHeightMm ?? 65).toString());
    wind = TextEditingController(text: '0');
    windDirection = TextEditingController(text: '90');
    temperature = TextEditingController(text: '15');
    pressure = TextEditingController(text: '1013.25');
    humidity = TextEditingController(text: '50');
    altitude = TextEditingController(text: '0');
    ranges = TextEditingController(
      text: '25, 50, 75, 100, 125, 150, 175, 200, 250, 300, 400',
    );
    _loadUnitPreference();
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
    final velocityMps = value(velocity);
    final zeroM = value(zero);
    final sightMm = value(sight);
    final windMps = value(wind);
    final temperatureC = value(temperature);
    final pressureHpa = value(pressure);
    final altitudeM = value(altitude);
    final metricRanges = DopeRanges.parse(ranges.text);

    // Commit only after the complete source form has been validated.
    velocity.text = UnitSystem.mpsToFps(velocityMps).toStringAsFixed(1);
    zero.text = UnitSystem.metersToYards(zeroM).toStringAsFixed(1);
    sight.text = UnitSystem.millimetersToInches(sightMm).toStringAsFixed(2);
    wind.text = UnitSystem.mpsToMph(windMps).toStringAsFixed(1);
    temperature.text = UnitSystem.celsiusToFahrenheit(
      temperatureC,
    ).toStringAsFixed(1);
    pressure.text = UnitSystem.hpaToInHg(pressureHpa).toStringAsFixed(2);
    altitude.text = UnitSystem.metersToFeet(altitudeM).toStringAsFixed(0);
    ranges.text = metricRanges
        .map((e) => UnitSystem.metersToYards(e).toStringAsFixed(1))
        .join(', ');
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
    final v = metric ? rawVelocity! : UnitSystem.fpsToMps(rawVelocity!);
    final g = rawGrain!;
    final z = metric ? rawZero! : UnitSystem.yardsToMeters(rawZero!);
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
      final displayMaxRange = metric
          ? ProductionLimits.maxRangeM
          : UnitSystem.metersToYards(ProductionLimits.maxRangeM);
      final enteredRanges = DopeRanges.parse(
        ranges.text,
        maxRangeM: displayMaxRange,
      );
      final requestedRanges = metric
          ? enteredRanges
          : enteredRanges.map(UnitSystem.yardsToMeters).toList();
      final environment = EnvironmentData(
        temperatureC: temp,
        pressureHpa: pres,
        humidityPercent: hum,
        altitudeM: alt,
        windMps: w,
        windDirectionDeg: wd,
      );
      final density = Atmosphere.densityKgM3(environment);
      final ratio = Atmosphere.densityRatio(environment);
      final sound = Atmosphere.speedOfSoundMps(environment);
      final mach = Atmosphere.machNumber(
        velocityMps: v,
        environment: environment,
      );

      // V1 deliberately runs the labelled vacuum/gravity baseline even when the
      // selected catalog ammunition has BC metadata. Passing that unvalidated BC
      // into BallisticEngine.solve() would correctly trip the production gate and
      // make DOPE unusable for precisely the catalog ammunition that has the best
      // metadata. Keep the BC visible to the user, but do not consume it until the
      // G1/G7 solver has passed independent reference-vector validation.
      final solved = const BallisticEngine().solve(
        BallisticInput(
          muzzleVelocityMps: v,
          grain: g,
          zeroRangeM: z,
          sightHeightMm: s,
          rangesM: requestedRanges,
          environment: environment,
        ),
      );

      setState(() {
        points = solved;
        airDensityKgM3 = density;
        densityRatio = ratio;
        speedOfSoundMps = sound;
        muzzleMach = mach;
        _basis = _ShotBasis(
          velocityMps: v,
          grain: g,
          zeroRangeM: z,
          sightHeightMm: s,
          environment: environment,
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
    super.dispose();
  }

  void _error(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // -------------------------------------------------------------------------
  // Shot (single range) evaluation of the last validated inputs.
  // -------------------------------------------------------------------------

  String get _distanceUnit => metric ? 'm' : 'yd';

  double get _displayMaxRange => metric
      ? ProductionLimits.maxRangeM
      : UnitSystem.metersToYards(ProductionLimits.maxRangeM);

  double _toDisplayRange(double meters) =>
      metric ? meters : UnitSystem.metersToYards(meters);
  double _fromDisplayRange(double value) =>
      metric ? value : UnitSystem.yardsToMeters(value);

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
  /// until a solve has succeeded (fail closed: no basis, no numbers).
  TrajectoryPoint? _shotPoint() {
    final basis = _basis;
    if (basis == null) return null;
    try {
      return const BallisticEngine()
          .solve(
            BallisticInput(
              muzzleVelocityMps: basis.velocityMps,
              grain: basis.grain,
              zeroRangeM: basis.zeroRangeM,
              sightHeightMm: basis.sightHeightMm,
              rangesM: [_shotRangeM],
              environment: basis.environment,
            ),
          )
          .first;
    } on ArgumentError {
      return null;
    } on UnsupportedError {
      return null;
    }
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

  /// Signed elevation correction text: "12,3 MOA (3,6 mrad)" plus a
  /// direction word. Positive [TrajectoryPoint.correctionMrad]/`correctionMoa`
  /// means the point of impact is BELOW the line of sight at this range (the
  /// vacuum drop formula is `atan2(drop, range)`), so the shooter must dial
  /// the turret UP to compensate; negative means dial DOWN (short of zero,
  /// where the bore angle puts the projectile above the line of sight).
  ({String direction, String value}) _elevationCorrectionText(
    TrajectoryPoint shot,
  ) {
    final moa = shot.correctionMoa;
    final mrad = shot.correctionMrad;
    final direction = moa >= 0 ? 'Yukarı' : 'Aşağı';
    final value =
        '${moa.abs().toStringAsFixed(2)} MOA  ·  ${mrad.abs().toStringAsFixed(2)} mrad';
    return (direction: direction, value: value);
  }

  /// Click count on THIS scope's real turret, using its actual click size
  /// and unit from the catalog (clicks only mean something relative to the
  /// specific turret you are holding — a MOA number is not "clicks" on a
  /// mrad turret). Null if the scope has no usable click value.
  int? _elevationClicksOnScope(TrajectoryPoint shot) {
    final s = scope;
    if (s == null || s.clickValue <= 0) return null;
    final correction = s.clickUnit == AngularUnit.moa
        ? shot.correctionMoa
        : shot.correctionMrad;
    return const BallisticEngine().clicks(
      correction: correction,
      clickValue: s.clickValue,
    );
  }

  Widget _referenceShotPanel(TrajectoryPoint? shot) {
    final c = MenzilColors.of(context);
    final correction = shot == null ? null : _elevationCorrectionText(shot);
    final clicks = shot == null ? null : _elevationClicksOnScope(shot);
    final clickUnitLabel = scope?.clickUnit == AngularUnit.moa
        ? 'MOA'
        : 'mrad';
    return MenzilCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.gps_fixed, size: 26, color: c.ink),
              const SizedBox(width: MenzilSpace.sm),
              Expanded(
                child: Text(
                  'Atış görünümü',
                  style: MenzilType.heading(c.ink, size: 22),
                ),
              ),
              Text(
                metric ? 'm' : 'yd',
                style: MenzilType.number(c.ink2, size: 16),
              ),
            ],
          ),
          const SizedBox(height: MenzilSpace.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _statusCard(
                    title: correction == null ? 'Yukarı' : correction.direction,
                    value: correction?.value ?? '—',
                    subtitle: clicks == null
                        ? 'Vakum düşüşünden (sürükleme yok); hesaplayın'
                        : '${clicks.abs()} klik ($clickUnitLabel dürbün)',
                    icon: Icons.vertical_align_top,
                  ),
                ),
                const SizedBox(width: MenzilSpace.md),
                Expanded(
                  child: _statusCard(
                    title: 'Rüzgâr',
                    value: 'KİLİTLİ',
                    subtitle: 'Drag doğrulaması bekleniyor',
                    icon: Icons.air,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MenzilSpace.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenH = MediaQuery.sizeOf(context).height;
              final side = math.min(
                constraints.maxWidth * 0.78,
                math.max(200.0, screenH * 0.42),
              );
              return Center(
                child: Semantics(
                  label:
                      'Retikül önizlemesi. Düzeltme işareti merkeze kilitli.',
                  image: true,
                  child: SizedBox.square(
                    dimension: side,
                    child: CustomPaint(painter: _SafeReticlePainter(c)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: MenzilSpace.sm),
          Text(
            'Retikül önizlemesi • yükseklik değeri solda sayısal olarak veriliyor; '
            'rüzgâr düzeltmesi doğrulanana kadar işaret görsel olarak merkeze kilitlidir.',
            textAlign: TextAlign.center,
            style: MenzilType.caption(c.ink2),
          ),
        ],
      ),
    );
  }

  Widget _statusCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    final c = MenzilColors.of(context);
    return MenzilCard(
      margin: EdgeInsets.zero,
      background: c.surface2,
      padding: const EdgeInsets.all(MenzilSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: c.ink2),
              const SizedBox(width: MenzilSpace.xs),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: MenzilSpace.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: MenzilType.heading(c.ink, size: 24),
            ),
          ),
          const SizedBox(height: MenzilSpace.xxs),
          Text(subtitle, style: MenzilType.caption(c.ink2)),
        ],
      ),
    );
  }

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
            ..._environmentInputs(context, collapseShotInputs: true),
            MenzilPrimaryButton(
              label: 'Hesapla',
              onPressed: solve,
              icon: Icons.calculate_outlined,
            ),
            const SizedBox(height: MenzilSpace.md),
            _atmosphereResult(context),
          ],
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

  Widget _bcNotice() => MenzilNotice(
    tone: MenzilNoticeTone.warning,
    message: ammunition?.ballisticCoefficient == null
        ? 'Deterministik vacuum/gravity temel solver. Bu mühimmat için doğrulanmış BC/model yok; G1/G7 ve rüzgâr düzeltmesi hesaplanmaz.'
        : 'Katalogda ${ammunition!.ballisticModel!.name.toUpperCase()} BC ${ammunition!.ballisticCoefficient} mevcut. Doğrulanmış drag solver tamamlanana kadar bu BC sahte bir hesapta kullanılmayacak.',
  );

  Widget _vacuumFootnote(BuildContext context) {
    final c = MenzilColors.of(context);
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
    unit: metric ? 'm' : 'yd',
    helperText:
        'Virgülle ayırın, en fazla ${_displayMaxRange.toStringAsFixed(0)} ${metric ? 'm' : 'yd'}.',
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
    final shotInputs = MenzilFieldGrid(
      children: [
        MenzilInput(
          key: BallisticsFieldKeys.velocity,
          controller: velocity,
          label: 'Namlu çıkış hızı',
          unit: metric ? 'm/s' : 'fps',
        ),
        MenzilInput(
          key: BallisticsFieldKeys.grain,
          controller: grain,
          label: 'Mühimmat ağırlığı',
          unit: 'grain',
        ),
        MenzilInput(
          key: BallisticsFieldKeys.zero,
          controller: zero,
          label: 'Sıfır mesafesi',
          unit: metric ? 'm' : 'yd',
        ),
        MenzilInput(
          key: BallisticsFieldKeys.sight,
          controller: sight,
          label: 'Dürbün eksen yüksekliği',
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
              unit: metric ? 'hPa' : 'inHg',
            ),
            MenzilInput(
              key: BallisticsFieldKeys.humidity,
              controller: humidity,
              label: 'Bağıl nem',
              unit: '%',
            ),
            MenzilInput(
              key: BallisticsFieldKeys.altitude,
              controller: altitude,
              label: 'İrtifa',
              unit: metric ? 'm' : 'ft',
              helperText: 'Kayıt/referans',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ],
        ),
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
              unit: metric ? 'm/s' : 'mph',
            ),
            MenzilInput(
              key: BallisticsFieldKeys.windDirection,
              controller: windDirection,
              label: 'Rüzgâr yönü',
              unit: '°',
              helperText: '90 = tam yan',
            ),
          ],
        ),
      ),
      if (collapseShotInputs)
        MenzilAccordion(
          title: 'Atış girdileri',
          subtitle: 'Profilden gelir; yalnız bu oturum için değiştirin.',
          child: shotInputs,
        )
      else ...[
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
    return [
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
              columns: [
                DataColumn(label: Text(metric ? 'm' : 'yd')),
                DataColumn(
                  label: Text(metric ? 'Vakum düşüşü cm*' : 'Vakum düşüşü in*'),
                  numeric: true,
                ),
                const DataColumn(label: Text('Yükseklik MOA*'), numeric: true),
                const DataColumn(
                  label: Text('Yükseklik mrad*'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    metric ? 'Namlu enerjisi J*' : 'Namlu enerjisi ft-lb*',
                  ),
                  numeric: true,
                ),
                const DataColumn(label: Text('TOF'), numeric: true),
              ],
              rows: points.map((p) {
                final displayRange = metric
                    ? p.rangeM
                    : UnitSystem.metersToYards(p.rangeM);
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
                      Text(displayRange.toStringAsFixed(metric ? 0 : 1)),
                    ),
                    DataCell(Text(displayDrop.toStringAsFixed(1))),
                    DataCell(Text(p.correctionMoa.toStringAsFixed(2))),
                    DataCell(Text(p.correctionMrad.toStringAsFixed(2))),
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
                  'Sıfır mesafesi ${_toDisplayRange(zeroM).toStringAsFixed(metric ? 0 : 1)} $_distanceUnit',
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

  List<Widget> _shotSection(BuildContext context) {
    final c = MenzilColors.of(context);
    final shot = _shotPoint();
    final display = _shotDisplay;
    final sliderMax = math.max(
      display.toDouble(),
      math.min(
        _displayMaxRange.floorToDouble(),
        points.isEmpty
            ? (metric ? 400.0 : 440.0)
            : _toDisplayRange(points.last.rangeM).ceilToDouble(),
      ),
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
      if (shot == null) ...[
        MenzilNotice(
          tone: MenzilNoticeTone.info,
          message: _basis == null
              ? 'Değerleri görmek için hesaplayın. Ortam ve atış girdileri Ortam sekmesindedir.'
              : 'Bu mesafe için değer üretilemedi. Mesafeyi veya girdileri kontrol edin.',
        ),
        MenzilPrimaryButton(
          label: 'Hesapla',
          onPressed: solve,
          icon: Icons.calculate_outlined,
          amber: true,
        ),
        const SizedBox(height: MenzilSpace.md),
      ],
      // V354: elevation correction/clicks are shown from the vacuum (no-drag)
      // drop, which is valid trigonometry (atan2(drop, range)) independent of
      // the unvalidated G1/G7 drag model. Wind stays locked — a vacuum model
      // has no aerodynamic coupling, so it cannot produce a real wind value
      // (see BallisticEngine.vacuumDope's windMrad == 0.0 comment).
      Padding(
        padding: const EdgeInsets.only(bottom: MenzilSpace.md),
        child: _referenceShotPanel(shot),
      ),
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
      if (shot != null)
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
        '* Vakum temelli (hava direnci modellenmez); rüzgâr düzeltmesi doğrulanmış sürükleme '
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
      unit: widget.unit,
      textInputAction: TextInputAction.done,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('İptal'),
      ),
      FilledButton(onPressed: _apply, child: const Text('Uygula')),
    ],
  );
}

class _SafeReticlePainter extends CustomPainter {
  final MenzilColors colors;
  const _SafeReticlePainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.44;
    canvas.drawCircle(center, radius, Paint()..color = colors.scopeBg);
    final main = Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fine = Paint()
      ..color = colors.scopeLine
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, main);
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      main,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      main,
    );
    for (var i = -3; i <= 3; i++) {
      if (i == 0) continue;
      final d = radius * i / 4;
      canvas.drawLine(
        Offset(center.dx + d, center.dy - 7),
        Offset(center.dx + d, center.dy + 7),
        fine,
      );
      canvas.drawLine(
        Offset(center.dx - 7, center.dy + d),
        Offset(center.dx + 7, center.dy + d),
        fine,
      );
    }
    canvas.drawCircle(center, 6, Paint()..color = colors.amber);
  }

  @override
  bool shouldRepaint(covariant _SafeReticlePainter oldDelegate) =>
      oldDelegate.colors != colors;
}
