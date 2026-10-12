// Ö13 — Duyarlılık testleri (docs/yeni-hesaplar-2026-10-11.md, bölüm 2).
//
// Her sürümde: hız +1 m/s, BC −%5, 1 m/s tam değer yan rüzgâr ve basınç
// −10 hPa uygulamanın kendi çözücüsünde düzeltmeyi hangi yöne ve ne kadar
// değiştiriyor? Beklenen değerler raporun 2.1 / 2.2 tablolarıdır; o tablolar
// uygulamadan bağımsız bir nokta-kütle hesabıyla üretildi (raporun Ek A'sı;
// depodaki tools/formula_reference.py ile yeniden hesaplandığında fark < %3).
// Tolerans max(%15, 0,3 cm): gizli bir birim/işaret hatası ya da sürüklenme
// modelinin bozulması bunu kesin aşar, iki bağımsız RK4'ün küçük farkı aşmaz.
//
// Kurallar (raporun Ek A'sı): sıfır nominal değerle (hız satırında sıfır günü
// hızı ayrı tutulur), ICAO kuru havada; + = mermi yukarı vurur.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/models/domain.dart';

const _icao = EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 0,
  altitudeM: 0,
  windMps: 0,
  windDirectionDeg: 90,
);

class _Weapon {
  final String name;
  final BallisticModel model;
  final double bc, grain, mps, sightMm, zeroM;
  final List<double> ranges;
  const _Weapon(
    this.name, {
    required this.model,
    required this.bc,
    required this.grain,
    required this.mps,
    required this.sightMm,
    required this.zeroM,
    required this.ranges,
  });

  BallisticInput input({
    double? mps,
    double? bc,
    EnvironmentData environment = _icao,
  }) => BallisticInput(
    muzzleVelocityMps: mps ?? this.mps,
    // Rifle zeroed with the nominal velocity (report, Ek A).
    zeroMuzzleVelocityMps: mps == null ? null : this.mps,
    grain: grain,
    zeroRangeM: zeroM,
    sightHeightMm: sightMm,
    rangesM: ranges,
    environment: environment,
    ballisticCoefficient: bc ?? this.bc,
    ballisticModel: model,
  );
}

// Raporun örnek silahları (bölüm 0).
const _t1 = _Weapon(
  'T1 .308 175 gr G7 0,243 790 m/s',
  model: BallisticModel.g7,
  bc: 0.243,
  grain: 175,
  mps: 790,
  sightMm: 45,
  zeroM: 100,
  ranges: [300, 600, 800, 1000],
);
const _t2 = _Weapon(
  'T2 6.5 CM 140 gr G7 0,315 820 m/s',
  model: BallisticModel.g7,
  bc: 0.315,
  grain: 140,
  mps: 820,
  sightMm: 45,
  zeroM: 100,
  ranges: [300, 600, 800, 1000],
);
const _p1 = _Weapon(
  'P1 PCP .22 diabolo 18 gr G1 0,031 275 m/s',
  model: BallisticModel.g1,
  bc: 0.031,
  grain: 18,
  mps: 275,
  sightMm: 50,
  zeroM: 30,
  ranges: [30, 50, 75, 100],
);
const _p2 = _Weapon(
  'P2 PCP .22 slug 25 gr G1 0,090 290 m/s',
  model: BallisticModel.g1,
  bc: 0.090,
  grain: 25,
  mps: 290,
  sightMm: 50,
  zeroM: 30,
  ranges: [30, 50, 75, 100],
);

const _engine = BallisticEngine();

/// Vertical change in cm at each range (+ = the bullet hits higher).
List<double> _verticalCm(BallisticInput nominal, BallisticInput shot) {
  final a = _engine.solve(nominal), b = _engine.solve(shot);
  return [
    for (var i = 0; i < a.length; i++)
      (a[i].correctionMrad - b[i].correctionMrad) * a[i].rangeM / 10,
  ];
}

/// Crosswind drift in cm at each range (magnitude).
List<double> _windCm(BallisticInput shot) => [
  for (final p in _engine.solve(shot)) (p.windMrad * p.rangeM / 10).abs(),
];

void _expectTable(String what, List<double> actual, List<double> expected) {
  for (var i = 0; i < expected.length; i++) {
    final e = expected[i], a = actual[i];
    final tolerance = (e.abs() * 0.15) > 0.3 ? e.abs() * 0.15 : 0.3;
    if (e.abs() >= 0.3) {
      expect(a.sign, e.sign, reason: '$what [$i]: işaret ($a cm, tablo $e)');
    }
    expect(a, closeTo(e, tolerance), reason: '$what [$i]: $a cm, tablo $e');
  }
}

