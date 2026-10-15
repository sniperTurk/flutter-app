// The source of a Dart library: its main file followed by its part files.
// profiles_screen.dart is one library split into part files (owner,
// 2026-10-15), so source checks read all of it.
import 'dart:io';

String librarySource(String path) {
  final main = File(path).readAsStringSync();
  final dir = File(path).parent.path;
  final parts = RegExp(
    r"^part '([^']+)';",
    multiLine: true,
  ).allMatches(main).map((m) => File('$dir/${m.group(1)}').readAsStringSync());
  return [main, ...parts].join('\n');
}
