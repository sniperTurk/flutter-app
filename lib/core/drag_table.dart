/// A validated piecewise-linear lookup primitive for Mach-indexed reference
/// drag data. This class contains no drag values of its own; the actual
/// G1/G7 Cd-vs-Mach tables live in [StandardDragTables] (see that file for
/// provenance). Keeping the interpolation primitive separate from the data
/// lets each be validated independently.
class DragSample {
  final double mach;
  final double coefficient;
  const DragSample(this.mach, this.coefficient);
}

class DragTable {
  final List<DragSample> samples;

  DragTable(Iterable<DragSample> values) : samples = List.unmodifiable(values) {
    if (samples.length < 2) {
      throw ArgumentError('drag table requires at least two samples');
    }
    double? previous;
    for (final sample in samples) {
      if (!sample.mach.isFinite || sample.mach < 0) {
        throw ArgumentError.value(sample.mach, 'mach', 'must be finite and >= 0');
      }
      if (!sample.coefficient.isFinite || sample.coefficient <= 0) {
        throw ArgumentError.value(sample.coefficient, 'coefficient', 'must be finite and > 0');
      }
      if (previous != null && sample.mach <= previous) {
        throw ArgumentError('drag table Mach values must be strictly increasing');
      }
      previous = sample.mach;
    }
  }

  double coefficientAtMach(double mach) {
    if (!mach.isFinite || mach < 0) {
      throw ArgumentError.value(mach, 'mach', 'must be finite and >= 0');
    }
    if (mach <= samples.first.mach) return samples.first.coefficient;
    if (mach >= samples.last.mach) return samples.last.coefficient;

    var low = 0;
    var high = samples.length - 1;
    while (high - low > 1) {
      final mid = (low + high) ~/ 2;
      if (samples[mid].mach <= mach) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final a = samples[low];
    final b = samples[high];
    final fraction = (mach - a.mach) / (b.mach - a.mach);
    return a.coefficient + (b.coefficient - a.coefficient) * fraction;
  }
}
