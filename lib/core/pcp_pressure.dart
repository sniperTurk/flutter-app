/// PCP tüp ve regülatör basıncı (owner, 2026-10-12).
///
/// Regulated PCP: while the tube pressure is at or above the regulator set
/// pressure the regulator feeds the valve the same pressure every shot, so
/// the velocity stays at the profile velocity. Once the tube falls below the
/// set pressure the regulator is out of play and the velocity drops
/// (Daystate, "regulators"; Pyramyd Air, "About PCPs and tuning, part 1").
/// Unregulated PCP: the velocity follows the tube pressure along the rifle's
/// own curve (rises, flat, falls).
///
/// The curve differs from rifle to rifle, so no formula or default is
/// assumed: the only source is the user's chronograph table (basınç–hız
/// points), linearly interpolated and held at its end values outside it. A
/// table needs at least [minPoints] points. Without a usable table the
/// profile velocity is used.
library;

class PressureVelocityPoint {
  /// Tube pressure in bar and the velocity measured there in m/s.
  final double bar, mps;
  const PressureVelocityPoint({required this.bar, required this.mps});

  @override
  bool operator ==(Object other) =>
      other is PressureVelocityPoint && other.bar == bar && other.mps == mps;

  @override
  int get hashCode => Object.hash(bar, mps);
}

class PcpVelocity {
  /// Velocity to shoot with, m/s.
  final double mps;

  /// Regulated rifle with the tube below the regulator set pressure.
  final bool regulatorBypassed;

  /// [mps] came from the user's table (not the profile velocity).
  final bool fromTable;
  const PcpVelocity({
    required this.mps,
    this.regulatorBypassed = false,
    this.fromTable = false,
  });
}

abstract final class PcpPressure {
  static const int minPoints = 2;

  /// Rows of the table on Profil.
  static const int tableRows = 4;

  /// Velocity at [bar] from [table]; null with fewer than [minPoints] valid
  /// points. Outside the table the end value is used.
  static double? interpolate(List<PressureVelocityPoint> table, double bar) {
    if (!bar.isFinite) return null;
    final pts =
        table
            .where(
              (p) => p.bar.isFinite && p.bar > 0 && p.mps.isFinite && p.mps > 0,
            )
            .toList()
          ..sort((a, b) => a.bar.compareTo(b.bar));
    if (pts.length < minPoints) return null;
    if (bar <= pts.first.bar) return pts.first.mps;
    if (bar >= pts.last.bar) return pts.last.mps;
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      if (bar <= b.bar) {
        final span = b.bar - a.bar;
        if (span <= 0) return b.mps;
        return a.mps + (b.mps - a.mps) * (bar - a.bar) / span;
      }
    }
    return pts.last.mps;
  }

  /// Velocity for the tube pressure [tubeBar] left in the field. Null or
  /// invalid [tubeBar]: the profile velocity, no warning.
  static PcpVelocity velocity({
    required double profileMps,
    double? regulatorBar,
    double? tubeBar,
    List<PressureVelocityPoint> table = const [],
  }) {
    final tube = tubeBar;
    if (tube == null || !tube.isFinite || tube <= 0) {
      return PcpVelocity(mps: profileMps);
    }
    final reg = regulatorBar;
    final regulated = reg != null && reg.isFinite && reg > 0;
    if (regulated) {
      if (tube >= reg) return PcpVelocity(mps: profileMps);
      // Below the set pressure: only a measured point there may say how
      // much slower.
      final measuredBelow = table.any((p) => p.bar < reg);
      final v = measuredBelow ? interpolate(table, tube) : null;
      return v == null
          ? PcpVelocity(mps: profileMps, regulatorBypassed: true)
          : PcpVelocity(mps: v, regulatorBypassed: true, fromTable: true);
    }
    final v = interpolate(table, tube);
    return v == null
        ? PcpVelocity(mps: profileMps)
        : PcpVelocity(mps: v, fromTable: true);
  }
}
