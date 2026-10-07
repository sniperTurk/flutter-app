// dart format off
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'serial_mutation_lock.dart';

/// User-owned catalog entries; never merged into manufacturer-verified records.
class ManualCatalogStore {
  static const key = 'sniper_turk.manual_catalog.v1';
  static const backupKey = 'sniper_turk.manual_catalog.v1.backup';
  // Zone-independent process-wide lock (see SerialMutationLock).
  static final SerialMutationLock _mutationLock = SerialMutationLock();

  Future<T> _enqueueMutation<T>(Future<T> Function() operation) =>
      _mutationLock.run(operation);

  static List<Map<String, dynamic>> _decodeAndValidate(String raw) {
    final parsed = jsonDecode(raw);
    if (parsed is! List) throw const FormatException('Invalid manual catalog');
    return parsed.map((e) {
      if (e is! Map) {
        throw const FormatException('Invalid manual catalog item');
      }
      final item = Map<String, dynamic>.from(e);
      _validateEntry(item);
      return item;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _read({bool repairPrimary = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        return _decodeAndValidate(raw);
      } on FormatException {
        // Fall through to the validated backup path.
      }
    }

    final backup = prefs.getString(backupKey);
    if (raw == null && backup == null) return [];
    if (backup == null) {
      throw StateError('Manual catalog corrupt; backup missing');
    }
    final recovered = _decodeAndValidate(backup);
    if (repairPrimary && !await prefs.setString(key, backup)) {
      throw StateError('Manual catalog recovery write failed');
    }
    return recovered;
  }

  Future<List<Map<String, dynamic>>> all() async {
    // Healthy reads stay lock-free. Recovery writes are serialized with
    // upsert/remove and re-read storage only after entering the queue, so an
    // older backup can never overwrite a newer concurrent mutation.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        return _decodeAndValidate(raw);
      } on FormatException {
        // Recovery below.
      }
    } else if (prefs.getString(backupKey) == null) {
      return [];
    }
    return _enqueueMutation(() => _read(repairPrimary: true));
  }

  static Map<String, dynamic> _snapshotEntry(Map<String, dynamic> entry) {
    // Map.from() is only shallow; nested caller-owned maps/lists would remain
    // mutable after upsert() crossed the asynchronous queue boundary. Detach the
    // complete JSON-persistable value graph before validation/persistence.
    final decoded = jsonDecode(jsonEncode(entry));
    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<void> upsert(Map<String, dynamic> entry) {
    _validateEntry(entry);
    final snapshot = _snapshotEntry(entry);
    _validateEntry(snapshot);
    return _mutate((items) {
      // Revalidate inside the mutation boundary as a defense-in-depth contract.
      _validateEntry(snapshot);
      items.removeWhere((e) => e['id'] == snapshot['id']);
      items.add(snapshot);
    });
  }
  static void _validateEntry(Map<String, dynamic> entry) {
    final kind = entry['kind'];
    final platform = entry['platform'];
    if (!{'rifle', 'ammo', 'scope', 'custom_ammunition'}.contains(kind) ||
        !{'pcp', 'firearm'}.contains(platform)) {
      throw const FormatException('Invalid manual catalog item');
    }
    // Keep persisted identity fields aligned with UserCatalogStore and the UI.
    // In particular, a whitespace-only brand previously passed this boundary,
    // and unbounded strings could inflate SharedPreferences payloads.
    for (final field in ['id', 'brand', 'model']) {
      final value = entry[field];
      // Custom (home-made) ammunition has no manufacturer: the dialog validator
      // deliberately lets the brand stay empty, so an empty brand is valid only
      // for that kind. Without this exception the record could not be saved and
      // an already-stored one would make the whole catalog unreadable.
      final mayBeEmpty = field == 'brand' && kind == 'custom_ammunition';
      if (value is! String ||
          (!mayBeEmpty && value.trim().isEmpty) ||
          value.length > 100) {
        throw FormatException('Invalid identity field: $field');
      }
    }
    if (kind == 'ammo' || kind == 'custom_ammunition') {
      final ammoType = entry['ammoType'];
      if (!{'pellet', 'slug', 'bullet'}.contains(ammoType) ||
          (platform == 'firearm' && ammoType != 'bullet') ||
          (platform == 'pcp' && ammoType == 'bullet')) {
        throw const FormatException('Invalid ammunition type for platform');
      }
    }
    // UI validation is not a persistence boundary: imported/migrated or
    // programmatically-created standard records must carry the same required
    // ballistic identity fields as records created by the dialog. Custom
    // ammunition intentionally remains permissive because its workflow allows
    // partial user measurements.
    if (kind != 'scope' && kind != 'custom_ammunition' && entry['caliberMm'] == null) {
      throw const FormatException('Caliber is required for standard rifle/ammunition records');
    }
    if (kind == 'ammo' && entry['grain'] == null) {
      throw const FormatException('Grain is required for standard ammunition records');
    }
    // Optional on older records; when present it must be a known unit. Scopes
    // without it stay stored but cannot be selected in a profile.
    final clickUnit = entry['clickUnit'];
    if (clickUnit != null && clickUnit != 'mrad' && clickUnit != 'moa') {
      throw const FormatException('Invalid click unit');
    }
    final twist = entry['twistDirection'];
    if (twist != null && twist != 'right' && twist != 'left') {
      throw const FormatException('Invalid twist direction');
    }
    for (final field in ['caliberMm', 'grain', 'diameterMm', 'lengthMm', 'bc', 'objectiveMm', 'click', 'twistRateIn']) {
      final value = entry[field];
      if (value != null && (value is! num || !value.isFinite || value <= 0)) {
        throw FormatException('Invalid numeric field: $field');
      }
    }
  }

  /// Ids the user deleted. Written BEFORE the record is removed (and removal is
  /// refused when it cannot be written), so a start-up legacy migration can
  /// never copy a deleted record back, whatever state its own ledger is in.
  static const removedKey = 'sniper_turk.manual_catalog.v1.removed_ids';

  Future<Set<String>> removedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return {...?prefs.getStringList(removedKey)};
  }

