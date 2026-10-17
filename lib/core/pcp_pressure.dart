/// PCP "Basınca göre hız" (owner, 2026-10-12) was DELETED on 2026-10-16
/// (owner: removed features are deleted, not hidden). The PCP velocity is
/// the Tüfek card's Namlu çıkış hızı (owner, 2026-10-17).
///
/// Only the stored point type is left: profiles saved before 2026-10-16
/// may hold a `pressureVelocity` table. It is still decoded and written back
/// unchanged so the user's saved data is never erased, but nothing reads it
/// for a calculation.
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
