import '../ports/clock.dart';
import '../ports/weather_provider.dart';

enum WeatherFreshness {
  /// Downloaded within [WeatherPolicy.freshFor].
  fresh,

  /// Older, but still shown with its age.
  stale,

  /// Too old to be treated as current; values are greyed out.
  expired,
}

/// Cache/staleness policy for weather data. Age is measured from the
/// download time; the provider's validity time is always shown separately.
abstract final class WeatherPolicy {
  static const freshFor = Duration(minutes: 30);
  static const staleFor = Duration(hours: 6);

  static Duration age(WeatherObservation o, Clock clock) {
    final d = clock.now().toUtc().difference(o.fetchedAt.toUtc());
    return d.isNegative ? Duration.zero : d;
  }

  static WeatherFreshness freshness(WeatherObservation o, Clock clock) {
    final a = age(o, clock);
    if (a <= freshFor) return WeatherFreshness.fresh;
    if (a <= staleFor) return WeatherFreshness.stale;
    return WeatherFreshness.expired;
  }

  /// Rounds a coordinate to 2 decimals (~1 km) for cache keys, so a precise
  /// position is never kept.
  static double roundCoordinate(double v) => (v * 100).round() / 100;

  /// Turkish text for an age, e.g. "12 dk önce", "3 sa 5 dk önce".
  static String ageText(Duration d) {
    if (d.inMinutes < 1) return 'şimdi';
    if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '$h sa önce' : '$h sa $m dk önce';
  }
}
