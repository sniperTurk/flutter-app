/// Ö8 Paralaks mesafe tablosu (PCP): the shooter records the side-focus
/// wheel mark that gives a sharp, parallax-free image at known distances;
/// in the field the distance for a mark is read back by linear
/// interpolation between the recorded marks. Outside the recorded range the
/// end value is used: nothing is extrapolated (owner, 2026-10-12).
///
/// Source: scope manufacturers' manuals (side-focus / parallax adjustment);
/// the mark–distance relation is not linear over the whole wheel, which is
/// why only neighbouring recorded marks are interpolated.
class ParallaxPoint {
  /// Wheel reading: the printed number or the tick count.
  final double mark;
  final double distanceM;
  const ParallaxPoint({required this.mark, required this.distanceM});
}

abstract final class ParallaxRange {
  static List<ParallaxPoint> _sorted(Iterable<ParallaxPoint> points) =>
      points.toList()..sort((a, b) => a.mark.compareTo(b.mark));

  /// Distance for [mark]; null with fewer than two different marks.
  static double? distanceAt(List<ParallaxPoint> points, double mark) {
    if (!mark.isFinite) return null;
    final s = _sorted(points);
    if (s.length < 2 || s.first.mark == s.last.mark) return null;
    if (mark <= s.first.mark) return s.first.distanceM;
    if (mark >= s.last.mark) return s.last.distanceM;
    for (var i = 1; i < s.length; i++) {
      final a = s[i - 1], b = s[i];
      if (mark > b.mark) continue;
      if (b.mark == a.mark) return b.distanceM;
      final t = (mark - a.mark) / (b.mark - a.mark);
      return a.distanceM + t * (b.distanceM - a.distanceM);
    }
    return s.last.distanceM;
  }

  /// Marks offered in the field: the recorded ones and the midpoint of each
  /// neighbouring pair (the half-way position between two marks).
  static List<double> pickMarks(List<ParallaxPoint> points) {
    final marks = _sorted(points).map((p) => p.mark).toSet().toList();
    if (marks.length < 2) return const [];
    return [
      for (var i = 0; i < marks.length; i++) ...[
        if (i > 0) (marks[i - 1] + marks[i]) / 2,
        marks[i],
      ],
    ];
  }

  /// [points] with [point] added; the same mark again replaces its
  /// distance. Sorted by mark.
  static List<ParallaxPoint> upsert(
    List<ParallaxPoint> points,
    ParallaxPoint point,
  ) => _sorted([...points.where((p) => p.mark != point.mark), point]);
}
