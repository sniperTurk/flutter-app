import '../ports/weather_provider.dart';

/// Google first, MET Norway when Google gives nothing usable (owner,
/// 2026-10-17 20:37: "Google cevap vermezse bugünkü gibi MET Norway'den
/// alınsın"). No key, no network, a non-200 answer, a timeout or invalid
/// data from [primary] → [secondary], called exactly as before. The
/// observation keeps its own [WeatherObservation.source], so the page can
/// say which service was used. When both fail, [secondary]'s failure is
/// what the page reports (the same messages as before this change).
class FallbackWeatherProvider implements WeatherProvider {
  final WeatherProvider primary;
  final WeatherProvider secondary;

  const FallbackWeatherProvider(this.primary, this.secondary);

  @override
  String get sourceName => '${primary.sourceName} ya da ${secondary.sourceName}';

  @override
  Future<WeatherObservation> fetch(double latitude, double longitude) async {
    try {
      return await primary.fetch(latitude, longitude);
    } catch (_) {
      // Any primary failure (typed or not) falls through to the secondary.
    }
    return secondary.fetch(latitude, longitude);
  }
}
