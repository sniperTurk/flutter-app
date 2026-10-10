// Formula parity with the App Store build (owner, 2026-10-11: "app storeye
// yüklediğin formüllerle yeni yazdıklarını karşılaştır").
//
// The same shots go through the frozen App Store copy
// (test/app_store_reference, build 59) and through the current lib/core.
// Every default result must be identical; the opt-in additions (local
// gravity, other G functions, own drag curve) must only change results when
// they are switched on.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart' as now_engine;
import 'package:sniper_turk/core/ballistic_input.dart' as now_input;
import 'package:sniper_turk/core/drag_table.dart' as now_table;
import 'package:sniper_turk/core/gravity.dart';
import 'package:sniper_turk/core/reticle_holds.dart' as now_holds;
import 'package:sniper_turk/core/standard_drag_tables.dart' as now_std;
import 'package:sniper_turk/models/domain.dart' as now;

import 'app_store_reference/core/ballistic_engine.dart' as old_engine;
import 'app_store_reference/core/ballistic_input.dart' as old_input;
import 'app_store_reference/core/reticle_holds.dart' as old_holds;
import 'app_store_reference/models/domain.dart' as old;

/// One shot, described once and built for both code bases.
class _Shot {
  final double mv, grain, zero, sight, bc;
  final int model; // 0 = G1, 1 = G7, 2 = GA
  final List<double> ranges;
  final double temp, pressure, humidity, altitude, wind, windDir;
  final double incline, cant;
  final double? latitude, azimuth, zeroMv;
  final List<(double, double)> bands;
  final (double, double)? zones; // mid, far wind (m/s)

  const _Shot({
    required this.mv,
    required this.grain,
    required this.zero,
    required this.sight,
    required this.bc,
    required this.model,
    required this.ranges,
    this.temp = 15,
    this.pressure = 1013.25,
    this.humidity = 50,
    this.altitude = 0,
    this.wind = 0,
    this.windDir = 90,
    this.incline = 0,
    this.cant = 0,
    this.latitude,
    this.azimuth,
    this.zeroMv,
    this.bands = const [],
    this.zones,
  });

  @override
  String toString() =>
      'mv=$mv gr=$grain zero=$zero sh=$sight bc=$bc model=$model '
      'T=$temp p=$pressure h=$humidity alt=$altitude wind=$wind@$windDir '
      'inc=$incline cant=$cant lat=$latitude az=$azimuth zmv=$zeroMv '
      'bands=$bands zones=$zones';

  old_input.BallisticInput get oldInput => old_input.BallisticInput(
    muzzleVelocityMps: mv,
    grain: grain,
    zeroRangeM: zero,
    sightHeightMm: sight,
    rangesM: ranges,
    environment: old.EnvironmentData(
      temperatureC: temp,
      pressureHpa: pressure,
      humidityPercent: humidity,
      altitudeM: altitude,
      windMps: wind,
      windDirectionDeg: windDir,
    ),
    ballisticCoefficient: bc,
    ballisticModel: old.BallisticModel.values[model],
    bcBands: [for (final b in bands) old.BcBand(b.$1, b.$2)],
    windZones: zones == null
        ? null
        : old_input.WindZones(
            rangeM: ranges.last,
            midMps: zones!.$1,
            farMps: zones!.$2,
          ),
    inclineDeg: incline,
    cantDeg: cant,
    latitudeDeg: latitude,
    azimuthDeg: azimuth,
    zeroMuzzleVelocityMps: zeroMv,
  );

  static const _nowModels = [
    now.BallisticModel.g1,
    now.BallisticModel.g7,
    now.BallisticModel.ga,
  ];

  now_input.BallisticInput nowInput({
    double gravity = Gravity.standard,
    now.BallisticModel? modelOverride,
    now_table.DragTable? dragTable,
  }) => now_input.BallisticInput(
    muzzleVelocityMps: mv,
    grain: grain,
    zeroRangeM: zero,
    sightHeightMm: sight,
    rangesM: ranges,
    environment: now.EnvironmentData(
      temperatureC: temp,
      pressureHpa: pressure,
      humidityPercent: humidity,
      altitudeM: altitude,
      windMps: wind,
      windDirectionDeg: windDir,
    ),
    ballisticCoefficient: bc,
    ballisticModel: modelOverride ?? _nowModels[model],
    bcBands: [for (final b in bands) now.BcBand(b.$1, b.$2)],
    dragTable: dragTable,
    windZones: zones == null
        ? null
        : now_input.WindZones(
            rangeM: ranges.last,
            midMps: zones!.$1,
            farMps: zones!.$2,
          ),
    inclineDeg: incline,
    cantDeg: cant,
    latitudeDeg: latitude,
    azimuthDeg: azimuth,
    zeroMuzzleVelocityMps: zeroMv,
    gravityMps2: gravity,
  );
}

