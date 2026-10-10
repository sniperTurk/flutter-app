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
}
