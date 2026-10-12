// Üretici tablosu doğrulaması: çözücünün (BallisticEngine → G1/G7 RK4)
// sonuçları, üreticilerin KENDİ sitelerinde yayımladığı balistik tablolarla
// karşılaştırılır. Kaynaklar, tablo koşulları ve fark tabloları:
// docs/hesap-dogrulama/RAPOR.md. Hiçbir balistik programın (ChairGun,
// Strelok, Applied Ballistics, QuickLOAD, GRT, JBM) çıktısı kullanılmaz.
//
// Koşullar (tablodan aynen): namlu hızı, BC (üreticinin verdiği değer, tek
// BC), nişan yüksekliği, sıfır mesafesi, yan rüzgâr (Federal 10 mph,
// Lapua 4 m/s; tam yan, soldan). Üreticiler atmosferi yazmıyor (Berger yalnız
// "deniz seviyesi"); ICAO standart (15 °C, 1013,25 hPa, %0 nem) kullanılır.
//
// Toleranslar (açısal, çünkü dürbüne girilen düzeltme açıdır):
//   ≤ 600 m      : yörünge 0,10 mrad (≈ 1 klik), hız %1,5, sürüklenme 0,15 mrad
//   600–1000 m   : yörünge 0,20 mrad, hız %3, sürüklenme 0,30 mrad
// Gerekçe: yayımlanan değerler 0,1 inç / 1 mm / 1 fps'e yuvarlanmış; üretici
// atmosferi yazmıyor; üreticiler (özellikle Lapua) kendi Doppler sürüklenme
// eğrisini kullanırken uygulama standart G1/G7 eğrisiyle çalışıyor ve bu fark
// ses hızına yaklaştıkça büyür. 1000 m ötesi (ses geçişi) ve Lapua 338 300 gr
// tablosunun kendi içinde tutarsız "600 m sıfır" satırı teste alınmaz; o
// farklar raporda gösterilir.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/models/domain.dart';

const _yard = 0.9144;
const _fps = 0.3048;
const _inch = 0.0254;

class _Row {
  final double range;

  /// Yayımlanan hız (fps veya m/s); null = tabloda yok.
  final double? velocity;

  /// Nişan hattına göre yörünge, üreticinin işaretiyle (+ yukarı).
  final double path;
  const _Row(this.range, this.velocity, this.path);
}

class _Zero {
  final double zero;
  final List<_Row> rows;
  const _Zero(this.zero, this.rows);
}

class _Case {
  final String id, name;

  /// true: yd / fps / inç; false: m / m/s / mm.
  final bool yards;
  final double muzzleVelocity, grain, sightHeight, bc;
  final BallisticModel model;
  final double? windMps;
  final List<(double, double)> drift;
  final List<_Zero> zeros;
  const _Case({
    required this.id,
    required this.name,
    required this.yards,
    required this.muzzleVelocity,
    required this.grain,
    required this.sightHeight,
    required this.model,
    required this.bc,
    required this.zeros,
    this.windMps,
    this.drift = const [],
  });

  double rangeM(double r) => yards ? r * _yard : r;
  double speedMps(double v) => yards ? v * _fps : v;
  double lengthM(double l) => yards ? l * _inch : l / 1000;
  double get sightMm => yards ? sightHeight * 25.4 : sightHeight;
}

const _icao = EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 0,
  altitudeM: 0,
  windMps: 0,
  windDirectionDeg: 90,
);

List<TrajectoryPoint> _solve(
  _Case c,
  double zero,
  List<double> ranges, {
  double windMps = 0,
}) => const BallisticEngine().solve(
  BallisticInput(
    muzzleVelocityMps: c.speedMps(c.muzzleVelocity),
    grain: c.grain,
    zeroRangeM: c.rangeM(zero),
    sightHeightMm: c.sightMm,
    rangesM: ranges.map(c.rangeM),
    environment: EnvironmentData(
      temperatureC: 15,
      pressureHpa: 1013.25,
      humidityPercent: 0,
      altitudeM: 0,
      windMps: windMps,
      // 90° = saat 9, soldan tam yan rüzgâr.
      windDirectionDeg: 90,
    ),
    zeroEnvironment: _icao,
    ballisticCoefficient: c.bc,
    ballisticModel: c.model,
  ),
);

