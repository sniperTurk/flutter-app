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

  testWidgets('nothing is pre-selected; a tapped hour is reported', (
    tester,
  ) async {
    int? hour;
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => WindClockPicker(
              hour: hour,
              onChanged: (h) => setState(() => hour = h),
            ),
          ),
        ),
      ),
    );
    expect(find.text(WindClockPicker.instruction), findsOneWidget);
    expect(find.byKey(const ValueKey('wind-clock-label')), findsNothing);
    await tester.tap(find.byKey(WindClockPicker.hourKey(3)));
    await tester.pump();
    expect(hour, 3);
    expect(find.text('Saat 3 · sağdan'), findsOneWidget);
    expect(WindDirectionDiagram.labels.length, 8);
  });
}
