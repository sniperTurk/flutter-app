import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/production_limits.dart';
import '../../core/scope_dial.dart';
import '../../models/domain.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// Stable keys for widget tests.
abstract final class ScopeDialKeys {
  static const elevationDrum = ValueKey('scope-elevation-drum');
  static const windageDrum = ValueKey('scope-windage-drum');
  static const reticle = ValueKey('scope-reticle');
  static const impactText = ValueKey('scope-impact-text');
  static const dialSolution = ValueKey('scope-dial-solution');
  static const reset = ValueKey('scope-reset');
  static const magnification = ValueKey('scope-magnification');
  static const turretToggle = ValueKey('scope-turret-toggle');
  static const fitNote = ValueKey('scope-fit-note');
  static const travelNote = ValueKey('scope-travel-note');
  static const mountNote = ValueKey('scope-mount-note');
  static const mountZeroNote = ValueKey('scope-mount-zero-note');
  static const workings = ValueKey('scope-workings');
}

/// Interactive scope: elevation turret on top, windage turret on the right,
/// and a reticle that shows where the shot lands for the dialled clicks.
///
/// The view is stateless; the parent owns the click counts so they survive
/// tab switches together with the rest of the ballistic workspace.
///
/// The required windage comes from the drag solver (0 in the vacuum
/// baseline, which has no wind model): with it the impact marker shows
/// where the shot lands for the dialled windage in the entered wind.
class ScopeDialView extends StatelessWidget {
  final AngularUnit unit;
  final double clickValue;
  final int elevationClicks;
  final int windageClicks;

  /// UP travel of the elevation turret from zero, in clicks (a canted
  /// mount is already included).
  final int maxElevationClicks;

  /// DOWN travel from zero, in clicks; null = same as [maxElevationClicks].
  /// A canted mount takes its clicks from here.
  final int? maxElevationDownClicks;

  /// Slope of the scope mount (Dürbün ayağı) in MOA and the UP clicks it
  /// adds; 0 for a normal mount.
  final double mountCantMoa;
  final int mountCantClicks;

  /// True when the turret travel comes from the scope's catalog data (not
  /// the generic fallback), so a mount size can be suggested.
  final bool travelKnown;

  /// Half of the scope's total elevation travel, in clicks (the zero sits in
  /// the middle of the travel); null when the travel is not known. A mount
  /// larger than this cannot be zeroed at all.
  final int? halfElevationClicks;
  final int maxWindageClicks;
  final ValueChanged<int> onElevationChanged;
  final ValueChanged<int> onWindageChanged;

  /// Incremented by the owner after "Çözümü kuleye kur"; each change slides
  /// the windage (right) turret open (owner, 2026-10-09).
  final int windageRevealToken;

  /// Called after "Çözümü kuleye kur" has dialled both turrets.
  final VoidCallback? onSolutionDialed;

  /// Required elevation at [rangeM] in [unit] (positive = dial up). Null
  /// until a validated solve exists: no impact marker, no hold labels.
  final double? requiredUp;

  /// Required windage at [rangeM] in [unit] (positive = dial RIGHT). Zero
  /// when the solver has no wind model or no wind was entered.
  final double requiredRight;

  /// Crosswind speed (m/s) that moves the impact by one [unit] at [rangeM].
  /// Null when the solver has no wind model.
  final double? windMpsPerUnit;

  /// Formats a crosswind speed in m/s for the user's units.
  final String Function(double mps)? windText;

  /// Focal plane from the profile's scope. Null (unknown) is drawn as FFP.
  final bool? firstFocalPlane;

  /// Zoom range of the scope; null when the catalog has none.
  final double? minMagnification, maxMagnification;

  /// Current magnification (parent-owned). SFP reticles are taken as
  /// calibrated at [maxMagnification], the common SFP calibration.
  final double? magnification;
  final ValueChanged<double>? onMagnificationChanged;

  /// Shown when the profile unit differs from the catalog turret unit.
  final String? unitNote;

  /// Short line explaining the wind side/speed the solve used, if any.
  final String? windNote;
  final double rangeM;
  final List<CorrectionSample> samples;

  /// Converts metres to the user's display distance (m or yd).
  final double Function(double meters) toDisplayRange;
  final String distanceUnit;
  final bool metric;

  /// Diameter of the ring target drawn at [rangeM], in metres. The target is
  /// drawn at its true angular size, so like a real scope it gets bigger
  /// when you zoom in (higher magnification) and smaller when the range
  /// grows. Default 10 cm (a common airgun paper target).
  final double targetDiameterM;

  /// Shot incline (degrees, + up) shown next to the range; the required
  /// corrections already include it.
  final double inclineDeg;

  /// Scope cant (degrees, + clockwise). The required corrections are in the
  /// canted scope's axes; the reticle is drawn rolled by this angle while
  /// the target stays upright, as seen through a canted scope.
  final double cantDeg;

  const ScopeDialView({
    super.key,
    required this.unit,
    required this.clickValue,
    required this.elevationClicks,
    required this.windageClicks,
    required this.maxElevationClicks,
    this.maxElevationDownClicks,
    this.mountCantMoa = 0,
    this.mountCantClicks = 0,
    this.travelKnown = false,
    this.halfElevationClicks,
    required this.maxWindageClicks,
    required this.onElevationChanged,
    required this.onWindageChanged,
    this.windageRevealToken = 0,
    this.onSolutionDialed,
    required this.requiredUp,
    this.requiredRight = 0,
    this.windMpsPerUnit,
    this.windText,
    this.windNote,
    this.firstFocalPlane,
    this.minMagnification,
    this.maxMagnification,
    this.magnification,
    this.onMagnificationChanged,
    this.unitNote,
    required this.rangeM,
    required this.samples,
    required this.toDisplayRange,
    required this.distanceUnit,
    required this.metric,
    this.targetDiameterM = 0.10,
    this.inclineDeg = 0,
    this.cantDeg = 0,
  });

  /// Target radius as a true angle in [unit] (null when the range is unknown).
  double? get targetRadius => rangeM > 0 && targetDiameterM > 0
      ? ScopeDialMath.angleAtRange(targetDiameterM, rangeM, unit) / 2
      : null;

  String get unitLabel => unit == AngularUnit.mrad ? 'mrad' : unit.label;

  String get otherUnitLabel => unit == AngularUnit.mrad ? 'MOA' : 'mrad';

  AngularUnit get otherUnit =>
      unit == AngularUnit.mrad ? AngularUnit.moa : AngularUnit.mrad;

  bool get ffp => firstFocalPlane ?? true;

