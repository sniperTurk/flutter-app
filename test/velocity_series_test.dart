// Kronograf serisi (Ö3, 2026-10-12): the statistics of a velocity string and
// the powder temperature coefficient fitted from series at different
// temperatures (NIST/SEMATECH e-Handbook 1.3.5.6 and 4.1.4).
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/core/velocity_series.dart';

void main() {
  group('VelocitySeries.parse', () {
    test('one value per line: mean, sample SD (n − 1), ES, n', () {
      final s = VelocitySeries.parse('800\n805\n795', fps: false);
      expect(s.n, 3);
      expect(s.meanMps, closeTo(800, 1e-9));
      expect(s.sdMps, closeTo(5, 1e-9));
      expect(s.esMps, closeTo(10, 1e-9));
    });

    test('fps values are converted to m/s', () {
      final s = VelocitySeries.parse('2625;2641', fps: true);
      expect(s.mps[0], closeTo(UnitSystem.fpsToMps(2625), 1e-9));
      expect(s.mps[1], closeTo(UnitSystem.fpsToMps(2641), 1e-9));
    });

    test('comma is the decimal mark, space separates values', () {
      final s = VelocitySeries.parse('812,4 811,6', fps: false);
      expect(s.mps, [812.4, 811.6]);
    });

    test('empty lines and trailing spaces are not errors', () {
      final s = VelocitySeries.parse('800\n\n805 \n', fps: false);
      expect(s.n, 2);
    });

    test('an unreadable value names its line', () {
      expect(
        () => VelocitySeries.parse('800\nabc', fps: false),
        throwsA(
          isA<VelocitySeriesFormatException>().having((e) => e.line, 'line', 2),
        ),
      );
    });

    test('a value outside 50–1500 m/s is rejected with its line', () {
      expect(
        () => VelocitySeries.parse('800\n801\n49', fps: false),
        throwsA(
          isA<VelocitySeriesFormatException>().having((e) => e.line, 'line', 3),
        ),
      );
      expect(
        () => VelocitySeries.parse('1501', fps: false),
        throwsA(isA<VelocitySeriesFormatException>()),
      );
    });

    test('no SD below three shots', () {
      expect(VelocitySeries.parse('800 805', fps: false).sdMps, isNull);
    });

    test('empty text is an empty series', () {
      final s = VelocitySeries.parse('  \n ', fps: false);
      expect(s.n, 0);
      expect(s.sdMps, isNull);
      expect(s.slopeMpsPerShot, isNull);
    });

    test('slope along the string in shot order (PCP)', () {
      final s = VelocitySeries.parse('280 279 278 277 276', fps: false);
      expect(s.slopeMpsPerShot, closeTo(-1, 1e-9));
      expect(VelocitySeries.parse('280', fps: false).slopeMpsPerShot, isNull);
    });
  });

  group('fitPowderCoefficient', () {
    test('two series 30 °C apart give k, T0 and v0', () {
      final fit = fitPowderCoefficient([
        (tempC: 5, meanMps: 790, n: 5),
        (tempC: 35, meanMps: 814, n: 5),
      ])!;
      expect(fit.coefPercentPer15C, closeTo(1.496, 0.005));
      expect(fit.referenceC, closeTo(20, 1e-9));
      expect(fit.v0Mps, closeTo(802, 1e-9));
    });

    test('series are weighted by their shot count', () {
      final fit = fitPowderCoefficient([
        (tempC: 5, meanMps: 790, n: 15),
        (tempC: 35, meanMps: 814, n: 5),
      ])!;
      expect(fit.referenceC, closeTo(12.5, 1e-9));
      expect(fit.v0Mps, closeTo(796, 1e-9));
    });

    test('one temperature, a narrow span or an absurd k give nothing', () {
      expect(
        fitPowderCoefficient([
          (tempC: 20, meanMps: 790, n: 5),
          (tempC: 20, meanMps: 795, n: 5),
        ]),
        isNull,
      );
      expect(
        fitPowderCoefficient([
          (tempC: 20, meanMps: 790, n: 5),
          (tempC: 28, meanMps: 795, n: 5),
        ]),
        isNull,
      );
      expect(
        fitPowderCoefficient([
          (tempC: 0, meanMps: 700, n: 5),
          (tempC: 30, meanMps: 900, n: 5),
        ]),
        isNull,
      );
      expect(fitPowderCoefficient([(tempC: 0, meanMps: 700, n: 5)]), isNull);
    });
  });
}
