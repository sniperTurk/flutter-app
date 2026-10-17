import '../../tools/ports/weather_provider.dart';

/// Rüzgâr card note (owner, 2026-10-17 20:40/20:44): the fetched wind as
/// the service gave it, for the shooter to set the clock by hand. The
/// direction is NOT turned into a clock hour and the shot azimuth is not
/// used: "<Kaynak> rüzgâr verisi (HH:MM): <yön>dan, <derece>°, <hız> m/s.
/// Rüzgâr yönünü siz seçin."
String windSourceNote(WeatherObservation o) {
  final t = o.validAt.toLocal();
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  final deg = windNoteDegrees(o.windFromDeg);
  final speed = o.windSpeedMps.toStringAsFixed(1).replaceAll('.', ',');
  return '${windNoteSourceLabel(o)} rüzgâr verisi ($hh:$mm): '
      '${turkishWindFrom(deg.toDouble())}, $deg°, $speed m/s. '
      'Rüzgâr yönünü siz seçin.';
}

/// "Google", "MET Norway", or the provider's own name.
String windNoteSourceLabel(WeatherObservation o) => switch (o.source) {
  WeatherSource.google => 'Google',
  WeatherSource.metNorway => 'MET Norway',
  WeatherSource.other => o.sourceName,
};

/// Whole degrees in [0, 360): 359,6° → 0°.
int windNoteDegrees(double fromDeg) {
  if (!fromDeg.isFinite) return 0;
  return fromDeg.round() % 360;
}

/// The 8-point Turkish name, with its ablative suffix, of the direction the
/// wind blows FROM (45° sectors centred on north, north-east, …).
String turkishWindFrom(double fromDeg) {
  const names = [
    'kuzeyden',
    'kuzeydoğudan',
    'doğudan',
    'güneydoğudan',
    'güneyden',
    'güneybatıdan',
    'batıdan',
    'kuzeybatıdan',
  ];
  final d = fromDeg.isFinite ? fromDeg % 360 : 0.0;
  return names[((d + 22.5) / 45).floor() % 8];
}
