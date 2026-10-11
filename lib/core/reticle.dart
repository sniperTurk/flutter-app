import '../models/domain.dart';

/// Retikül ailesi (owner, 2026-10-10): every catalog reticle is drawn as one
/// of these, with its own spacing. Drawn by the app from the manufacturer's
/// published subtensions; no manufacturer image is copied.
enum ReticleFamily { tree, hash, milDot, duplex }

/// One row of a Christmas-tree holdover grid: dots every [dotStep] from
/// −[halfWidth] to +[halfWidth] at [y] below the centre (reticle units).
/// A null [dotStep] (not given by the manufacturer) draws only the two end
/// dots at ±[halfWidth]; the dots in between are never guessed.
class ReticleTreeRow {
  final double y, halfWidth;
  final double? dotStep;
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

  /// The fine lines stop short of the centre, leaving the centre dot (or
  /// an empty centre) floating.
  final bool floatingCenter;

  /// Line thicknesses in reticle units from the data file; null = the
  /// drawing's default widths.
  final double? lineWidth, postWidth;

  /// Data-file fields that were null and were drawn as the generic grid
  /// (or left out); empty = the reticle is drawn completely from its data.
  /// Only reticles from [ReticleData] set [fromData].
  final List<String> genericParts;
  final bool fromData;

  /// True when every part of a data-file reticle is known.
  bool get complete => fromData && genericParts.isEmpty;

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
    this.floatingCenter = false,
    this.lineWidth,
    this.postWidth,
    this.genericParts = const [],
    this.fromData = false,
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
    final moa =
        n.contains('MOA') ||
        (!n.contains('MIL') && !n.contains('MRAD') && turretUnit.moaFamily);
    if (n.contains('MILDOT') ||
        n.contains('MIL-DOT') ||
        n.contains('MIL DOT')) {
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

  /// A reticle from a manufacturer-sourced data file (data/reticles/*.json
  /// schema); null when the record is unusable. The app itself uses the
  /// generated constants (lib/data/reticle_library.dart), never JSON.
  static ReticleSpec? fromJson(Map<String, Object?> j) =>
      ReticleData.fromJson(j)?.toSpec();
}

/// One row of [ReticleData.tree]; null = not given by the manufacturer.
class ReticleDataRow {
  final double? y, halfWidth, dotStep;
  const ReticleDataRow({this.y, this.halfWidth, this.dotStep});
}

/// A reticle's manufacturer-sourced measurements, as generated from
/// data/reticles/*.json by tools/data_gen/generate_reticles.py. Every
/// distance is in the reticle's own unit; null = unknown (never guessed).
class ReticleData {
  final String id, brand, name;

  /// 'mil' or 'moa'.
  final String unit;

  /// 'hash', 'tree', 'mildot', 'duplex' or null (unknown).
  final String? family;
  final double? hashStep, majorEvery, numbersEvery;
  final double? extentH, extentUp, extentDown;
  final List<ReticleDataRow>? tree;
  final double? postsStart;
  final bool? centerDot, floatingCenter;
  final double? lineWidth, postWidth;
  final List<String> scopes;
  final String? sourceUrl;

  const ReticleData({
    required this.id,
    required this.brand,
    required this.name,
    required this.unit,
    this.family,
    this.hashStep,
    this.majorEvery,
    this.numbersEvery,
    this.extentH,
    this.extentUp,
    this.extentDown,
    this.tree,
    this.postsStart,
    this.centerDot,
    this.floatingCenter,
    this.lineWidth,
    this.postWidth,
    this.scopes = const [],
    this.sourceUrl,
  });

  AngularUnit get angularUnit =>
      unit == 'moa' ? AngularUnit.moa : AngularUnit.mrad;

  /// Reads one record of the data-file schema (used by tests and to check
  /// the generator); null when name or unit is missing.
  static ReticleData? fromJson(Map<String, Object?> j) {
    double? d(Object? v) =>
        v is num && v.isFinite && v > 0 ? v.toDouble() : null;
    bool? b(Object? v) => v is bool ? v : null;
    final name = j['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final unit = switch (j['unit']) {
      'mil' || 'mrad' => 'mil',
      'moa' => 'moa',
      _ => null,
    };
    if (unit == null) return null;
    final family = j['family'];
    List<ReticleDataRow>? rows;
    final tree = j['tree'];
    if (tree is Map && tree['rows'] is List) {
      rows = [
        for (final r in tree['rows'] as List)
          if (r is Map)
            ReticleDataRow(
              y: d(r['y']),
              halfWidth: d(r['half_width']),
              dotStep: d(r['dot_step']),
            ),
      ];
    }
    final brand = j['brand'];
    return ReticleData(
      id: name,
      brand: brand is String ? brand : '',
      name: name.trim(),
      unit: unit,
      family: const {'hash', 'tree', 'mildot', 'duplex'}.contains(family)
          ? family as String
          : null,
      hashStep: d(j['hash_step']),
      majorEvery: d(j['major_every']),
      numbersEvery: d(j['numbers_every']),
      extentH: d(j['extent_h']),
      extentUp: d(j['extent_v_up']),
      extentDown: d(j['extent_v_down']),
      tree: rows,
      postsStart: d(j['posts_start']),
      centerDot: b(j['center_dot']),
      floatingCenter: b(j['floating_center']),
      lineWidth: d(j['line_width']),
      postWidth: d(j['post_width']),
    );
  }

