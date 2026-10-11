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

  /// The reticle's own designation without unit and focal-plane words
  /// ("APRS14 FFP IR MIL" → APRS14, "TOR-MIL" → TOR) and the unit the name
  /// states ('mil', 'moa' or null).
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
      core.write(t.replaceAll(RegExp(r'[^A-Z0-9]'), ''));
    }
    return (core: core.toString(), unit: unit);
  }

  /// The data record for [name] on a [brand] scope, or null. Never picks
  /// between two records it cannot tell apart.
  static ReticleData? find(
    String? name,
    AngularUnit turretUnit, {
    String? brand,
    List<ReticleData> library = ReticleLibrary.all,
  }) {
    if (name == null || brand == null) return null;
    final key = nameKey(name);
    if (key.core.isEmpty) return null;
    var hits = [
      for (final r in library)
        if (brandMatches(r.brand, brand) && nameKey(r.name).core == key.core) r,
    ];
    if (key.unit != null) {
      hits = [
        for (final r in hits)
          if (r.unit == key.unit) r,
      ];
    } else if (hits.length > 1) {
      final turret = turretUnit.moaFamily ? 'moa' : 'mil';
      hits = [
        for (final r in hits)
          if (r.unit == turret) r,
      ];
    }
    return hits.length == 1 ? hits.single : null;
  }

  /// The reticle to draw on the Hedef screen: the scope's own reticle from
  /// its data when it is drawable, else the generic grid for the name.
  static ReticleSpec? forScope(
    String? name,
    AngularUnit turretUnit, {
    String? brand,
  }) {
    if (name == null || name.trim().isEmpty) return null;
    if (!Reticles.genericNames.contains(name)) {
      final spec = find(
        name,
        turretUnit,
        brand: brand,
      )?.toSpec(displayName: name);
      if (spec != null) return spec;
    }
    return Reticles.forName(name, turretUnit);
  }
}
