import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog_repository.dart';
import '../data/user_catalog.dart';
import 'manual_catalog_store.dart';
import 'user_catalog_store.dart';

class UserCatalogLoadResult {
  final UserCatalog catalog;

  /// Number of legacy (`user_catalog.v1`) records copied in this run.
  final int migrated;

  /// User-facing warning when something could not be read or copied. Data is
  /// never deleted on any path, so the warning always says so.
  final String? warning;
  const UserCatalogLoadResult({
    required this.catalog,
    this.migrated = 0,
    this.warning,
  });
}

/// Loads the personal catalog, migrates the older `UserCatalogStore` format
/// into `ManualCatalogStore` (copy only; the legacy key is never deleted or
/// rewritten), and installs the converted records into [CatalogRepository].
class UserCatalogLoader {
  final ManualCatalogStore manual;
  final UserCatalogStore legacy;

  /// Persists the migration ledger and reports whether it really was stored.
  /// Injectable so tests can simulate a failed write.
  final Future<bool> Function(SharedPreferences prefs, List<String> ids)
  _writeLedger;

  UserCatalogLoader({
    ManualCatalogStore? manual,
    UserCatalogStore? legacy,
    Future<bool> Function(SharedPreferences prefs, List<String> ids)?
    writeLedger,
  }) : manual = manual ?? ManualCatalogStore(),
       legacy = legacy ?? UserCatalogStore(),
       _writeLedger = writeLedger ?? _defaultWriteLedger;

  static Future<bool> _defaultWriteLedger(
    SharedPreferences prefs,
    List<String> ids,
  ) async {
    try {
      return await prefs.setStringList(migratedIdsKey, ids);
    } catch (_) {
      return false;
    }
  }

  /// Throws when the manual catalog itself cannot be read; in that case the
  /// previously installed personal catalog is left untouched.
  Future<UserCatalogLoadResult> load() async {
    var migrated = 0;
    String? warning;
    try {
      migrated = await migrateLegacy();
    } on LegacyMigrationIncomplete catch (e) {
      migrated = e.copied;
      warning =
          'Eski kişisel katalogdaki ${e.skipped} kayıt taşınamadı. '
          'Eski kayıtlar silinmedi.';
    } catch (_) {
      warning =
          'Eski kişisel katalog okunamadı; kayıtlar silinmedi ve '
          'taşınmadı.';
    }
    final items = await manual.all();
    final catalog = UserCatalog.fromManualEntries(items);
    CatalogRepository.installUserCatalog(catalog);
    return UserCatalogLoadResult(
      catalog: catalog,
      migrated: migrated,
      warning: warning,
    );
  }

  /// Ids of legacy records already copied (or already present). Kept so a
  /// record the user later deletes from the manual catalog is not resurrected
  /// by the next start-up migration.
  static const migratedIdsKey = 'sniper_turk.user_catalog.v1.migrated_ids';

  /// Copies every legacy record that has not been migrated before and whose
  /// id is not yet in the manual catalog. Idempotent. Returns the number
  /// copied; throws [LegacyMigrationIncomplete] when some could not be copied.
  ///
  /// Ordering matters for deletions: the ledger entry is persisted BEFORE the
  /// record is copied. If the ledger cannot be written, that record is not
  /// copied at all (reported as not migrated; the legacy record stays intact),
  /// so a record the user later deletes can never be copied back by a start-up
  /// migration whose ledger write had failed.
  Future<int> migrateLegacy() async {
    final old = await legacy.all();
    if (old.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final ledger = {...?prefs.getStringList(migratedIdsKey)};
    final existing = {for (final e in await manual.all()) e['id']};
    var copied = 0;
    var skipped = 0;

    Future<bool> persist() => _writeLedger(prefs, ledger.toList()..sort());

    for (final item in old) {
      final id = item['id'];
      if (id is! String || ledger.contains(id)) continue;
      if (existing.contains(id)) {
        // Already present: remember it so a later deletion is respected. If
        // that cannot be stored, say so instead of pretending it is safe.
        ledger.add(id);
        if (!await persist()) {
          ledger.remove(id);
          skipped++;
        }
        continue;
      }
      final converted = convertLegacy(item);
      if (converted == null) {
        skipped++;
        continue;
      }
      ledger.add(id);
      if (!await persist()) {
        ledger.remove(id);
        skipped++;
        continue;
      }
      try {
        await manual.upsert(converted);
        copied++;
      } on FormatException {
        ledger.remove(id);
        await persist(); // best effort: nothing was copied for this id
        skipped++;
      } catch (_) {
        ledger.remove(id);
        await persist();
        rethrow;
      }
    }
    if (skipped > 0) throw LegacyMigrationIncomplete(copied, skipped);
    return copied;
  }

  /// Maps one `UserCatalogStore` record to the `ManualCatalogStore` schema.
  /// Returns null for a kind that has no equivalent.
  static Map<String, dynamic>? convertLegacy(Map<String, dynamic> e) {
    final base = <String, dynamic>{
      'id': e['id'],
      'brand': e['brand'],
      'model': e['model'],
      'notes': '',
      'sourceName': userCatalogSourceName,
      'migratedFrom': UserCatalogStore.key,
    };
    switch (e['kind']) {
      case 'rifle':
        return {
          ...base,
          'kind': 'rifle',
          'platform': e['platform'],
          'caliberMm': e['caliberMm'],
          'barrelLengthMm': e['barrelLengthMm'],
          'airCapacityCc': e['airCapacityCc'],
        };
      case 'ammunition':
        return {
          ...base,
          'kind': 'ammo',
          'platform': e['platform'],
          'caliberMm': e['caliberMm'],
          'grain': e['grain'],
          'ammoType': e['type'],
        };
      case 'scope':
        return {
          ...base,
          'kind': 'scope',
          // ManualCatalogStore requires a platform on every record; optics are
          // listed for both platforms regardless of this value.
          'platform': 'pcp',
          'objectiveMm': e['objectiveDiameterMm'],
          'click': e['clickValue'],
          'clickUnit': e['clickUnit'],
        };
      default:
        return null;
    }
  }
}

class LegacyMigrationIncomplete implements Exception {
  final int copied;
  final int skipped;
  const LegacyMigrationIncomplete(this.copied, this.skipped);
  @override
  String toString() =>
      'LegacyMigrationIncomplete($copied copied, $skipped skipped)';
}
