import '../models/domain.dart';

/// Tahmini BC for a PCP pellet or slug whose maker publishes none (owner,
/// 2026-10-12/13: "BC boş bırakılabilir, boş ise G1 hesaplamaya dahil
/// edilir"). Without a BC the solver would run the vacuum baseline, which
/// ignores air drag and wind, so the side turret always stayed at 0.
///
/// BC = SD / i, with the sectional density SD = grain / (7000 · d²)
/// (lb/in², d in inches) and i the G1 form factor. The form factors are
/// the medians of i = SD / BC(G1) over the PCP records in
/// `lib/data/bullet_library.dart` whose BC the maker publishes (H&N, NSA,
/// Zan Projectiles; computed 2026-10-13): slugs 0.825 (209 records,
/// interquartile 0.72–0.93), pellets 2.06 (45 records, 1.72–2.42). The
/// spread is wide (see docs/research/pellet_slug_hassas_hesap.md, B.3), so
/// the value is only a starting point and is always labelled "tahmini".
abstract final class EstimatedBc {
  static const double slugFormFactor = 0.825;
  static const double pelletFormFactor = 2.06;

  /// The estimated G1 BC, or null when it does not apply (firearm, a
  /// catalog row, a BC already given, or an unusable weight/calibre).
  static double? g1For(Ammunition a) {
    // Profile ammunition is always the user's own record (Profil saves it);
    // built-in catalog rows keep their published data as they are.
    if (a.platform != WeaponPlatform.pcp ||
        !a.userEntered ||
        a.ballisticCoefficient != null ||
        a.dragCurve != null) {
      return null;
    }
    final i = switch (a.type) {
      AmmunitionType.slug => slugFormFactor,
      AmmunitionType.pellet => pelletFormFactor,
      AmmunitionType.bullet => null,
    };
    final dIn = a.caliberMm / 25.4;
    if (i == null || !a.grain.isFinite || a.grain <= 0 || dIn <= 0) {
      return null;
    }
    final sd = a.grain / (7000 * dIn * dIn);
    return double.parse((sd / i).toStringAsFixed(3));
  }

  /// [a] with the estimated G1 BC filled in; [a] itself when none applies.
  static Ammunition fill(Ammunition a) {
    final bc = g1For(a);
    if (bc == null) return a;
    return Ammunition(
      id: a.id,
      brand: a.brand,
      model: a.model,
      platform: a.platform,
      caliberMm: a.caliberMm,
      grain: a.grain,
      type: a.type,
      ballisticCoefficient: bc,
      ballisticModel: BallisticModel.g1,
      lengthMm: a.lengthMm,
      sourceName: a.sourceName,
      sourceDocument: a.sourceDocument,
      userEntered: a.userEntered,
      modelWithoutBc: a.modelWithoutBc,
    );
  }

  /// Sectional density in lb/in²: grain / (7000 · d²), d = [caliberMm] in
  /// inches. 7,62 mm (0,3 in), 168 gr: 0,267. Used by Profil's BC
  /// plausibility check (moved from the editor, 2026-10-15, same
  /// arithmetic).
  static double sectionalDensity(double grain, double caliberMm) {
    final dIn = caliberMm / 25.4;
    return grain / (7000 * dIn * dIn);
  }

  /// Bullet weight in grains that has sectional density [sd] at
  /// [caliberMm]: sd · 7000 · d² (inverse of [sectionalDensity]).
  static double grainForSectionalDensity(double sd, double caliberMm) {
    final dIn = caliberMm / 25.4;
    return sd * (7000 * dIn * dIn);
  }
}
