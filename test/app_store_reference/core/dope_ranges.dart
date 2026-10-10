import 'production_limits.dart';

class DopeRanges {
  const DopeRanges._();

  /// Parses comma/space/semicolon separated metric ranges, removes duplicates,
  /// sorts ascending and rejects unsafe/non-physical values.
  static List<double> parse(
    String input, {
    double maxRangeM = ProductionLimits.maxRangeM,
  }) {
    final tokens = input
        .split(RegExp(r'[,;\s]+'))
        .where((e) => e.trim().isNotEmpty);
    final values = <double>{};
    for (final token in tokens) {
      final value = double.tryParse(token);
      if (value == null || !value.isFinite || value <= 0 || value > maxRangeM) {
        throw FormatException('Geçersiz mesafe: $token');
      }
      values.add(value);
    }
    if (values.isEmpty) {
      throw const FormatException('En az bir mesafe girilmeli');
    }
    final result = values.toList()..sort();
    return List.unmodifiable(result);
  }
}