  Future<void> remove(String id) => _mutate((items) {
    items.removeWhere((e) => e['id'] == id);
  }, tombstone: id);

  /// Removes a record WITHOUT recording a user deletion. Only for undoing a
  /// copy that the migration made itself and could not confirm.
  Future<void> discardUnconfirmedCopy(String id) => _mutate((items) {
    items.removeWhere((e) => e['id'] == id);
  });

  Future<void> _mutate(
    void Function(List<Map<String, dynamic>>) change, {
    String? tombstone,
  }) =>
      _enqueueMutation(() async {
      final prefs = await SharedPreferences.getInstance();
      if (tombstone != null) {
        final removed = {...?prefs.getStringList(removedKey), tombstone};
        if (!await prefs.setStringList(removedKey, removed.toList()..sort())) {
          throw StateError('Removal could not be recorded; nothing was deleted');
        }
      }
      // Already inside the mutation queue: read privately to avoid recursively
      // enqueueing recovery and deadlocking on the same process-wide tail.
      final items = await _read();
      // Snapshot the validated state, never a corrupt primary payload.
      final previousSnapshot = jsonEncode(items);
      change(items);
      final old = prefs.getString(key);
      final previousBackup = prefs.getString(backupKey);
      final encoded = jsonEncode(items);
      // Keep a recoverable snapshot even on the very first user-created entry.
      // Previously the first write had no backup at all, so a later corrupt
      // primary value could not be recovered. On subsequent mutations the
      // backup intentionally remains the last known-good primary snapshot.
      // If primary disappeared, preserve the existing recoverable backup.
      // If primary was corrupt, snapshot the recovered, validated entries.
      final backupSnapshot = old == null && prefs.getString(backupKey) == null
          ? encoded
          : previousSnapshot;
      if (!await prefs.setString(backupKey, backupSnapshot)) {
        throw StateError('Backup write failed');
      }
      if (!await prefs.setString(key, encoded)) {
        final rollbackOk = previousBackup == null
            ? await prefs.remove(backupKey)
            : await prefs.setString(backupKey, previousBackup);
        if (!rollbackOk) {
          throw StateError('Manual catalog write failed and backup rollback failed');
        }
        throw StateError('Manual catalog write failed');
      }
    });
}
