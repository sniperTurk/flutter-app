// dart format off
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'serial_mutation_lock.dart';
import '../models/domain.dart';

/// User records never acquire manufacturer provenance and never overwrite built-ins.
class UserCatalogStore {
  static const key = 'sniper_turk.user_catalog.v1';
  static const backupKey = 'sniper_turk.user_catalog.v1.backup';
  // Zone-independent process-wide lock (see SerialMutationLock).
  static final SerialMutationLock _mutationLock = SerialMutationLock();

  Future<T> _enqueueMutation<T>(Future<T> Function() operation) =>
      _mutationLock.run(operation);

  Future<List<Map<String, dynamic>>> _read({bool repairPrimary = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        return _decodeAndValidate(raw);
      } on FormatException {
        // Fall through to the backup path.
      }
    }

    final backup = prefs.getString(backupKey);
    if (raw == null && backup == null) return [];
    if (backup == null) {
      throw const FormatException('Kişisel katalog okunamadı');
    }
    final recovered = _decodeAndValidate(backup);
    if (repairPrimary && !await prefs.setString(key, backup)) {
      throw StateError('Kişisel katalog yedekten geri yüklenemedi');
    }
    return recovered;
  }

  Future<List<Map<String, dynamic>>> all() async {
    // Keep healthy reads lock-free. Recovery writes are serialized with
    // save/remove and re-read storage after entering the queue, so a stale
    // backup can never overwrite a newer concurrent mutation.
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

  static List<Map<String, dynamic>> _decodeAndValidate(String raw) {
    dynamic value;
    try {
      value = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('Kişisel katalog okunamadı');
    }
    if (value is! List) throw const FormatException('Kişisel katalog okunamadı');
    final items = <Map<String, dynamic>>[];
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      if (item is! Map) {
        throw FormatException('Kişisel katalog kaydı geçersiz: index $index');
      }
      final decoded = Map<String, dynamic>.from(item);
      try {
        validate(decoded);
      } on FormatException catch (error) {
        throw FormatException('Kişisel katalog kaydı geçersiz: index $index: $error');
      }
      items.add(decoded);
    }
    // save()/remove() mutate the returned list in place, so it must stay growable.
    return items;
  }

  static Map<String, dynamic> _snapshotEntry(Map<String, dynamic> entry) {
    // A shallow Map.from() still aliases nested caller-owned maps/lists. Round-trip
    // through JSON so every JSON-persistable nested value is detached before the
    // asynchronous mutation queue can yield.
    final decoded = jsonDecode(jsonEncode(entry));
    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<void> save(Map<String, dynamic> entry) {
    // Freeze the complete caller-owned value graph before crossing the async
    // queue boundary. Validation and persistence then observe one immutable-by-
    // ownership snapshot rather than aliases the caller can still mutate.
    final snapshot = _snapshotEntry(entry);
    return _enqueueMutation(() async {
      validate(snapshot);
      final items = await _read();
      items.removeWhere((item) => item['id'] == snapshot['id']);
      items.add(snapshot);
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(items);
      await _commit(prefs, encoded, operationError: 'Kişisel katalog kaydedilemedi');
    });
  }

  Future<void> remove(String id) => _enqueueMutation(() async {
      final items = await _read();
      items.removeWhere((item) => item['id'] == id);
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(items);
      await _commit(prefs, encoded, operationError: 'Kişisel katalog silinemedi');
  });

  static Future<void> _commit(SharedPreferences prefs, String encoded,
      {required String operationError}) async {
    final previousBackup = prefs.getString(backupKey);
    // Backup first: a backup failure must never leave a committed primary while
    // the caller receives an exception.
    if (!await prefs.setString(backupKey, encoded)) {
      throw StateError('Kişisel katalog yedeği kaydedilemedi');
    }
    if (!await prefs.setString(key, encoded)) {
      final rollbackOk = previousBackup == null
          ? await prefs.remove(backupKey)
          : await prefs.setString(backupKey, previousBackup);
      if (!rollbackOk) {
        throw StateError('$operationError; yedek geri alma da başarısız');
      }
      throw StateError(operationError);
    }
  }

  static void validate(Map<String, dynamic> item) {
    if (!{'rifle', 'ammunition', 'scope'}.contains(item['kind'])) {
      throw const FormatException('Geçersiz katalog türü');
    }
    for (final field in ['id', 'brand', 'model']) {
      final value = item[field];
      if (value is! String || value.trim().isEmpty || value.length > 100) {
        throw FormatException('$field alanı gerekli (en fazla 100 karakter)');
      }
    }
    if (item['kind'] != 'scope' && !{'pcp', 'firearm'}.contains(item['platform'])) {
      throw const FormatException('Platform seçimi gerekli');
    }
    for (final field in ['caliberMm', 'grain', 'objectiveDiameterMm', 'clickValue', 'barrelLengthMm', 'airCapacityCc']) {
      final value = item[field];
      if (value != null && (value is! num || !value.isFinite || value <= 0)) {
        throw FormatException('$field pozitif bir sayı olmalı');
      }
    }
    if (item['kind'] != 'scope' && item['caliberMm'] == null) {
      throw const FormatException('Kalibre gerekli');
    }
    if (item['kind'] == 'ammunition' && (item['grain'] == null ||
        !{'pellet', 'slug', 'bullet'}.contains(item['type']) ||
        (item['platform'] == 'firearm' && item['type'] != 'bullet') ||
        (item['platform'] == 'pcp' && item['type'] == 'bullet'))) {
      throw const FormatException('Mühimmat ağırlığı veya tipi geçersiz');
    }
    if (item['kind'] == 'scope' && (item['objectiveDiameterMm'] == null ||
        item['clickValue'] == null || !{'mrad', 'moa'}.contains(item['clickUnit']))) {
      throw const FormatException('Dürbün objektifi ve klik değeri gerekli');
    }
  }

  static Rifle rifle(Map<String, dynamic> e) => Rifle(
    id: e['id'] as String, brand: e['brand'] as String, model: e['model'] as String,
    platform: WeaponPlatform.values.byName(e['platform'] as String),
    caliberMm: (e['caliberMm'] as num).toDouble(),
    barrelLengthMm: (e['barrelLengthMm'] as num?)?.toDouble(),
    airCapacityCc: (e['airCapacityCc'] as num?)?.toDouble(),
    sourceName: 'Kullanıcı girdisi', sourceDocument: 'Kişisel kayıt; üretici doğrulaması yok');

  static Ammunition ammunition(Map<String, dynamic> e) => Ammunition(
    id: e['id'] as String, brand: e['brand'] as String, model: e['model'] as String,
    platform: WeaponPlatform.values.byName(e['platform'] as String),
    caliberMm: (e['caliberMm'] as num).toDouble(), grain: (e['grain'] as num).toDouble(),
    type: AmmunitionType.values.byName(e['type'] as String),
    sourceName: 'Kullanıcı girdisi', sourceDocument: 'Kişisel kayıt; üretici doğrulaması yok');

  static ScopeOptic scope(Map<String, dynamic> e) => ScopeOptic(
    id: e['id'] as String, brand: e['brand'] as String, model: e['model'] as String,
    objectiveDiameterMm: (e['objectiveDiameterMm'] as num).toDouble(),
    clickValue: (e['clickValue'] as num).toDouble(),
    clickUnit: AngularUnit.values.byName(e['clickUnit'] as String),
    sourceName: 'Kullanıcı girdisi', sourceDocument: 'Kişisel kayıt; üretici doğrulaması yok');
}
