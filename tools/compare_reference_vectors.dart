// dart format off
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:sniper_turk/core/aerodynamic_trajectory_solver.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/models/domain.dart';

Never _fail(String message) {
  stderr.writeln('reference-vector comparison FAILED: $message');
  exit(2);
}

double _number(Object? value, String path) {
  if (value is! num || !value.toDouble().isFinite) _fail('$path must be a finite number');
  return value.toDouble();
}

double _positiveNumber(Object? value, String path) {
  final number = _number(value, path);
  if (number <= 0) _fail('$path must be > 0');
  return number;
}

Object? _canonicalJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalJson(value[key]),
    };
  }
  if (value is List) return value.map(_canonicalJson).toList(growable: false);
  return value;
}

void main() {
  // Resolve validation inputs from this tool's own location rather than the
  // caller's working directory. CI/developer wrappers may invoke this script
  // from outside the repository root; acceptance must remain deterministic.
  final toolFile = File.fromUri(Platform.script).absolute;
  final root = toolFile.parent.parent;
  final policyFile = File('${root.path}/validation/acceptance.json');
  final fixtureFile = File('${root.path}/validation/py_ballisticcalc_vectors.json');
  if (!policyFile.existsSync()) _fail('validation/acceptance.json is missing');
  if (!fixtureFile.existsSync()) _fail('independent reference fixture is missing');

  // The Python validator is the canonical fixture-contract gate. Running it
  // here makes direct comparator invocation fail closed too; callers cannot
  // bypass frozen scenarios/unknown-field checks by skipping CI wrapper steps.
  final validator = File('${root.path}/tools/validate_py_ballisticcalc_fixture.py');
  if (!validator.existsSync()) _fail('canonical fixture validator is missing');
  final validation = Process.runSync(
    'python3',
    <String>[validator.path, fixtureFile.path],
    workingDirectory: root.path,
  );
  if (validation.exitCode != 0) {
    final detail = '${validation.stdout}${validation.stderr}'.trim();
    _fail('canonical fixture validation failed${detail.isEmpty ? '' : ': $detail'}');
  }

  final policy = jsonDecode(policyFile.readAsStringSync()) as Map<String, dynamic>;
  final fixture = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
  if (fixture['schema'] != 1) _fail('unsupported reference fixture schema');
  if (fixture['generator'] != 'py-ballisticcalc') _fail('unexpected reference generator');
  if (fixture['engine'] != 'rk4_engine') {
    _fail('reference fixture was not generated with the locked RK4 engine');
  }
  if (fixture['version'] != policy['reference']['version']) _fail('reference version does not match acceptance policy');
  if (jsonEncode(_canonicalJson(fixture['acceptance'])) !=
      jsonEncode(_canonicalJson(policy))) {
    _fail('fixture was not generated under the current acceptance policy');
  }
  final atmospheres = fixture['atmospheres'];
  if (atmospheres is! Map<String, dynamic>) _fail('reference fixture atmospheres are missing');

  final tolerances = policy['tolerances'] as Map<String, dynamic>;
  final heightTol = _number(tolerances['height_m_absolute'], 'height tolerance');
  final velocityTol = _number(tolerances['velocity_mps_absolute'], 'velocity tolerance');
  final timeTol = _number(tolerances['time_s_absolute'], 'time tolerance');
  final requirements = policy['requirements'] as Map<String, dynamic>;
  final requiredModels = (requirements['models'] as List).cast<String>().toSet();
  final minimumCases = (requirements['minimum_cases'] as num).toInt();
  final minimumPoints = (requirements['minimum_points_per_case'] as num).toInt();
  final requiredAtmospheres = (requirements['required_atmospheres'] as List).cast<String>().toSet();
  final rangeRequirementsRaw = requirements['minimum_max_range_m_by_model'];
  if (rangeRequirementsRaw is! Map<String, dynamic>) {
    _fail('acceptance policy is missing minimum_max_range_m_by_model');
  }
  final rangeRequirements = <String, double>{
    for (final model in requiredModels)
      model: _number(rangeRequirementsRaw[model], 'minimum max range for $model'),
  };
  final cases = (fixture['cases'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  if (cases.length < minimumCases) _fail('fixture has fewer than $minimumCases cases');

  final seenModels = <String>{};
  var compared = 0;
  var worstHeight = 0.0;
  var worstVelocity = 0.0;
  var worstTime = 0.0;
  final failures = <String>[];
  final seenAtmospheres = <String>{};
  final seenModelAtmospherePairs = <String>{};
  final seenCaseIds = <String>{};

  for (final c in cases) {
    final id = c['id'] as String?;
    if (id == null || id.isEmpty) _fail('case id is required');
    if (!seenCaseIds.add(id)) _fail('duplicate case id $id');
    final modelName = c['model'] as String?;
    if (modelName != 'G1' && modelName != 'G7') _fail('$id has unsupported model $modelName');
    seenModels.add(modelName!);
    final atmosphereId = c['atmosphere'] as String?;
    if (atmosphereId == null || !requiredAtmospheres.contains(atmosphereId)) _fail('$id has unsupported atmosphere $atmosphereId');
    final atmosphereJson = atmospheres[atmosphereId];
    if (atmosphereJson is! Map<String, dynamic>) _fail('$id atmosphere definition is missing');
    seenAtmospheres.add(atmosphereId);
    seenModelAtmospherePairs.add('$modelName|$atmosphereId');
    final temperatureC = _number(atmosphereJson['temperature_c'], '$id.temperature_c');
    final pressureHpa = _number(atmosphereJson['pressure_hpa'], '$id.pressure_hpa');
    final humidityPercent = _number(atmosphereJson['humidity_percent'], '$id.humidity_percent');
    final altitudeM = _number(atmosphereJson['altitude_m'], '$id.altitude_m');
    if (pressureHpa <= 0) _fail('$id.pressure_hpa must be > 0');
    if (humidityPercent < 0 || humidityPercent > 100) {
      _fail('$id.humidity_percent must be within 0..100');
    }
    final environment = EnvironmentData(
      temperatureC: temperatureC,
      pressureHpa: pressureHpa,
      humidityPercent: humidityPercent,
      altitudeM: altitudeM,
      windMps: 0,
      windDirectionDeg: 90,
    );
    final refs = (c['points'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (refs.length < minimumPoints) _fail('$id has fewer than $minimumPoints points');
    final ranges = refs.map((p) => _positiveNumber(p['range_m'], '$id.range_m')).toList(growable: false);
    for (var i = 1; i < ranges.length; i++) {
      if (ranges[i] <= ranges[i - 1]) _fail('$id ranges must be strictly increasing');
    }
    final requiredMaxRange = rangeRequirements[modelName]!;
    if (ranges.reduce(math.max) < requiredMaxRange) {
      _fail('$id maximum range is below required ${requiredMaxRange}m');
    }
    final input = BallisticInput(
      muzzleVelocityMps: _positiveNumber(c['mv'], '$id.mv'),
      grain: _positiveNumber(c['grain'], '$id.grain'),
      zeroRangeM: _positiveNumber(c['zero'], '$id.zero'),
      sightHeightMm: _positiveNumber(c['sight_mm'], '$id.sight_mm'),
      rangesM: ranges,
      environment: environment,
      zeroEnvironment: environment,
      ballisticCoefficient: _positiveNumber(c['bc'], '$id.bc'),
      ballisticModel: modelName == 'G1' ? BallisticModel.g1 : BallisticModel.g7,
    );
    final actual = const AerodynamicTrajectorySolver().solveNoWind(input);
    if (actual.length != refs.length) _fail('$id point-count mismatch');
    for (var i = 0; i < refs.length; i++) {
      final ref = refs[i];
      final p = actual[i];
      final expectedHeight = _number(ref['height_m'], '$id[$i].height_m');
      final expectedVelocity = _positiveNumber(ref['velocity_mps'], '$id[$i].velocity_mps');
      final expectedTime = _positiveNumber(ref['time_s'], '$id[$i].time_s');
      final dh = (p.dropM + expectedHeight).abs(); // solver stores drop = -height
      final dv = (p.velocityMps - expectedVelocity).abs();
      final dt = (p.timeOfFlightS - expectedTime).abs();
      worstHeight = math.max(worstHeight, dh);
      worstVelocity = math.max(worstVelocity, dv);
      worstTime = math.max(worstTime, dt);
      if (dh > heightTol || dv > velocityTol || dt > timeTol) {
        failures.add('$id @ ${ranges[i]}m: |dh|=${dh.toStringAsFixed(6)}m, |dv|=${dv.toStringAsFixed(6)}m/s, |dt|=${dt.toStringAsFixed(6)}s');
      }
      compared++;
    }
  }
  if (!seenModels.containsAll(requiredModels)) _fail('fixture does not cover required models $requiredModels');
  if (!seenAtmospheres.containsAll(requiredAtmospheres)) _fail('fixture does not cover required atmospheres $requiredAtmospheres');
  if (requirements['require_model_atmosphere_cross_product'] != true) {
    _fail('acceptance policy must require the model-atmosphere cross-product');
  }
  final missingPairs = <String>[
    for (final model in requiredModels)
      for (final atmosphere in requiredAtmospheres)
        if (!seenModelAtmospherePairs.contains('$model|$atmosphere')) '$model/$atmosphere',
  ];
  if (missingPairs.isNotEmpty) _fail('fixture is missing required model-atmosphere pairs: $missingPairs');
  if (failures.isNotEmpty) {
    for (final line in failures.take(20)) {
      stderr.writeln(line);
    }
    _fail('${failures.length}/$compared points exceeded predeclared tolerances');
  }
  stdout.writeln('reference-vector comparison PASSED: $compared points; worst |dh|=${worstHeight.toStringAsFixed(6)}m, |dv|=${worstVelocity.toStringAsFixed(6)}m/s, |dt|=${worstTime.toStringAsFixed(6)}s');
}