  /// The generic grid of the same unit and family: what the view drew
  /// before this reticle had data, and what fills its unknown extents.
  static ReticleSpec _generic(AngularUnit u, ReticleFamily f) {
    final moa = u.moaFamily;
    final g = switch (f) {
      ReticleFamily.tree => Reticles.generic(
        moa ? Reticles.hashMoa : Reticles.treeMil,
      ),
      ReticleFamily.hash => Reticles.generic(
        moa ? Reticles.hashMoa : Reticles.hashMil,
      ),
      ReticleFamily.milDot => Reticles.generic(Reticles.milDot),
      ReticleFamily.duplex => Reticles.generic(Reticles.duplex),
    };
    if (g.unit == u) return g;
    // Mil-Dot and Duplex are defined in mrad: same angles, MOA numbers.
    double c(double v) => u.fromMrad(g.unit.toMrad(v));
    return ReticleSpec(
      name: g.name,
      unit: u,
      family: g.family,
      hashStep: c(g.hashStep),
      majorEvery: c(g.majorEvery),
      extentH: c(g.extentH),
      extentUp: c(g.extentUp),
      extentDown: c(g.extentDown),
      postsStart: g.postsStart == null ? null : c(g.postsStart!),
    );
  }

  /// The drawable reticle, or null when too little is known to draw this
  /// reticle at all (no family, or marks without a spacing): the caller
  /// then falls back to the generic grid for the name.
  ///
  /// Known parts are drawn as given. Unknown extents take the generic
  /// grid's; unknown major marks, numbers, posts, tree rows, centre dot and
  /// floating centre are left out. Each such field is listed in
  /// [ReticleSpec.genericParts].
  ReticleSpec? toSpec({String? displayName}) {
    final f = switch (family) {
      'tree' => ReticleFamily.tree,
      'hash' => ReticleFamily.hash,
      'mildot' => ReticleFamily.milDot,
      'duplex' => ReticleFamily.duplex,
      _ => null,
    };
    if (f == null) return null;
    final step = hashStep;
    if (f != ReticleFamily.duplex && step == null) return null;
    final u = angularUnit;
    final g = _generic(u, f);
    final parts = <String>[];
    double pick(double? v, double fallback, String key) {
      if (v != null) return v;
      parts.add(key);
      return fallback;
    }

    final marks = f != ReticleFamily.duplex;
    final h = marks ? pick(extentH, g.extentH, 'extent_h') : 0.0;
    final up = marks ? pick(extentUp, g.extentUp, 'extent_v_up') : 0.0;
    final down = marks ? pick(extentDown, g.extentDown, 'extent_v_down') : 0.0;
    if (marks && f != ReticleFamily.milDot && majorEvery == null) {
      parts.add('major_every');
    }
    if (marks && f != ReticleFamily.milDot && numbersEvery == null) {
      parts.add('numbers_every');
    }
    double? posts = postsStart;
    if (posts == null) {
      if (f == ReticleFamily.duplex) {
        // A duplex is its posts: without the distance it is the generic one.
        posts = g.postsStart;
      }
      parts.add('posts_start');
    }
    final rows = <ReticleTreeRow>[];
    if (f == ReticleFamily.tree) {
      final t = tree;
      if (t == null || t.isEmpty) {
        parts.add('tree');
      } else {
        var rowMissing = false, dotMissing = false;
        for (final r in t) {
          final y = r.y, w = r.halfWidth;
          if (y == null || w == null) {
            rowMissing = true;
            continue;
          }
          if (r.dotStep == null) dotMissing = true;
          rows.add(ReticleTreeRow(y, w, r.dotStep));
        }
        if (rowMissing) parts.add('tree.rows');
        if (dotMissing) parts.add('tree.dot_step');
      }
    }
    if (centerDot == null) parts.add('center_dot');
    if (floatingCenter == null) parts.add('floating_center');
    return ReticleSpec(
      name: displayName ?? name,
      unit: u,
      family: f,
      hashStep: step ?? 0,
      majorEvery: majorEvery ?? 0,
      numbersEvery: numbersEvery,
      extentH: h,
      extentUp: up,
      extentDown: down,
      tree: List.unmodifiable(rows),
      postsStart: posts,
      centerDot: centerDot ?? false,
      floatingCenter: floatingCenter ?? false,
      lineWidth: lineWidth,
      postWidth: postWidth,
      genericParts: List.unmodifiable(parts),
      fromData: true,
    );
  }
}
