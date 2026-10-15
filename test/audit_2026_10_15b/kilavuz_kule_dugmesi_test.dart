// Pre-TestFlight audit 2026-10-15b — KLV-1 (düşük): #317 renamed the Hedef
// button "Çözümü kulelere kur" to "Kuleleri kur" (scope_turrets.dart), but
// the Kullanım rehberi still tells the user to tap the old name.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/guide/usage_guide_content.dart';

void main() {
  test('KLV-1: Kullanım rehberi names the Hedef button "Kuleleri kur"', () {
    final text = [
      for (final s in UsageGuideContent.sections) ...s.paragraphs,
    ].join('\n');
    expect(text, isNot(contains('Çözümü kulelere kur')));
    expect(text, contains('Kuleleri kur'));
  }, skip: false);
}
