import 'dart:math' as math;

/// First-order low-pass (exponential approach) used to ease the Su Terazisi
/// bubbles (owner: "viskoz sıvı"). Only the drawing is eased; the numbers
/// always show the measured value. Moved from the level screen (2026-10-15,
/// same arithmetic).
abstract final class LowPass {
  /// Share of the remaining gap closed in [dtS] seconds with time constant
  /// [tauS]: 1 − e^(−dt/τ). 0 at dt = 0, 1 − 1/e ≈ 0.632 at dt = τ.
  static double factor(double dtS, double tauS) => 1 - math.exp(-dtS / tauS);

  /// One step from [current] toward [target]: current + (target − current)·k.
  static double step(double current, double target, double k) =>
      current + (target - current) * k;
}
