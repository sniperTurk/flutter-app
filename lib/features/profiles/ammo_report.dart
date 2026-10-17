/// "Aradığın mühimmat listede yok mu?" (owner, 2026-10-17 21:33–21:51
/// Istanbul): what is sent when the user taps Gönder. Only the text the
/// user typed, the rifle type and the Kalibre shown on the Tüfek card; no
/// profile values, location or device identifiers.
library;

/// The text box takes at most this many characters (the worker accepts
/// 200 per value).
const int ammoReportMaxLength = 200;

/// Version of the app in the report: "1.0.0+<TestFlight build>". The build
/// number comes from the TestFlight build (`--dart-define=APP_BUILD_NUMBER`,
/// the same number TestFlight shows); other builds say "dev".
const String appVersionName = '1.0.0';
const String _appBuildNumber = String.fromEnvironment('APP_BUILD_NUMBER');
String get appVersionText =>
    '$appVersionName+${_appBuildNumber.isEmpty ? 'dev' : _appBuildNumber}';

const double _grainPerGram = 15.4323584;

/// Last "<number> <unit>" of [text] (comma or dot decimals): "gr", "gr.",
/// "grain(s)", "grn" read as grain; "g", "gram(s)" as grams, converted to
/// grain. Anything else (no unit, another unit, no number) reads as null.
/// Best effort only: it never blocks sending.
({double? grain, String? unit}) readWeightGrain(String text) {
  final matches = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(grains?|grams?|grn|gr\.?|g)(?![\p{L}\d])',
    caseSensitive: false,
    unicode: true,
  ).allMatches(text);
  if (matches.isEmpty) return (grain: null, unit: null);
  final m = matches.last;
  final value = double.tryParse(m.group(1)!.replaceAll(',', '.'));
  if (value == null || !value.isFinite) return (grain: null, unit: null);
  final u = m.group(2)!.toLowerCase();
  final gram = u == 'g' || u.startsWith('gram');
  final grain = gram ? value * _grainPerGram : value;
  return (grain: (grain * 100).roundToDouble() / 100, unit: gram ? 'g' : 'gr');
}

/// The JSON body for the catalog inbox (`tur` "muhimmat").
Map<String, Object?> ammoReportBody({
  required String text,
  required bool firearm,
  required String? caliber,
  required String appVersion,
}) {
  final w = readWeightGrain(text);
  return {
    'tur': 'muhimmat',
    'platform': 'ios',
    'uygulamaSurumu': appVersion,
    'kurulumKimligi': null,
    'alanlar': {
      'metin': text,
      'silah': firearm ? 'atesli' : 'pcp',
      'kalibre': caliber,
      'okunanAgirlikGr': w.grain,
      'okunanBirim': w.unit,
    },
  };
}
