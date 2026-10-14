// Tolerant matching of a saved Tüfek / Dürbün to the built-in lists (owner,
// 2026-10-14: "Sayfalar son yaptığımız düzenleme ile açılsın"). Profiles
// saved before the 13 Oct catalog update (#235) carry names that no longer
// equal the list names letter for letter ("GEN2" / "Gen 2", a series name
// that moved, a brand written together). The exact rules in the editor run
// first and are unchanged; this is only the fallback when they find nothing.
//
// Only the page's list choice is derived from a match: the saved values
// (büyütme, mercek çapı, kalibre, yiv) stay as they were saved.
import '../../data/reticle_catalog.dart';
import '../../data/rifle_library.dart';
import '../../models/domain.dart';

abstract final class ProfileCatalogMatch {
  /// Lower case words of [text] ("Viper PST Gen II" -> viper, pst, gen,
  /// ii); a decimal comma is read as a point.
  static List<String> words(String text) => [
    for (final w
        in text
            .toLowerCase()
            .replaceAll(',', '.')
            .split(RegExp(r'[^a-z0-9çğıöşü.]+')))
      if (w.replaceAll('.', '').isNotEmpty)
        w.replaceAll(RegExp(r'^\.+|\.+$'), ''),
  ];

  /// Letters and digits only: "Gazi Sniper" and "GaziSniper" are equal.
  static String squash(String text) => words(text).join().replaceAll('.', '');

  /// "5-25x56", "6–36×56", "4,5-29x56i", "10x42": the designation the
  /// numeric checks already compare.
  static final RegExp _designation = RegExp(
    r'\d+(?:[.,]\d+)?\s*(?:[–-]\s*\d+(?:[.,]\d+)?\s*)?[×xX]\s*\d+(?:[.,]\d+)?\w*',
  );

  static const _focalWords = {'ffp', 'sfp'};

  /// [saved] brand is the catalog [brand] (written together, with an extra
  /// word such as "Optics", or with the series after it).
  static bool brandMatches(String saved, String brand) {
    final s = squash(saved), b = squash(brand);
    if (s.isEmpty || b.length < 3) return false;
    if (s == b || s.startsWith(b)) return true;
    final sw = words(saved), bw = words(brand);
    return sw.isNotEmpty &&
        bw.isNotEmpty &&
        sw.first.length >= 3 &&
        sw.first == bw.first;
  }

  /// Saved words found in the candidate (also inside a joined word:
  /// "gen2" covers "gen" and "2").
  static int _covered(List<String> saved, List<String> cand) {
    final joined = cand.join().replaceAll('.', '');
    var n = 0;
    for (final w in saved) {
      if (cand.contains(w) || joined.contains(w.replaceAll('.', ''))) n++;
    }
    return n;
  }

  static List<String> _nameWords(String text, String brand) {
    final drop = {...words(brand), ..._focalWords};
    return [
      for (final w in words(text.replaceAll(_designation, ' ')))
        if (!drop.contains(w)) w,
    ];
  }

  static bool _same(double? a, double? b, double tol) =>
      a == null || b == null || (a - b).abs() <= tol;

