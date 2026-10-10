import 'drag_table.dart';

/// Özel sürüklenme eğrisi (custom drag curve, owner 2026-10-10): the
/// bullet's own Cd-vs-Mach curve, e.g. a Lapua/QuickTARGET `.drg` file, a
/// Doppler-radar export or a two-column CSV.
///
/// With the bullet's own Cd the form factor is 1, so the solver uses the
/// curve as its reference table and the sectional density (lb/in²) as the
/// "BC": a = ½·ρ·Cd·(π/4)·v² / (SD·703.07) = ½·ρ·Cd·A·v² / m.
abstract final class DragCurve {
  static const minPoints = 5;
  static const maxPoints = 500;

  /// Sectional density in lb/in² from the bullet weight (grain) and
  /// diameter (mm). 168 gr .308 (7.82 mm) → 0.253.
  static double sectionalDensity({
    required double grain,
    required double diameterMm,
  }) {
    if (!grain.isFinite ||
        grain <= 0 ||
        !diameterMm.isFinite ||
        diameterMm <= 0) {
      throw ArgumentError('grain and diameter must be > 0');
    }
    final inches = diameterMm / 25.4;
    return grain / 7000 / (inches * inches);
  }

  /// Parses pasted text or file contents into a curve.
  ///
  /// Every line holding exactly two numbers is a point; header, comment and
  /// blank lines are skipped. Separators: comma, semicolon, tab or spaces;
  /// a decimal comma ("0,235") is accepted when the separator is not a
  /// comma. The column order is detected: Mach is the column that rises
  /// steadily and reaches past 1 (`.drg` files list Cd first, CSV exports
  /// usually Mach first).
  ///
  /// Throws [FormatException] with a Turkish message the UI shows as is.
  static List<DragSample> parse(String text) {
    final rows = <(double, double)>[];
    for (final raw in text.split(RegExp(r'\r?\n|\r'))) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('//')) {
        continue;
      }
      final pair = _pair(line);
      if (pair != null) rows.add(pair);
    }
    if (rows.length < minPoints) {
      throw FormatException(
        'En az $minPoints nokta gerekli (her satırda Mach ve Cd); '
        '${rows.length} bulundu.',
      );
    }
    if (rows.length > maxPoints) {
      throw const FormatException('En fazla $maxPoints nokta olabilir.');
    }
    final a = [for (final r in rows) r.$1];
    final b = [for (final r in rows) r.$2];
    final machFirst = _looksLikeMach(a) && !_looksLikeMach(b)
        ? true
        : _looksLikeMach(b) && !_looksLikeMach(a)
        ? false
        : _max(a) >= _max(b);
    final points = <DragSample>[];
    for (final r in rows) {
      final mach = machFirst ? r.$1 : r.$2;
      final cd = machFirst ? r.$2 : r.$1;
      if (mach < 0 || mach > 10) {
        throw FormatException('Mach değeri 0 ile 10 arasında olmalı: $mach');
      }
      if (cd <= 0 || cd > 2) {
        throw FormatException('Cd değeri 0 ile 2 arasında olmalı: $cd');
      }
      points.add(DragSample(mach, cd));
    }
    points.sort((x, y) => x.mach.compareTo(y.mach));
    final unique = <DragSample>[];
    for (final p in points) {
      if (unique.isNotEmpty && unique.last.mach == p.mach) continue;
      unique.add(p);
    }
    if (unique.length < minPoints) {
      throw const FormatException('Aynı Mach değeri tekrar ediyor.');
    }
    if (unique.last.mach < 1.2) {
      throw FormatException(
        'Eğri en az Mach 1,2\'ye kadar gitmeli (son nokta '
        '${unique.last.mach.toStringAsFixed(2)}).',
      );
    }
    return List.unmodifiable(unique);
  }

  /// Validates stored points (JSON `[[mach, cd], ...]`); null when invalid.
  static List<DragSample>? fromJson(Object? v) {
    if (v is! List || v.length < minPoints || v.length > maxPoints) {
      return null;
    }
    final out = <DragSample>[];
    for (final e in v) {
      if (e is! List || e.length != 2) return null;
      final m = e[0], cd = e[1];
      if (m is! num || cd is! num) return null;
      if (!m.isFinite || !cd.isFinite || m < 0 || m > 10 || cd <= 0 || cd > 2) {
        return null;
      }
      if (out.isNotEmpty && m <= out.last.mach) return null;
      out.add(DragSample(m.toDouble(), cd.toDouble()));
    }
    return List.unmodifiable(out);
  }

  static List<List<double>> toJson(List<DragSample> points) => [
    for (final p in points) [p.mach, p.coefficient],
  ];

  static (double, double)? _pair(String line) {
    List<String> parts;
    var decimalComma = false;
    if (line.contains(';') || line.contains('\t')) {
      parts = line.split(RegExp(r'[;\t]+'));
      decimalComma = true;
    } else {
      final ws = line.split(RegExp(r'\s+'));
      if (ws.length == 2 && !ws[0].endsWith(',')) {
        parts = ws;
        decimalComma = true;
      } else {
        parts = line.split(RegExp(r'\s*,\s*'));
      }
    }
    parts = [
      for (final p in parts)
        if (p.trim().isNotEmpty) p.trim(),
    ];
    if (parts.length != 2) return null;
    double? number(String s) =>
        double.tryParse(decimalComma ? s.replaceAll(',', '.') : s);
    final x = number(parts[0]), y = number(parts[1]);
    if (x == null || y == null || !x.isFinite || !y.isFinite) return null;
    return (x, y);
  }

  /// Rising (allowing tiny noise), from below 1 to past 1.
  static bool _looksLikeMach(List<double> v) {
    var rises = 0;
    for (var i = 1; i < v.length; i++) {
      if (v[i] > v[i - 1]) rises++;
    }
    return rises >= (v.length - 1) * 0.9 && v.first < 1 && v.last > 1;
  }

  static double _max(List<double> v) => v.reduce((x, y) => x > y ? x : y);
}
