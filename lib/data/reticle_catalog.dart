import '../core/reticle.dart';
import '../models/domain.dart';
import 'reticle_library.dart';

/// Finds the manufacturer-sourced drawing of a scope's reticle
/// (owner, 2026-10-11): the reticle name chosen in Profil → Dürbün →
/// Retikül and the scope's brand pick a [ReticleData] record from
/// [ReticleLibrary]; without a record, or when the record is too
/// incomplete to draw, the generic grid of [Reticles.forName] is used.
abstract final class ReticleCatalog {
  /// Words that name no reticle: focal plane, illumination, glass.
  static const _noise = {
    'FFP',
    'SFP',
    'IR',
    'F1',
    'ILLUMINATED',
    'RETICLE',
    'ETCHED',
    'GLASS',
  };
  static const _units = {
    'MIL': 'mil',
    'MILS': 'mil',
    'MRAD': 'mil',
    'MOA': 'moa',
  };

  /// Words of a brand without "Optics": "Athlon Optics" and "Athlon" are
  /// the same brand.
  static List<String> brandWords(String brand) => [
    for (final w in brand.toLowerCase().split(RegExp(r'[^a-z0-9]+')))
      if (w.isNotEmpty && w != 'optics' && w != 'optic') w,
  ];

  /// True when the scope's brand is [dataBrand]. A scope picked from the
  /// list is saved with its series after the brand ("Athlon CRONUS BTR
  /// GEN2 UHD IR MIL"), so the data brand's words must lead it.
  static bool brandMatches(String dataBrand, String scopeBrand) {
    final d = brandWords(dataBrand), s = brandWords(scopeBrand);
    if (d.isEmpty || s.length < d.length) return false;
    for (var i = 0; i < d.length; i++) {
      if (d[i] != s[i]) return false;
    }
    return true;
  }

  /// Reticle names of a scope record: "VPR-MIL / VHR-MIL" is two,
  /// "30/30" one (only a spaced slash separates names). A focal plane alone
  /// is not a reticle, and a trailing "options" ("MIL-C / MIL-XT options")
  /// names none.
  static List<String> options(String? reticle) => [
    for (final part in (reticle ?? '').split(RegExp(r'\s+/\s+')))
      if (_option(part).isNotEmpty &&
          !const {'FFP', 'SFP'}.contains(_option(part)))
        _option(part),
  ];

  static String _option(String part) => part
      .trim()
      .replaceFirst(RegExp(r'\s+options$', caseSensitive: false), '')
      .trim();

  /// A focal-plane or unit word glued to the last part of a hyphenated
  /// designation: "VCT-34FFP", "VEPG-TMIL".
  static final _glued = RegExp(
    r'^(.*-[A-Z0-9]*?[A-Z0-9])(FFP|SFP|MILS|MIL|MRAD|MOA)$',
  );

  /// The reticle's own designation without unit and focal-plane words
  /// ("APRS14 FFP IR MIL" → APRS14, "TOR-MIL" → TOR, "VCT-34FFP" → VCT34)
  /// and the unit the name states ('mil', 'moa' or null). "+" is part of
  /// the name: SKMR4+ is not SKMR4.
  static ({String core, String? unit}) nameKey(String name) {
    String? unit;
    final core = StringBuffer();
    for (var t in name.toUpperCase().split(RegExp(r'[\s(),/]+'))) {
      if (t.isEmpty || _noise.contains(t)) continue;
      final u = _units[t];
      if (u != null) {
        unit = u;
        continue;
      }
      final suffix = RegExp(r'^(.+?)-(MIL|MILS|MRAD|MOA)$').firstMatch(t);
      if (suffix != null) {
        unit = _units[suffix.group(2)!];
        t = suffix.group(1)!;
      }
      for (var g = _glued.firstMatch(t); g != null; g = _glued.firstMatch(t)) {
        t = g.group(1)!;
        unit = _units[g.group(2)!] ?? unit;
      }
      t = t.replaceAll('+', 'PLUS');
      core.write(t.replaceAll(RegExp(r'[^A-Z0-9]'), ''));
    }
    return (core: core.toString(), unit: unit);
  }

  static List<String> _words(String text) => [
    for (final w in text.toLowerCase().split(RegExp(r'[^a-z0-9]+')))
      if (w.isNotEmpty) w,
  ];

