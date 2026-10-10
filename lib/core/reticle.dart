import '../models/domain.dart';

/// Retikül ailesi (owner, 2026-10-10): every catalog reticle is drawn as one
/// of these, with its own spacing. Drawn by the app from the manufacturer's
/// published subtensions; no manufacturer image is copied.
enum ReticleFamily { tree, hash, milDot, duplex }

/// One row of a Christmas-tree holdover grid: dots every [dotStep] from
/// −[halfWidth] to +[halfWidth] at [y] below the centre (reticle units).
class ReticleTreeRow {
  final double y, halfWidth, dotStep;
  const ReticleTreeRow(this.y, this.halfWidth, this.dotStep);
}

/// A drawable reticle. Every distance is from the centre, in [unit]
/// (mrad for MIL reticles, MOA for MOA reticles).
class ReticleSpec {
  final String name;
  final AngularUnit unit;
  final ReticleFamily family;

  /// Small marks every [hashStep]; longer marks every [majorEvery].
  final double hashStep, majorEvery;

  /// Numbers every [numbersEvery] units; null = none.
  final double? numbersEvery;

  /// How far the marks run: left/right, up and down.
  final double extentH, extentUp, extentDown;
  final List<ReticleTreeRow> tree;

  /// Thick posts start this far from the centre; null = no posts.
  final double? postsStart;
  final bool centerDot;

  const ReticleSpec({
    required this.name,
    required this.unit,
    required this.family,
    required this.hashStep,
    required this.majorEvery,
    this.numbersEvery,
    required this.extentH,
    required this.extentUp,
    required this.extentDown,
    this.tree = const [],
    this.postsStart,
    this.centerDot = false,
  });

  /// mrad per reticle unit.
  double get mradPerUnit => unit.mradPerUnit;
}

abstract final class Reticles {
  /// Names shown in the Profil "Retikül" list for the generic families.
  static const treeMil = 'Christmas tree (MIL)';
  static const hashMil = 'MIL çizgili';
  static const hashMoa = 'MOA çizgili';
  static const milDot = 'Mil-Dot';
  static const duplex = 'Duplex';
  static const genericNames = [treeMil, hashMil, hashMoa, milDot, duplex];

  static ReticleSpec generic(String name) => switch (name) {
    treeMil => ReticleSpec(
      name: treeMil,
      unit: AngularUnit.mrad,
      family: ReticleFamily.tree,
      hashStep: 0.2,
      majorEvery: 1,
      numbersEvery: 2,
      extentH: 10,
      extentUp: 5,
      extentDown: 10,
      tree: [for (var y = 1; y <= 8; y++) ReticleTreeRow(y + 0.0, y + 0.0, 1)],
      postsStart: 12,
    ),
    hashMoa => const ReticleSpec(
      name: hashMoa,
      unit: AngularUnit.moa,
      family: ReticleFamily.hash,
      hashStep: 2,
      majorEvery: 10,
      numbersEvery: 10,
      extentH: 40,
      extentUp: 40,
      extentDown: 40,
      postsStart: 44,
    ),
    milDot => const ReticleSpec(
      name: milDot,
      unit: AngularUnit.mrad,
      family: ReticleFamily.milDot,
      hashStep: 1,
      majorEvery: 1,
      extentH: 4,
      extentUp: 4,
      extentDown: 4,
      postsStart: 5,
    ),
    duplex => const ReticleSpec(
      name: duplex,
      unit: AngularUnit.mrad,
      family: ReticleFamily.duplex,
      hashStep: 0,
      majorEvery: 0,
      extentH: 0,
      extentUp: 0,
      extentDown: 0,
      postsStart: 4,
    ),
    _ => const ReticleSpec(
      name: hashMil,
      unit: AngularUnit.mrad,
      family: ReticleFamily.hash,
      hashStep: 0.2,
      majorEvery: 1,
      numbersEvery: 2,
      extentH: 10,
      extentUp: 10,
      extentDown: 10,
      postsStart: 12,
    ),
  };

  /// The reticle to draw for a scope's reticle name (catalog name or one of
  /// [genericNames]); [turretUnit] decides MIL/MOA when the name says
  /// nothing. Null name = null (the view keeps its plain marks).
  static ReticleSpec? forName(String? name, AngularUnit turretUnit) {
    if (name == null || name.trim().isEmpty) return null;
    if (genericNames.contains(name)) return generic(name);
    final n = name.toUpperCase();
    final moa = n.contains('MOA') ||
        (!n.contains('MIL') && !n.contains('MRAD') && turretUnit.moaFamily);
    if (n.contains('MILDOT') || n.contains('MIL-DOT') || n.contains('MIL DOT')) {
      return _named(generic(milDot), name);
    }
    if (n.contains('DUPLEX') || n.contains('VFD') || n.contains('HUNT')) {
      return _named(generic(duplex), name);
    }
    if (!moa &&
        (n.contains('VPR') ||
            n.contains('TOR') ||
            n.contains('VTA-8') ||
            n.contains('PRS') ||
            n.contains('TREE') ||
            n.contains('H59') ||
            n.contains('APR'))) {
      return _named(generic(treeMil), name);
    }
    return _named(generic(moa ? hashMoa : hashMil), name);
  }

  static ReticleSpec _named(ReticleSpec s, String name) => ReticleSpec(
    name: name,
    unit: s.unit,
    family: s.family,
    hashStep: s.hashStep,
    majorEvery: s.majorEvery,
    numbersEvery: s.numbersEvery,
    extentH: s.extentH,
    extentUp: s.extentUp,
    extentDown: s.extentDown,
    tree: s.tree,
    postsStart: s.postsStart,
    centerDot: s.centerDot,
  );

  /// A reticle from a manufacturer-sourced data file (data/reticles/*.json);
  /// null when the record is unusable.
  static ReticleSpec? fromJson(Map<String, Object?> j) {
    double? d(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
    final name = j['name'];
    if (name is! String || name.isEmpty) return null;
    final unit = j['unit'] == 'moa' ? AngularUnit.moa : AngularUnit.mrad;
    final family = switch (j['family']) {
      'tree' => ReticleFamily.tree,
      'mildot' => ReticleFamily.milDot,
      'duplex' => ReticleFamily.duplex,
      _ => ReticleFamily.hash,
    };
    final rows = <ReticleTreeRow>[];
    final tree = j['tree'];
    if (tree is Map && tree['rows'] is List) {
      for (final r in tree['rows'] as List) {
        if (r is! Map) continue;
        final y = d(r['y']), w = d(r['half_width']), s = d(r['dot_step']);
        if (y != null && w != null && s != null && s > 0) {
          rows.add(ReticleTreeRow(y, w, s));
        }
      }
    }
    final step = d(j['hash_step']) ?? (unit == AngularUnit.moa ? 2 : 0.2);
    final h = d(j['extent_h']) ?? (unit == AngularUnit.moa ? 40 : 10);
    return ReticleSpec(
      name: name,
      unit: unit,
      family: family,
      hashStep: step,
      majorEvery: d(j['major_every']) ?? step * 5,
      numbersEvery: d(j['numbers_every']),
      extentH: h,
      extentUp: d(j['extent_v_up']) ?? h,
      extentDown: d(j['extent_v_down']) ?? h,
      tree: List.unmodifiable(rows),
      postsStart: d(j['posts_start']),
      centerDot: j['center_dot'] == true,
    );
  }
}
