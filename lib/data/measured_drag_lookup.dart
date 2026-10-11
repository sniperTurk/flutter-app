import '../core/drag_curve.dart';
import '../core/drag_table.dart';
import 'bullet_library.dart';
import 'measured_drag_curves.dart';

/// A bullet's own measured Cd-vs-Mach curve (Doppler radar or spark range),
/// published with reuse permission and linked to one [LibraryBullet] by
/// brand, name and grain (owner, 2026-10-11). Generated into
/// [measuredDragCurves] by tools/data_gen/generate_measured_drag_curves.py.
class MeasuredDragCurve {
  final String id, brand, name, method, sourceUrl, license;
  final double grain;

  /// `[[Mach, Cd], ...]`, the stored custom-curve format of [DragCurve].
  final List<List<double>> points;

  const MeasuredDragCurve({
    required this.id,
    required this.brand,
    required this.name,
    required this.grain,
    required this.method,
    required this.sourceUrl,
    required this.license,
    required this.points,
  });

  /// The validated curve; null if the points are not a valid curve.
  List<DragSample>? get samples => DragCurve.fromJson(points);
}

abstract final class MeasuredDragLookup {
  /// Tests only: replaces [measuredDragCurves] when set.
  static List<MeasuredDragCurve>? debugOverride;

  static List<MeasuredDragCurve> get all =>
      debugOverride ?? measuredDragCurves;

  /// The measured curve of exactly this library bullet; null = none (the
  /// bullet's G1/G7 BC applies).
  static MeasuredDragCurve? forBullet(LibraryBullet b) {
    for (final c in all) {
      if (c.brand == b.brand &&
          c.name == b.name &&
          (c.grain - b.grain).abs() < 0.01 &&
          c.samples != null) {
        return c;
      }
    }
    return null;
  }
}