double _pathTolMrad(double rangeM) => rangeM <= 600.5 ? 0.10 : 0.20;
double _speedTolFraction(double rangeM) => rangeM <= 600.5 ? 0.015 : 0.03;
double _driftTolMrad(double rangeM) => rangeM <= 600.5 ? 0.15 : 0.30;

void main() {
  test('veri seti: en az 15 fişek, 4 üretici, hepsi 1000 m içinde', () {
    expect(_cases.length, greaterThanOrEqualTo(15));
    expect(
      _cases.map((c) => c.name.split(' ').first).toSet().length,
      greaterThanOrEqualTo(4),
    );
    for (final c in _cases) {
      for (final z in c.zeros) {
        for (final r in z.rows) {
          expect(c.rangeM(r.range), lessThanOrEqualTo(1000.0001), reason: c.id);
        }
      }
    }
  });

  for (final c in _cases) {
    group('${c.id} ${c.name}', () {
      for (final z in c.zeros) {
        test('yörünge ve hız, ${z.zero.toStringAsFixed(0)} '
            '${c.yards ? 'yd' : 'm'} sıfır', () {
          final points = _solve(c, z.zero, [for (final r in z.rows) r.range]);
          for (var i = 0; i < z.rows.length; i++) {
            final row = z.rows[i];
            final p = points[i];
            final rangeM = c.rangeM(row.range);
            // Çözücü: dropM = nişan hattının altı (+). Üretici: + yukarı.
            final diffMrad =
                (-p.dropM - c.lengthM(row.path)) / rangeM * 1000;
            expect(
              diffMrad.abs(),
              lessThanOrEqualTo(_pathTolMrad(rangeM)),
              reason:
                  '${c.id} ${row.range} ${c.yards ? 'yd' : 'm'}: yörünge '
                  'farkı ${diffMrad.toStringAsFixed(3)} mrad',
            );
            final v = row.velocity;
            if (v != null) {
              final published = c.speedMps(v);
              final rel = (p.velocityMps - published) / published;
              expect(
                rel.abs(),
                lessThanOrEqualTo(_speedTolFraction(rangeM)),
                reason:
                    '${c.id} ${row.range}: hız farkı '
                    '${(rel * 100).toStringAsFixed(2)} %',
              );
            }
          }
        });
      }
      if (c.windMps != null && c.drift.isNotEmpty) {
        test('yan rüzgâr sürüklenmesi', () {
          final points = _solve(
            c,
            c.zeros.first.zero,
            [for (final d in c.drift) d.$1],
            windMps: c.windMps!,
          );
          for (var i = 0; i < c.drift.length; i++) {
            final (range, published) = c.drift[i];
            final rangeM = c.rangeM(range);
            final calcM = math.tan(points[i].windMrad.abs() / 1000) * rangeM;
            final diffMrad = (calcM - c.lengthM(published)) / rangeM * 1000;
            expect(
              diffMrad.abs(),
              lessThanOrEqualTo(_driftTolMrad(rangeM)),
              reason:
                  '${c.id} $range: sürüklenme farkı '
                  '${diffMrad.toStringAsFixed(3)} mrad',
            );
          }
        });
      }
    });
  }
}

