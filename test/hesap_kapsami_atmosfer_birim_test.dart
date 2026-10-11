// Hesap kapsamı: atmosfer, yerçekimi, birim dönüşümleri, rüzgâr saati,
// barut sıcaklığı ve DOPE mesafe girişi.
//
// Beklenen değerler yalnızca fizik formüllerinden / tanımlı sabitlerden
// türetilir (ideal gaz, γRT ses hızı, WGS-84 normal yerçekimi, uluslararası
// yard/pound tanımları). Hiçbir balistik programın çıktısı kullanılmaz.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/atmosphere.dart';
import 'package:sniper_turk/core/dope_ranges.dart';
import 'package:sniper_turk/core/gravity.dart';
import 'package:sniper_turk/core/powder_temperature.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/core/units.dart';
import 'package:sniper_turk/core/wind_clock.dart';
import 'package:sniper_turk/models/domain.dart';

// Kuru hava gaz sabiti (J/(kg·K)); Atmosphere ile aynı fiziksel sabit.
const _rDry = 287.05;

EnvironmentData _dry(double tC, double pHpa) =>
    EnvironmentData(temperatureC: tC, pressureHpa: pHpa, humidityPercent: 0);

void main() {
  group('Atmosfer — ideal gaz ve ses hızı özdeşlikleri', () {
    test('ICAO standardı: ρ = p/(R·T) ve c = √(γ·R·T)', () {
      final env = _dry(15, 1013.25);
      const tK = 288.15;
      expect(
        Atmosphere.densityKgM3(env),
        closeTo(101325 / (_rDry * tK), 1e-9),
      );
      expect(
        Atmosphere.speedOfSoundMps(env),
        closeTo(math.sqrt(1.4 * _rDry * tK), 1e-9),
      );
    });

    test('kuru havada ses hızı basınca bağlı değildir (c = √(γRT))', () {
      final low = Atmosphere.speedOfSoundMps(_dry(15, 300));
      final high = Atmosphere.speedOfSoundMps(_dry(15, 1100));
      expect(low, closeTo(high, 1e-9));
    });

    test('yoğunluk basınçla doğru, mutlak sıcaklıkla ters orantılı', () {
      final base = Atmosphere.densityKgM3(_dry(15, 1000));
      expect(
        Atmosphere.densityKgM3(_dry(15, 500)),
        closeTo(base / 2, 1e-12),
      );
      // 15 °C → 303.15 K: T oranı 288.15/303.15.
      expect(
        Atmosphere.densityKgM3(_dry(30, 1000)),
        closeTo(base * 288.15 / 303.15, 1e-12),
      );
      expect(
        Atmosphere.densityRatio(_dry(15, 506.625)),
        closeTo(101325 / 2 / (_rDry * 288.15) / 1.225, 1e-12),
      );
    });

    test('aşırı uçlar (−60 °C / 300 hPa, 60 °C / 1100 hPa) sonlu ve fiziksel',
        () {
      for (final env in [
        const EnvironmentData(
          temperatureC: -60,
          pressureHpa: 300,
          humidityPercent: 100,
        ),
        const EnvironmentData(
          temperatureC: 60,
          pressureHpa: 1100,
          humidityPercent: 100,
        ),
      ]) {
        final rho = Atmosphere.densityKgM3(env);
        final c = Atmosphere.speedOfSoundMps(env);
        expect(rho.isFinite && rho > 0, isTrue);
        expect(c.isFinite && c > 250 && c < 420, isTrue);
      }
      // Sıcak havada ses daha hızlıdır.
      expect(
        Atmosphere.speedOfSoundMps(_dry(60, 1013.25)),
        greaterThan(Atmosphere.speedOfSoundMps(_dry(-60, 1013.25))),
      );
    });

    test('Magnus doyma basıncı: 0 °C’de 6.112 hPa, sıcaklıkla artar', () {
      expect(Atmosphere.saturationVaporPressureHpa(0), closeTo(6.112, 1e-12));
      var previous = 0.0;
      for (var t = -40.0; t <= 60; t += 10) {
        final e = Atmosphere.saturationVaporPressureHpa(t);
        expect(e, greaterThan(previous));
        previous = e;
      }
      expect(
        () => Atmosphere.saturationVaporPressureHpa(double.nan),
        throwsArgumentError,
      );
      expect(
        () => Atmosphere.saturationVaporPressureHpa(double.infinity),
        throwsArgumentError,
      );
    });

    test('su buharı kısmi basıncı istasyon basıncını aşamaz', () {
      // 60 °C doyma basıncı ≈ 200 hPa > 150 hPa.
      expect(
        () => Atmosphere.densityKgM3(
          const EnvironmentData(
            temperatureC: 60,
            pressureHpa: 150,
            humidityPercent: 100,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('geçersiz nem, sıcaklık ve hız reddedilir', () {
      for (final h in [-0.1, 100.1, double.nan]) {
        expect(
          () => Atmosphere.densityKgM3(EnvironmentData(humidityPercent: h)),
          throwsArgumentError,
        );
      }
      expect(
        () => Atmosphere.densityKgM3(
          const EnvironmentData(temperatureC: double.nan),
        ),
        throwsArgumentError,
      );
      expect(
        () => Atmosphere.densityKgM3(
          const EnvironmentData(pressureHpa: double.infinity),
        ),
        throwsArgumentError,
      );
      for (final v in [-1.0, double.nan, double.infinity]) {
        expect(
          () => Atmosphere.machNumber(
            velocityMps: v,
            environment: const EnvironmentData(),
          ),
          throwsArgumentError,
        );
      }
    });

    test('Mach = v / c; 0 m/s Mach 0, ses hızında Mach 1', () {
      final env = _dry(15, 1013.25);
      final c = Atmosphere.speedOfSoundMps(env);
      expect(
        Atmosphere.machNumber(velocityMps: 0, environment: env),
        0,
      );
      expect(
        Atmosphere.machNumber(velocityMps: c, environment: env),
        closeTo(1, 1e-12),
      );
    });
  });

  group('Yerel yerçekimi — WGS-84 normal yerçekimi', () {
    test('ekvator ve kutup değerleri WGS-84 tanımıyla aynı', () {
      expect(Gravity.at(latitudeDeg: 0), closeTo(9.7803253359, 1e-9));
      expect(Gravity.at(latitudeDeg: 90), closeTo(9.8321849379, 1e-9));
      expect(Gravity.at(latitudeDeg: -90), closeTo(9.8321849379, 1e-9));
    });

    test('kuzey/güney simetrik ve enlemle artar', () {
      var previous = 0.0;
      for (var lat = 0.0; lat <= 90; lat += 15) {
        final g = Gravity.at(latitudeDeg: lat);
        expect(Gravity.at(latitudeDeg: -lat), closeTo(g, 1e-12));
        expect(g, greaterThan(previous));
        previous = g;
      }
    });

    test('serbest hava düzeltmesi ≈ 0.3086 mGal/m (1000 m’de ≈ 3.08 mm/s²)',
        () {
      final sea = Gravity.at(latitudeDeg: 45);
      final high = Gravity.at(latitudeDeg: 45, altitudeM: 1000);
      expect(sea - high, closeTo(3.086e-3, 2e-5));
      // Türkiye bandı 36–42° K: 9.79–9.81 m/s².
      for (final lat in [36.0, 39.0, 42.0]) {
        final g = Gravity.at(latitudeDeg: lat);
        expect(g, inInclusiveRange(9.79, 9.81));
      }
    });
  });

  group('Birim dönüşümleri — tanımlar ve gidiş-dönüş', () {
    test('1 MOA = π/10.8 mrad; 60 MOA = 1° = π/180 rad', () {
      expect(Units.moaToMrad(1), closeTo(math.pi / 10.8, 1e-15));
      expect(Units.moaToMrad(60), closeTo(math.pi / 180 * 1000, 1e-12));
      expect(Units.mradToMoa(1000 * math.pi / 180), closeTo(60, 1e-12));
      for (final v in [0.0, 0.1, 1.0, 12.5, -7.3, 300.0]) {
        expect(Units.mradToMoa(Units.moaToMrad(v)), closeTo(v, 1e-12));
      }
    });

    test('7000 grain = 1 lb = 0.45359237 kg', () {
      expect(Units.grainToKg(7000), closeTo(0.45359237, 1e-12));
      expect(Units.grainToKg(0), 0);
    });

    test('SMOA = 1 inç / 100 yd; MOA = π/10.8 mrad', () {
      expect(AngularUnit.smoa.toMrad(1), closeTo(25.4 / 91440 * 1000, 1e-15));
      expect(AngularUnit.moa.toMrad(1), closeTo(math.pi / 10.8, 1e-15));
      expect(AngularUnit.mrad.toMrad(1), 1);
    });

    test('açı birimleri arasında her yönde gidiş-dönüş', () {
      const units = AngularUnit.values;
      for (final a in units) {
        for (final b in units) {
          for (final v in [0.0, 0.25, 1.0, -3.7, 40.0]) {
            final there = ScopeDialMath.convert(v, a, b);
            expect(ScopeDialMath.convert(there, b, a), closeTo(v, 1e-12));
          }
        }
      }
      // 1 mrad = 3.6 SMOA (tanım: 1/3600 rad başına SMOA).
      expect(
        ScopeDialMath.convert(1, AngularUnit.mrad, AngularUnit.smoa),
        closeTo(3.6, 1e-12),
      );
    });

    test('UnitSystem gidiş-dönüşleri', () {
      const values = [0.0, 1.0, 12.345, 1000.0, -40.0];
      final pairs = <(double Function(double), double Function(double))>[
        (UnitSystem.yardsToMeters, UnitSystem.metersToYards),
        (UnitSystem.feetToMeters, UnitSystem.metersToFeet),
        (UnitSystem.fpsToMps, UnitSystem.mpsToFps),
        (UnitSystem.inchesToMillimeters, UnitSystem.millimetersToInches),
        (UnitSystem.inHgToHpa, UnitSystem.hpaToInHg),
        (UnitSystem.mphToMps, UnitSystem.mpsToMph),
        (UnitSystem.fahrenheitToCelsius, UnitSystem.celsiusToFahrenheit),
      ];
      for (final (to, back) in pairs) {
        for (final v in values) {
          expect(back(to(v)), closeTo(v, 1e-9));
        }
      }
    });

    test('UnitSystem tanım değerleri', () {
      expect(UnitSystem.yardsToMeters(100), closeTo(91.44, 1e-12));
      expect(UnitSystem.feetToMeters(3), closeTo(0.9144, 1e-12));
      expect(UnitSystem.fahrenheitToCelsius(32), closeTo(0, 1e-12));
      expect(UnitSystem.fahrenheitToCelsius(212), closeTo(100, 1e-12));
      expect(UnitSystem.celsiusToFahrenheit(-40), closeTo(-40, 1e-12));
      // 1 mil/saat = 1609.344 m / 3600 s.
      expect(UnitSystem.mphToMps(1), closeTo(1609.344 / 3600, 1e-12));
      // 1 knot = 1852 m / 3600 s; 1 km/sa = 1/3.6 m/s.
      expect(
        UnitSystem.metersPerSecondPerKnot,
        closeTo(1852 / 3600, 1e-12),
      );
      expect(UnitSystem.mpsToKmh(10), closeTo(36, 1e-12));
      // 1 ft·lbf = 0.3048 m × 4.4482216152605 N.
      expect(
        UnitSystem.joulesToFootPounds(0.3048 * 4.4482216152605),
        closeTo(1, 1e-12),
      );
      // 1 inHg (0 °C) = 25.4 mm × 13595.1 kg/m³ × 9.80665 m/s² ≈ 3386.39 Pa.
      expect(UnitSystem.inHgToHpa(1), closeTo(33.8639, 1e-3));
    });
  });

  group('Rüzgâr saati', () {
    test('her saat derece üzerinden kendine döner', () {
      for (var h = 1; h <= 12; h++) {
        expect(WindClock.fromDegrees(WindClock.toDegrees(h)), h);
      }
    });

    test('ana yönler: 12 karşı, 3 sağ, 6 arka, 9 sol', () {
      expect(WindClock.toDegrees(12), 0);
      expect(WindClock.toDegrees(9), 90);
      expect(WindClock.toDegrees(6), 180);
      expect(WindClock.toDegrees(3), 270);
    });

    test('360° ve negatif dereceler saate sarılır', () {
      expect(WindClock.fromDegrees(360), 12);
      expect(WindClock.fromDegrees(720), 12);
      expect(WindClock.fromDegrees(-90), 3);
      expect(WindClock.fromDegrees(-270), 9);
    });

    test('geçersiz saat reddedilir', () {
      for (final h in [0, 13, -1]) {
        expect(() => WindClock.toDegrees(h), throwsArgumentError);
      }
    });

    test('yön metinleri tüm saatleri kapsar', () {
      expect(WindClock.side(12), 'karşıdan');
      expect(WindClock.side(3), 'sağdan');
      expect(WindClock.side(6), 'arkadan');
      expect(WindClock.side(9), 'soldan');
      expect(WindClock.side(1), 'sağ önden');
      expect(WindClock.side(5), 'sağ arkadan');
      expect(WindClock.side(7), 'sol arkadan');
      expect(WindClock.side(11), 'sol önden');
    });
  });

  group('Barut sıcaklığı — v = v0·(1 + k/100·ΔT/15)', () {
    test('referans sıcaklıkta katsayı 1', () {
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 1.5,
          referenceTempC: 21,
          todayTempC: 21,
        ),
        1,
      );
    });

    test('ΔT = ±15 °C tam olarak ±k %', () {
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 2,
          referenceTempC: 15,
          todayTempC: 30,
        ),
        closeTo(1.02, 1e-12),
      );
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 2,
          referenceTempC: 15,
          todayTempC: 0,
        ),
        closeTo(0.98, 1e-12),
      );
    });

    test('bant sınırları: |k| = 10 ve T0 = −50/60 kabul, dışı 1', () {
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 10,
          referenceTempC: 60,
          todayTempC: 45,
        ),
        closeTo(0.9, 1e-12),
      );
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: -10,
          referenceTempC: -50,
          todayTempC: -35,
        ),
        closeTo(0.9, 1e-12),
      );
      for (final (k, t0) in [(10.01, 15.0), (1.0, 60.01), (1.0, -50.01)]) {
        expect(
          PowderTemperature.factor(
            coefPercentPer15C: k,
            referenceTempC: t0,
            todayTempC: 0,
          ),
          1,
        );
      }
    });

    test('eksik veya sonsuz değerlerde katsayı 1', () {
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: null,
          referenceTempC: 15,
          todayTempC: 30,
        ),
        1,
      );
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 1,
          referenceTempC: null,
          todayTempC: 30,
        ),
        1,
      );
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 1,
          referenceTempC: 15,
          todayTempC: double.nan,
        ),
        1,
      );
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: double.infinity,
          referenceTempC: 15,
          todayTempC: 30,
        ),
        1,
      );
    });

    test('fiziksel olmayan (≤ 0) hız katsayısı 1’e düşer', () {
      // 1 + 10/100 · (−100 − 60)/15 = −0.067 → kullanılmaz.
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 10,
          referenceTempC: 60,
          todayTempC: -100,
        ),
        1,
      );
    });
  });

  group('DOPE mesafe girişi', () {
    test('ayırıcılar, tekrar ve sıralama', () {
      expect(DopeRanges.parse('300, 100;200  100\t50'), [50, 100, 200, 300]);
    });

    test('0 m, negatif, sınır üstü ve sayı olmayan reddedilir', () {
      for (final bad in ['0', '-10', '3000.1', 'abc', 'NaN', 'Infinity']) {
        expect(() => DopeRanges.parse(bad), throwsFormatException);
      }
      expect(() => DopeRanges.parse(' ,; '), throwsFormatException);
    });

    test('tam sınır (3000 m) ve özel üst sınır', () {
      expect(DopeRanges.parse('3000'), [3000]);
      expect(() => DopeRanges.parse('600', maxRangeM: 500),
          throwsFormatException);
    });
  });
}