List<_Shot> _shots() {
  final shots = <_Shot>[
    // Typical firearm and PCP shots, written out.
    const _Shot(
      mv: 822,
      grain: 175,
      zero: 100,
      sight: 50,
      bc: 0.243,
      model: 1,
      ranges: [50, 100, 300, 600, 1000],
      wind: 4,
      windDir: 90,
    ),
    const _Shot(
      mv: 860,
      grain: 140,
      zero: 100,
      sight: 45,
      bc: 0.610,
      model: 0,
      ranges: [100, 200, 500, 800],
      temp: -5,
      pressure: 950,
      humidity: 80,
      altitude: 900,
      wind: 6,
      windDir: 45,
      incline: 12,
      cant: 2,
      latitude: 39.9,
      azimuth: 75,
    ),
    const _Shot(
      mv: 274,
      grain: 25.39,
      zero: 30,
      sight: 55,
      bc: 0.033,
      model: 2,
      ranges: [10, 20, 30, 50, 75, 100],
      wind: 2,
      windDir: 270,
    ),
    const _Shot(
      mv: 290,
      grain: 33.95,
      zero: 40,
      sight: 60,
      bc: 0.11,
      model: 0,
      ranges: [25, 50, 100, 150],
      bands: [(260, 0.11), (220, 0.10)],
      zones: (3, 5),
      wind: 1,
      zeroMv: 285,
    ),
  ];

  // A fixed-seed spread over the whole input space.
  final r = math.Random(20261011);
  double between(double a, double b) => a + (b - a) * r.nextDouble();
  for (var i = 0; i < 48; i++) {
    final model = i % 3;
    final firearm = model != 2;
    final mv = firearm ? between(550, 1000) : between(220, 330);
    final zero = firearm ? between(50, 300) : between(15, 50);
    final far = firearm ? between(400, 1200) : between(60, 150);
    shots.add(
      _Shot(
        mv: mv,
        grain: firearm ? between(40, 250) : between(8, 50),
        zero: zero,
        sight: between(35, 80),
        bc: model == 1
            ? between(0.12, 0.35)
            : firearm
            ? between(0.25, 0.7)
            : between(0.02, 0.06),
        model: model,
        ranges: [for (var k = 1; k <= 6; k++) far * k / 6],
        temp: between(-15, 40),
        pressure: between(850, 1040),
        humidity: between(0, 100),
        altitude: between(0, 2000),
        wind: between(0, 10),
        windDir: between(0, 360),
        incline: i % 4 == 0 ? between(-20, 20) : 0,
        cant: i % 5 == 0 ? between(-5, 5) : 0,
        latitude: i % 2 == 0 ? between(-60, 60) : null,
        azimuth: i % 2 == 0 ? between(0, 360) : null,
        zeroMv: i % 6 == 0 ? mv * between(0.97, 1.03) : null,
        zones: i % 7 == 0 ? (between(0, 8), between(0, 8)) : null,
      ),
    );
  }
  return shots;
}

bool _same(double a, double b) =>
    a == b || (a - b).abs() <= 1e-9 * math.max(1, math.max(a.abs(), b.abs()));

List<List<double>> _oldRows(old_input.BallisticInput input) => [
  for (final p in const old_engine.BallisticEngine().solve(input))
    [
      p.rangeM,
      p.dropM,
      p.correctionMrad,
      p.correctionMoa,
      p.velocityMps,
      p.energyJ,
      p.timeOfFlightS,
      p.windMrad,
    ],
];

