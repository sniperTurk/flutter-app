/// Wind direction as a clock face, as used by ChairGun, Strelok and Kestrel:
/// the target is at 12, and the hour says where the wind COMES FROM.
/// 12 = from the front (headwind), 3 = from the right, 6 = from behind,
/// 9 = from the left.
///
/// The solver's degrees are: 0 = headwind, 90 = from the left, 180 =
/// tailwind, 270 = from the right. So hour h ↔ (360 − 30·h) mod 360.
abstract final class WindClock {
  /// Solver degrees for clock hour [hour] (1…12).
  static double toDegrees(int hour) {
    if (hour < 1 || hour > 12) {
      throw ArgumentError.value(hour, 'hour', 'must be 1…12');
    }
    return ((360 - hour * 30) % 360).toDouble();
  }

  /// Nearest clock hour (1…12) for solver [degrees].
  static int fromDegrees(double degrees) {
    final d = degrees % 360;
    final h = ((360 - d) / 30).round() % 12;
    return h == 0 ? 12 : h;
  }

  /// Where the wind comes from, in plain Turkish.
  static String side(int hour) => switch (hour) {
    12 => 'karşıdan',
    6 => 'arkadan',
    3 => 'sağdan',
    9 => 'soldan',
    1 || 2 => 'sağ önden',
    4 || 5 => 'sağ arkadan',
    7 || 8 => 'sol arkadan',
    _ => 'sol önden',
  };
}
