import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain.dart';
import 'profile_codec.dart';
import 'profile_document_codec.dart';

abstract class ProfileStore {
  Future<List<RifleProfile>> all();
  Future<void> save(RifleProfile profile);
  Future<void> remove(String id);
}

class PersistentProfileStore implements ProfileStore {
  static const _key = 'sniper_turk.rifle_profiles.v1';
  static const _backupKey = 'sniper_turk.rifle_profiles.v1.backup';
  // Undecodable primary bytes are copied here BEFORE any repair or overwrite so
  // recovery never destroys the only evidence of what was on disk. First
  // evidence wins; nothing in the app reads or deletes this key.
  static const _quarantineKey = 'sniper_turk.rifle_profiles.v1.corrupt';
  static const _codec = ProfileCodec();
  static const _documentCodec = ProfileDocumentCodec(profileCodec: _codec);

  // Profile screens can create separate store instances. Serialize every
  // read-modify-write mutation process-wide so concurrent saves/removes cannot
  // overwrite each other with stale snapshots. The tail always completes
  // successfully, even when an individual operation fails, so one storage
  // error cannot permanently poison later mutations.
  static Future<void> _mutationTail = Future<void>.value();

  Future<T> _enqueueMutation<T>(Future<T> Function() operation) {
    final result = _mutationTail.then((_) => operation());
    _mutationTail = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  List<RifleProfile>? _decodeCollection(String? raw) {
    if (raw == null) return const [];
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return _documentCodec.decode(decoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> _quarantine(SharedPreferences prefs, String? corruptRaw) async {
    if (corruptRaw == null || prefs.getString(_quarantineKey) != null) return;
    if (!await prefs.setString(_quarantineKey, corruptRaw)) {
      throw StateError('Profile quarantine write failed');
    }
  }

  Future<List<RifleProfile>> _read({bool repairPrimary = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final primaryRaw = prefs.getString(_key);
    if (primaryRaw != null) {
      final primary = _decodeCollection(primaryRaw);
      if (primary != null) return primary;
    }

    final backupRaw = prefs.getString(_backupKey);
    if (primaryRaw == null && backupRaw == null) return const [];
    if (backupRaw == null) {
      throw StateError('Profile storage is corrupt and backup is missing');
    }
    final recovered = _decodeCollection(backupRaw);
    if (recovered == null) {
      // Existing persisted bytes that cannot be decoded are not equivalent to
      // an empty profile collection. Failing closed prevents a later save
      // from silently replacing the only remaining evidence of user data.
      throw StateError('Profile storage is corrupt and no valid backup is available');
    }

    if (repairPrimary) {
      await _quarantine(prefs, primaryRaw);
      final repaired = await prefs.setString(_key, backupRaw);
      if (!repaired) throw StateError('Profile recovery write failed');
    }
    return recovered;
  }

  @override
  Future<List<RifleProfile>> all() async {
    // A normal read is lock-free. Only recovery mutates storage, so serialize
    // that repair with save/remove and re-read inside the queue. This prevents
    // a stale corrupt-primary recovery from overwriting a concurrent save.
    final prefs = await SharedPreferences.getInstance();
    final primaryRaw = prefs.getString(_key);
    if (primaryRaw != null) {
      final primary = _decodeCollection(primaryRaw);
      if (primary != null) return primary;
    } else if (prefs.getString(_backupKey) == null) {
      return const [];
    }
    return _enqueueMutation(() => _read(repairPrimary: true));
  }

  @override
  Future<void> save(RifleProfile profile) => _enqueueMutation(() async {
    // Already inside the mutation queue: use the private reader directly to
    // avoid recursively enqueueing and deadlocking when primary is corrupt.
    final items = (await _read()).toList();
    items.removeWhere((p) => p.id == profile.id);
    items.add(profile);
    await _write(items);
  });

  @override
  Future<void> remove(String id) => _enqueueMutation(() async {
    final items = (await _read()).where((p) => p.id != id).toList();
    await _write(items);
  });

  Future<void> _write(List<RifleProfile> items) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_key);
    final previousBackup = prefs.getString(_backupKey);
    final payload = jsonEncode(_documentCodec.encode(items));
    if (previous != null && _decodeCollection(previous) == null) {
      await _quarantine(prefs, previous);
    }

    // The first successful profile write must already have a recoverable
    // backup. Later writes keep the previous validated primary as the backup.
    final backupPayload = previous != null && _decodeCollection(previous) != null
        ? previous
        : payload;
    if (!await prefs.setString(_backupKey, backupPayload)) {
      throw StateError('Profile backup write failed');
    }
    if (!await prefs.setString(_key, payload)) {
      // A failed first write must not leave an uncommitted payload recoverable
      // as if the save had succeeded. Best-effort restore the prior backup and
      // fail closed if even rollback cannot be persisted.
      final rollbackOk = previousBackup == null
          ? await prefs.remove(_backupKey)
          : await prefs.setString(_backupKey, previousBackup);
      if (!rollbackOk) throw StateError('Profile write failed and backup rollback failed');
      throw StateError('Profile write failed');
    }
  }
}

class MemoryProfileStore implements ProfileStore {
  final List<RifleProfile> _items = [];
  @override Future<List<RifleProfile>> all() async => List.unmodifiable(_items);
  @override Future<void> save(RifleProfile profile) async { _items.removeWhere((p) => p.id == profile.id); _items.add(profile); }
  @override Future<void> remove(String id) async => _items.removeWhere((p) => p.id == id);
}
