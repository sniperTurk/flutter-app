import 'dart:math' as math;

/// A point in image pixel coordinates.
class PixelPoint {
  final double x, y;
  const PixelPoint(this.x, this.y);
}

class SightHeightResult {
  /// Centre-to-centre distance between scope axis and bore axis.
  final double heightMm;

  /// Scale used: millimetres per image pixel at the objective plane.
  final double mmPerPixel;
  const SightHeightResult(this.heightMm, this.mmPerPixel);
}

/// Pure geometry for the side-photo measurement. The user marks points on
/// the photo; nothing is detected automatically and no AI is involved.
///
/// Known limits (the UI states them): the scale comes from the objective
/// bell's physical OUTER diameter at the objective plane, while the bore
/// axis is at another depth, so perspective error is unquantified. The
/// result is an estimate to be confirmed with a caliper/ruler.
abstract final class SightHeightGeometry {
  /// Largest sane result; larger values indicate a marking mistake.
  static const maxPlausibleMm = 200.0;

  /// [objectiveTop]/[objectiveBottom] mark the two edges of the objective
  /// bell across its diameter in the side photo. [boreCentre] marks the
  /// centre of the barrel bore. Returns null when the marks cannot give a
  /// plausible result.
  static SightHeightResult? measure({
    required double objectiveOuterDiameterMm,
    required PixelPoint objectiveTop,
    required PixelPoint objectiveBottom,
    required PixelPoint boreCentre,
  }) {
    if (!objectiveOuterDiameterMm.isFinite || objectiveOuterDiameterMm <= 0)
      return null;
    final dx = objectiveBottom.x - objectiveTop.x;
    final dy = objectiveBottom.y - objectiveTop.y;
    final diameterPx = math.sqrt(dx * dx + dy * dy);
    if (!diameterPx.isFinite || diameterPx < 20) return null;
    final mmPerPx = objectiveOuterDiameterMm / diameterPx;

    // Scope axis = midpoint of the marked diameter.
    final ax = (objectiveTop.x + objectiveBottom.x) / 2;
    final ay = (objectiveTop.y + objectiveBottom.y) / 2;

    // Distance of the bore point from the scope axis measured perpendicular to
    // the bore line direction is not available from one point, so the
    // vertical axis of the marked diameter (unit vector u) is used: the
    // component of (bore - axis) along u.
    final ux = dx / diameterPx, uy = dy / diameterPx;
    final along = (boreCentre.x - ax) * ux + (boreCentre.y - ay) * uy;
    final heightMm = along.abs() * mmPerPx;
    if (!heightMm.isFinite || heightMm <= 0 || heightMm > maxPlausibleMm)
      return null;
    // The bore centre cannot lie inside the objective disc: the axis height is
    // objective radius + gap + wall + bore radius, always more than the radius.
    if (heightMm <= objectiveOuterDiameterMm / 2) return null;
    return SightHeightResult(heightMm, mmPerPx);
  }
}
