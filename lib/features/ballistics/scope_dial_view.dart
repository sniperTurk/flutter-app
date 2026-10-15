import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/production_limits.dart';
import '../../core/reticle.dart';
import '../../core/scope_dial.dart';
import '../../models/domain.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

part 'scope_reticle.dart';
part 'scope_results.dart';
part 'scope_turrets.dart';
part 'scope_workings.dart';

/// Stable keys for widget tests.
abstract final class ScopeDialKeys {
  static const elevationDrum = ValueKey('scope-elevation-drum');
  static const windageDrum = ValueKey('scope-windage-drum');

  /// The side turret's drum box, without its arrows.
  static const windageDrumBox = ValueKey('scope-windage-drum-box');
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

  /// The "Hesap dökümü" row that opens and closes the lines.
  static const workingsToggle = ValueKey('scope-workings-toggle');
  static const labelsToggle = ValueKey('scope-labels-toggle');
  static const zoomReset = ValueKey('scope-zoom-reset');
}

/// Light scope palette whatever the app theme (owner, 2026-10-12).
MenzilColors _scopeColors(MenzilColors c) =>
    identical(c, MenzilColors.light) || c.scopeBg == MenzilColors.light.scopeBg
    ? MenzilColors.light
    : MenzilColors.light.copyWith(scopeBg: MenzilColors.scopeBgDim);

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

  /// The zero's bore angle above the sight line, in clicks (denetim F2,
  /// 2026-10-14): the zeroed turret already holds it, so it is already
  /// out of [maxElevationClicks] and in [maxElevationDownClicks]. 0 when
  /// unknown.
  final int zeroAngleClicks;

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

  /// Incremented by the owner after "Kuleleri kur"; each change slides
  /// the windage (right) turret open (owner, 2026-10-09).
  final int windageRevealToken;

  /// Called after "Kuleleri kur" has dialled both turrets.
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

  /// Shown right under the turret buttons, before the notes (the empty
  /// Hedef page puts its "Profil oluştur" card here).
  final Widget? belowButtons;

  /// The scope's own reticle (Profil → Dürbün → Retikül); null = the plain
  /// marks.
  final ReticleSpec? reticle;

  /// Firearm selected: the notes say "mermi" instead of "saçma".
  final bool firearm;

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
    this.zeroAngleClicks = 0,
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
    this.belowButtons,
    this.reticle,
    this.firearm = false,
  });

  /// Target radius as a true angle in [unit] (null when the range is unknown).
  double? get targetRadius => rangeM > 0 && targetDiameterM > 0
      ? ScopeDialMath.angleAtRange(targetDiameterM, rangeM, unit) / 2
      : null;

  String get unitLabel => unit.label;

  String get otherUnitLabel => unit == AngularUnit.mrad ? 'MOA' : 'MRAD';

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

  /// Whole numbers without decimals, else one decimal with a comma.
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
        'yolu yaklaşık $limit klik'
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
    // only while the zero can still be dialled: the mount minus the zero
    // angle must fit in half of the travel (denetim F2).
    final missing = (need - limit) * clickValue;
    // Mounts are sold in true MOA.
    final missingMoa = AngularUnit.moa.fromMrad(unit.toMrad(missing));
    final needMoa = mountCantMoa + missingMoa;
    final suggest = needMoa.ceil();
    final half =
        halfElevationClicks ??
        (maxElevationClicks - mountCantClicks + zeroAngleClicks);
    final halfAngle = (half + zeroAngleClicks) * clickValue;
    final halfMoa = AngularUnit.moa.fromMrad(unit.toMrad(halfAngle));
    if (needMoa > halfMoa + 1e-9) {
      return '${base}Hiçbir dürbün ayağı yetmez: gereken ayak ($suggest MOA) '
          'sıfırlanabilen en büyük ayaktan (yaklaşık '
          '${_trim((halfMoa * 10).floor() / 10)} MOA) büyük, o ayakla dürbün '
          'sıfırlanamaz. Mesafeyi kısaltın, '
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

  /// True when the mount, less the zero angle, is larger than half of the
  /// known travel: the turret cannot be dialled down far enough to zero the
  /// rifle (denetim F2).
  bool get mountBlocksZero {
    final half = halfElevationClicks;
    return travelKnown &&
        half != null &&
        mountCantClicks - zeroAngleClicks > half;
  }

  static String _fmt(double v) {
    final r = v.abs() < 0.005 ? 0.0 : v;
    return r.toStringAsFixed(2).replaceAll('.', ',');
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
                child: _ReticleViewport(
                  side: side,
                  builder: (zoom, showLabels) => ScopeReticlePainter(
                    zoom: zoom,
                    showLabels: showLabels,
                    // The scope inside is light in both themes: a black
                    // reticle on an off-white field, like a daytime scope
                    // (owner, 2026-10-12). Off-white in Koyu to spare the eye.
                    colors: _scopeColors(c),
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
                        '${hasZoom ? ' · ${_trim(currentMag)}x' : ''}',
                    sfpNote: !ffp && hasZoom && (sub - 1).abs() > 1e-6
                        ? '1 çizgi = ${sub.toStringAsFixed(2).replaceAll('.', ',')} $unitLabel'
                        : null,
                    reticle: reticle,
                    reticleToView: reticle == null
                        ? 1
                        : reticle!.mradPerUnit / unit.mradPerUnit,
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
            _turretButtons(),
            if (belowButtons != null) ...[
              const SizedBox(height: MenzilSpace.sm),
              belowButtons!,
            ],
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
                      '"Kuleleri kur"a dokunun.',
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
                      'MOA ayak için kuleyi yaklaşık '
                      '${mountCantClicks - zeroAngleClicks} klik aşağı '
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
                      '${travelKnown ? ' (yukarı toplam yaklaşık $maxElevationClicks klik)' : ' (kule ayar aralığı Profil\'de girilmediği için toplam yol gösterilmiyor)'}'
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
            label: '${_trim(currentMag)}x',
            onChanged: onMagnificationChanged,
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            '${_trim(currentMag)}x',
            textAlign: TextAlign.end,
            style: MenzilType.number(c.ink, size: 16, live: true),
          ),
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
}