  /// True when a zoom range is known and the view can model magnification.
  bool get hasZoom {
    final max = maxMagnification, mag = magnification;
    return max != null && max > 0 && mag != null && mag > 0;
  }

  /// Magnification the reticle is true at (SFP) and the reference for the
  /// field of view (the view shows [halfField] at this magnification).
  double get calibrationMag => maxMagnification ?? 1;

  double get currentMag => hasZoom ? magnification! : calibrationMag;

  /// One reticle mark = this many [unit] at the current magnification.
  double get subtension => hasZoom
      ? ScopeDialMath.reticleSubtension(
          firstFocalPlane: ffp,
          magnification: currentMag,
          calibrationMagnification: calibrationMag,
        )
      : 1.0;

  /// True angle from the centre to the edge of the view.
  double get trueHalfField => hasZoom
      ? ScopeDialMath.visibleHalfField(
          halfFieldAtReference: halfField,
          magnification: currentMag,
          referenceMagnification: calibrationMag,
        )
      : halfField;

  /// Reticle units from the centre to the edge of the view: FFP marks grow
  /// with the image, SFP marks stay put.
  double get reticleHalfField => ffp ? trueHalfField : halfField;

  /// Half of the visible reticle field, in reticle units.
  double get halfField => unit.moaFamily ? 32 : 10;

  /// Reticle mark spacing on the vertical stadia, in reticle units.
  double get markStep => unit.moaFamily ? 2 : 1;

  /// Horizontal marks that carry crosswind labels, in reticle units.
  double get windStep => unit.moaFamily ? 4 : 1;

  int get _downClicks => maxElevationDownClicks ?? maxElevationClicks;

