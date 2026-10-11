import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/wez.dart';

void main() {
  test('a tight group in a big target almost always hits', () {
    final r = Wez.simulate(
      sources: const [WezSource('grup', sigmaX: 0.05, sigmaY: 0.05)],
      targetRadiusMrad: 0.5,
    );
    expect(r.probability, greaterThan(0.99));
    expect(r.impacts.length, Wez.shots);
    expect(r.dominant!.name, 'grup');
  });

  test('one sigma radius circle holds ~39 % (Rayleigh)', () {
    final r = Wez.simulate(
      sources: const [WezSource('grup', sigmaX: 1, sigmaY: 1)],
      targetRadiusMrad: 1,
      count: 20000,
    );
    expect(r.probability, closeTo(0.393, 0.02));
  });

  test('the biggest source is named and the result is repeatable', () {
    const sources = [
      WezSource('grup', sigmaX: 0.1, sigmaY: 0.1),
      WezSource('rüzgâr belirsizliği', sigmaX: 0.4),
      WezSource('mesafe hatası', sigmaY: 0.05),
    ];
    final a = Wez.simulate(sources: sources, targetRadiusMrad: 0.3);
    final b = Wez.simulate(sources: sources, targetRadiusMrad: 0.3);
    expect(a.dominant!.name, 'rüzgâr belirsizliği');
    expect(a.probability, b.probability);
    expect(a.probability, lessThan(0.9));
  });

  test('group and ± helpers', () {
    // 3.067 cm group at 100 m = 0.1 mrad sigma.
    expect(Wez.groupSigmaMrad(0.03067, 100), closeTo(0.1, 1e-3));
    expect(Wez.sigmaOfPlusMinus(1), 0.5);
  });

  test('en az bir isabet: 1 − (1 − p)^n', () {
    // One shot is the first-shot probability itself.
    expect(Wez.atLeastOneHit(0.6, 1), closeTo(0.6, 1e-12));
    // 0.5 per shot: 3 shots = 1 − 0.125, 5 shots = 1 − 1/32.
    expect(Wez.atLeastOneHit(0.5, 3), closeTo(0.875, 1e-12));
    expect(Wez.atLeastOneHit(0.5, 5), closeTo(0.96875, 1e-12));
    // 0.2 per shot, 10 shots = 1 − 0.8^10 = 0.892626...
    expect(Wez.atLeastOneHit(0.2, 10), closeTo(0.8926258176, 1e-9));
    // Edges: never hit stays 0, always hit stays 1.
    expect(Wez.atLeastOneHit(0, 10), 0);
    expect(Wez.atLeastOneHit(1, 3), 1);
    // More shots never lower the chance.
    var last = 0.0;
    for (final n in Wez.shotCounts) {
      final v = Wez.atLeastOneHit(0.3, n);
      expect(v, greaterThanOrEqualTo(last));
      last = v;
    }
    // Out-of-range inputs are clamped / rejected.
    expect(Wez.atLeastOneHit(1.5, 2), 1);
    expect(Wez.atLeastOneHit(-0.1, 2), 0);
    expect(() => Wez.atLeastOneHit(0.5, 0), throwsArgumentError);
  });

  test('atış sayısı list starts at 1 and the default is 1', () {
    expect(Wez.shotCounts, [1, 3, 5, 10]);
    expect(Wez.shotCounts.first, Wez.defaultShotCount);
    expect(Wez.defaultShotCount, 1);
  });

  test('with a simulated p the n-shot line matches the formula', () {
    final r = Wez.simulate(
      sources: const [WezSource('grup', sigmaX: 1, sigmaY: 1)],
      targetRadiusMrad: 1,
      count: 20000,
    );
    final p = r.probability;
    expect(
      Wez.atLeastOneHit(p, 5),
      closeTo(1 - (1 - p) * (1 - p) * (1 - p) * (1 - p) * (1 - p), 1e-12),
    );
  });
}
