// Hesap kapsamı: vakum ve G1/G7 çözücü, rüzgâr, Coriolis, eğim/açı, dürbün
// eğimi (cant), ses altı/üstü geçiş, giriş doğrulama sınırları.
//
// Beklenen değerler fizik formüllerinden türetilir: vakum menzil denklemi
// (sin 2α = g·x/v²), sabit ivmeli hareket, Coriolis yatay sapması
// Z ≈ ω·sinφ·X·t (düz atış), simetri ve monotonluk özdeşlikleri. Hiçbir
// balistik programın çıktısı kullanılmaz.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/aerodynamic_trajectory_solver.dart';
import 'package:sniper_turk/core/atmosphere.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/units.dart';
import 'package:sniper_turk/models/domain.dart';

const _g = 9.80665;

/// Sıfırlama ortamıyla aynı (ICAO kuru, rüzgârsız) atış ortamı.
const _standard = EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 0,
  altitudeM: 0,
  windMps: 0,
  windDirectionDeg: 90,
);

EnvironmentData _wind(double mps, double deg) => EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 0,
  windMps: mps,
  windDirectionDeg: deg,
);

BallisticInput _rifle({
  List<double> ranges = const [100, 300, 600, 1000],
  EnvironmentData environment = _standard,
  double bc = 0.25,
  BallisticModel model = BallisticModel.g7,
  double velocity = 850,
  double inclineDeg = 0,
  double cantDeg = 0,
  double? latitudeDeg,
  double? azimuthDeg,
  WindZones? windZones,
}) => BallisticInput(
  muzzleVelocityMps: velocity,
  grain: 175,
  zeroRangeM: 100,
  sightHeightMm: 50,
  rangesM: ranges,
  environment: environment,
  ballisticCoefficient: bc,
  ballisticModel: model,
  inclineDeg: inclineDeg,
  cantDeg: cantDeg,
  latitudeDeg: latitudeDeg,
  azimuthDeg: azimuthDeg,
  windZones: windZones,
);

List<TrajectoryPoint> _solve(BallisticInput input) =>
    const BallisticEngine().solve(input);

