import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  test('uses the Turkish decimal comma', () {
    expect(MenzilFormat.dec(0.37, 3), '0,370');
    expect(MenzilFormat.dec(1013.25, 2), '1013,25');
    expect(MenzilFormat.dec(270, 0), '270');
  });

  test('never prints a negative zero', () {
    expect(MenzilFormat.dec(-0.0001, 1), '0,0');
    expect(MenzilFormat.dec(-0.0, 0), '0');
    expect(MenzilFormat.dec(-0.04, 1), '0,0');
  });

  test('keeps real negative values signed', () {
    expect(MenzilFormat.dec(-0.06, 1), '-0,1');
    expect(MenzilFormat.dec(-12.5, 1), '-12,5');
  });
}
