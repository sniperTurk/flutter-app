// Metin temizliği (owner, 2026-10-11): no English messages for the user,
// "mermi" instead of "saçma" while a firearm is selected, and no bold Pro
// box titles.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/input_error_text.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/profiles/profile_field_info.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

final _english = RegExp(
  r'\b(must|be|is|not|and|the|finite|invalid|required)\b',
  caseSensitive: false,
);

void main() {
  group('InputErrorText', () {
    test('a solver input error is shown with its Turkish field name', () {
      ArgumentError? caught;
      try {
        BallisticInput(
          muzzleVelocityMps: 280,
          grain: 25,
          zeroRangeM: 30,
          sightHeightMm: 50,
          rangesM: const [30],
          environment: const EnvironmentData(humidityPercent: 140),
        );
      } on ArgumentError catch (e) {
        caught = e;
      }
      expect(caught, isNotNull);
      final text = InputErrorText.of(caught!, fallback: 'x');
      expect(text, 'Geçersiz değer: Nem. Kontrol edip tekrar deneyin.');
      expect(_english.hasMatch(text), isFalse);
    });

    test('prefixed and unknown names', () {
      expect(InputErrorText.labelOf('zeroEnvironment.temperatureC'), 'Sıcaklık');
      expect(InputErrorText.labelOf('bcBands.minVelocityMps'), 'Hıza göre BC');
      expect(InputErrorText.labelOf('windZones.rangeM'), 'Yol boyu rüzgâr');
      expect(InputErrorText.labelOf('sightHeightMm'), 'Sight height');
      expect(InputErrorText.labelOf(null), isNull);
      expect(
        InputErrorText.of(
          ArgumentError('water-vapor partial pressure must be below'),
          fallback: 'Geçersiz değer. Kontrol edip tekrar deneyin.',
        ),
        'Geçersiz değer. Kontrol edip tekrar deneyin.',
      );
    });
  });

  group('saçma / mermi by platform', () {
    final helpers = <String Function({required bool firearm})>[
      EnvironmentFieldInfo.temperatureFor,
      EnvironmentFieldInfo.windSpeedFor,
      EnvironmentFieldInfo.inclineFor,
      EnvironmentFieldInfo.cantFor,
      EnvironmentFieldInfo.coriolisFor,
    ];

    test('firearm texts say mermi, PCP texts keep saçma', () {
      for (final f in helpers) {
        final firearm = f(firearm: true), pcp = f(firearm: false);
        expect(firearm, isNot(contains('saçma')));
        expect(firearm, contains('mermi'));
        expect(pcp, contains('saçma'));
      }
      expect(
        EnvironmentFieldInfo.windSpeedFor(firearm: true),
        contains('Yan rüzgâr mermiyi yana taşır'),
      );
      expect(
        EnvironmentFieldInfo.windSpeedFor(firearm: false),
        contains('Yan rüzgâr saçmayı yana taşır'),
      );
      expect(EnvironmentFieldInfo.windDirection, isNot(contains('saçma')));
      expect(ProfileFieldInfo.bandSpeedFirearm, isNot(contains('saçma')));
    });

    Widget dial({required bool firearm}) => MaterialApp(
      theme: MenzilTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScopeDialView(
            firearm: firearm,
            unit: AngularUnit.mrad,
            clickValue: 0.1,
            elevationClicks: 0,
            windageClicks: 0,
            maxElevationClicks: 100,
            maxWindageClicks: 100,
            onElevationChanged: (_) {},
            onWindageChanged: (_) {},
            requiredUp: 1.5,
            rangeM: 100,
            samples: const [],
            toDisplayRange: (m) => m,
            distanceUnit: 'm',
            metric: true,
            cantDeg: 3,
          ),
        ),
      ),
    );

    testWidgets('the cant note follows the platform', (tester) async {
      tester.view.physicalSize = const Size(430, 2400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(dial(firearm: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('mermi yatık tarafa'), findsOneWidget);
      expect(find.textContaining('saçma yatık tarafa'), findsNothing);

      await tester.pumpWidget(dial(firearm: false));
      await tester.pumpAndSettle();
      expect(find.textContaining('saçma yatık tarafa'), findsOneWidget);
    });
  });
}