void main() {
  group('Vakum çözücü — kapalı form fizik', () {
    const engine = BallisticEngine();

    test('nişan yüksekliği 0: menzil denklemi sin 2α = g·x/v²', () {
      const v = 300.0, x = 100.0;
      final alpha = 0.5 * math.asin(_g * x / (v * v));
      final points = engine.vacuumDope(
        muzzleVelocityMps: v,
        grain: 18,
        zeroRangeM: x,
        sightHeightMm: 0,
        rangesM: const [50, 100, 200, 400],
      );
      for (final p in points) {
        final r = p.rangeM;
        final cos = math.cos(alpha);
        final y = r * math.tan(alpha) - _g * r * r / (2 * v * v * cos * cos);
        expect(p.dropM, closeTo(-y, 1e-9), reason: '$r m düşüş');
        expect(p.timeOfFlightS, closeTo(r / (v * cos), 1e-12));
        expect(p.correctionMrad, closeTo(math.atan2(-y, r) * 1000, 1e-9));
        expect(
          p.correctionMoa,
          closeTo(Units.mradToMoa(p.correctionMrad), 1e-12),
        );
      }
      expect(points[1].dropM.abs(), lessThan(1e-9));
    });

    test('namlu ağzına çok yakın mesafede düşüş ≈ nişan yüksekliği', () {
      final p = engine
          .vacuumDope(
            muzzleVelocityMps: 280,
            grain: 18,
            zeroRangeM: 30,
            sightHeightMm: 50,
            rangesM: const [0.001],
          )
          .single;
      expect(p.dropM, closeTo(0.05, 1e-4));
    });

    test('vakumda hız sabit, enerji ½·m·v² (7000 gr = 0.45359237 kg)', () {
      final p = engine
          .vacuumDope(
            muzzleVelocityMps: 300,
            grain: 7000,
            zeroRangeM: 50,
            sightHeightMm: 40,
            rangesM: const [200],
          )
          .single;
      expect(p.velocityMps, 300);
      expect(p.energyJ, closeTo(0.5 * 0.45359237 * 300 * 300, 1e-6));
    });

    test('vakumda rüzgâr sapma üretmez', () {
      final p = engine
          .vacuumDope(
            muzzleVelocityMps: 300,
            grain: 18,
            zeroRangeM: 50,
            sightHeightMm: 40,
            rangesM: const [100],
            environment: _wind(10, 90),
          )
          .single;
      expect(p.windMrad, 0);
    });

    test('dürbün eğimi φ: yana sapma ½·g·sinφ·t²', () {
      const v = 300.0, phi = 10.0;
      final p = engine
          .vacuumDope(
            muzzleVelocityMps: v,
            grain: 18,
            zeroRangeM: 100,
            sightHeightMm: 0,
            rangesM: const [200],
            cantDeg: phi,
          )
          .single;
      final alpha = 0.5 * math.asin(_g * 100 / (v * v));
      final t = 200 / (v * math.cos(alpha));
      final z = 0.5 * _g * math.sin(phi * math.pi / 180) * t * t;
      expect(p.windMrad, closeTo(math.atan2(-z, 200) * 1000, 1e-9));
      expect(p.windMrad, lessThan(0), reason: 'saat yönü eğim → sağa sapma');
    });

    test('sıfır menzile ulaşılamıyorsa ArgumentError', () {
      expect(
        () => engine.vacuumDope(
          muzzleVelocityMps: 30,
          grain: 18,
          zeroRangeM: 100,
          sightHeightMm: 50,
          rangesM: const [100],
        ),
        throwsArgumentError,
      );
      expect(
        () => engine.vacuumDope(
          muzzleVelocityMps: 300,
          grain: 18,
          zeroRangeM: 100,
          sightHeightMm: 50,
          rangesM: const [100],
          zeroVelocityMps: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => engine.vacuumDope(
          muzzleVelocityMps: 0,
          grain: 18,
          zeroRangeM: 100,
          sightHeightMm: 50,
          rangesM: const [100],
        ),
        throwsArgumentError,
      );
    });

    test('dik yokuş yukarı: mermi menzile çıkamıyorsa StateError', () {
      // v² < 2·g·sinθ·r → 50² < 2·9.8·0.866·200.
      expect(
        () => engine.vacuumDope(
          muzzleVelocityMps: 50,
          grain: 18,
          zeroRangeM: 20,
          sightHeightMm: 50,
          rangesM: const [200],
          inclineDeg: 60,
        ),
        throwsStateError,
      );
    });

    test('düzeltme açısı 0 m ve negatif mesafede tanımsız', () {
      expect(
        () => engine.correctionMrad(offsetM: 0.1, rangeM: 0),
        throwsArgumentError,
      );
      expect(
        () => engine.correctionMrad(offsetM: 0.1, rangeM: -5),
        throwsArgumentError,
      );
      expect(
        engine.correctionMrad(offsetM: 0.1, rangeM: 100),
        closeTo(math.atan(0.001) * 1000, 1e-12),
      );
    });

    test('bugünkü hız sıfırlama hızından yüksekse düşüş azalır', () {
      List<TrajectoryPoint> at(double v) => engine.vacuumDope(
        muzzleVelocityMps: v,
        grain: 18,
        zeroRangeM: 50,
        sightHeightMm: 40,
        rangesM: const [150],
        zeroVelocityMps: 280,
      );
      expect(at(300).single.dropM, lessThan(at(280).single.dropM));
    });
  });

  group('G1/G7 çözücü — fizik özdeşlikleri', () {
    test('aynı ortamda sıfır mesafesinde düşüş ≈ 0', () {
      final p = _solve(_rifle(ranges: const [100])).single;
      expect(p.dropM.abs(), lessThan(1e-6));
    });

    test('rüzgâr sıfırken yana sapma tam sıfır', () {
      for (final p in _solve(_rifle())) {
        expect(p.windMrad, closeTo(0, 1e-12));
      }
    });

    test(
      'soldan ve sağdan eşit rüzgâr: eşit büyüklük, zıt yön, aynı düşüş',
      () {
        final left = _solve(_rifle(environment: _wind(5, 90)));
        final right = _solve(_rifle(environment: _wind(5, 270)));
        for (var i = 0; i < left.length; i++) {
          expect(left[i].windMrad, closeTo(-right[i].windMrad, 1e-9));
          expect(left[i].dropM, closeTo(right[i].dropM, 1e-9));
        }
        // Soldan esen rüzgâr mermiyi sağa iter → sola düzeltme (negatif).
        expect(left.last.windMrad, lessThan(0));
      },
    );

    test('karşıdan rüzgâr arkadan rüzgârdan daha çok düşürür', () {
      final head = _solve(_rifle(environment: _wind(8, 0))).last;
      final tail = _solve(_rifle(environment: _wind(8, 180))).last;
      expect(head.dropM, greaterThan(tail.dropM));
      expect(head.windMrad, closeTo(0, 1e-12));
      expect(head.timeOfFlightS, greaterThan(tail.timeOfFlightS));
    });

    test('hız azalır, uçuş süresi artar, enerji ½·m·v²', () {
      final points = _solve(
        _rifle(ranges: const [100, 200, 400, 600, 800, 1000]),
      );
      final m = Units.grainToKg(175);
      for (var i = 0; i < points.length; i++) {
        final p = points[i];
        expect(
          p.energyJ,
          closeTo(0.5 * m * p.velocityMps * p.velocityMps, 1e-9),
        );
        if (i > 0) {
          expect(p.velocityMps, lessThan(points[i - 1].velocityMps));
          expect(p.timeOfFlightS, greaterThan(points[i - 1].timeOfFlightS));
          expect(p.dropM, greaterThan(points[i - 1].dropM));
        }
      }
    });

    test(
      'ses üstünden ses altına geçiş: hız monoton, Mach 1 bir kez geçilir',
      () {
        final ranges = [for (var r = 100.0; r <= 1500; r += 100) r];
        final points = _solve(_rifle(ranges: ranges, bc: 0.15));
        final c = Atmosphere.speedOfSoundMps(_standard);
        expect(points.first.velocityMps, greaterThan(c));
        expect(points.last.velocityMps, lessThan(c));
        var crossings = 0;
        for (var i = 1; i < points.length; i++) {
          expect(points[i].velocityMps, lessThan(points[i - 1].velocityMps));
          if ((points[i - 1].velocityMps - c).sign !=
              (points[i].velocityMps - c).sign) {
            crossings++;
          }
          expect(points[i].velocityMps.isFinite, isTrue);
        }
        expect(crossings, 1);
      },
    );

    test('yüksek BC: daha az düşüş, daha çok kalan hız', () {
      final low = _solve(_rifle(bc: 0.2)).last;
      final high = _solve(_rifle(bc: 0.3)).last;
      expect(high.dropM, lessThan(low.dropM));
      expect(high.velocityMps, greaterThan(low.velocityMps));
    });

    test('ince hava (yükseklik): sıfır sabitken uzakta daha az düşüş', () {
      final thin = _solve(
        _rifle(
          environment: const EnvironmentData(
            temperatureC: 15,
            pressureHpa: 700,
            humidityPercent: 0,
          ),
        ),
      ).last;
      final sea = _solve(_rifle()).last;
      expect(thin.dropM, lessThan(sea.dropM));
      expect(thin.velocityMps, greaterThan(sea.velocityMps));
    });

    test('yokuş yukarı ve aşağı (±30°): düz atıştan daha az yükseltme', () {
      final level = _solve(_rifle(ranges: const [600])).single;
      final up = _solve(_rifle(ranges: const [600], inclineDeg: 30)).single;
      final down = _solve(_rifle(ranges: const [600], inclineDeg: -30)).single;
      expect(up.correctionMrad, lessThan(level.correctionMrad));
      expect(down.correctionMrad, lessThan(level.correctionMrad));
    });

    test('dürbün eğimi ±φ: ayna simetrisi; saat yönü → sağa sapma', () {
      final cw = _solve(_rifle(cantDeg: 10));
      final ccw = _solve(_rifle(cantDeg: -10));
      for (var i = 0; i < cw.length; i++) {
        expect(cw[i].windMrad, closeTo(-ccw[i].windMrad, 1e-9));
        expect(cw[i].dropM, closeTo(ccw[i].dropM, 1e-9));
      }
      expect(cw.last.windMrad, lessThan(0));
    });

    test('dikine atış (90°) menzile ulaşamaz: StateError; '
        'solveReachable yalnız o mesafeyi düşürür', () {
      final input = BallisticInput(
        muzzleVelocityMps: 280,
        grain: 18,
        zeroRangeM: 30,
        sightHeightMm: 50,
        rangesM: const [50, 1500],
        environment: _standard,
        ballisticCoefficient: 0.03,
        ballisticModel: BallisticModel.g1,
        inclineDeg: 90,
      );
      expect(() => _solve(input), throwsStateError);
      final reachable = const BallisticEngine().solveReachable(input);
      expect(reachable.points.map((p) => p.rangeM), [50]);
      expect(reachable.unreachableM, [1500]);
    });
  });

  group('Coriolis — Dünya dönüşü', () {
    const omega = 7.2921159e-5;

    test('kuzey yarıkürede sağa, güneyde sola; büyüklük fiziksel sınırlarda', () {
      const x = 1000.0, v0 = 850.0;
      final north = _solve(
        _rifle(ranges: const [x], latitudeDeg: 45, azimuthDeg: 0),
      ).single;
      final south = _solve(
        _rifle(ranges: const [x], latitudeDeg: -45, azimuthDeg: 0),
      ).single;
      // Yatay bileşen: z'' = 2Ω·sinφ·vx − k·z', vx' = −k·vx ⇒ z' = 2Ω·sinφ·t·vx
      // ⇒ Z = 2Ω·sinφ·∫t dx. t(x) ≥ x/v0 ve t(x) dışbükey (t ≤ x/X·T) olduğundan
      //   Ω·sinφ·X/v0 ≤ Z/X ≤ Ω·sinφ·T   (vakumda iki sınır eşittir).
      final s = math.sin(45 * math.pi / 180);
      final lower = omega * s * x / v0 * 1000 * 0.95;
      final upper = omega * s * north.timeOfFlightS * 1000 * 1.05;
      expect(north.windMrad, lessThan(0));
      expect(south.windMrad, greaterThan(0));
      expect(-north.windMrad, inInclusiveRange(lower, upper));
      expect(south.windMrad, inInclusiveRange(lower, upper));
    });

    test('ekvatorda kuzeye atışta yatay sapma ihmal edilebilir', () {
      final equator = _solve(
        _rifle(ranges: const [1000], latitudeDeg: 0, azimuthDeg: 0),
      ).single;
      final mid = _solve(
        _rifle(ranges: const [1000], latitudeDeg: 45, azimuthDeg: 0),
      ).single;
      expect(equator.windMrad.abs(), lessThan(mid.windMrad.abs() * 0.05));
    });

    test('Eötvös: doğuya atış batıya atıştan yüksek vurur', () {
      final east = _solve(
        _rifle(ranges: const [1000], latitudeDeg: 0, azimuthDeg: 90),
      ).single;
      final west = _solve(
        _rifle(ranges: const [1000], latitudeDeg: 0, azimuthDeg: 270),
      ).single;
      expect(east.dropM, lessThan(west.dropM));
    });

    test('enlem ve azimut birlikte verilmeli, sınırlar içinde olmalı', () {
      expect(() => _rifle(latitudeDeg: 40), throwsArgumentError);
      expect(() => _rifle(azimuthDeg: 40), throwsArgumentError);
      expect(
        () => _rifle(latitudeDeg: 90.1, azimuthDeg: 0),
        throwsArgumentError,
      );
      expect(
        () => _rifle(latitudeDeg: 40, azimuthDeg: 360.1),
        throwsArgumentError,
      );
      expect(
        () => _rifle(latitudeDeg: 40, azimuthDeg: -0.1),
        throwsArgumentError,
      );
      expect(_rifle(latitudeDeg: -90, azimuthDeg: 360).coriolis, isTrue);
      expect(_rifle().coriolis, isFalse);
    });
  });

  group('Rüzgâr bölgeleri ve çoklu BC', () {
    test('bölge sınırları: ⅓ ve ⅔ mesafede bir sonraki bölge başlar', () {
      const zones = WindZones(rangeM: 900, midMps: 4, farMps: 8);
      expect(zones.at(0, 2), 2);
      expect(zones.at(299.999, 2), 2);
      expect(zones.at(300, 2), 4);
      expect(zones.at(599.999, 2), 4);
      expect(zones.at(600, 2), 8);
      expect(zones.at(5000, 2), 8);
      final input = _rifle(environment: _wind(2, 90), windZones: zones);
      expect(input.windAt(100), 2);
      expect(input.windAt(700), 8);
      expect(_rifle(environment: _wind(3, 90)).windAt(700), 3);
    });

    test('uzakta sıfır rüzgâr: tek tip rüzgârdan daha az sapma', () {
      final uniform = _solve(_rifle(environment: _wind(5, 90))).last;
      final calmFar = _solve(
        _rifle(
          environment: _wind(5, 90),
          windZones: const WindZones(rangeM: 1000, midMps: 0, farMps: 0),
        ),
      ).last;
      expect(calmFar.windMrad.abs(), lessThan(uniform.windMrad.abs()));
      expect(calmFar.windMrad, lessThan(0));
    });

    test('hıza göre BC: eşik, en düşük bant ve bantsız temel BC', () {
      final input = BallisticInput(
        muzzleVelocityMps: 850,
        grain: 175,
        zeroRangeM: 100,
        sightHeightMm: 50,
        rangesM: const [100],
        ballisticCoefficient: 0.25,
        ballisticModel: BallisticModel.g7,
        bcBands: const [BcBand(400, 0.23), BcBand(600, 0.25)],
      );
      expect(input.bcAtSpeed(700), 0.25);
      expect(input.bcAtSpeed(600), 0.25);
      expect(input.bcAtSpeed(599.9), 0.23);
      expect(input.bcAtSpeed(100), 0.23);
      expect(_rifle(bc: 0.31).bcAtSpeed(100), 0.31);

      final trued = input.withBallisticCoefficient(0.5);
      expect(trued.ballisticCoefficient, 0.5);
      expect(trued.bcAtSpeed(700), closeTo(0.5, 1e-12));
      expect(trued.bcAtSpeed(100), closeTo(0.46, 1e-12));
    });

    test('hız doğrulama sıfırlama hızını aynı oranla ölçekler', () {
      final input = BallisticInput(
        muzzleVelocityMps: 820,
        grain: 175,
        zeroRangeM: 100,
        sightHeightMm: 50,
        rangesM: const [100],
        zeroMuzzleVelocityMps: 800,
      );
      final scaled = input.withMuzzleVelocity(410);
      expect(scaled.muzzleVelocityMps, 410);
      expect(scaled.zeroVelocityMps, closeTo(400, 1e-12));
      expect(_rifle().withMuzzleVelocity(700).zeroMuzzleVelocityMps, isNull);
    });
  });

  group('Çözücü giriş sınırları', () {
    BallisticInput base({
      double sight = 50,
      double gravity = 9.80665,
      double? zeroVelocity,
      List<double> ranges = const [100],
      double? bc = 0.25,
      BallisticModel? model = BallisticModel.g7,
      List<BcBand> bands = const [],
      WindZones? zones,
      EnvironmentData environment = _standard,
      EnvironmentData zeroEnvironment = _standard,
      double incline = 0,
      double cant = 0,
    }) => BallisticInput(
      muzzleVelocityMps: 850,
      grain: 175,
      zeroRangeM: 100,
      sightHeightMm: sight,
      rangesM: ranges,
      environment: environment,
      zeroEnvironment: zeroEnvironment,
      ballisticCoefficient: bc,
      ballisticModel: model,
      bcBands: bands,
      windZones: zones,
      gravityMps2: gravity,
      zeroMuzzleVelocityMps: zeroVelocity,
      inclineDeg: incline,
      cantDeg: cant,
    );

    test('sınır değerler kabul edilir', () {
      expect(() => base(sight: 299.999), returnsNormally);
      expect(() => base(ranges: const [3000]), returnsNormally);
      expect(() => base(gravity: 9.7), returnsNormally);
      expect(() => base(gravity: 9.9), returnsNormally);
      expect(() => base(incline: -180, cant: 180), returnsNormally);
      expect(() => base(bc: 5), returnsNormally);
    });

    test('sınır dışı değerler reddedilir', () {
      final cases = <String, BallisticInput Function()>{
        'nişan 300 mm': () => base(sight: 300),
        'mesafe 0 m': () => base(ranges: const [0]),
        'mesafe 3000.1 m': () => base(ranges: const [3000.1]),
        'boş mesafe': () => base(ranges: const []),
        'g 9.69': () => base(gravity: 9.69),
        'g 9.91': () => base(gravity: 9.91),
        'g NaN': () => base(gravity: double.nan),
        'sıfırlama hızı 0': () => base(zeroVelocity: 0),
        'sıfırlama hızı 1501': () => base(zeroVelocity: 1501),
        'BC 5.01': () => base(bc: 5.01),
        'BC modelsiz': () => base(model: null),
        'model BC’siz': () => base(bc: null),
        'bant BC 0': () => base(bands: const [BcBand(500, 0)]),
        'bant BC 5.1': () => base(bands: const [BcBand(500, 5.1)]),
        'bant hızı −1': () => base(bands: const [BcBand(-1, 0.2)]),
        '6 bant': () => base(
          bands: const [
            BcBand(100, 0.2),
            BcBand(200, 0.2),
            BcBand(300, 0.2),
            BcBand(400, 0.2),
            BcBand(500, 0.2),
            BcBand(600, 0.2),
          ],
        ),
        'bant BC’siz': () =>
            base(bc: null, model: null, bands: const [BcBand(500, 0.2)]),
        'bölge mesafesi 0': () =>
            base(zones: const WindZones(rangeM: 0, midMps: 1, farMps: 1)),
        'bölge rüzgârı 61': () =>
            base(zones: const WindZones(rangeM: 500, midMps: 61, farMps: 1)),
        'bölge rüzgârı −1': () =>
            base(zones: const WindZones(rangeM: 500, midMps: 1, farMps: -1)),
        'eğim 180.1°': () => base(incline: 180.1),
        'cant −180.1°': () => base(cant: -180.1),
        'sıcaklık 61 °C': () =>
            base(environment: const EnvironmentData(temperatureC: 61)),
        'basınç 299 hPa': () =>
            base(environment: const EnvironmentData(pressureHpa: 299)),
        'rüzgâr 60 m/s': () => base(environment: _wind(60, 90)),
        'rüzgâr yönü 360.1°': () => base(environment: _wind(1, 360.1)),
        'sıfır ortamı rüzgâr 60': () => base(zeroEnvironment: _wind(60, 90)),
        'sıfır ortamı nem 101': () =>
            base(zeroEnvironment: const EnvironmentData(humidityPercent: 101)),
        'sıfır ortamı yön −1': () => base(zeroEnvironment: _wind(1, -1)),
      };
      for (final entry in cases.entries) {
        expect(entry.value, throwsArgumentError, reason: entry.key);
      }
    });

    test('integrasyon adımı ve BC olmadan aerodinamik çözüm reddedilir', () {
      final input = _rifle(ranges: const [100]);
      for (final dt in [0.0, -0.001, 0.0101, double.nan, double.infinity]) {
        expect(
          () => AerodynamicTrajectorySolver(
            integrationStepSeconds: dt,
          ).solve(input),
          throwsArgumentError,
          reason: 'dt = $dt',
        );
      }
      final noBc = BallisticInput(
        muzzleVelocityMps: 850,
        grain: 175,
        zeroRangeM: 100,
        sightHeightMm: 50,
        rangesM: const [100],
      );
      expect(
        () => const AerodynamicTrajectorySolver().solve(noBc),
        throwsArgumentError,
      );
      // BC'siz istek vakum çözücüye gider (hız sabit).
      expect(_solve(noBc).single.velocityMps, 850);
    });
  });
}