  /// True when one of [record]'s manufacturer scope series stands in the
  /// scope's brand and model words ("Helos BTR GEN2" in "HELOS BTR GEN2
  /// 6-24x56 …").
  static bool namesScope(ReticleData record, String brand, String? model) {
    final words = _words('$brand ${model ?? ''}');
    for (final entry in record.scopes) {
      final e = _words(entry);
      if (e.isEmpty) continue;
      for (var i = 0; i + e.length <= words.length; i++) {
        var all = true;
        for (var j = 0; j < e.length && all; j++) {
          all = words[i + j] == e[j];
        }
        if (all) return true;
      }
    }
    return false;
  }

  static final _code = RegExp(r'^[A-Z]{2,}[A-Z0-9]*-[A-Z0-9]+$');

  /// Manufacturer product codes in parentheses of [record]'s scope list:
  /// "Continental x10 1-10x28 ED FFP (SCFF-68, SCFF-47)".
  static List<String> productCodes(ReticleData record) => [
    for (final entry in record.scopes)
      for (final group in RegExp(r'\(([^)]*)\)').allMatches(entry))
        for (final c in group.group(1)!.split(RegExp(r'[\s,]+')))
          if (_code.hasMatch(c)) c,
  ];

  /// True when one of [record]'s product codes stands whole in the scope's
  /// [source] document ("…-SCOM-T39.html"; SCOM-39 is not it).
  static bool listsProduct(ReticleData record, String? source) {
    if (source == null || source.isEmpty) return false;
    for (final c in productCodes(record)) {
      final whole = RegExp(
        '(?<![A-Za-z0-9])${RegExp.escape(c)}(?![A-Za-z0-9])',
      );
      if (whole.hasMatch(source)) return true;
    }
    return false;
  }

  /// The data record for [name] on a [brand] scope, or null. Never
  /// guesses: a name listing several reticles, a record in the other unit
  /// than the turret, or two records it cannot tell apart give null.
  ///
  /// Product code (owner, 2026-10-12): when no record has the name in the
  /// turret unit, the one record of the brand and turret unit whose
  /// manufacturer scope list names the scope's product code from its
  /// [source] document is used ("VTC-10A" on SCOM-T39 → VCT-10A MIL,
  /// which Vector lists for SCOM-T39).
  static ReticleData? find(
    String? name,
    AngularUnit turretUnit, {
    String? brand,
    String? model,
    String? source,
    List<ReticleData> library = ReticleLibrary.all,
  }) {
    final byName = _findByName(
      name,
      turretUnit,
      brand: brand,
      model: model,
      library: library,
    );
    if (byName.record != null || !byName.tryCode) return byName.record;
    final turret = turretUnit.moaFamily ? 'moa' : 'mil';
    final coded = [
      for (final r in library)
        if (r.unit == turret &&
            brandMatches(r.brand, brand!) &&
            listsProduct(r, source))
          r,
    ];
    return coded.length == 1 ? coded.single : null;
  }

  /// [find] by name only; tryCode is true when the name found no record
  /// in the turret unit (none at all, only another brand's, or only the
  /// other unit's) and does not itself state the other unit.
  static ({ReticleData? record, bool tryCode}) _findByName(
    String? name,
    AngularUnit turretUnit, {
    String? brand,
    String? model,
    required List<ReticleData> library,
  }) {
    const none = (record: null, tryCode: false);
    if (name == null || brand == null) return none;
    if (options(name).length != 1) return none;
    final key = nameKey(name);
    final turret = turretUnit.moaFamily ? 'moa' : 'mil';
    if (key.unit != null && key.unit != turret) return none;
    if (key.core.isEmpty) return none;
    var hits = [
      for (final r in library)
        if (r.unit == turret &&
            brandMatches(r.brand, brand) &&
            nameKey(r.name).core == key.core)
          r,
    ];
    if (hits.length > 1) {
      // Same name twice (with and without illumination): the record whose
      // manufacturer scope list names this scope, if exactly one does.
      final named = [
        for (final r in hits)
          if (namesScope(r, brand, model)) r,
      ];
      if (named.length == 1) hits = named;
    }
    if (hits.isEmpty) return (record: null, tryCode: true);
    return (record: hits.length == 1 ? hits.single : null, tryCode: false);
  }

  /// The reticle to draw on the Hedef screen: the scope's own reticle from
  /// its data when it is drawable, else the generic grid for the name.
  static ReticleSpec? forScope(
    String? name,
    AngularUnit turretUnit, {
    String? brand,
    String? model,
    String? source,
  }) {
    if (name == null || name.trim().isEmpty) return null;
    if (!Reticles.genericNames.contains(name)) {
      final spec = find(
        name,
        turretUnit,
        brand: brand,
        model: model,
        source: source,
      )?.toSpec(displayName: name);
      if (spec != null) return spec;
    }
    return Reticles.forName(name, turretUnit);
  }
}
