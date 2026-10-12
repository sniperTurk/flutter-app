import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/wez.dart';

/// Ö12 (owner, 2026-10-11): range, wind and BC errors are shared by every
/// shot of a series; group and SD change from shot to shot. "En az bir
/// isabet" is a two-layer Monte Carlo.
void main() {
  // Main session's example: group σ 0.15 mrad, shared wind σ 0.4 mrad,
  // target radius 0.25 mrad.
  const example = [
    WezSource('grup (tüfek ve atıcı)', sigmaX: 0.15, sigmaY: 0.15),
    WezSource('rüzgâr belirsizliği', sigmaX: 0.4, shared: true),
  ];

  test('örnek: tek %35, bağımsız %72, ortak hatayla %57', () {
    final single = Wez.simulate(sources: example, targetRadiusMrad: 0.25);
    expect(single.probability, closeTo(0.35, 0.03));
    expect(Wez.atLeastOneHit(single.probability, 3), closeTo(0.72, 0.03));
    final series = Wez.seriesHitProbability(
      sources: example,
      targetRadiusMrad: 0.25,
      shotCount: 3,
    );
    expect(series, closeTo(0.57, 0.03));
    // Shared error makes the independent formula too optimistic.
    expect(series, lessThan(Wez.atLeastOneHit(single.probability, 3) - 0.1));
  });

  test('1 atışta sonuç tek atış olasılığının aynısı', () {
    final single = Wez.simulate(sources: example, targetRadiusMrad: 0.25);
    expect(
      Wez.seriesHitProbability(
        sources: example,
        targetRadiusMrad: 0.25,
        shotCount: 1,
      ),
      single.probability,
    );
  });

  test('shared bayrağı tek atış olasılığını ve vuruşları değiştirmez', () {
    const unmarked = [
      WezSource('grup (tüfek ve atıcı)', sigmaX: 0.15, sigmaY: 0.15),
      WezSource('rüzgâr belirsizliği', sigmaX: 0.4),
    ];
    final a = Wez.simulate(sources: unmarked, targetRadiusMrad: 0.25);
    final b = Wez.simulate(sources: example, targetRadiusMrad: 0.25);
    expect(b.probability, a.probability);
    expect(b.impacts, a.impacts);
    expect(b.dominant!.name, a.dominant!.name);
  });

  test('sabit tohum: aynı girdi aynı sayı', () {
    double run() => Wez.seriesHitProbability(
      sources: example,
      targetRadiusMrad: 0.25,
      shotCount: 5,
    );
    expect(run(), run());
  });

  test('hepsi atıştan atışa ise bağımsız formüle yakın', () {
    const perShot = [WezSource('grup', sigmaX: 0.3, sigmaY: 0.3)];
    final p = Wez.simulate(
      sources: perShot,
      targetRadiusMrad: 0.25,
    ).probability;
    expect(
      Wez.seriesHitProbability(
        sources: perShot,
        targetRadiusMrad: 0.25,
        shotCount: 3,
      ),
      closeTo(Wez.atLeastOneHit(p, 3), 0.04),
    );
  });

  test('hepsi ortak ise tekrar atmak şansı artırmaz', () {
    const allShared = [
      WezSource('rüzgâr belirsizliği', sigmaX: 0.3, shared: true),
      WezSource('mesafe hatası', sigmaY: 0.3, shared: true),
    ];
    final p = Wez.simulate(
      sources: allShared,
      targetRadiusMrad: 0.25,
    ).probability;
    expect(
      Wez.seriesHitProbability(
        sources: allShared,
        targetRadiusMrad: 0.25,
        shotCount: 10,
      ),
      closeTo(p, 0.04),
    );
  });

  test('daha çok atış şansı düşürmez; 0 atış reddedilir', () {
    var last = 0.0;
    for (final n in Wez.shotCounts) {
      final v = Wez.seriesHitProbability(
        sources: example,
        targetRadiusMrad: 0.25,
        shotCount: n,
      );
      expect(v, greaterThanOrEqualTo(last - 0.02));
      expect(v, inInclusiveRange(0, 1));
      last = v;
    }
    expect(
      () => Wez.seriesHitProbability(
        sources: example,
        targetRadiusMrad: 0.25,
        shotCount: 0,
      ),
      throwsArgumentError,
    );
  });
}