void main() {
  group('Bölüm 2.1 — ateşli tüfek (300/600/800/1000 m, cm)', () {
    test('T1 hız +1 m/s: yukarı, tablo/10 (2/11/24/46 → 0,2/1,1/2,4/4,6)', () {
      _expectTable('T1 hız +1', _verticalCm(_t1.input(), _t1.input(mps: 791)), [
        0.2,
        1.1,
        2.4,
        4.6,
      ]);
    });
    test('T1 hız +10 m/s: yukarı 2/11/24/46', () {
      _expectTable(
        'T1 hız +10',
        _verticalCm(_t1.input(), _t1.input(mps: 800)),
        [2, 11, 24, 46],
      );
    });
    test('T2 hız +10 m/s: yukarı 2/9/18/32', () {
      _expectTable(
        'T2 hız +10',
        _verticalCm(_t2.input(), _t2.input(mps: 830)),
        [2, 9, 18, 32],
      );
    });
    test('T1 BC −%5: aşağı −1/−9/−29/−75', () {
      _expectTable(
        'T1 BC −5 %',
        _verticalCm(_t1.input(), _t1.input(bc: 0.243 * 0.95)),
        [-1, -9, -29, -75],
      );
    });
    test('T2 BC −%5: aşağı −0,5/−5/−16/−38', () {
      _expectTable(
        'T2 BC −5 %',
        _verticalCm(_t2.input(), _t2.input(bc: 0.315 * 0.95)),
        [-0.5, -5, -16, -38],
      );
    });
    test('T1 basınç −10 hPa: yukarı 0,1/1,7/5,3/14 (Ö4)', () {
      _expectTable(
        'T1 basınç −10',
        _verticalCm(
          _t1.input(),
          _t1.input(
            environment: const EnvironmentData(
              temperatureC: 15,
              pressureHpa: 1003.25,
              humidityPercent: 0,
            ),
          ),
        ),
        [0.1, 1.7, 5.3, 14],
      );
    });
    test('1 m/s tam değer yan rüzgâr: T1 5/23/46/80, T2 4/16/30/51', () {
      const wind = EnvironmentData(
        temperatureC: 15,
        pressureHpa: 1013.25,
        humidityPercent: 0,
        windMps: 1,
        windDirectionDeg: 90,
      );
      _expectTable('T1 rüzgâr', _windCm(_t1.input(environment: wind)), [
        5,
        23,
        46,
        80,
      ]);
      _expectTable('T2 rüzgâr', _windCm(_t2.input(environment: wind)), [
        4,
        16,
        30,
        51,
      ]);
    });
    test('rüzgâr yönü: soldan (saat 9) esen rüzgâr sağa, sağdan sola', () {
      EnvironmentData from(double deg) => EnvironmentData(
        temperatureC: 15,
        pressureHpa: 1013.25,
        humidityPercent: 0,
        windMps: 1,
        windDirectionDeg: deg,
      );
      final left = _engine.solve(_t1.input(environment: from(90))).last;
      final right = _engine.solve(_t1.input(environment: from(270))).last;
      expect(left.windMrad.sign, -right.windMrad.sign);
      expect(left.windMrad.abs(), closeTo(right.windMrad.abs(), 1e-9));
    });
  });

  group('Bölüm 2.2 — PCP (30/50/75/100 m, cm)', () {
    test('P1 hız +10 m/s: yukarı 0,4/1,2/2,8/5,3', () {
      _expectTable(
        'P1 hız +10',
        _verticalCm(_p1.input(), _p1.input(mps: 285)),
        [0.4, 1.2, 2.8, 5.3],
      );
    });
    test('P1 hız +1 m/s: yukarı, tablo/10', () {
      _expectTable('P1 hız +1', _verticalCm(_p1.input(), _p1.input(mps: 276)), [
        0.04,
        0.12,
        0.28,
        0.53,
      ]);
    });
    test('P1 BC −%10: aşağı −0,1/−0,4/−1,4/−3,8', () {
      _expectTable(
        'P1 BC −10 %',
        _verticalCm(_p1.input(), _p1.input(bc: 0.031 * 0.90)),
        [-0.1, -0.4, -1.4, -3.8],
      );
    });
    test('1 m/s yan rüzgâr: P1 0,9/2,5/5,8/10,5, P2 0,3/0,9/2,0/3,6', () {
      const wind = EnvironmentData(
        temperatureC: 15,
        pressureHpa: 1013.25,
        humidityPercent: 0,
        windMps: 1,
        windDirectionDeg: 90,
      );
      _expectTable('P1 rüzgâr', _windCm(_p1.input(environment: wind)), [
        0.9,
        2.5,
        5.8,
        10.5,
      ]);
      _expectTable('P2 rüzgâr', _windCm(_p2.input(environment: wind)), [
        0.3,
        0.9,
        2.0,
        3.6,
      ]);
    });
  });
}
