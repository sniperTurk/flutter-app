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

  UserCatalogLoader({ManualCatalogStore? manual, UserCatalogStore? legacy})
    : manual = manual ?? ManualCatalogStore(),
      legacy = legacy ?? UserCatalogStore();

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
  Future<int> migrateLegacy() async {
    final old = await legacy.all();
    if (old.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final ledger = {...?prefs.getStringList(migratedIdsKey)};
    final existing = {for (final e in await manual.all()) e['id']};
    var copied = 0;
    var skipped = 0;
    var ledgerChanged = false;
    for (final item in old) {
      final id = item['id'];
      if (id is! String || ledger.contains(id)) continue;
      if (existing.contains(id)) {
        ledger.add(id);
        ledgerChanged = true;
        continue;
      }
      final converted = convertLegacy(item);
      if (converted == null) {
        skipped++;
        continue;
      }
      try {
        await manual.upsert(converted);
      } on FormatException {
        skipped++;
        continue;
      }
      copied++;
      ledger.add(id);
      ledgerChanged = true;
    }
    if (ledgerChanged) {
      // A failed ledger write only means the copy may be attempted again; the
      // id check above then skips it, so no duplicate can appear.
      await prefs.setStringList(migratedIdsKey, ledger.toList()..sort());
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