  static String _trim(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(1).replaceAll('.', ',');

  /// Why the turret cannot reach [need] clicks, and what would help.
  String _travelMessage(double req, int need) {
    final up = need > 0;
    final limit = up ? maxElevationClicks : _downClicks;
    final mount = mountCantMoa > 0
        ? ' (${_trim(mountCantMoa)} MOA dürbün ayağı dahil)'
        : '';
    final base =
        'Kule yetmez: gereken ${need.abs()} klik '
        '(${_fmt(req.abs())} $unitLabel), kulenin ${up ? 'yukarı' : 'aşağı'} '
        'yolu $limit klik'
        '${up ? mount : ''}. ';
    if (!up) {
      // Only blame the mount when there is one.
      return mountCantMoa > 0
          ? '${base}Dürbün ayağının eğimi bu kısa mesafe için fazla; '
                'retikülde tutuş yapın.'
          : '${base}Bu kısa mesafe için retikülde tutuş yapın.';
    }
    if (!travelKnown) {
      return '${base}Mesafeyi kısaltın veya retikülde tutuş yapın.';
    }
    // Mount slope that would cover the missing clicks. A mount is usable
    // only while the zero can still be dialled, i.e. while it is not larger
    // than half of the travel (the zero sits mid-travel).
    final missing = (need - limit) * clickValue;
    // Mounts are sold in true MOA.
    final missingMoa = AngularUnit.moa.fromMrad(unit.toMrad(missing));
    final needMoa = mountCantMoa + missingMoa;
    final suggest = needMoa.ceil();
    final half = halfElevationClicks ?? (maxElevationClicks - mountCantClicks);
    final halfAngle = half * clickValue;
    final halfMoa = AngularUnit.moa.fromMrad(unit.toMrad(halfAngle));
    if (needMoa > halfMoa + 1e-9) {
      return '${base}Hiçbir dürbün ayağı yetmez: gereken ayak ($suggest MOA) '
          'kulenin yarı yolundan (${_trim((halfMoa * 10).floor() / 10)} MOA) '
          'büyük, o ayakla dürbün sıfırlanamaz. Mesafeyi kısaltın, '
          'retikülde tutuş yapın veya ayar aralığı daha geniş bir dürbün '
          'kullanın.';
    }
    final options = [
      for (final o in ProductionLimits.mountCantOptionsMoa)
        if (o >= needMoa - 1e-9 && o <= halfMoa + 1e-9) o,
    ];
    final listed = options.isEmpty
        ? ''
        : ' (listeden: ${_trim(options.first)} MOA)';
    return '${base}Bu mesafe için en az $suggest MOA dürbün ayağı gerekir'
        '$listed; veya mesafeyi kısaltın ya da retikülde tutuş yapın.';
  }

  /// True when the mount is larger than half of the known travel: the turret
  /// cannot be dialled down far enough to zero the rifle.
  bool get mountBlocksZero {
    final half = halfElevationClicks;
    return travelKnown && half != null && mountCantClicks > half;
  }

  static String _fmt(double v) {
    final r = v.abs() < 0.005 ? 0.0 : v;
    return r.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final dialedUp = ScopeDialMath.clicksToAngle(elevationClicks, clickValue);
    final dialedRight = ScopeDialMath.clicksToAngle(windageClicks, clickValue);
    final req = requiredUp;
    final impact = req == null
        ? null
        : ScopeDialMath.impactOffset(
            dialedUp: dialedUp,
            requiredUp: req,
            dialedRight: dialedRight,
            requiredRight: requiredRight,
          );

    // Hold labels on every vertical mark inside the posts, above and below.
    final steps = (halfField * 0.8 / markStep).floor();
    final marks = <double>[
      for (var i = -steps; i <= steps; i++)
        if (i != 0) i * markStep,
    ];
    // A mark k reticle units below the centre covers k × subtension true
    // units; the hold range is found for the true angle and drawn at k.
    final sub = subtension;
    final holds = req == null
        ? const <HoldoverMark>[]
        : ScopeDialMath.holdovers(
            dialedUp: dialedUp,
            markAngles: [for (final m in marks) m * sub],
            samples: samples,
          );
    final holdLabels = [
      for (final h in holds)
        (h.markAngle / sub, toDisplayRange(h.rangeM).round().toString()),
    ];
    final perUnit = windMpsPerUnit;
    final windFmt = windText;
    final windLabels = <(double, String)>[
      if (perUnit != null && windFmt != null)
        for (var i = 1; i <= 4; i++)
          (i * windStep, windFmt(perUnit * i * windStep * sub)),
    ];

    // The reticle is always drawn at its real scale (zooming the view out
    // shrank the reticle into a meaningless black cross). An impact outside
    // the field is shown as an arrow at the edge with its offset, plus a note.
    final impactDistance = impact == null
        ? 0.0
        : math.sqrt(impact.up * impact.up + impact.right * impact.right);
    final outside = impactDistance > trueHalfField * 0.92;

    final elevationDrum = _TurretDrum(
      key: ScopeDialKeys.elevationDrum,
      axis: Axis.horizontal,
      clicks: elevationClicks,
      clickValue: clickValue,
      unitLabel: unitLabel,
      maxClicks: maxElevationClicks,
      maxNegativeClicks: _downClicks,
      positiveLetter: 'U',
      negativeLetter: 'D',
      semanticName: 'Yükseklik kulesi',
      positiveWord: 'yukarı',
      negativeWord: 'aşağı',
      onChanged: onElevationChanged,
    );
    // Windage: a vertical drum on the right, R up / L down (ChairGun).
    final windageDrum = _TurretDrum(
      key: ScopeDialKeys.windageDrum,
      axis: Axis.vertical,
      clicks: windageClicks,
      clickValue: clickValue,
      unitLabel: unitLabel,
      maxClicks: maxWindageClicks,
      positiveLetter: 'R',
      negativeLetter: 'L',
      semanticName: 'Rüzgâr kulesi',
      positiveWord: 'sağa',
      negativeWord: 'sola',
      onChanged: onWindageChanged,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenH = MediaQuery.sizeOf(context).height;
        final side = math.max(
          200.0,
          math.min(constraints.maxWidth, math.max(240.0, screenH * 0.56)),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TurretBar(
              revealToken: windageRevealToken,
              elevation: elevationDrum,
              windage: windageDrum,
              side: side,
              reticle: Semantics(
                label: _reticleSemantics(impact),
                image: true,
                child: SizedBox.square(
                  key: ScopeDialKeys.reticle,
                  dimension: side,
                  child: CustomPaint(
                    painter: ScopeReticlePainter(
                      colors: c,
                      halfField: halfField,
                      reticleHalfField: reticleHalfField,
                      trueHalfField: trueHalfField,
                      targetRadius: targetRadius,
                      markStep: markStep,
                      unitLabel: unitLabel,
                      impactUp: impact?.up,
                      impactRight: impact?.right,
                      holdLabels: holdLabels,
                      windLabels: windLabels,
                      headline:
                          'Hedef: ${toDisplayRange(rangeM).round()} $distanceUnit'
                          '${inclineDeg.round() == 0 ? '' : ' ∠ ${inclineDeg.round()}°'}',
                      cantDeg: cantDeg,
                      opticLine:
                          '${ffp ? 'FFP' : 'SFP'} · $unitLabel'
                          '${hasZoom ? ' · ${_mag(currentMag)}x' : ''}',
                      sfpNote: !ffp && hasZoom && (sub - 1).abs() > 1e-6
                          ? '1 çizgi = ${sub.toStringAsFixed(2)} $unitLabel'
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            if (hasZoom &&
                onMagnificationChanged != null &&
                (minMagnification ?? 0) > 0 &&
                minMagnification! < maxMagnification!)
              _zoomRow(context),
            // Owner, 2026-10-08: the turret buttons sit right under the
            // magnification; the explanations follow below them.
            const SizedBox(height: MenzilSpace.sm),
            Builder(
              builder: (context) {
                // Owner, 2026-10-10: the button of the turrets' current state
                // turns orange — the solution dialled, or both at zero.
                final rawElev = req == null
                    ? null
                    : ScopeDialMath.clicksFor(req, clickValue);
                final rawWind = ScopeDialMath.clicksFor(
                  requiredRight,
                  clickValue,
                );
                final solElev = rawElev
                    ?.clamp(-_downClicks, maxElevationClicks)
                    .toInt();
                final solWind = rawWind
                    .clamp(-maxWindageClicks, maxWindageClicks)
                    .toInt();
                // "Kurulu" only when the turrets really hold the solution:
                // a solution beyond the turret travel is never reported as
                // dialled (the button keeps dialling to the travel limit).
                final dialled =
                    solElev != null &&
                    solElev == rawElev &&
                    solWind == rawWind &&
                    elevationClicks == solElev &&
                    windageClicks == solWind;
                final atZero = elevationClicks == 0 && windageClicks == 0;
                return Row(
                  children: [
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: ScopeDialKeys.dialSolution,
                        label: dialled
                            ? 'Çözüm kuleye kurulu'
                            : 'Çözümü kuleye kur',
                        icon: dialled ? Icons.check_circle : Icons.tune,
                        expand: true,
                        active: dialled,
                        onPressed: req == null || dialled
                            ? null
                            : () {
                                onElevationChanged(solElev!);
                                onWindageChanged(solWind);
                                onSolutionDialed?.call();
                              },
                      ),
                    ),
                    const SizedBox(width: MenzilSpace.sm),
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: ScopeDialKeys.reset,
                        label: atZero ? 'Kuleler sıfırda' : 'Kuleleri sıfırla',
                        icon: atZero ? Icons.check_circle : Icons.restart_alt,
                        expand: true,
                        active: atZero,
                        onPressed: atZero
                            ? null
                            : () {
                                onElevationChanged(0);
                                onWindageChanged(0);
                              },
                      ),
                    ),
                  ],
                );
              },
            ),
            if (outside && impact != null)
              Padding(
                padding: const EdgeInsets.only(top: MenzilSpace.xs),
                child: MenzilNotice(
                  key: ScopeDialKeys.fitNote,
                  tone: MenzilNoticeTone.warning,
                  message:
                      'Vuruş noktası dürbünün görüş alanı dışında: '
                      '${_fmt(impact.up.abs())} $unitLabel '
                      '${impact.up >= 0 ? 'yukarıda' : 'aşağıda'}'
                      '${impact.right.abs() < 0.005 ? '' : ', ${_fmt(impact.right.abs())} $unitLabel ${impact.right >= 0 ? 'sağda' : 'solda'}'}'
                      '. Kenardaki ok o yönü gösterir. Kuleyi çevirin veya '
                      '"Çözümü kuleye kur"a dokunun.',
                ),
              ),
            if (mountBlocksZero)
              Padding(
                padding: const EdgeInsets.only(top: MenzilSpace.xs),
                child: MenzilNotice(
                  key: ScopeDialKeys.mountZeroNote,
                  tone: MenzilNoticeTone.danger,
                  message:
                      'Bu ayakla dürbün sıfırlanamaz: ${_trim(mountCantMoa)} '
                      'MOA ayak için kuleyi $mountCantClicks klik aşağı '
                      'çevirmek gerekir, kulenin aşağı yolu '
                      '${halfElevationClicks!} klik. Profil\'de daha küçük '
                      'bir dürbün ayağı seçin.',
                ),
              ),
            // Without the scope's real travel there is nothing honest to
            // warn about: no guessed limit is ever shown.
            if (travelKnown &&
                req != null &&
                (ScopeDialMath.clicksFor(req, clickValue) >
                        maxElevationClicks ||
                    ScopeDialMath.clicksFor(req, clickValue) < -_downClicks))
              Padding(
                padding: const EdgeInsets.only(top: MenzilSpace.xs),
                child: MenzilNotice(
                  key: ScopeDialKeys.travelNote,
                  tone: MenzilNoticeTone.warning,
                  message: _travelMessage(
                    req,
                    ScopeDialMath.clicksFor(req, clickValue),
                  ),
                ),
              ),
            if (mountCantMoa > 0)
              Padding(
                padding: const EdgeInsets.only(top: MenzilSpace.xs),
                child: MenzilNotice(
                  key: ScopeDialKeys.mountNote,
                  tone: MenzilNoticeTone.info,
                  message:
                      'Dürbün ayağı ${_trim(mountCantMoa)} MOA: kulede yukarı '
                      '+$mountCantClicks klik ek yer'
                      '${travelKnown ? ' (yukarı toplam $maxElevationClicks klik)' : ' (kule ayar aralığı Profil\'de girilmediği için toplam yol gösterilmiyor)'}'
                      '. Gereken klik sayısı değişmez; ayak yalnızca kuleye '
                      'yer açar.',
                ),
              ),
            if (unitNote != null) ...[
              const SizedBox(height: MenzilSpace.xs),
              MenzilNotice(tone: MenzilNoticeTone.warning, message: unitNote!),
            ],
            const SizedBox(height: MenzilSpace.md),
            _readout(context, dialedUp, dialedRight, impact),
            const SizedBox(height: MenzilSpace.md),
            _workings(context, dialedUp, dialedRight, impact),
          ],
        );
      },
    );
  }

