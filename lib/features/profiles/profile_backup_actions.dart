import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a finished backup file to the system share sheet; the user chooses
/// where it goes (Dosyalar'a Kaydet → iCloud Drive, Google Drive, …).
typedef BackupShare =
    Future<void> Function(String fileName, String text, Rect? origin);

/// Lets the user pick a backup file; null = cancelled.
typedef BackupPick = Future<String?> Function();

Future<void> shareBackupFile(String fileName, String text, Rect? origin) async {
  final bytes = Uint8List.fromList(utf8.encode(text));
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'application/json')],
      fileNameOverrides: [fileName],
      // iPad presents the share sheet as a popover anchored here.
      sharePositionOrigin: origin,
    ),
  );
}

Future<String?> pickBackupFile() async {
  const group = XTypeGroup(
    label: 'SNIPER TÜRK yedeği',
    extensions: ['json'],
    uniformTypeIdentifiers: ['public.json', 'public.data'],
  );
  final file = await openFile(acceptedTypeGroups: const [group]);
  return file?.readAsString();
}
