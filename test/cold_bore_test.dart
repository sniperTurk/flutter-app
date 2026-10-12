// Ö9 Soğuk namlu: ilk atışların ortalama kaçıklığı yalnız yeterli kayıtta
// (≥ 5 ilk atış) ve ortalama belirsizliğinden belirgin büyükse öneri olur.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/tools/domain/cold_bore.dart';

ColdBoreShot _first(double up, double right, {bool suppressor = false}) =>
    ColdBoreShot(
      rangeM: 100,
      missUpCm: up,
      missRightCm: right,
      firstShot: true,
      suppressor: suppressor,
    );

void main() {
  test('four first shots: too few, no suggestion', () {
    final s = ColdBore.forState([
      for (var i = 0; i < 4; i++) _first(2, 0),
    ], suppressor: false);
    expect(s.firstShots, 4);
    expect(s.verdict, ColdBoreVerdict.tooFew);
    expect(s.meanUpMrad, isNull);
  });

  test('five consistent first shots: suggestion against the mean', () {
    final s = ColdBore.forState([
      _first(1.9, -0.1),
      _first(2.1, 0.1),
      _first(2.0, 0.0),
      _first(1.8, -0.2),
      _first(2.2, 0.2),
    ], suppressor: false);
    expect(s.verdict, ColdBoreVerdict.suggest);
    // 2 cm at 100 m = 0.2 mrad high -> dial 0.2 mrad down.
    expect(s.meanUpMrad, closeTo(0.2, 1e-9));
    expect(s.meanRightMrad, closeTo(0, 1e-9));
    expect(s.correctionUpMrad, closeTo(-0.2, 1e-9));
    expect(s.seUpMrad, greaterThan(0));
  });

  test('scattered first shots: mean inside its uncertainty, no suggestion', () {
    final s = ColdBore.forState([
      _first(5, 4),
      _first(-5, -4),
      _first(4, -5),
      _first(-4, 5),
      _first(1, 0),
    ], suppressor: false);
    expect(s.firstShots, 5);
    expect(s.verdict, ColdBoreVerdict.notSignificant);
  });

  test('only first shots of the asked suppressor state count', () {
    final shots = [
      for (var i = 0; i < 5; i++) _first(2, 0, suppressor: true),
      for (var i = 0; i < 5; i++)
        const ColdBoreShot(
          rangeM: 100,
          missUpCm: 9,
          missRightCm: 9,
          firstShot: false,
          suppressor: false,
        ),
    ];
    expect(ColdBore.forState(shots, suppressor: false).firstShots, 0);
    final on = ColdBore.forState(shots, suppressor: true);
    expect(on.firstShots, 5);
    expect(on.verdict, ColdBoreVerdict.suggest);
  });

  test('ranges combine by angle; invalid ranges are skipped', () {
    final s = ColdBore.forState([
      for (var i = 0; i < 5; i++)
        ColdBoreShot(
          rangeM: i.isEven ? 100 : 300,
          missUpCm: i.isEven ? 3 : 9,
          missRightCm: 0,
          firstShot: true,
          suppressor: false,
        ),
      const ColdBoreShot(
        rangeM: 0,
        missUpCm: 50,
        missRightCm: 0,
        firstShot: true,
        suppressor: false,
      ),
    ], suppressor: false);
    expect(s.firstShots, 5);
    expect(s.meanUpMrad, closeTo(0.3, 1e-9));
    expect(s.verdict, ColdBoreVerdict.suggest);
  });
}
