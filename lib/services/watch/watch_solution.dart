/// What the watch shows: the phone's current Atış solution, already solved.
///
/// The watch never computes ballistics (single source of truth). This class
/// only carries the numbers the shot view already shows, in a message made
/// of property-list / Monkey C friendly types (String, int, double, bool).
library;

/// Message schema version understood by the watch apps.
const int watchSchemaVersion = 1;

class WatchSolution {
  /// False when the phone has no valid solution; the watch then shows
  /// "Çözüm yok" and never an older number.
  final bool ok;

  /// Active profile name.
  final String profile;

  /// Target distance in [rangeUnit] ("m" or "yd").
  final int range;
  final String rangeUnit;

  /// Step the watch uses when the shooter changes the distance.
  final int rangeStep;

  /// Required turret clicks: + up / + right, − down / − left.
  final int up;
  final int right;

  /// The same corrections as angles in [unit].
  final double upAngle;
  final double rightAngle;

  /// "MRAD" or "MOA".
  final String unit;

  /// Click value in [unit] (e.g. 0.1).
  final double click;

  /// Wind the windage was solved with (null = no wind entered).
  final double? windSpeed;
  final String? windUnit;

  /// Clock hour (1…12) the wind comes from.
  final int? windClock;

  /// When the phone produced this solution.
  final DateTime at;

  const WatchSolution({
    required this.ok,
    required this.profile,
    required this.range,
    required this.rangeUnit,
    required this.rangeStep,
    required this.up,
    required this.right,
    required this.upAngle,
    required this.rightAngle,
    required this.unit,
    required this.click,
    this.windSpeed,
    this.windUnit,
    this.windClock,
    required this.at,
  });

  /// No valid solution on the phone.
  factory WatchSolution.none({required String profile, required DateTime at}) =>
      WatchSolution(
        ok: false,
        profile: profile,
        range: 0,
        rangeUnit: 'm',
        rangeStep: 10,
        up: 0,
        right: 0,
        upAngle: 0,
        rightAngle: 0,
        unit: 'MRAD',
        click: 0,
        at: at,
      );

  /// The same solution, stamped [time] (a refresh of unchanged content).
  WatchSolution withTime(DateTime time) => WatchSolution(
    ok: ok,
    profile: profile,
    range: range,
    rangeUnit: rangeUnit,
    rangeStep: rangeStep,
    up: up,
    right: right,
    upAngle: upAngle,
    rightAngle: rightAngle,
    unit: unit,
    click: click,
    windSpeed: windSpeed,
    windUnit: windUnit,
    windClock: windClock,
    at: time,
  );

  /// [v] rounded to 2 decimals, never "-0.0".
  static double _round2(double v) {
    final r = (v * 100).roundToDouble() / 100;
    return r == 0 ? 0.0 : r;
  }

  /// The message sent to the watch. Without a solution only the identity
  /// fields travel, so a watch can never show stale clicks as current.
  Map<String, Object> toMessage() {
    final m = <String, Object>{
      'v': watchSchemaVersion,
      'ok': ok,
      'profile': profile,
      'at': at.millisecondsSinceEpoch,
    };
    if (!ok) return m;
    m.addAll({
      'range': range,
      'rangeUnit': rangeUnit,
      'rangeStep': rangeStep,
      'up': up,
      'right': right,
      'upAngle': _round2(upAngle),
      'rightAngle': _round2(rightAngle),
      'unit': unit,
      'click': click,
    });
    final ws = windSpeed;
    final wu = windUnit;
    final wc = windClock;
    if (ws != null && wu != null && ws > 0) {
      m['windSpeed'] = (ws * 10).roundToDouble() / 10;
      m['windUnit'] = wu;
      if (wc != null) m['windClock'] = wc;
    }
    return m;
  }

  /// The message without its timestamp: two solutions with the same
  /// content are the same thing for the watch.
  Map<String, Object> contentKey() => Map.of(toMessage())..remove('at');
}
