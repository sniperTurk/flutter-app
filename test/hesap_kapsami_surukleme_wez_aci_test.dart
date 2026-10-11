// Hesap kapsamı: sürüklenme tablosu ve G-fonksiyonu yavaşlaması, WEZ /
// isabet olasılığı, dürbün kulesi/retikül açı hesapları, eğim ve cant
// (telefon ivmeölçeri) hesapları.
//
// Beklenen değerler: a = ½·ρ·Cd·(π/4)·v²/BC_SI, 1 lb/in² = 0.45359237 kg /
// 0.0254² m², Rayleigh dağılımı P(r ≤ R) = 1 − exp(−R²/2σ²), olasılık
// 1 − (1 − p)^n, trigonometrik özdeşlikler. Balistik program çıktısı
// kullanılmaz.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/atmosphere.dart';
import 'package:sniper_turk/core/drag_table.dart';
import 'package:sniper_turk/core/reference_drag_model.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/core/standard_drag_tables.dart';
import 'package:sniper_turk/core/wez.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/hit_probability.dart';
import 'package:sniper_turk/tools/domain/shot_angle_math.dart';
import 'package:sniper_turk/tools/domain/tilt_math.dart';
import 'package:sniper_turk/tools/ports/tilt_provider.dart';

const _dryStandard = EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 0,
);

double _rayleigh(double r, double sigma) =>
    1 - math.exp(-(r * r) / (2 * sigma * sigma));