// Üretici tabloları, yayımlandığı birimde ve aynen (bkz. RAPOR.md).
// dart format off
const _cases = <_Case>[
  _Case(
    id: 'H1',
    name: 'Hornady .308 Win 168 gr ELD Match (80966)',
    yards: true,
    muzzleVelocity: 2700.0,
    grain: 168.0,
    sightHeight: 1.5,
    model: BallisticModel.g7,
    bc: 0.263,
    zeros: [
      _Zero(200.0, [_Row(100.0, 2530.0, 2.0), _Row(200.0, 2366.0, 0.0), _Row(300.0, 2209.0, -8.2), _Row(400.0, 2057.0, -23.5), _Row(500.0, 1912.0, -47.1)]),
    ],
  ),
  _Case(
    id: 'H2',
    name: 'Hornady .308 Win 178 gr ELD-X Precision Hunter (80994)',
    yards: true,
    muzzleVelocity: 2600.0,
    grain: 178.0,
    sightHeight: 1.5,
    model: BallisticModel.g7,
    bc: 0.278,
    zeros: [
      _Zero(200.0, [_Row(100.0, 2443.0, 2.2), _Row(200.0, 2291.0, 0.0), _Row(300.0, 2145.0, -8.8), _Row(400.0, 2004.0, -25.2), _Row(500.0, 1868.0, -50.2)]),
    ],
  ),
  _Case(
    id: 'H3',
    name: 'Hornady 6.5 Creedmoor 140 gr ELD Match (81500)',
    yards: true,
    muzzleVelocity: 2710.0,
    grain: 140.0,
    sightHeight: 1.5,
    model: BallisticModel.g7,
    bc: 0.326,
    zeros: [
      _Zero(200.0, [_Row(100.0, 2564.0, 1.9), _Row(200.0, 2422.0, 0.0), _Row(300.0, 2285.0, -7.8), _Row(400.0, 2152.0, -22.3), _Row(500.0, 2023.0, -44.4)]),
    ],
  ),
  _Case(
    id: 'H4',
    name: 'Hornady 6.5 Creedmoor 143 gr ELD-X Precision Hunter (81499)',
    yards: true,
    muzzleVelocity: 2700.0,
    grain: 143.0,
    sightHeight: 1.5,
    model: BallisticModel.g7,
    bc: 0.314,
    zeros: [
      _Zero(200.0, [_Row(100.0, 2556.0, 1.9), _Row(200.0, 2417.0, 0.0), _Row(300.0, 2282.0, -7.9), _Row(400.0, 2151.0, -22.4), _Row(500.0, 2025.0, -44.5)]),
    ],
  ),
  _Case(
    id: 'H5',
    name: 'Hornady .223 Rem 73 gr ELD Match (80269)',
    yards: true,
    muzzleVelocity: 2790.0,
    grain: 73.0,
    sightHeight: 1.5,
    model: BallisticModel.g7,
    bc: 0.2,
    zeros: [
      _Zero(200.0, [_Row(100.0, 2563.0, 1.9), _Row(200.0, 2348.0, 0.0), _Row(300.0, 2143.0, -8.2), _Row(400.0, 1949.0, -24.0), _Row(500.0, 1766.0, -49.0)]),
    ],
  ),
  _Case(
    id: 'H6',
    name: 'Hornady .300 Win Mag 178 gr ELD-X Precision Hunter (82041)',
    yards: true,
    muzzleVelocity: 2960.0,
    grain: 178.0,
    sightHeight: 1.5,
    model: BallisticModel.g7,
    bc: 0.278,
    zeros: [
      _Zero(200.0, [_Row(100.0, 2789.0, 1.5), _Row(200.0, 2625.0, 0.0), _Row(300.0, 2467.0, -6.6), _Row(400.0, 2314.0, -18.8), _Row(500.0, 2166.0, -37.6)]),
    ],
  ),
  _Case(
    id: 'H7',
    name: 'Hornady .300 Win Mag 200 gr ELD-X Precision Hunter (82002)',
    yards: true,
    muzzleVelocity: 2860.0,
    grain: 200.0,
    sightHeight: 1.5,
    model: BallisticModel.g7,
    bc: 0.301,
    zeros: [
      _Zero(200.0, [_Row(100.0, 2707.0, 1.6), _Row(200.0, 2558.0, 0.0), _Row(300.0, 2414.0, -6.9), _Row(400.0, 2274.0, -19.9), _Row(500.0, 2140.0, -39.5)]),
    ],
  ),
  _Case(
    id: 'H8',
    name: 'Hornady .338 Lapua Mag 285 gr ELD Match (82300)',
    yards: true,
    muzzleVelocity: 2745.0,
    grain: 285.0,
    sightHeight: 1.5,
    model: BallisticModel.g7,
    bc: 0.417,
    zeros: [
      _Zero(200.0, [_Row(100.0, 2636.0, 1.8), _Row(200.0, 2530.0, 0.0), _Row(300.0, 2426.0, -7.2), _Row(400.0, 2324.0, -20.3), _Row(500.0, 2225.0, -39.8)]),
    ],
  ),
  _Case(
    id: 'F1',
    name: 'Federal .308 Win 175 gr SMK Gold Medal (GM308M2)',
    yards: true,
    muzzleVelocity: 2600.0,
    grain: 175.0,
    sightHeight: 1.5,
    model: BallisticModel.g1,
    bc: 0.505,
    windMps: 4.4704,
    drift: [(100.0, 0.6), (200.0, 2.9), (300.0, 6.9), (400.0, 12.5), (500.0, 20.3)],
    zeros: [
      _Zero(200.0, [_Row(100.0, 2427.0, 2.2), _Row(200.0, 2262.0, 0.0), _Row(300.0, 2102.0, -9.1), _Row(400.0, 1949.0, -25.8), _Row(500.0, 1803.0, -51.8)]),
      _Zero(100.0, [_Row(50.0, None, -0.1), _Row(200.0, None, -4.4), _Row(300.0, None, -15.7)]),
    ],
  ),
  _Case(
    id: 'F2',
    name: 'Federal 6.5 Creedmoor 130 gr Berger Hybrid Gold Medal (GM65CRDBH130)',
    yards: true,
    muzzleVelocity: 2875.0,
    grain: 130.0,
    sightHeight: 1.5,
    model: BallisticModel.g1,
    bc: 0.56,
    windMps: 4.4704,
    drift: [(100.0, 0.6), (200.0, 2.3), (300.0, 5.2), (400.0, 9.7), (500.0, 15.7)],
    zeros: [
      _Zero(200.0, [_Row(100.0, 2709.0, 1.6), _Row(200.0, 2550.0, 0.0), _Row(300.0, 2396.0, -6.9), _Row(400.0, 2247.0, -20.0), _Row(500.0, 2104.0, -40.0)]),
      _Zero(100.0, [_Row(50.0, None, -0.2), _Row(200.0, None, -3.2), _Row(300.0, None, -11.8)]),
    ],
  ),
  _Case(
    id: 'F3',
    name: 'Federal .223 Rem 69 gr SMK Gold Medal (GM223M)',
    yards: true,
    muzzleVelocity: 2950.0,
    grain: 69.0,
    sightHeight: 1.5,
    model: BallisticModel.g1,
    bc: 0.301,
    windMps: 4.4704,
    drift: [(100.0, 1.0), (200.0, 4.3), (300.0, 10.3), (400.0, 19.3), (500.0, 32.4)],
    zeros: [
      _Zero(200.0, [_Row(100.0, 2642.0, 1.7), _Row(200.0, 2353.0, 0.0), _Row(300.0, 2084.0, -8.1), _Row(400.0, 1832.0, -24.1), _Row(500.0, 1604.0, -51.0)]),
      _Zero(100.0, [_Row(50.0, None, -0.2), _Row(200.0, None, -3.5), _Row(300.0, None, -13.3)]),
    ],
  ),
  _Case(
    id: 'F4',
    name: 'Federal .300 Win Mag 190 gr SMK Gold Medal (GM300WM)',
    yards: true,
    muzzleVelocity: 2900.0,
    grain: 190.0,
    sightHeight: 1.5,
    model: BallisticModel.g1,
    bc: 0.533,
    windMps: 4.4704,
    drift: [(100.0, 0.6), (200.0, 2.4), (300.0, 5.5), (400.0, 10.1), (500.0, 16.4)],
    zeros: [
      _Zero(200.0, [_Row(100.0, 2725.0, 1.6), _Row(200.0, 2557.0, 0.0), _Row(300.0, 2395.0, -6.9), _Row(400.0, 2239.0, -19.9), _Row(500.0, 2089.0, -39.9)]),
      _Zero(100.0, [_Row(50.0, None, -0.2), _Row(200.0, None, -3.2), _Row(300.0, None, -11.6)]),
    ],
  ),
  _Case(
    id: 'F5',
    name: 'Federal .338 Lapua Mag 300 gr SMK Gold Medal (GM338LM2)',
    yards: true,
    muzzleVelocity: 2580.0,
    grain: 300.0,
    sightHeight: 1.5,
    model: BallisticModel.g1,
    bc: 0.768,
    windMps: 4.4704,
    drift: [(100.0, 0.4), (200.0, 1.8), (300.0, 4.3), (400.0, 8.0), (500.0, 12.8)],
    zeros: [
      _Zero(200.0, [_Row(100.0, 2466.0, 2.1), _Row(200.0, 2355.0, 0.0), _Row(300.0, 2248.0, -8.5), _Row(400.0, 2143.0, -23.8), _Row(500.0, 2040.0, -46.6)]),
      _Zero(100.0, [_Row(50.0, None, -0.1), _Row(200.0, None, -4.2), _Row(300.0, None, -14.7)]),
    ],
  ),
  _Case(
    id: 'F6',
    name: 'Federal 7.62x39 123 gr JSP Power-Shok (76239B)',
    yards: true,
    muzzleVelocity: 2350.0,
    grain: 123.0,
    sightHeight: 1.5,
    model: BallisticModel.g1,
    bc: 0.274,
    windMps: 4.4704,
    drift: [(100.0, 1.6), (200.0, 6.7), (300.0, 16.2), (400.0, 30.7), (500.0, 50.8)],
    zeros: [
      _Zero(200.0, [_Row(100.0, 2055.0, 3.4), _Row(200.0, 1783.0, 0.0), _Row(300.0, 1539.0, -14.5), _Row(400.0, 1329.0, -43.9), _Row(500.0, 1164.0, -93.3)]),
      _Zero(100.0, [_Row(50.0, None, 0.2), _Row(200.0, None, -6.7), _Row(300.0, None, -24.6)]),
    ],
  ),
  _Case(
    id: 'L1',
    name: 'Lapua 6.5 Creedmoor 136 gr Scenar-L (4316063)',
    yards: false,
    muzzleVelocity: 835.0,
    grain: 136.0,
    sightHeight: 40.0,
    model: BallisticModel.g7,
    bc: 0.274,
    windMps: 4.0,
    drift: [(100.0, 19.0), (200.0, 76.0), (300.0, 179.0), (600.0, 807.0), (800.0, 1564.0), (1000.0, 2671.0)],
    zeros: [
      _Zero(100.0, [_Row(100.0, 780.0, 0.0), _Row(200.0, 725.0, -122.0), _Row(300.0, 673.0, -430.0), _Row(600.0, 529.0, -2814.0), _Row(800.0, 446.0, -6087.0), _Row(1000.0, 375.0, -11351.0)]),
      _Zero(300.0, [_Row(100.0, None, 143.0), _Row(200.0, None, 165.0), _Row(600.0, None, -1953.0), _Row(800.0, None, -4939.0), _Row(1000.0, None, -9916.0)]),
      _Zero(600.0, [_Row(100.0, None, 469.0), _Row(200.0, None, 816.0), _Row(300.0, None, 976.0), _Row(800.0, None, -2335.0), _Row(1000.0, None, -6661.0)]),
    ],
  ),
  _Case(
    id: 'L2',
    name: 'Lapua .308 Win 185 gr Scenar GB432 (4317523)',
    yards: false,
    muzzleVelocity: 755.0,
    grain: 185.0,
    sightHeight: 40.0,
    model: BallisticModel.g7,
    bc: 0.242,
    windMps: 4.0,
    drift: [(100.0, 21.0), (200.0, 88.0), (300.0, 207.0), (600.0, 963.0), (800.0, 1898.0)],
    zeros: [
      _Zero(100.0, [_Row(100.0, 697.0, 0.0), _Row(200.0, 640.0, -162.0), _Row(300.0, 585.0, -563.0), _Row(600.0, 438.0, -3735.0), _Row(800.0, 356.0, -8288.0)]),
      _Zero(300.0, [_Row(100.0, None, 188.0), _Row(200.0, None, 214.0), _Row(600.0, None, -2609.0), _Row(800.0, None, -6787.0)]),
    ],
  ),
  _Case(
    id: 'L3',
    name: 'Lapua .308 Win 167 gr Scenar GB422 (4317515)',
    yards: false,
    muzzleVelocity: 820.0,
    grain: 167.0,
    sightHeight: 40.0,
    model: BallisticModel.g7,
    bc: 0.223,
    windMps: 4.0,
    drift: [(100.0, 20.0), (200.0, 85.0), (300.0, 200.0), (600.0, 946.0), (800.0, 1899.0)],
    zeros: [
      _Zero(100.0, [_Row(100.0, 754.0, 0.0), _Row(200.0, 690.0, -132.0), _Row(300.0, 628.0, -470.0), _Row(600.0, 459.0, -3212.0), _Row(800.0, 364.0, -7258.0)]),
      _Zero(300.0, [_Row(100.0, None, 157.0), _Row(200.0, None, 181.0), _Row(600.0, None, -2271.0), _Row(800.0, None, -6003.0)]),
      _Zero(600.0, [_Row(100.0, None, 535.0), _Row(200.0, None, 938.0), _Row(300.0, None, 1135.0), _Row(800.0, None, -2975.0)]),
    ],
  ),
  _Case(
    id: 'L4',
    name: 'Lapua .338 Lapua Mag 250 gr Scenar GB488 (4318017)',
    yards: false,
    muzzleVelocity: 905.0,
    grain: 250.0,
    sightHeight: 40.0,
    model: BallisticModel.g7,
    bc: 0.322,
    windMps: 4.0,
    drift: [(100.0, 12.0), (200.0, 48.0), (300.0, 112.0), (600.0, 495.0), (800.0, 944.0), (1000.0, 1489.0)],
    zeros: [
      _Zero(100.0, [_Row(100.0, 856.0, 0.0), _Row(200.0, 808.0, -93.0), _Row(300.0, 762.0, -336.0), _Row(600.0, 631.0, -2164.0), _Row(800.0, 551.0, -4570.0), _Row(1000.0, 477.0, -8274.0)]),
      _Zero(300.0, [_Row(100.0, None, 112.0), _Row(200.0, None, 131.0), _Row(600.0, None, -1493.0), _Row(800.0, None, -3674.0), _Row(1000.0, None, -7155.0)]),
      _Zero(600.0, [_Row(100.0, None, 361.0), _Row(200.0, None, 628.0), _Row(300.0, None, 746.0), _Row(800.0, None, -1684.0), _Row(1000.0, None, -4667.0)]),
    ],
  ),
  _Case(
    id: 'L5',
    name: 'Lapua .338 Lapua Mag 300 gr Scenar GB528 (4318013)',
    yards: false,
    muzzleVelocity: 820.0,
    grain: 300.0,
    sightHeight: 40.0,
    model: BallisticModel.g7,
    bc: 0.368,
    windMps: 4.0,
    drift: [(100.0, 12.0), (200.0, 47.0), (300.0, 109.0), (600.0, 469.0), (800.0, 880.0), (1000.0, 1457.0)],
    zeros: [
      _Zero(100.0, [_Row(100.0, 780.0, 0.0), _Row(200.0, 741.0, -122.0), _Row(300.0, 703.0, -422.0), _Row(600.0, 597.0, -2609.0), _Row(800.0, 532.0, -5404.0), _Row(1000.0, 471.0, -9595.0)]),
      _Zero(300.0, [_Row(100.0, None, 141.0), _Row(200.0, None, 160.0), _Row(600.0, None, -1765.0), _Row(800.0, None, -4278.0), _Row(1000.0, None, -8188.0)]),
    ],
  ),
  _Case(
    id: 'B1',
    name: 'Berger 6.5 Creedmoor 140 gr Hybrid Target (31011)',
    yards: true,
    muzzleVelocity: 2750.0,
    grain: 140.0,
    sightHeight: 1.5,
    model: BallisticModel.g7,
    bc: 0.311,
    zeros: [
      _Zero(200.0, [_Row(100.0, 2602.0, 1.82), _Row(200.0, 2459.0, 0.0), _Row(300.0, 2320.0, -7.58), _Row(400.0, 2186.0, -21.61)]),
    ],
  ),
  _Case(
    id: 'B2',
    name: 'Berger .308 Win 185 gr Juggernaut OTM Tactical (60050)',
    yards: true,
    muzzleVelocity: 2608.0,
    grain: 185.0,
    sightHeight: 1.5,
    model: BallisticModel.g7,
    bc: 0.283,
    zeros: [
      _Zero(200.0, [_Row(100.0, 2450.0, 2.15), _Row(200.0, 2298.0, 0.0), _Row(300.0, 2152.0, -8.73), _Row(400.0, 2011.0, -24.98)]),
    ],
  ),
  _Case(
    id: 'B3',
    name: 'Berger .338 Lapua Mag 300 gr Hybrid OTM Tactical (81110)',
    yards: true,
    muzzleVelocity: 2725.0,
    grain: 300.0,
    sightHeight: 1.5,
    model: BallisticModel.g7,
    bc: 0.421,
    zeros: [
      _Zero(200.0, [_Row(100.0, 2616.0, 1.78), _Row(200.0, 2509.0, 0.0), _Row(300.0, 2405.0, -7.3), _Row(400.0, 2304.0, -20.6)]),
    ],
  ),
  _Case(
    id: 'N1',
    name: 'Norma .308 Win 180 gr Bondstrike (20176412)',
    yards: false,
    muzzleVelocity: 800.0,
    grain: 180.0,
    sightHeight: 40.0,
    model: BallisticModel.g1,
    bc: 0.615,
    zeros: [
      _Zero(100.0, [_Row(50.0, None, 0.0), _Row(80.0, None, 5.0), _Row(100.0, 752.0, 0.0), _Row(150.0, None, -44.0), _Row(200.0, 707.0, -133.0), _Row(300.0, 662.0, -464.0)]),
    ],
  ),
  _Case(
    id: 'N2',
    name: 'Norma 6.5 Creedmoor 143 gr Bondstrike (20166402)',
    yards: false,
    muzzleVelocity: 835.0,
    grain: 143.0,
    sightHeight: 40.0,
    model: BallisticModel.g1,
    bc: 0.629,
    zeros: [
      _Zero(100.0, [_Row(50.0, None, -1.0), _Row(80.0, None, 4.0), _Row(100.0, 786.0, 0.0), _Row(150.0, None, -38.0), _Row(200.0, 739.0, -118.0), _Row(300.0, 694.0, -415.0)]),
    ],
  ),
  _Case(
    id: 'N3',
    name: 'Norma .300 Win Mag 180 gr Bondstrike (20176332)',
    yards: false,
    muzzleVelocity: 940.0,
    grain: 180.0,
    sightHeight: 40.0,
    model: BallisticModel.g1,
    bc: 0.615,
    zeros: [
      _Zero(100.0, [_Row(50.0, None, -5.0), _Row(80.0, None, 1.0), _Row(100.0, 887.0, 0.0), _Row(150.0, None, -26.0), _Row(200.0, 837.0, -85.0), _Row(300.0, 788.0, -310.0)]),
    ],
  ),
];
// dart format on