  static String _mag(double m) =>
      m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toStringAsFixed(1);

  Widget _zoomRow(BuildContext context) {
    final c = MenzilColors.of(context);
    final min = minMagnification!, max = maxMagnification!;
    final steps = ((max - min) * 2).round();
    return Row(
      children: [
        Text('Büyütme', style: MenzilType.body(c.ink2)),
        Expanded(
          child: Slider(
            key: ScopeDialKeys.magnification,
            min: min,
            max: max,
            divisions: steps > 0 ? steps : null,
            value: currentMag.clamp(min, max).toDouble(),
            label: '${_mag(currentMag)}x',
            onChanged: onMagnificationChanged,
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            '${_mag(currentMag)}x',
            textAlign: TextAlign.end,
            style: MenzilType.number(c.ink, size: 16),
          ),
        ),
      ],
    );
  }

  /// Step-by-step working of the turret and reticle numbers, so the user
  /// can follow every value on the scope.
  Widget _workings(
    BuildContext context,
    double dialedUp,
    double dialedRight,
    ({double up, double right})? impact,
  ) {
    final c = MenzilColors.of(context);
    final req = requiredUp;
    String f(double v) => _fmt(v);
    String len(double angle) {
      final m = ScopeDialMath.linearAtRange(angle.abs(), rangeM, unit);
      return metric
          ? '${(m * 100).toStringAsFixed(1)} cm'
          : '${(m * 39.3700787).toStringAsFixed(1)} in';
    }

    final lines = <String>[];
    final r = toDisplayRange(rangeM).round();
    lines.add(
      '1 $unitLabel, $r $distanceUnit mesafede = ${len(1)}'
      '${switch (unit) {
        AngularUnit.mrad => '  (mesafe(m) / 10 cm)',
        AngularUnit.moa => '  (mesafe(m) × 0.02909 cm)',
        AngularUnit.smoa => '  (100 yd\'de 1 inç)',
      }}',
    );
    lines.add(
      unit == AngularUnit.smoa
          ? '1 SMOA = 0.27778 mrad = 0.955 MOA'
          : '1 MOA = 0.29089 mrad · 1 mrad = 3.43775 MOA',
    );
    final tRad = targetRadius;
    if (tRad != null) {
      final d = metric
          ? '${(targetDiameterM * 100).toStringAsFixed(0)} cm'
          : '${(targetDiameterM * 39.3700787).toStringAsFixed(1)} in';
      lines.add(
        'Hedef halkası Ø$d = ${f(tRad * 2)} $unitLabel; gerçek boyutunda '
        'çizilir: büyütme arttıkça büyür, mesafe arttıkça küçülür.',
      );
    }
    if (inclineDeg.round() != 0) {
      final horizontal = toDisplayRange(
        rangeM * math.cos(inclineDeg * math.pi / 180),
      );
      lines.add(
        'Tüfek eğimi ∠${inclineDeg.round()}°: düşüş eğik mesafe ($r '
        '$distanceUnit) boyunca eğime göre hesaplandı; yatay mesafe '
        '${horizontal.round()} $distanceUnit.',
      );
    }
    if (cantDeg.round() != 0) {
      lines.add(
        'Dürbün eğimi ${cantDeg.abs().round()}° '
        '${cantDeg > 0 ? 'sağa' : 'sola'}: saçma yatık tarafa ve aşağı '
        'kayar; kule değerleri yatık dürbünün kendi eksenlerinde verildi.',
      );
    }
    if (req != null) {
      final other = ScopeDialMath.convert(req, unit, otherUnit);
      lines.add(
        'Gereken yükseliş: ${len(req)} → ${f(req.abs())} $unitLabel '
        '(${f(other.abs())} $otherUnitLabel) ${req >= 0 ? 'U' : 'D'}',
      );
      final clicks = ScopeDialMath.clicksFor(req, clickValue);
      lines.add(
        'Klik = ${f(req.abs())} / $clickValue = ${clicks.abs()} klik '
        '${req >= 0 ? 'U' : 'D'}',
      );
      final otherClick = ScopeDialMath.standardClick(otherUnit);
      final otherClicks = ScopeDialMath.clicksFor(other, otherClick);
      lines.add(
        'Karşılaştırma: aynı düzeltme $otherClick $otherUnitLabel klikli '
        'kulede ${otherClicks.abs()} klik',
      );
      if (requiredRight.abs() > 1e-9) {
        final w = ScopeDialMath.clicksFor(requiredRight, clickValue);
        lines.add(
          'Gereken yan: ${f(requiredRight.abs())} $unitLabel → '
          '${w.abs()} klik ${requiredRight >= 0 ? 'R' : 'L'}',
        );
      }
    }
    lines.add(
      'Kulede: $elevationClicks × $clickValue = ${f(dialedUp)} $unitLabel · '
      '$windageClicks × $clickValue = ${f(dialedRight)} $unitLabel',
    );
    if (impact != null) {
      lines.add(
        'Kalan = kule − gereken = ${f(impact.up)} $unitLabel dikey, '
        '${f(impact.right)} $unitLabel yatay',
      );
    }
    if (ffp) {
      lines.add(
        'FFP: retikül görüntüyle birlikte büyür; 1 çizgi her büyütmede '
        '1 $unitLabel. Tutuş = kalan.',
      );
    } else {
      final sub = subtension;
      lines.add(
        'SFP: retikül yalnız ${_mag(calibrationMag)}x büyütmede doğru. '
        '1 çizgi = ${_mag(calibrationMag)} / ${_mag(currentMag)} = '
        '${sub.toStringAsFixed(3)} $unitLabel.',
      );
      if (impact != null) {
        lines.add(
          'Retikülde tutuş = kalan / ${sub.toStringAsFixed(3)} = '
          '${f(impact.up.abs() / sub)} çizgi '
          '${impact.up <= 0 ? 'aşağıdaki' : 'yukarıdaki'} işaret',
        );
      }
    }
    return Column(
      key: ScopeDialKeys.workings,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Hesap dökümü', style: MenzilType.heading(c.ink, size: 17)),
        const SizedBox(height: MenzilSpace.xxs),
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(l, style: MenzilType.caption(c.ink2)),
          ),
      ],
    );
  }

  String _reticleSemantics(({double up, double right})? impact) {
    if (impact == null) {
      return 'Dürbün retikülü. Vuruş noktası henüz hesaplanmadı.';
    }
    return 'Dürbün retikülü. Vuruş noktası artı işaretine göre '
        '${_fmt(impact.up.abs())} $unitLabel ${impact.up >= 0 ? 'yukarıda' : 'aşağıda'}, '
        '${_fmt(impact.right.abs())} $unitLabel ${impact.right >= 0 ? 'sağda' : 'solda'}.';
  }

  Widget _readout(
    BuildContext context,
    double dialedUp,
    double dialedRight,
    ({double up, double right})? impact,
  ) {
    final c = MenzilColors.of(context);
    String linear(double angle) {
      final m = ScopeDialMath.linearAtRange(angle.abs(), rangeM, unit);
      return metric
          ? '${(m * 100).toStringAsFixed(1)} cm'
          : '${(m * 39.3700787).toStringAsFixed(1)} in';
    }

    String dial(int clicks, double angle, String pos, String neg) =>
        '${clicks.abs()} klik ${clicks >= 0 ? pos : neg} '
        '(${_fmt(angle.abs())} $unitLabel)';

    final impactText = impact == null
        ? 'Vuruş noktası: hesaplama bekleniyor'
        : (impact.up.abs() < clickValue / 2 &&
              impact.right.abs() < clickValue / 2)
        ? 'Vuruş noktası: artı işaretinde'
        : 'Vuruş noktası: ${linear(impact.up)} '
              '${impact.up >= 0 ? 'yukarı' : 'aşağı'} · '
              '${linear(impact.right)} ${impact.right >= 0 ? 'sağ' : 'sol'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Kule: ${dial(elevationClicks, dialedUp, 'yukarı', 'aşağı')} · '
          '${dial(windageClicks, dialedRight, 'sağ', 'sol')}',
          style: MenzilType.body(c.ink),
        ),
        const SizedBox(height: MenzilSpace.xxs),
        Semantics(
          liveRegion: true,
          child: Text(
            impactText,
            key: ScopeDialKeys.impactText,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
          ),
        ),
        const SizedBox(height: MenzilSpace.xxs),
        Text(
          'Kırmızı sayılar: o noktayı hedefe tuttuğunuzda vuracağınız mesafe '
          '($distanceUnit).'
          '${windMpsPerUnit == null ? '' : ' Turuncu sayılar: bu mesafede isabeti o işarete kaydıran yan rüzgâr hızı.'}'
          '${windNote == null ? '' : ' $windNote'}'
          '${ffp ? ' FFP: retikül aralıkları her büyütmede geçerlidir.' : ' SFP: retikül aralıkları yalnız ${_mag(calibrationMag)}x büyütmede geçerlidir; sayılar seçili büyütmeye göre hesaplandı.'}',
          style: MenzilType.caption(c.ink2),
        ),
      ],
    );
  }
}