  /// The catalog scope a saved (typed) scope stands for, or null.
  ///
  /// Brand first, then the series / model words, then büyütme, mercek çapı,
  /// odak düzlemi and birim must agree. [modelOf] gives the list's Model
  /// (the catalog name without its reticle). Two different models that fit
  /// equally well give null: nothing is chosen silently.
  static ScopeOptic? scope(
    ScopeOptic saved,
    List<ScopeOptic> lib,
    String Function(ScopeOptic) modelOf,
  ) {
    if (saved.maxMagnification == null) return null;
    final savedText = '${saved.brand} ${saved.model}';
    final hits =
        <({ScopeOptic s, String key, double score, int extra, bool reticle})>[];
    for (final r in lib) {
      if (!brandMatches(saved.brand, r.brand)) continue;
      if (r.maxMagnification == null) continue;
      if (!_same(saved.minMagnification, r.minMagnification, 0.01) ||
          !_same(saved.maxMagnification, r.maxMagnification, 0.01)) {
        continue;
      }
      if (saved.objectiveDiameterMm > 0 &&
          r.objectiveDiameterMm > 0 &&
          (saved.objectiveDiameterMm - r.objectiveDiameterMm).abs() > 0.5) {
        continue;
      }
      if (saved.firstFocalPlane != null &&
          r.firstFocalPlane != null &&
          saved.firstFocalPlane != r.firstFocalPlane) {
        continue;
      }
      if (saved.clickUnit != r.clickUnit) continue;
      final mine = _nameWords(savedText, r.brand);
      final theirs = _nameWords('${r.brand} ${r.model}', r.brand);
      final covered = _covered(mine, theirs);
      // No series word saved (an older record kept only the brand): the
      // numbers decide, if they point at one model only.
      final score = mine.isEmpty ? 0.0 : covered / mine.length;
      if (mine.isNotEmpty && score < 0.5) continue;
      final reticles = ReticleCatalog.options(r.reticle);
      hits.add((
        s: r,
        key: '${r.brand}|${modelOf(r)}',
        score: score,
        extra: theirs.length - covered,
        reticle: saved.reticle != null && reticles.contains(saved.reticle),
      ));
    }
    if (hits.isEmpty) return null;
    final first = hits.first.key;
    if (hits.every((h) => h.score == 0) && hits.any((h) => h.key != first)) {
      return null;
    }
    hits.sort((a, b) {
      final s = b.score.compareTo(a.score);
      if (s != 0) return s;
      if (a.reticle != b.reticle) return a.reticle ? -1 : 1;
      return a.extra.compareTo(b.extra);
    });
    final best = hits.first;
    for (final h in hits.skip(1)) {
      if (h.key == best.key) continue;
      if (h.score == best.score &&
          h.reticle == best.reticle &&
          h.extra == best.extra) {
        return null;
      }
      break;
    }
    // Same model, several reticles: the saved reticle's record.
    return hits.where((h) => h.key == best.key && h.reticle).firstOrNull?.s ??
        best.s;
  }

  /// The list rifle (Marka / Model) a saved rifle stands for, or null.
  ///
  /// Brand first, then the model words (one name holding the other, or
  /// most words shared), then the saved caliber. Two models that fit
  /// equally well give null.
  static LibraryRifle? rifle(
    String brand,
    String model,
    double? caliberMm,
    List<LibraryRifle> lib,
  ) {
    if (squash(model).isEmpty) return null;
    final hits = <({LibraryRifle r, bool exact, double f1, bool caliber})>[];
    final seen = <String>{};
    for (final r in lib) {
      if (!brandMatches(brand, r.brand)) continue;
      if (!seen.add('${r.brand}|${r.model}')) continue;
      final mine = _nameWords(model, r.brand);
      final theirs = _nameWords(r.model, r.brand);
      if (mine.isEmpty || theirs.isEmpty) continue;
      final exact = squash(mine.join(' ')) == squash(theirs.join(' '));
      final a = _covered(mine, theirs), b = _covered(theirs, mine);
      final f1 = (a + b) / (mine.length + theirs.length);
      if (!exact && a < mine.length && b < theirs.length && f1 < 0.67) {
        continue;
      }
      final caliber =
          caliberMm != null &&
          lib.any(
            (v) =>
                v.brand == r.brand &&
                v.model == r.model &&
                (v.diameterMm - caliberMm).abs() < 0.005,
          );
      hits.add((r: r, exact: exact, f1: f1, caliber: caliber));
    }
    if (hits.isEmpty) return null;
    // A model with the saved caliber goes before one without it.
    final pool = hits.any((h) => h.caliber)
        ? hits.where((h) => h.caliber).toList()
        : hits;
    pool.sort((a, b) {
      if (a.exact != b.exact) return a.exact ? -1 : 1;
      return b.f1.compareTo(a.f1);
    });
    final best = pool.first;
    if (pool.length > 1) {
      final next = pool[1];
      if (next.exact == best.exact && next.f1 == best.f1) return null;
    }
    return best.r;
  }
}
