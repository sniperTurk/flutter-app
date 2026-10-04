import '../../core/production_limits.dart';

/// Result of the physical (caliper) Sight Height method.
class PhysicalSightHeight {
  /// 1 · half of the bore diameter (caliber).
  final double boreRadiusMm;

  /// 2 · barrel wall above the bore (top wall thickness).
  final double barrelWallMm;

  /// 3 · gap between the scope's underside and the barrel top at the FRONT end.
  final double gapMm;

  /// 4 · half of the objective housing's OUTER diameter at the front end.
  final double objectiveRadiusMm;

  const PhysicalSightHeight({
    required this.boreRadiusMm,
    required this.barrelWallMm,
    required this.gapMm,
    required this.objectiveRadiusMm,
  });

  double get totalMm => boreRadiusMm + barrelWallMm + gapMm + objectiveRadiusMm;

  /// The value written to a profile: one decimal, like the page shows.
  double get roundedMm =>
      double.parse(roundedText(totalMm, 1).replaceAll(',', '.'));

  /// Half-up rounding without relying on binary `toStringAsFixed` ties, with a
  /// Turkish decimal comma ("62,38").
  static String roundedText(double v, int digits) {
    var scale = 1.0;
    for (var i = 0; i < digits; i++) {
      scale *= 10;
    }
    final r = (v * scale + 1e-9).roundToDouble() / scale;
    return r.toStringAsFixed(digits).replaceAll('.', ',');
  }
}

/// Physical method. Every measurement is taken at the scope's FRONT
/// (objective) end, the end nearest the muzzle, which also gives the right
/// answer for a scope mounted at an angle to the bore:
///
///   Sight Height = bore radius + top wall + front gap + objective outer radius
///
/// The objective value is the housing's real OUTERMOST diameter, never the
/// glass size in the model name (for example 56 mm).
abstract final class SightHeightPhysical {
  /// Returns null when an input is missing, not finite, not positive, or the
  /// total is outside the profile limits.
  static PhysicalSightHeight? compute({
    required double? boreDiameterMm,
    required double? barrelWallMm,
    required double? gapMm,
    required double? objectiveOuterDiameterMm,
  }) {
    bool ok(double? v) => v != null && v.isFinite && v > 0;
    if (!ok(boreDiameterMm) ||
        !ok(barrelWallMm) ||
        !ok(gapMm) ||
        !ok(objectiveOuterDiameterMm)) {
      return null;
    }
    // Bounds that catch unit/typing mistakes without rejecting real equipment.
    if (boreDiameterMm! > 30 ||
        barrelWallMm! > 60 ||
        gapMm! > 100 ||
        objectiveOuterDiameterMm! > 120) {
      return null;
    }
    final result = PhysicalSightHeight(
      boreRadiusMm: boreDiameterMm / 2,
      barrelWallMm: barrelWallMm,
      gapMm: gapMm,
      objectiveRadiusMm: objectiveOuterDiameterMm / 2,
    );
    if (result.totalMm >= ProductionLimits.maxSightHeightMm) return null;
    return result;
  }
}