/// A turret drum that the user drags (or steps with buttons) one click at a
/// time. Horizontal drum: dragging right dials UP. Vertical drum: dragging
/// down dials RIGHT — the numbers on the drum move toward the pointer the
/// way a real turret's markings do.
/// Turrets around the scope, as in ChairGun: the elevation drum sits on top
/// (its zero right above the reticle's vertical line); "L-R" slides the
/// windage drum in from the right over the scope's right edge, its zero on
/// the reticle's horizontal line. Tapping "L-R" again slides it away, so the
/// scope keeps the whole width.
class _TurretBar extends StatefulWidget {
  final Widget elevation, windage, reticle;
  final double side;

  /// A change opens the windage drum (after "Çözümü kuleye kur").
  final int revealToken;
  const _TurretBar({
    required this.revealToken,
    required this.elevation,
    required this.windage,
    required this.reticle,
    required this.side,
  });

  @override
  State<_TurretBar> createState() => _TurretBarState();
}

class _TurretBarState extends State<_TurretBar> {
  bool _windage = false;

  @override
  void didUpdateWidget(covariant _TurretBar old) {
    super.didUpdateWidget(old);
    if (widget.revealToken != old.revealToken) _windage = true;
  }

  static const double _drumWidth = 58;

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final side = widget.side;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // An empty slot on the left balances the L-R button on the right,
        // so the drum (and its zero) is centred over the reticle.
        Row(
          children: [
            const SizedBox(width: 52 + MenzilSpace.xs),
            Expanded(child: widget.elevation),
            const SizedBox(width: MenzilSpace.xs),
            Semantics(
              button: true,
              toggled: _windage,
              label: _windage
                  ? 'Rüzgâr kulesini gizle'
                  : 'Rüzgâr kulesini göster',
              child: ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 52,
                  child: Material(
                    key: ScopeDialKeys.turretToggle,
                    color: _windage ? c.ink : c.cyan,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _windage = !_windage),
                      child: const Center(
                        child: Text(
                          'L-R',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: MenzilSpace.xs),
        Center(
          child: SizedBox.square(
            dimension: side,
            child: Stack(
              children: [
                Positioned.fill(child: widget.reticle),
                // Windage drum over the right edge, vertically centred on
                // the reticle so its zero meets the horizontal line.
                Positioned(
                  right: 0,
                  top: side * 0.18,
                  bottom: side * 0.18,
                  width: _drumWidth,
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                      child: _windage
                          ? DecoratedBox(
                              key: const ValueKey('windage-open'),
                              decoration: BoxDecoration(
                                color: c.surface2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: c.line),
                              ),
                              child: widget.windage,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('windage-closed'),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TurretDrum extends StatefulWidget {
  final Axis axis;
  final int clicks;
  final double clickValue;
  final String unitLabel;
  final int maxClicks;

  /// Travel on the negative side; null = [maxClicks].
  final int? maxNegativeClicks;
  final String positiveLetter, negativeLetter;
  final String semanticName, positiveWord, negativeWord;
  final ValueChanged<int> onChanged;

  const _TurretDrum({
    super.key,
    required this.axis,
    required this.clicks,
    required this.clickValue,
    required this.unitLabel,
    required this.maxClicks,
    this.maxNegativeClicks,
    required this.positiveLetter,
    required this.negativeLetter,
    required this.semanticName,
    required this.positiveWord,
    required this.negativeWord,
    required this.onChanged,
  });

  @override
  State<_TurretDrum> createState() => _TurretDrumState();
}

class _TurretDrumState extends State<_TurretDrum> {
  static const double pixelsPerClick = 9;
  double _carry = 0;

  void _set(int value) {
    final v = value
        .clamp(
          -(widget.maxNegativeClicks ?? widget.maxClicks),
          widget.maxClicks,
        )
        .toInt();
    if (v != widget.clicks) widget.onChanged(v);
  }

  void _drag(double delta) {
    _carry += delta;
    final steps = (_carry / pixelsPerClick).truncate();
    if (steps != 0) {
      _carry -= steps * pixelsPerClick;
      _set(widget.clicks + steps);
    }
  }

  String _valueText() {
    final angle = (widget.clicks * widget.clickValue).abs().toStringAsFixed(2);
    if (widget.clicks == 0) return '${widget.semanticName} sıfırda';
    final word = widget.clicks > 0 ? widget.positiveWord : widget.negativeWord;
    return '${widget.clicks.abs()} klik $word, $angle ${widget.unitLabel}';
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final horizontal = widget.axis == Axis.horizontal;
    final drum = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: horizontal ? (_) => _carry = 0 : null,
      onHorizontalDragUpdate: horizontal ? (d) => _drag(d.delta.dx) : null,
      onVerticalDragStart: horizontal ? null : (_) => _carry = 0,
      onVerticalDragUpdate: horizontal ? null : (d) => _drag(d.delta.dy),
      child: CustomPaint(
        painter: _DrumPainter(
          colors: c,
          axis: widget.axis,
          clicks: widget.clicks,
          clickValue: widget.clickValue,
          unitLabel: widget.unitLabel,
          positiveLetter: widget.positiveLetter,
          negativeLetter: widget.negativeLetter,
          pixelsPerClick: pixelsPerClick,
        ),
        child: const SizedBox.expand(),
      ),
    );

    Widget step(int delta, IconData icon, String label) => SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: label,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 22, color: c.ink),
        onPressed: () => _set(widget.clicks + delta),
      ),
    );

    final up = '${widget.semanticName} 1 klik ${widget.positiveWord}';
    final down = '${widget.semanticName} 1 klik ${widget.negativeWord}';
    final body = horizontal
        ? SizedBox(
            height: 52,
            child: Row(
              children: [
                step(1, Icons.chevron_left, up),
                Expanded(child: drum),
                step(-1, Icons.chevron_right, down),
              ],
            ),
          )
        : Column(
            children: [
              step(1, Icons.expand_less, up),
              Expanded(child: drum),
              step(-1, Icons.expand_more, down),
            ],
          );

    return Semantics(
      container: true,
      slider: true,
      label: widget.semanticName,
      value: _valueText(),
      increasedValue: '${widget.clicks + 1}',
      decreasedValue: '${widget.clicks - 1}',
      onIncrease: () => _set(widget.clicks + 1),
      onDecrease: () => _set(widget.clicks - 1),
      child: body,
    );
  }
}

class _DrumPainter extends CustomPainter {
  final MenzilColors colors;
  final Axis axis;
  final int clicks;
  final double clickValue;
  final String unitLabel;
  final String positiveLetter, negativeLetter;
  final double pixelsPerClick;

  const _DrumPainter({
    required this.colors,
    required this.axis,
    required this.clicks,
    required this.clickValue,
    required this.unitLabel,
    required this.positiveLetter,
    required this.negativeLetter,
    required this.pixelsPerClick,
  });

  /// Clicks between labelled major ticks: one whole unit (1 mrad / 1 MOA).
  int get _major => math.max(1, (1 / clickValue).round());

  void _text(
    Canvas canvas,
    String s,
    Offset center,
    Color color,
    double size, {
    FontWeight weight = FontWeight.w600,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  String _letter(int v) =>
      v == 0 ? '' : (v > 0 ? positiveLetter : negativeLetter);

  String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: axis == Axis.horizontal
              ? Alignment.centerLeft
              : Alignment.topCenter,
          end: axis == Axis.horizontal
              ? Alignment.centerRight
              : Alignment.bottomCenter,
          colors: [colors.surface2, colors.line, colors.surface2],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    final horizontal = axis == Axis.horizontal;
    final length = horizontal ? size.width : size.height;
    final across = horizontal ? size.height : size.width;
    final mid = length / 2;
    final tick = Paint()
      ..color = colors.ink
      ..strokeWidth = 1.2;
    final reach = (mid / pixelsPerClick).ceil() + 1;
    final label = colors.ink;
    for (var v = clicks - reach; v <= clicks + reach; v++) {
      // Values above the current setting sit before the pointer, so dragging
      // toward the pointer increases the setting.
      final p = mid - (v - clicks) * pixelsPerClick;
      final major = v % _major == 0;
      final len = major ? across * 0.30 : across * 0.16;
      if (horizontal) {
        canvas.drawLine(
          Offset(p, size.height),
          Offset(p, size.height - len),
          tick,
        );
        if (major) {
          final value = (v * clickValue).abs();
          final letter = _letter(v);
          _text(
            canvas,
            '${_num(value)}$letter',
            Offset(p, size.height * 0.40),
            label,
            15,
          );
        }
      } else {
        canvas.drawLine(Offset(0, p), Offset(len, p), tick);
        if (major) {
          final value = (v * clickValue).abs();
          final letter = _letter(v);
          _text(
            canvas,
            '${_num(value)}$letter',
            Offset(size.width * 0.62, p),
            label,
            13,
          );
        }
      }
    }
    canvas.restore();

    // Fixed pointer.
    final pointer = Paint()..color = colors.danger;
    final path = Path();
    if (horizontal) {
      path
        ..moveTo(mid - 7, size.height)
        ..lineTo(mid + 7, size.height)
        ..lineTo(mid, size.height - 11)
        ..close();
      _text(
        canvas,
        '← $positiveLetter   $unitLabel   $negativeLetter →',
        Offset(mid, 10),
        colors.ink2,
        10,
      );
    } else {
      path
        ..moveTo(0, mid - 7)
        ..lineTo(0, mid + 7)
        ..lineTo(11, mid)
        ..close();
      _text(canvas, '↑$positiveLetter', Offset(size.width / 2, 10), label, 11);
      _text(
        canvas,
        '$negativeLetter↓',
        Offset(size.width / 2, size.height - 10),
        label,
        11,
      );
    }
    canvas.drawPath(path, pointer);
  }

  @override
  bool shouldRepaint(covariant _DrumPainter old) =>
      old.clicks != clicks ||
      old.clickValue != clickValue ||
      old.colors != colors ||
      old.unitLabel != unitLabel;
}

/// Reticle with hold marks, range labels for each mark and the point of
/// impact for the current turret setting. Marks are drawn in the scope's
/// angular unit: mil-dots every 1 mrad, or hashes every 2 MOA.
class ScopeReticlePainter extends CustomPainter {
  final MenzilColors colors;

  /// Physical extent of the reticle pattern, in reticle units: marks run to
  /// 80 % of it and the thick posts start at 82 %.
  final double halfField;

  /// Reticle units between the centre and the edge of the view (FFP: grows
  /// and shrinks with magnification; SFP: fixed).
  final double reticleHalfField;

  /// True angle between the centre and the edge of the view; the point of
  /// impact is drawn on this scale.
  final double trueHalfField;

  /// Radius of the ring target as a true angle (same unit as
  /// [trueHalfField]); drawn on the true scale behind the reticle so it grows
  /// with magnification. Null: no target.
  final double? targetRadius;

  /// Reticle roll in degrees (+ clockwise); the target is not rolled.
  final double cantDeg;
  final double markStep;
  final String unitLabel;
  final double? impactUp;
  final double? impactRight;
  final List<(double, String)> holdLabels;
  final List<(double, String)> windLabels;
  final String headline;
  final String? opticLine;
  final String? sfpNote;

  const ScopeReticlePainter({
    required this.colors,
    required this.halfField,
    double? reticleHalfField,
    double? trueHalfField,
    this.targetRadius,
    this.cantDeg = 0,
    this.opticLine,
    this.sfpNote,
    required this.markStep,
    required this.unitLabel,
    required this.impactUp,
    required this.impactRight,
    required this.holdLabels,
    this.windLabels = const [],
    required this.headline,
  }) : reticleHalfField = reticleHalfField ?? halfField,
       trueHalfField = trueHalfField ?? halfField;

  /// On-screen radius of the target for a view of [radius] px.
  static double targetRadiusPx({
    required double radius,
    required double trueHalfField,
    required double targetRadius,
  }) => targetRadius * radius / trueHalfField;

  void _text(
    Canvas canvas,
    String s,
    Offset at,
    Color color,
    double size, {
    bool alignLeft = false,
    FontWeight weight = FontWeight.w600,
    Color? halo,
  }) {
    if (halo != null) {
      final edge = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeJoin = StrokeJoin.round
              ..color = halo,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final edx = alignLeft ? 0.0 : edge.width / 2;
      edge.paint(canvas, at - Offset(edx, edge.height / 2));
    }
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignLeft ? 0.0 : tp.width / 2;
    tp.paint(canvas, at - Offset(dx, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2;
    // px per reticle unit (marks) and px per true unit (impact).
    final scale = radius / reticleHalfField;
    final trueScale = radius / trueHalfField;
    final ink = colors.scopeLine;

    canvas.drawCircle(center, radius, Paint()..color = colors.scopeBg);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    // Ring target at the point of aim, at its true angular size: zooming in
    // makes it bigger (it "comes closer"), a longer range makes it smaller.
    final tr = targetRadius;
    if (tr != null && tr > 0) {
      final px = targetRadiusPx(
        radius: radius,
        trueHalfField: trueHalfField,
        targetRadius: tr,
      );
      // Paper target (owner, 2026-10-09): white face, thin red rings and a
      // light centre, so the black reticle stays readable on top of it.
      canvas.drawCircle(center, px, Paint()..color = colors.paperFace);
      Paint ring(Color c, double w) => Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = w;
      canvas.drawCircle(center, px * 0.75, ring(colors.paperRingSoft, 1));
      canvas.drawCircle(center, px * 0.5, ring(colors.paperRingSoft, 1));
      canvas.drawCircle(center, px * 0.25, Paint()..color = colors.paperCentre);
      canvas.drawCircle(center, px * 0.25, ring(colors.paperRing, 1));
      canvas.drawCircle(center, px, ring(colors.paperRing, 2));
    }

    // Everything of the reticle (lines, marks, labels on marks, impact) is
    // in the scope's own axes: roll it by the cant about the centre.
    void roll() {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(cantDeg * math.pi / 180);
      canvas.translate(-center.dx, -center.dy);
    }

    // A thin background-coloured edge (halo) under every reticle line, mark
    // and label keeps them readable over the target (owner, 2026-10-09).
    final halo = colors.scopeBg.withValues(alpha: 0.85);
    void line(Offset a, Offset b, double width) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = halo
          ..strokeWidth = width + 2.4,
      );
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = ink
          ..strokeWidth = width,
      );
    }

    const fine = 1.4;
    final postStart = halfField * 0.82 * scale;
    roll();
    // Fine crosshair.
    line(
      Offset(center.dx - postStart, center.dy),
      Offset(center.dx + postStart, center.dy),
      fine,
    );
    line(
      Offset(center.dx, center.dy - postStart),
      Offset(center.dx, center.dy + postStart),
      fine,
    );
    // Thick posts.
    const directions = [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
    ];
    for (final d in directions) {
      line(center + d * postStart, center + d * radius, 7);
    }

    // Marks.
    final steps = (halfField * 0.8 / markStep).floor();
    final dot = Paint()..color = ink;
    final dotHalo = Paint()..color = halo;
    final dotR = math.max(
      1.5,
      math.min(size.shortestSide * 0.011, markStep * scale * 0.12),
    );
    for (var i = -steps; i <= steps; i++) {
      if (i == 0) continue;
      final p = i * markStep * scale;
      if (unitLabel == 'mrad') {
        for (final at in [center + Offset(p, 0), center + Offset(0, p)]) {
          canvas.drawCircle(at, dotR + 1.2, dotHalo);
          canvas.drawCircle(at, dotR, dot);
        }
      } else {
        final long =
            (i % 5 == 0 ? 9.0 : 5.0) * math.min(1.0, markStep * scale / 12);
        line(center + Offset(p, -long), center + Offset(p, long), fine);
        line(center + Offset(-long, p), center + Offset(long, p), fine);
      }
    }
    canvas.drawCircle(center, 2.5, Paint()..color = colors.ok);

    // Range labels next to each hold mark (positive mark = below centre).
    // When the marks crowd together (FFP at low power) every n-th is kept.
    final gap = markStep * scale;
    final stride = gap <= 0 ? 1 : math.max(1, (16 / gap).ceil());
    final holdFont = math.max(10.0, size.shortestSide * 0.042);
    final holdYs = <double>[];
    for (final (mark, label) in holdLabels) {
      if ((mark / markStep).round() % stride != 0) continue;
      final y = center.dy + mark * scale;
      holdYs.add(y);
      _text(
        canvas,
        label,
        Offset(center.dx + dotR + 6, y),
        colors.danger,
        holdFont,
        alignLeft: true,
        weight: FontWeight.w700,
        halo: halo,
      );
    }

    // Crosswind speed above each horizontal mark, mirrored left and right.
    // Keep at least ~38 px between crosswind labels (they are wider than the
    // hold numbers); when marks crowd together every n-th is kept.
    final windGap = windLabels.isEmpty ? 0.0 : windLabels.first.$1 * scale;
    final windStride = windGap <= 0 ? 1 : math.max(1, (38 / windGap).ceil());
    final windFont = math.max(9.0, size.shortestSide * 0.036);
    final windY = center.dy - dotR - 11;
    // A hold number right of the vertical line sharing the wind labels' row
    // would be overprinted (owner, 2026-10-10: "532" ran into "5.0").
    final holdInRow = holdYs.any(
      (y) => (y - windY).abs() < (holdFont + windFont) / 2 + 1,
    );
    final holdRight = dotR + 6 + holdFont * 2.0;
    for (final (i, (mark, label)) in windLabels.indexed) {
      if ((i + 1) % windStride != 0) continue;
      if (mark * scale > postStart) continue;
      for (final side in const [-1.0, 1.0]) {
        if (side > 0 &&
            holdInRow &&
            mark * scale - windFont * label.length * 0.3 < holdRight) {
          continue;
        }
        _text(
          canvas,
          label,
          Offset(center.dx + side * mark * scale, windY),
          colors.amberInk,
          windFont,
          weight: FontWeight.w700,
          halo: halo,
        );
      }
    }

    canvas.restore(); // roll
    // Headline and scale legend.
    _text(
      canvas,
      headline,
      Offset(center.dx - radius * 0.48, center.dy + radius * 0.36),
      colors.cyanInk,
      math.max(11.0, size.shortestSide * 0.045),
    );
    _text(
      canvas,
      'aralık: ${markStep.toStringAsFixed(0)} $unitLabel',
      Offset(center.dx - radius * 0.48, center.dy + radius * 0.50),
      colors.cyanInk,
      math.max(10.0, size.shortestSide * 0.036),
    );
    final optic = opticLine;
    if (optic != null) {
      _text(
        canvas,
        optic,
        Offset(center.dx - radius * 0.48, center.dy - radius * 0.50),
        colors.cyanInk,
        math.max(10.0, size.shortestSide * 0.038),
      );
    }
    final note = sfpNote;
    if (note != null) {
      _text(
        canvas,
        note,
        Offset(center.dx - radius * 0.48, center.dy - radius * 0.38),
        colors.amberInk,
        math.max(10.0, size.shortestSide * 0.036),
      );
    }

    // Point of impact (scope axes, so rolled with the reticle).
    roll();
    final up = impactUp;
    final right = impactRight;
    if (up != null && right != null) {
      var poi = center + Offset(right * trueScale, -up * trueScale);
      final offset = poi - center;
      final limit = radius - 14;
      final outside = offset.distance > limit;
      if (outside) {
        poi = center + offset / offset.distance * limit;
      }
      Paint stroke(Color c, double w) => Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = w;
      if (!outside) {
        // Hollow ring with a small centre dot: the crosshair stays visible
        // through it (owner, 2026-10-09).
        canvas.drawCircle(poi, 9, stroke(halo, 5));
        canvas.drawCircle(poi, 9, stroke(colors.scopeImpact, 2.5));
        canvas.drawCircle(poi, 3.2, Paint()..color = halo);
        canvas.drawCircle(poi, 2.2, Paint()..color = colors.scopeImpact);
      } else {
        // Off-field: an arrow at the edge pointing toward the impact.
        final dir = offset / offset.distance;
        final normal = Offset(-dir.dy, dir.dx);
        final tip = poi + dir * 10;
        final arrow = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo((poi + normal * 9).dx, (poi + normal * 9).dy)
          ..lineTo((poi - normal * 9).dx, (poi - normal * 9).dy)
          ..close();
        canvas.drawPath(arrow, Paint()..color = colors.scopeImpact);
        canvas.drawPath(arrow, stroke(halo, 1.5));
        // How far out it is, written just inside the arrow.
        final far = math.sqrt(up * up + right * right);
        _text(
          canvas,
          '${far.toStringAsFixed(far >= 10 ? 0 : 1)} $unitLabel',
          poi - dir * 30,
          colors.scopeImpact,
          math.max(11.0, size.shortestSide * 0.04),
          weight: FontWeight.w700,
          halo: halo,
        );
      }
    }
    canvas.restore(); // roll
    canvas.restore();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant ScopeReticlePainter old) =>
      old.impactUp != impactUp ||
      old.impactRight != impactRight ||
      old.headline != headline ||
      old.colors != colors ||
      old.unitLabel != unitLabel ||
      old.halfField != halfField ||
      old.reticleHalfField != reticleHalfField ||
      old.trueHalfField != trueHalfField ||
      old.targetRadius != targetRadius ||
      old.cantDeg != cantDeg ||
      old.opticLine != opticLine ||
      old.sfpNote != sfpNote ||
      !_sameLabels(old.holdLabels, holdLabels) ||
      !_sameLabels(old.windLabels, windLabels);

  static bool _sameLabels(List<(double, String)> a, List<(double, String)> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
