import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/dope_ranges.dart';

void main() {
  test('DOPE ranges are parsed, deduplicated and sorted', () {
    expect(DopeRanges.parse('100, 25; 50 100'), [25, 50, 100]);
  });
  test('DOPE ranges reject zero, negative and excessive values', () {
    expect(() => DopeRanges.parse('0, 100'), throwsFormatException);
    expect(() => DopeRanges.parse('-25'), throwsFormatException);
    expect(DopeRanges.parse('2500'), [2500]);
    expect(DopeRanges.parse('3000'), [3000]);
    expect(() => DopeRanges.parse('3000.1'), throwsFormatException);
  });
  test('DOPE ranges reject empty input', () {
    expect(() => DopeRanges.parse('  '), throwsFormatException);
  });
}
