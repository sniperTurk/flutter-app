// dart format off
// Compares the experimental G1/G7 solver's wind response with the separate,
// independently generated wind acceptance vectors. Tolerances and the wind
// direction convention are read from validation/wind_acceptance.json, which
// was frozen before any output existed. Any missing input, mismatch or
// out-of-tolerance point exits non-zero.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:sniper_turk/core/aerodynamic_trajectory_solver.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/models/domain.dart';

Never _fail(String message) {
  stderr.writeln('wind reference comparison FAILED: $message');
  exit(2);
}

double _num(Object? v, String path) {
  if (v is! num || !v.toDouble().isFinite) _fail('$path must be a finite number');
  return v.toDouble();
}

Object? _canonical(Object? v) {
  if (v is Map) {
    final keys = v.keys.map((k) => k.toString()).toList()..sort();
    return <String, Object?>{for (final k in keys) k: _canonical(v[k])};
  }
  if (v is List) return v.map(_canonical).toList(growable: false);
  // Python writes 0.0 / 4.0 for floats; Dart may decode integral JSON numbers
  // as int. Compare numbers by value.
  if (v is num) return v.toDouble();
  return v;
}

void main(List<String> args) {
  final root = File.fromUri(Platform.script).absolute.parent.parent;
  // Optional: <policy.json> <fixture.json> for another frozen set in the same
  // format (e.g. the envelope corner cases).
  final policyFile = File(args.isNotEmpty ? args[0] : '${root.path}/validation/wind_acceptance.json');
  final fixtureFile = File(args.length > 1 ? args[1] : '${root.path}/validation/py_ballisticcalc_wind_vectors.json');
  if (!policyFile.existsSync()) _fail('${policyFile.path} is missing');
  if (!fixtureFile.existsSync()) _fail('wind reference fixture is missing');
  final policy = jsonDecode(policyFile.readAsStringSync()) as Map<String, dynamic>;
  final fixture = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
  if (fixture['generator'] != 'py-ballisticcalc' || fixture['engine'] != 'rk4_engine') {
    _fail('unexpected generator/engine');
  }
  // Key order differs between Python (sort_keys) and this file, so compare a
  // canonical (key-sorted) encoding of the embedded and current policy.
  if (jsonEncode(_canonical(fixture['policy'])) != jsonEncode(_canonical(policy))) {
    _fail('fixture was not generated under the current wind acceptance policy');
  }
  final tol = policy['tolerances'] as Map<String, dynamic>;
  // A set may instead declare ANGULAR tolerances (mrad at the range), which
  // is what a shooter dials: 0.1 mrad = one click of a 0.1 mrad turret. Used
  // for long ranges, where tens of metres of drop make a fixed 1 cm bound
  // meaningless (owner decision 2026-10-08).
  final angular = tol.containsKey('height_mrad');
  final windTol = angular
      ? _num(tol['windage_mrad'], 'windage tolerance (mrad)')
      : _num(tol['windage_m_absolute'], 'windage tolerance');
  final heightTol = angular
      ? _num(tol['height_mrad'], 'height tolerance (mrad)')
      : _num(tol['height_m_absolute'], 'height tolerance');
  final velocityTol = _num(tol['velocity_mps_absolute'], 'velocity tolerance');
  final timeTol = _num(tol['time_s_absolute'], 'time tolerance');
  final atmospheres = policy['atmospheres'] as Map<String, dynamic>;
  final policyCases = (policy['cases'] as List).cast<Map<String, dynamic>>();
  final refCases = {
    for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) c['id'] as String: c,
  };
  final unproducible = <String, Object?>{
    ...?(fixture['unproducible'] as Map<String, dynamic>?),
  };
  if (refCases.length + unproducible.length != policyCases.length) {
    _fail('case count differs from policy');
  }

  var compared = 0;
  var worstWind = 0.0, worstHeight = 0.0, worstVelocity = 0.0, worstTime = 0.0;
  final failures = <String>[];
  final perCase = <String>[];
  for (final c in policyCases) {
    var caseWind = 0.0, caseHeight = 0.0, caseVelocity = 0.0, caseTime = 0.0;
    final id = c['id'] as String;
    if (unproducible.containsKey(id)) {
      failures.add('$id (reference cannot produce: ${unproducible[id]})');
      perCase.add('$id UNPRODUCIBLE');
      continue;
    }
    final ref = refCases[id];
    if (ref == null) _fail('reference case $id is missing');
    final a = atmospheres[c['atmosphere']] as Map<String, dynamic>?;
    if (a == null) _fail('$id atmosphere is missing');
    final windMps = _num(c['wind_mps'], '$id.wind_mps');
    final windDeg = _num(c['wind_direction_deg'], '$id.wind_direction_deg');
    final expectedFrom = (180.0 - windDeg) % 360.0;
    if ((_num(ref['py_direction_from_deg'], '$id.py_direction_from_deg') - expectedFrom).abs() > 1e-9) {
      _fail('$id reference used a different wind direction mapping');
    }
    EnvironmentData env(double wind) => EnvironmentData(
      temperatureC: _num(a['temperature_c'], '$id.temperature_c'),
      pressureHpa: _num(a['pressure_hpa'], '$id.pressure_hpa'),
      humidityPercent: _num(a['humidity_percent'], '$id.humidity_percent'),
      altitudeM: _num(a['altitude_m'], '$id.altitude_m'),
      windMps: wind,
      windDirectionDeg: windDeg,
    );
    final points = (ref['points'] as List).cast<Map<String, dynamic>>();
    final ranges = (c['ranges'] as List).map((r) => _num(r, '$id.range')).toList(growable: false);
    if (points.length != ranges.length) _fail('$id point count differs from policy');
    final input = BallisticInput(
      muzzleVelocityMps: _num(c['mv'], '$id.mv'),
      grain: _num(c['grain'], '$id.grain'),
      zeroRangeM: _num(c['zero'], '$id.zero'),
      sightHeightMm: _num(c['sight_mm'], '$id.sight_mm'),
      rangesM: ranges,
      environment: env(windMps),
      zeroEnvironment: env(0),
      ballisticCoefficient: _num(c['bc'], '$id.bc'),
      ballisticModel: c['model'] == 'G1' ? BallisticModel.g1 : BallisticModel.g7,
    );
    final actual = const AerodynamicTrajectorySolver().solve(input);
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final range = ranges[i];
      if ((_num(p['range_m'], '$id[$i].range_m') - range).abs() > 1e-9) _fail('$id range order differs');
      final z = -range * math.tan(actual[i].windMrad / 1000);
      final dw = (z - _num(p['windage_m'], '$id[$i].windage_m')).abs();
      final dh = (actual[i].dropM + _num(p['height_m'], '$id[$i].height_m')).abs();
      final dv = (actual[i].velocityMps - _num(p['velocity_mps'], '$id[$i].velocity_mps')).abs();
      final dt = (actual[i].timeOfFlightS - _num(p['time_s'], '$id[$i].time_s')).abs();
      caseWind = math.max(caseWind, dw);
      caseHeight = math.max(caseHeight, dh);
      caseVelocity = math.max(caseVelocity, dv);
      caseTime = math.max(caseTime, dt);
      worstWind = math.max(worstWind, dw);
      worstHeight = math.max(worstHeight, dh);
      worstVelocity = math.max(worstVelocity, dv);
      worstTime = math.max(worstTime, dt);
      stdout.writeln('$id @ ${range}m: z=${z.toStringAsFixed(4)} ref=${_num(p['windage_m'], 'w').toStringAsFixed(4)} '
          'h=${(-actual[i].dropM).toStringAsFixed(3)} refh=${_num(p['height_m'], 'h').toStringAsFixed(3)} '
          '|dw|=${dw.toStringAsFixed(5)} |dh|=${dh.toStringAsFixed(5)} (${(dh / range * 1000).toStringAsFixed(3)} mrad) '
          '|dv|=${dv.toStringAsFixed(4)} |dt|=${dt.toStringAsFixed(5)}');
      final wCheck = angular ? dw / range * 1000 : dw;
      final hCheck = angular ? dh / range * 1000 : dh;
      if (wCheck > windTol || hCheck > heightTol || dv > velocityTol || dt > timeTol) {
        failures.add('$id @ ${range}m');
      }
      compared++;
    }
    perCase.add('$id dw=${caseWind.toStringAsFixed(4)} dh=${caseHeight.toStringAsFixed(4)} '
        'dv=${caseVelocity.toStringAsFixed(3)} dt=${caseTime.toStringAsFixed(5)}');
  }
  stdout.writeln('case-summary ${perCase.join('; ')}');
  final summary = '$compared points; worst |dw|=${worstWind.toStringAsFixed(6)}m, |dh|=${worstHeight.toStringAsFixed(6)}m, '
      '|dv|=${worstVelocity.toStringAsFixed(6)}m/s, |dt|=${worstTime.toStringAsFixed(6)}s';
  if (failures.isNotEmpty) {
    _fail('${failures.length}/$compared points exceeded predeclared tolerances (${failures.join(', ')}); $summary');
  }
  stdout.writeln('wind reference comparison PASSED: $summary');
}
