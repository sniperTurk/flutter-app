// Pre-TestFlight audit 2026-10-15b — hidden flag added by #317:
// WIND_GUIDE_LINK must be off by default (no "Rüzgâr tahmini nasıl
// yapılır?" link on Hava Durumu); the Rüzgâr ⓘ opens the same guide.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/wind_guide.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import '../support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'd15b-w',
  name: 'W',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('WIND_GUIDE_LINK off by default: no link, the Rüzgâr ⓘ opens '
      'the guide', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 3000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        builder: (context, c) =>
            ToolsServicesScope(services: testServices(), child: c!),
        home: const Scaffold(
          body: BallisticsScreen(
            profile: _profile,
            view: BallisticsView.environment,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WindGuideLink), findsNothing);
    final info = find.byKey(const Key('environment-wind-info'));
    expect(info, findsOneWidget);
    await tester.ensureVisible(info);
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect(find.text('Kapat'), findsWidgets);
  });
}
