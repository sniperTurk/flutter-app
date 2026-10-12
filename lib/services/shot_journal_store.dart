import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One logged shot (Ö9 Atış günlüğü). Kept on the phone only; nothing is
/// sent anywhere.
class ShotRecord {
  final String id;
  final DateTime time;
  final String profileId;
  final double rangeM;
  final bool firstShot;
  final bool suppressor;

  /// Observed miss after the dialled correction: + = high / right, cm.
  final double missUpCm;
  final double missRightCm;

  /// Dialled elevation / windage as typed (may be empty) and its unit.
  final String elevationText;
  final String windageText;
  final String unitLabel;

  const ShotRecord({
    required this.id,
    required this.time,
    required this.profileId,
    required this.rangeM,
    required this.firstShot,
    required this.suppressor,
    required this.missUpCm,
    required this.missRightCm,
    this.elevationText = '',
    this.windageText = '',
    this.unitLabel = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time.toUtc().toIso8601String(),
    'profileId': profileId,
    'rangeM': rangeM,
    'firstShot': firstShot,
    'suppressor': suppressor,
    'missUp': missUpCm,
    'missRight': missRightCm,
    'elevation': elevationText,
    'windage': windageText,
    'unit': unitLabel,
  };

  /// Null for a damaged record (it is skipped, never repaired by guessing).
  static ShotRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final profileId = json['profileId'];
    final time = json['time'] is String
        ? DateTime.tryParse(json['time'] as String)
        : null;
    double? number(Object? v) =>
        v is num && v.toDouble().isFinite ? v.toDouble() : null;
    final range = number(json['rangeM']);
    final up = number(json['missUp']);
    final right = number(json['missRight']);
    final first = json['firstShot'];
    final sup = json['suppressor'];
    if (id is! String ||
        profileId is! String ||
        time == null ||
        range == null ||
        range <= 0 ||
        up == null ||
        right == null ||
        first is! bool ||
        sup is! bool) {
      return null;
    }
    String text(Object? v) => v is String && v.length <= 20 ? v : '';
    return ShotRecord(
      id: id,
      time: time,
      profileId: profileId,
      rangeM: range,
      firstShot: first,
      suppressor: sup,
      missUpCm: up,
      missRightCm: right,
      elevationText: text(json['elevation']),
      windageText: text(json['windage']),
      unitLabel: text(json['unit']),
    );
  }
}

/// Atış günlüğü and the cold-bore approvals, as JSON in SharedPreferences
/// (same pattern as [ShotSettingsStore]).
class ShotJournalStore {
  static const key = 'sniper_turk.shot_journal.v1';
  static const approvalsKey = 'sniper_turk.cold_bore_approvals.v1';

  /// The oldest records drop out beyond this.
  static const maxRecords = 1000;

  const ShotJournalStore();

  /// Bumped after every write, so an open Hedef page refreshes its
  /// cold-bore line.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<List<ShotRecord>> _all(SharedPreferences prefs) async {
    final raw = prefs.getString(key);
    if (raw == null) return [];
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return [];
    }
    if (decoded is! List) return [];
    final out = <ShotRecord>[];
    for (final item in decoded) {
      final r = ShotRecord.fromJson(item);
      if (r != null) out.add(r);
    }
    out.sort((a, b) => b.time.compareTo(a.time));
    return out;
  }

  /// Newest first; only [profileId]'s records when given.
  Future<List<ShotRecord>> load({String? profileId}) async {
    final all = await _all(await SharedPreferences.getInstance());
    return profileId == null
        ? all
        : [
            for (final r in all)
              if (r.profileId == profileId) r,
          ];
  }

  Future<void> _write(SharedPreferences prefs, List<ShotRecord> all) async {
    final ok = await prefs.setString(
      key,
      jsonEncode([for (final r in all.take(maxRecords)) r.toJson()]),
    );
    if (!ok) throw StateError('Günlük kaydedilemedi.');
    changes.value++;
  }

  Future<void> add(ShotRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _all(prefs)
      ..add(record)
      ..sort((a, b) => b.time.compareTo(a.time));
    await _write(prefs, all);
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _all(prefs)
      ..removeWhere((r) => r.id == id);
    await _write(prefs, all);
  }

  static String _approvalId(String profileId, bool suppressor) =>
      '$profileId|${suppressor ? 'on' : 'off'}';

  Future<bool> isApproved(String profileId, {required bool suppressor}) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(approvalsKey) ?? const <String>[]).contains(
      _approvalId(profileId, suppressor),
    );
  }

  Future<void> setApproved(
    String profileId, {
    required bool suppressor,
    required bool approved,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final set = {...?prefs.getStringList(approvalsKey)};
    final id = _approvalId(profileId, suppressor);
    if (approved) {
      set.add(id);
    } else {
      set.remove(id);
    }
    await prefs.setStringList(approvalsKey, set.toList()..sort());
    changes.value++;
  }
}
