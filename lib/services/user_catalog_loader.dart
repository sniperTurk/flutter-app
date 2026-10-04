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

  /// Ledger entries share one string list so every state change is a single
  /// write: a bare id means "copied and confirmed"; `pending:<id>` means "copy
  /// started, not confirmed". A pending id is never treated as migrated unless
  /// the record is really present in the manual catalog.
  static const _pendingPrefix = 'pending:';

  /// Copies every legacy record that has not been migrated before. Idempotent.
  /// Returns the number copied; throws [LegacyMigrationIncomplete] when some
  /// could not be copied. Legacy records are never deleted.
  ///
  /// Interruption safety (kill, crash or failed write at any point):
  ///  * intent (`pending:<id>`) is persisted BEFORE the copy; if that write
  ///    fails nothing is copied;
  ///  * after the copy the entry becomes a confirmed id in one write; if that
  ///    write fails the fresh copy is removed again, so state is "not copied";
  ///  * on the next start a pending id whose record is present is confirmed
  ///    (copy had happened), and one whose record is absent is simply copied
  ///    again (copy had not happened). A record can therefore neither be lost
  ///    nor copied back after a user deleted it.
  /// A record the user deletes is additionally recorded by
  /// [ManualCatalogStore.remove] (before the removal happens), and such ids are
  /// never copied again, even if the ledger could not be written at all.
  Future<int> migrateLegacy() async {
    final old = await legacy.all();
    if (old.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(migratedIdsKey) ?? const <String>[];
    final done = <String>{
      for (final e in stored)
        if (!e.startsWith(_pendingPrefix)) e,
    };
    final pending = <String>{
      for (final e in stored)
        if (e.startsWith(_pendingPrefix)) e.substring(_pendingPrefix.length),
    };
    final existing = {for (final e in await manual.all()) e['id']};
    final removed = await manual.removedIds();
    var copied = 0;
    var skipped = 0;

    Future<bool> persist() => _writeLedger(prefs, [
      ...(done.toList()..sort()),
      ...(pending.toList()..sort()).map((id) => '$_pendingPrefix$id'),
    ]);

    for (final item in old) {
      final id = item['id'];
      if (id is! String || done.contains(id)) continue;
      if (removed.contains(id) && !existing.contains(id)) {
        // The user deleted this record. Never copy it back, whatever state the
        // ledger is in (including a pending id left by an interruption).
        done.add(id);
        pending.remove(id);
        await persist(); // best effort: the deletion record already protects it
        continue;
      }
      if (existing.contains(id)) {
        // Present in the manual catalog: confirm it so a later deletion is
        // respected. If that cannot be stored, report instead of trusting.
        done.add(id);
        final wasPending = pending.remove(id);
        if (!await persist()) {
          done.remove(id);
          if (wasPending) pending.add(id);
          skipped++;
        }
        continue;
      }
      final converted = convertLegacy(item);
      if (converted == null) {
        skipped++;
        continue;
      }
      // 1. Record the intent first; without it nothing is copied.
      pending.add(id);
      if (!await persist()) {
        pending.remove(id);
        skipped++;
        continue;
      }
      // 2. Copy.
      try {
        await manual.upsert(converted);
      } on FormatException {
        pending.remove(id);
        await persist(); // best effort: nothing was copied for this id
        skipped++;
        continue;
      } catch (_) {
        pending.remove(id);
        await persist(); // best effort; a stale pending id is harmless
        rethrow;
      }
      // 3. Confirm in one write; otherwise undo the copy.
      pending.remove(id);
      done.add(id);
      if (await persist()) {
        copied++;
        continue;
      }
      done.remove(id);
      pending.add(id);
      try {
        await manual.discardUnconfirmedCopy(id);
      } catch (_) {
        // Could not undo: the pending id stays; start-up confirms it because
        // the record is present, so nothing is duplicated or lost.
      }
      skipped++;
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