void main() {
  group('Sürüklenme tablosu (Cd–Mach) ara değerleme', () {
    final table = DragTable(const [
      DragSample(0.5, 0.2),
      DragSample(1.0, 0.4),
      DragSample(2.0, 0.3),
    ]);

    test('tablo dışı uçlar sabit tutulur, düğümler aynen döner', () {
      expect(table.coefficientAtMach(0), 0.2);
      expect(table.coefficientAtMach(0.5), 0.2);
      expect(table.coefficientAtMach(1.0), 0.4);
      expect(table.coefficientAtMach(2.0), 0.3);
      expect(table.coefficientAtMach(9.0), 0.3);
    });

    test('düğümler arası doğrusal', () {
      expect(table.coefficientAtMach(0.75), closeTo(0.3, 1e-12));
      expect(table.coefficientAtMach(1.5), closeTo(0.35, 1e-12));
      // G1 tablosu: Mach 1.0 → 0.4805, 1.025 → 0.5136 (BRL tablosu).
      expect(
        StandardDragTables.g1.coefficientAtMach(1.0125),
        closeTo((0.4805 + 0.5136) / 2, 1e-12),
      );
    });

    test('geçersiz Mach reddedilir', () {
      for (final m in [-0.01, double.nan, double.infinity]) {
        expect(() => table.coefficientAtMach(m), throwsArgumentError);
      }
    });

    test('geçersiz tablolar reddedilir', () {
      final bad = <List<DragSample>>[
        const [DragSample(0, 0.2)],
        const [DragSample(0, 0.2), DragSample(0, 0.3)],
        const [DragSample(1, 0.2), DragSample(0.5, 0.3)],
        const [DragSample(-0.1, 0.2), DragSample(1, 0.3)],
        const [DragSample(0, 0), DragSample(1, 0.3)],
        const [DragSample(0, 0.2), DragSample(double.nan, 0.3)],
        const [DragSample(0, 0.2), DragSample(1, double.infinity)],
      ];
      for (final samples in bad) {
        expect(() => DragTable(samples), throwsArgumentError);
      }
    });
  });

  group('G-fonksiyonu yavaşlaması a = ½ρ·Cd·(π/4)·v²/BC_SI', () {
    // Cd sabit tablo: hız ölçeklemesi yalnız v²'den gelir.
    final model = ReferenceDragModel(
      DragTable(const [DragSample(0, 0.5), DragSample(10, 0.5)]),
    );

    test('1 lb/in² = 0.45359237 kg / 0.0254² m²', () {
      expect(
        ReferenceDragModel.ballisticCoefficientKgPerM2(1),
        closeTo(0.45359237 / (0.0254 * 0.0254), 1e-9),
      );
    });

    test('formülün kendisi', () {
      final rho = Atmosphere.densityKgM3(_dryStandard);
      const v = 300.0, bc = 0.25;
      final expected =
          0.5 * rho * 0.5 * (math.pi / 4) * v * v /
          (bc * 0.45359237 / (0.0254 * 0.0254));
      expect(
        model.decelerationMps2(
          speedMps: v,
          ballisticCoefficient: bc,
          environment: _dryStandard,
        ),
        closeTo(expected, 1e-9),
      );
    });

    test('BC yarıya inince yavaşlama iki katı, hız iki katında dört katı', () {
      double a(double v, double bc) => model.decelerationMps2(
        speedMps: v,
        ballisticCoefficient: bc,
        environment: _dryStandard,
      );
      expect(a(300, 0.1), closeTo(2 * a(300, 0.2), 1e-9));
      expect(a(400, 0.2), closeTo(4 * a(200, 0.2), 1e-9));
    });

    test('yoğunluk yarıya inince yavaşlama yarıya iner', () {
      const half = EnvironmentData(
        temperatureC: 15,
        pressureHpa: 1013.25 / 2,
        humidityPercent: 0,
      );
      final full = model.decelerationMps2(
        speedMps: 250,
        ballisticCoefficient: 0.3,
        environment: _dryStandard,
      );
      final thin = model.decelerationMps2(
        speedMps: 250,
        ballisticCoefficient: 0.3,
        environment: half,
      );
      expect(thin, closeTo(full / 2, 1e-9));
    });

    test('0 m/s: yavaşlama 0; geçersiz hız ve BC reddedilir', () {
      expect(
        model.decelerationMps2(
          speedMps: 0,
          ballisticCoefficient: 0.2,
          environment: _dryStandard,
        ),
        0,
      );
      for (final v in [-1.0, double.nan, double.infinity]) {
        expect(
          () => model.decelerationMps2(
            speedMps: v,
            ballisticCoefficient: 0.2,
            environment: _dryStandard,
          ),
          throwsArgumentError,
        );
      }
      for (final bc in [0.0, -0.1, double.nan]) {
        expect(
          () => model.decelerationMps2(
            speedMps: 0,
            ballisticCoefficient: bc,
            environment: _dryStandard,
          ),
          throwsArgumentError,
        );
      }
    });

    test('G7 ses duvarında Cd sıçrar: Mach 0.9 → 1.05 arası artış', () {
      final g7 = StandardDragTables.g7;
      expect(g7.coefficientAtMach(1.05), greaterThan(g7.coefficientAtMach(0.9)));
      expect(g7.coefficientAtMach(0.5), closeTo(0.1194, 1e-12));
    });
  });

  group('WEZ — en az bir isabet 1 − (1 − p)^n', () {
    test('özdeşlikler', () {
      expect(Wez.atLeastOneHit(0, 10), 0);
      expect(Wez.atLeastOneHit(1, 3), 1);
      expect(Wez.atLeastOneHit(0.37, 1), closeTo(0.37, 1e-12));
      expect(Wez.atLeastOneHit(0.5, 3), closeTo(0.875, 1e-12));
    });

    test('olasılık [0, 1]’e kırpılır; NaN = 0; atış sayısı ≥ 1', () {
      expect(Wez.atLeastOneHit(1.5, 2), 1);
      expect(Wez.atLeastOneHit(-0.2, 2), 0);
      expect(Wez.atLeastOneHit(double.nan, 5), 0);
      expect(() => Wez.atLeastOneHit(0.5, 0), throwsArgumentError);
    });
  });

  group('WEZ benzetimi — Rayleigh dağılımı', () {
    test('kaynak yoksa her atış merkezde: olasılık 1, baskın kaynak yok', () {
      final r = Wez.simulate(sources: const [], targetRadiusMrad: 0.1);
      expect(r.probability, 1);
      expect(r.dominant, isNull);
      expect(r.impacts.length, Wez.shots);
    });

    test('dairesel Gauss: P(R = σ) = 1 − e^(−½), P(R = 2σ) = 1 − e^(−2)', () {
      const s = [WezSource('tek', sigmaX: 1, sigmaY: 1)];
      final one = Wez.simulate(sources: s, targetRadiusMrad: 1, count: 4000);
      final two = Wez.simulate(sources: s, targetRadiusMrad: 2, count: 4000);
      expect(one.probability, closeTo(_rayleigh(1, 1), 0.03));
      expect(two.probability, closeTo(_rayleigh(2, 1), 0.02));
    });

    test('bağımsız kaynaklar karelerin toplamıyla birleşir (0.6² + 0.8² = 1²)',
        () {
      const sources = [
        WezSource('rüzgâr', sigmaX: 0.6, sigmaY: 0.6),
        WezSource('hız', sigmaX: 0.8, sigmaY: 0.8),
      ];
      final r = Wez.simulate(
        sources: sources,
        targetRadiusMrad: 1,
        count: 4000,
      );
      expect(r.probability, closeTo(_rayleigh(1, 1), 0.03));
      expect(r.dominant?.name, 'hız');
    });

    test('hedef yarıçapı 0 ise isabet 0; aynı tohum aynı sonuç', () {
      const s = [WezSource('a', sigmaX: 0.5)];
      expect(
        Wez.simulate(sources: s, targetRadiusMrad: 0).probability,
        0,
      );
      final a = Wez.simulate(sources: s, targetRadiusMrad: 0.4, seed: 3);
      final b = Wez.simulate(sources: s, targetRadiusMrad: 0.4, seed: 3);
      expect(a.probability, b.probability);
      expect(a.impacts.first, b.impacts.first);
    });

    test('grup boyutu → σ ve ± değeri → σ', () {
      // 5 atış ES = 3.067σ: 1000 m'de 30.67 cm grup ≈ 0.1 mrad σ.
      expect(
        Wez.groupSigmaMrad(0.3067, 1000),
        closeTo(math.atan(0.3067 / 1000) * 1000 / 3.067, 1e-12),
      );
      expect(Wez.groupSigmaMrad(0.3067, 1000), closeTo(0.1, 1e-6));
      expect(Wez.sigmaOfPlusMinus(2), 1);
    });
  });

  group('İsabet olasılığı (kapalı form)', () {
    test('hedef yarıçapı = σ → 1 − e^(−½)', () {
      // 3.067 MOA 5'li grup → σ = 1 MOA; 100 m'de σ = 100·tan… ≈ π/10.8 · 0.1 m.
      final sigma = HitProbabilityEngine.sigmaM(
        groupDiameterMoa: 3.067,
        rangeM: 100,
      );
      expect(sigma, closeTo(math.pi / 10.8 / 1000 * 100, 1e-12));
      final p = HitProbabilityEngine.probabilityOfHit(
        groupDiameterMoa: 3.067,
        targetDiameterCm: sigma * 2 * 100,
        rangeM: 100,
      );
      expect(p, closeTo(_rayleigh(1, 1), 1e-12));
    });

    test('olasılıktan menzil ve geri: aynı olasılığı verir', () {
      final r = HitProbabilityEngine.maxRangeForProbability(
        groupDiameterMoa: 1,
        targetDiameterCm: 20,
        probability: 0.9,
      )!;
      final p = HitProbabilityEngine.probabilityOfHit(
        groupDiameterMoa: 1,
        targetDiameterCm: 20,
        rangeM: r,
      );
      expect(p, closeTo(0.9, 1e-9));
    });

    test('N = 2 için ES/σ = √π; desteklenmeyen atış sayıları reddedilir', () {
      expect(
        HitProbabilityEngine.extremeSpreadFactor(2),
        closeTo(math.sqrt(math.pi), 1e-3),
      );
      for (final n in [1, 11]) {
        expect(
          () => HitProbabilityEngine.extremeSpreadFactor(n),
          throwsArgumentError,
        );
      }
    });

    test('geçersiz girişler', () {
      expect(
        () => HitProbabilityEngine.probabilityOfHit(
          groupDiameterMoa: 1,
          targetDiameterCm: 10,
          rangeM: 0,
        ),
        throwsArgumentError,
      );
      for (final p in [0.0, 1.0, -0.1]) {
        expect(
          HitProbabilityEngine.maxRangeForProbability(
            groupDiameterMoa: 1,
            targetDiameterCm: 10,
            probability: p,
          ),
          isNull,
        );
      }
      expect(
        HitProbabilityEngine.maxRangeForProbability(
          groupDiameterMoa: 0,
          targetDiameterCm: 10,
          probability: 0.5,
        ),
        isNull,
      );
    });
  });

  group('Dürbün kulesi ve retikül açıları', () {
    test('tık hesabı: yuvarlama ve geçersiz tık değeri', () {
      expect(ScopeDialMath.clicksFor(1.04, 0.1), 10);
      expect(ScopeDialMath.clicksFor(-1.06, 0.1), -11);
      expect(ScopeDialMath.clicksToAngle(-7, 0.25), -1.75);
      for (final c in [0.0, -0.1, double.nan]) {
        expect(() => ScopeDialMath.clicksFor(1, c), throwsArgumentError);
      }
      expect(
        () => ScopeDialMath.clicksFor(double.infinity, 0.1),
        throwsArgumentError,
      );
    });

    test('eğimli kaide: 20 MOA = 58 tık (0.1 mrad), 60 MOA = 240 tık (¼ MOA)',
        () {
      // 20 MOA = 20·π/10.8 = 5.818 mrad → 58 tam tık (aşağı yuvarlanır).
      expect(
        ScopeDialMath.mountCantClicks(20, 0.1, AngularUnit.mrad),
        (20 * math.pi / 10.8 / 0.1).floor(),
      );
      expect(ScopeDialMath.mountCantClicks(60, 0.25, AngularUnit.moa), 240);
      expect(ScopeDialMath.mountCantClicks(0, 0.1, AngularUnit.mrad), 0);
      expect(
        () => ScopeDialMath.mountCantClicks(-1, 0.1, AngularUnit.mrad),
        throwsArgumentError,
      );
    });

    test('açı ↔ boyut gidiş-dönüş; 10 cm @ 50 m = 2 mrad', () {
      expect(
        ScopeDialMath.angleAtRange(0.1, 50, AngularUnit.mrad),
        closeTo(math.atan(0.002) * 1000, 1e-12),
      );
      for (final unit in AngularUnit.values) {
        final size = ScopeDialMath.linearAtRange(3, 400, unit);
        expect(
          ScopeDialMath.angleAtRange(size, 400, unit),
          closeTo(3, 1e-9),
        );
      }
      expect(
        () => ScopeDialMath.angleAtRange(0.1, 0, AngularUnit.mrad),
        throwsArgumentError,
      );
    });

    test('SFP retikül: kalibrasyon/büyütme; FFP her büyütmede 1', () {
      expect(
        ScopeDialMath.reticleSubtension(
          firstFocalPlane: true,
          magnification: 5,
          calibrationMagnification: 10,
        ),
        1,
      );
      expect(
        ScopeDialMath.reticleSubtension(
          firstFocalPlane: false,
          magnification: 5,
          calibrationMagnification: 10,
        ),
        2,
      );
      expect(
        () => ScopeDialMath.reticleSubtension(
          firstFocalPlane: false,
          magnification: 0,
          calibrationMagnification: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => ScopeDialMath.reticleSubtension(
          firstFocalPlane: false,
          magnification: 5,
          calibrationMagnification: double.nan,
        ),
        throwsArgumentError,
      );
      expect(
        ScopeDialMath.visibleHalfField(
          halfFieldAtReference: 20,
          magnification: 10,
          referenceMagnification: 5,
        ),
        10,
      );
    });

    test('tutma işaretleri: doğrusal ara değer, sırasız örnek reddedilir', () {
      const samples = [
        CorrectionSample(100, 0),
        CorrectionSample(200, 1),
        CorrectionSample(300, 3),
      ];
      final marks = ScopeDialMath.holdovers(
        dialedUp: 0,
        markAngles: const [2, 5],
        samples: samples,
      );
      expect(marks.single.markAngle, 2);
      expect(marks.single.rangeM, closeTo(250, 1e-12));
      expect(
        ScopeDialMath.holdovers(
          dialedUp: 0,
          markAngles: const [1],
          samples: const [CorrectionSample(100, 0)],
        ),
        isEmpty,
      );
      expect(
        () => ScopeDialMath.holdovers(
          dialedUp: 0,
          markAngles: const [1],
          samples: const [CorrectionSample(200, 0), CorrectionSample(100, 2)],
        ),
        throwsArgumentError,
      );
    });
  });

  group('Atış eğimi ve cant — telefon ivmeölçeri', () {
    const g = 9.80665;
    double rad(double d) => d * math.pi / 180;

    test('dik tutuş 0°, ekran yukarı yatık −90°, ekran aşağı +90°', () {
      expect(ShotAngleMath.inclineDeg(const GravityVector(0, g, 0)), 0);
      expect(
        ShotAngleMath.inclineDeg(const GravityVector(0, 0, g)),
        closeTo(-90, 1e-12),
      );
      expect(
        ShotAngleMath.inclineDeg(const GravityVector(0, 0, -g)),
        closeTo(90, 1e-12),
      );
    });

    test('eğim yanal dönmeden bağımsızdır', () {
      for (final roll in [0.0, 15.0, -40.0]) {
        final inPlane = g * math.cos(rad(30));
        final v = GravityVector(
          inPlane * math.sin(rad(roll)),
          inPlane * math.cos(rad(roll)),
          -g * math.sin(rad(30)),
        );
        expect(ShotAngleMath.inclineDeg(v), closeTo(30, 1e-9));
      }
    });

    test('ters tutuşta ±90° ötesi; zayıf vektör null', () {
      final v = GravityVector(0, -g * math.cos(rad(30)), -g * math.sin(rad(30)));
      expect(ShotAngleMath.inclineDeg(v), closeTo(150, 1e-9));
      expect(ShotAngleMath.inclineDeg(const GravityVector(0, 1, 1)), isNull);
      expect(ShotAngleMath.cantDeg(const GravityVector(0, 0, g)), isNull);
    });

    test('cant: saat yönü (üst sağa) pozitif', () {
      final v = GravityVector(-g * math.sin(rad(10)), g * math.cos(rad(10)), 0);
      expect(ShotAngleMath.cantDeg(v), closeTo(10, 1e-9));
      final w = GravityVector(g * math.sin(rad(10)), g * math.cos(rad(10)), 0);
      expect(ShotAngleMath.cantDeg(w), closeTo(-10, 1e-9));
    });

    test('sıfır ofseti −180…180 aralığında sarılır', () {
      expect(ShotAngleMath.relative(170, -20), closeTo(-170, 1e-12));
      expect(ShotAngleMath.relative(-170, 20), closeTo(170, 1e-12));
      expect(ShotAngleMath.relative(10, 10), 0);
      expect(ShotAngleMath.relative(540, 0), closeTo(180, 1e-12));
    });

    test('saat gösterimi', () {
      expect(ShotAngleMath.clock(0), '0:00');
      expect(ShotAngleMath.clock(90), '3:00');
      expect(ShotAngleMath.clock(-30), '11:00');
      expect(ShotAngleMath.clock(360), '0:00');
      expect(ShotAngleMath.clock(15), '0:30');
      expect(ShotAngleMath.degrees(-0.4), '0°');
      expect(ShotAngleMath.degrees(-7.6), '−8°');
      expect(ShotAngleMath.degrees(12.4), '12°');
    });

    test('su terazisi: % eğim = tan θ·100, çatı eğimi = tan θ·12', () {
      expect(TiltMath.percentGrade(45), closeTo(100, 1e-9));
      expect(TiltMath.roofPitchPer12(45), closeTo(12, 1e-9));
      expect(TiltMath.percentGrade(89.9), isNull);
      expect(TiltMath.roofPitchPer12(-89.9), isNull);
      expect(TiltMath.percentText(-0.01), '0,0%');
      expect(TiltMath.roofPitchText(-45), '-12/12');
      expect(TiltMath.roofPitchText(90), '—');
      final flat = TiltMath.angles(
        GravityVector(g * math.sin(rad(3)), 0, g * math.cos(rad(3))),
        TiltMode.flat,
      )!;
      expect(flat.xDeg, closeTo(3, 1e-9));
      expect(flat.yDeg, closeTo(0, 1e-12));
      expect(TiltMath.angles(const GravityVector(0, 0, 1), TiltMode.flat),
          isNull);
    });
  });
}