List<List<double>> _nowRows(now_input.BallisticInput input) => [
  for (final p in const now_engine.BallisticEngine().solve(input))
    [
      p.rangeM,
      p.dropM,
      p.correctionMrad,
      p.correctionMoa,
      p.velocityMps,
      p.energyJ,
      p.timeOfFlightS,
      p.windMrad,
    ],
];

/// The rows, or the error type when the shot cannot be solved.
Object _run(List<List<double>> Function() f) {
  try {
    return f();
  } on StateError {
    return StateError;
  } on ArgumentError {
    return ArgumentError;
  }
}

const _fields = [
  'range',
  'drop',
  'mrad',
  'moa',
  'velocity',
  'energy',
  'time',
  'wind',
];

void _expectSame(Object a, Object b, String reason) {
  if (a is! List<List<double>> || b is! List<List<double>>) {
    expect(b, a, reason: reason);
    return;
  }
  expect(b.length, a.length, reason: reason);
  for (var i = 0; i < a.length; i++) {
    for (var k = 0; k < _fields.length; k++) {
      expect(
        _same(a[i][k], b[i][k]),
        isTrue,
        reason: '$reason\nrow $i ${_fields[k]}: '
            'App Store ${a[i][k]} vs now ${b[i][k]}',
      );
    }
  }
}

void main() {
  final shots = _shots();

  test('every default result equals the App Store build', () {
    var solved = 0;
    for (final s in shots) {
      final a = _run(() => _oldRows(s.oldInput));
      final b = _run(() => _nowRows(s.nowInput()));
      _expectSame(a, b, '$s');
      if (a is List) solved++;
    }
    // The comparison is not vacuous.
    expect(solved, greaterThan(shots.length * 3 ~/ 4));
  });

  test('reticle holds and wind-per-mil equal the App Store build', () {
    for (final s in shots.take(6)) {
      final a = old_holds.ReticleHolds.sample(s.oldInput);
      final b = now_holds.ReticleHolds.sample(s.nowInput());
      expect(b.length, a.length, reason: '$s');
      for (var i = 0; i < a.length; i += 37) {
        expect(
          _same(a[i].correctionMrad, b[i].correctionMrad),
          isTrue,
          reason: '$s @ ${a[i].rangeM}',
        );
      }
      final range = s.ranges[s.ranges.length ~/ 2];
      final wa = old_holds.ReticleHolds.crosswindForMil(
        base: s.oldInput,
        rangeM: range,
        mil: 1,
      );
      final wb = now_holds.ReticleHolds.crosswindForMil(
        base: s.nowInput(),
        rangeM: range,
        mil: 1,
      );
      expect(wb == null, wa == null, reason: '$s');
      if (wa != null) expect(_same(wa, wb!), isTrue, reason: '$s');
    }
  });

  test('the standard tables are still the App Store tables', () {
    // forModel(G1/G7/GA) must hand the solver the same table as before;
    // the explicit table gives the same result as the model.
    for (final s in shots.take(12)) {
      final model = _Shot._nowModels[s.model];
      final a = _run(() => _nowRows(s.nowInput()));
      final b = _run(
        () => _nowRows(
          s.nowInput(dragTable: now_std.StandardDragTables.forModel(model)),
        ),
      );
      _expectSame(a, b, '$s');
    }
  });

  test('local gravity is opt-in and moves the drop the right way', () {
    final s = shots.first;
    final standard = _nowRows(s.nowInput());
    final light = _nowRows(s.nowInput(gravity: 9.78));
    final heavy = _nowRows(s.nowInput(gravity: 9.83));
    final last = standard.length - 1;
    // Weaker gravity: less correction beyond the zero; stronger: more.
    expect(light[last][2], lessThan(standard[last][2]));
    expect(heavy[last][2], greaterThan(standard[last][2]));
    // The size is physical: ~0.25 % g changes the 1000 m hold by well under
    // 1 %.
    final rel = (heavy[last][2] - standard[last][2]) / standard[last][2];
    expect(rel, inExclusiveRange(0, 0.01));
    // Turkey (36–42° N) lies between the equator and the poles.
    expect(Gravity.at(latitudeDeg: 0), closeTo(9.7803253359, 1e-9));
    expect(Gravity.at(latitudeDeg: 90), closeTo(9.8321849378, 1e-9));
    expect(Gravity.at(latitudeDeg: 45), closeTo(9.8061992, 1e-6));
  });
}
