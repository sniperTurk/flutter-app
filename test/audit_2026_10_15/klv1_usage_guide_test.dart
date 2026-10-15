// Audit finding KLV-1 (low), 2026-10-15: the usage guide (Araçlar >
// Kullanım rehberi) still told users to tap "Çözümü kulelere kur", but the
// Hedef button is now "Kuleleri kur" (#317). Regression guard: the guide
// never names the old button and does name the current one.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/guide/usage_guide_content.dart';

String _guideText() => [
  UsageGuideContent.intro,
  for (final s in UsageGuideContent.sections) ...[s.title, ...s.paragraphs],
].join('\n');

void main() {
  test('KLV-1: guide does not name the old "Çözümü kulelere kur" button', () {
    expect(_guideText(), isNot(contains('Çözümü kulelere kur')));
  });

  test('KLV-1: guide names the "Kuleleri kur" button', () {
    expect(_guideText(), contains('"Kuleleri kur"'));
  });

  test('KLV-1: the Hedef button label the guide names still exists', () {
    final src = File(
      'lib/features/ballistics/scope_turrets.dart',
    ).readAsStringSync();
    expect(src, contains("'Kuleleri kur'"));
  });

  test('KLV-1: generated REHBER.md matches the in-app guide wording', () {
    final md = File('docs/kullanim-rehberi/REHBER.md').readAsStringSync();
    expect(md, isNot(contains('Çözümü kulelere kur')));
    expect(md, contains('"Kuleleri kur"'));
  });
}
