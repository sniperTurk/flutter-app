// Sistem yazı tipi (owner, 2026-10-15; PR #128's intent, on main since
// #277): the app theme uses the platform system font (San Francisco on iOS
// through Flutter's CupertinoSystemText / CupertinoSystemDisplay names),
// never a font bundled through pubspec `fonts:`. See
// docs/reports/sistem_yazi_tipi.md.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

/// Font families bundled through pubspec.yaml `fonts:`.
Set<String> _bundledFamilies() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final family = RegExp(r'^\s*-\s*family:\s*(\S+)\s*$', multiLine: true);
  return {for (final m in family.allMatches(pubspec)) m.group(1)!};
}

void main() {
  test('app theme text roles use the system font, not a bundled one', () {
    const system = {MenzilType.textFamily, MenzilType.displayFamily};
    final bundled = _bundledFamilies();
    for (final theme in [MenzilTheme.light(), MenzilTheme.dark()]) {
      final t = theme.textTheme;
      for (final s in [
        t.displayLarge,
        t.headlineMedium,
        t.titleMedium,
        t.bodyMedium,
        t.labelLarge,
      ]) {
        expect(system, contains(s!.fontFamily), reason: s.debugLabel);
        expect(bundled, isNot(contains(s.fontFamily)), reason: s.debugLabel);
        expect(s.fontFamilyFallback ?? const <String>[], isEmpty);
      }
    }
  });
}
