import 'dart:convert';

import '../models/domain.dart';
import 'manual_catalog_store.dart';
import 'profile_document_codec.dart';
import 'profile_store.dart';

/// What a backup file holds: the profiles and the user's own catalog entries
/// (tüfek, mühimmat, dürbün they typed in themselves).
class ProfileBackupContents {
  final List<RifleProfile> profiles;
  final List<Map<String, dynamic>> catalog;
  const ProfileBackupContents({required this.profiles, required this.catalog});
}

/// Result of a restore: how many records were written and how many catalog
/// entries were skipped because they no longer pass validation.
class ProfileRestoreResult {
  final int profiles;
  final int catalog;
  final int skipped;
  const ProfileRestoreResult({
    required this.profiles,
    required this.catalog,
    required this.skipped,
  });
}

/// Profiller → Yedekle / Geri yükle (owner, 2026-10-12): one JSON file the
/// user saves wherever they like (iCloud Drive, Google Drive) through the
/// system share sheet and picks again with the document picker. Nothing is
/// sent anywhere by the app itself.
class ProfileBackup {
  static const format = 'sniper_turk.yedek';
  static const currentVersion = 1;
  static const notABackup = 'Bu dosya SNIPER TÜRK yedeği değil.';

  static const _documents = ProfileDocumentCodec();

  const ProfileBackup._();

  /// File name for a backup made on [day], e.g. sniper-turk-yedek-2026-10-12.json.
  static String fileName(DateTime day) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'sniper-turk-yedek-${day.year}-${two(day.month)}-${two(day.day)}.json';
  }

  static String encode(ProfileBackupContents contents, {DateTime? createdAt}) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': format,
        'version': currentVersion,
        'createdAt': (createdAt ?? DateTime.now()).toUtc().toIso8601String(),
        'profiles': _documents.encode(contents.profiles),
        'catalog': contents.catalog,
      });

  /// Reads a backup file. Anything that is not a SNIPER TÜRK backup, or a
  /// newer version than this build understands, throws [FormatException]
  /// with a message meant for the user; nothing is changed.
  static ProfileBackupContents decode(String text) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw const FormatException(notABackup);
    }
    if (root is! Map || root['format'] != format) {
      throw const FormatException(notABackup);
    }
    final version = root['version'];
    if (version is! int || version < 1) {
      throw const FormatException(notABackup);
    }
    if (version > currentVersion) {
      throw const FormatException(
        'Bu yedek uygulamanın daha yeni bir sürümüyle alınmış. '
        'Uygulamayı güncelleyip tekrar deneyin.',
      );
    }
    final List<RifleProfile> profiles;
    try {
      profiles = _documents.decode(root['profiles']);
    } on Object {
      throw const FormatException('Yedekteki profiller okunamadı.');
    }
    final rawCatalog = root['catalog'] ?? const [];
    if (rawCatalog is! List) {
      throw const FormatException('Yedekteki kayıtlar okunamadı.');
    }
    final catalog = [
      for (final e in rawCatalog)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
    return ProfileBackupContents(profiles: profiles, catalog: catalog);
  }

  /// Everything currently stored, ready for [encode].
  static Future<ProfileBackupContents> collect(
    ProfileStore profiles,
    ManualCatalogStore catalog,
  ) async => ProfileBackupContents(
    profiles: await profiles.all(),
    catalog: await catalog.all(),
  );

  /// Adds the backup to what is stored. A profile or entry with the same id
  /// is replaced by the backup's copy; nothing is deleted.
  static Future<ProfileRestoreResult> restore(
    ProfileBackupContents contents,
    ProfileStore profiles,
    ManualCatalogStore catalog,
  ) async {
    var written = 0;
    var skipped = 0;
    for (final entry in contents.catalog) {
      try {
        await catalog.upsert(entry);
        written++;
      } on FormatException {
        skipped++;
      }
    }
    for (final p in contents.profiles) {
      await profiles.save(p);
    }
    return ProfileRestoreResult(
      profiles: contents.profiles.length,
      catalog: written,
      skipped: skipped,
    );
  }
}
