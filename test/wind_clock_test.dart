// Wind direction on a clock face (ChairGun / Strelok / Kestrel): the hour
// the wind comes from, with 12 = from the target. Maps onto the solver's
// degrees (0 head, 90 from the left, 270 from the right).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/wind_clock.dart';
import 'package:sniper_turk/features/ballistics/wind_clock_picker.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  test('clock hours map onto the solver degrees', () {
    expect(WindClock.toDegrees(12), 0);
    expect(WindClock.toDegrees(3), 270, reason: '3 o\'clock = from the right');
    expect(WindClock.toDegrees(6), 180);
    expect(WindClock.toDegrees(9), 90, reason: '9 o\'clock = from the left');
    expect(WindClock.toDegrees(1), 330);
    for (var h = 1; h <= 12; h++) {
      expect(WindClock.fromDegrees(WindClock.toDegrees(h)), h);
    }
    expect(WindClock.fromDegrees(275), 3, reason: 'nearest hour');
    expect(WindClock.side(3), 'sağdan');
    expect(WindClock.side(9), 'soldan');
    expect(() => WindClock.toDegrees(0), throwsArgumentError);
  });

  testWidgets('tapping an hour selects it and says where the wind is from', (
    tester,
  ) async {
    var hour = 9;
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => WindClockPicker(
              hour: hour,
              info: 'x',
              onChanged: (h) => setState(() => hour = h),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Saat 9 · soldan'), findsOneWidget);
    await tester.tap(find.byKey(WindClockPicker.hourKey(3)));
    await tester.pump();
    expect(hour, 3);
    expect(find.text('Saat 3 · sağdan'), findsOneWidget);
    expect(find.byTooltip('Bilgi: Rüzgâr yönü'), findsOneWidget);
    // The ⓘ box shows the 0–315° dial with every 45° labelled.
    await tester.tap(find.byTooltip('Bilgi: Rüzgâr yönü'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('wind-direction-diagram')),
      findsOneWidget,
    );
    expect(WindDirectionDiagram.labels, [
      '0°',
      '45°',
      '90°',
      '135°',
      '180°',
      '225°',
      '270°',
      '315°',
    ]);
  });
}
