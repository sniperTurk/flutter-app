import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

// Gazi Sniper 6–36×56 FFP: 0.1 mrad clicks, 26 mrad elevation travel.
const _profile = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

Future<void> _pumpSolved(
  WidgetTester tester, {
  RifleProfile profile = _profile,
}) async {
  tester.view.physicalSize = const Size(430, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // The app opens on Profil; the scope lives on the Atış tab.
  await tester.tap(find.text('Hedef'));
  await tester.pumpAndSettle();
}

String _impact(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ScopeDialKeys.impactText)).data!;

void main() {
  testWidgets('turrets and reticle are shown on the shot tab', (tester) async {
    await _pumpSolved(tester);
    expect(find.byKey(ScopeDialKeys.elevationDrum), findsOneWidget);
    // The drum's zero sits exactly above the reticle's centre line.
    expect(
      tester.getCenter(find.byKey(ScopeDialKeys.elevationDrum)).dx,
      closeTo(tester.getCenter(find.byKey(ScopeDialKeys.reticle)).dx, 0.5),
    );
    // As in ChairGun: the windage drum is hidden until "L-R", then slides
    // in from the right over the scope's right edge; the top drum stays.
    expect(find.byKey(ScopeDialKeys.windageDrum), findsNothing);
    await tester.ensureVisible(find.byKey(ScopeDialKeys.turretToggle));
    await tester.tap(find.byKey(ScopeDialKeys.turretToggle));
    await tester.pumpAndSettle();
    expect(find.byKey(ScopeDialKeys.windageDrum), findsOneWidget);
    expect(find.byKey(ScopeDialKeys.elevationDrum), findsOneWidget);
    final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
    final drum = tester.getRect(find.byKey(ScopeDialKeys.windageDrum));
    // Its zero is on the reticle's horizontal line, at the right edge.
    expect(drum.center.dy, closeTo(reticle.center.dy, 0.5));
    expect(drum.right, closeTo(reticle.right, 0.5));
    expect(drum.left, greaterThan(reticle.center.dx));
    // "L-R" again hides it.
    await tester.tap(find.byKey(ScopeDialKeys.turretToggle));
    await tester.pumpAndSettle();
    expect(find.byKey(ScopeDialKeys.windageDrum), findsNothing);
    expect(find.byKey(ScopeDialKeys.reticle), findsOneWidget);
    // Wind is still not modelled.
    expect(
      find.textContaining('Rüzgâr düzeltmesi hiç modellenmez (KİLİTLİ)'),
      findsOneWidget,
    );
  });

  testWidgets('dialling the solution centres the impact; reset drops it', (
    tester,
  ) async {
    await _pumpSolved(tester);
    // At 100 m with a 25 m zero the impact is below the crosshair.
    expect(_impact(tester), contains('aşağı'));

    await tester.ensureVisible(find.byKey(ScopeDialKeys.dialSolution));
    await tester.tap(find.byKey(ScopeDialKeys.dialSolution));
    await tester.pumpAndSettle();
    expect(_impact(tester), 'Vuruş noktası: artı işaretinde');

    await tester.tap(find.byKey(ScopeDialKeys.reset));
    await tester.pumpAndSettle();
    expect(_impact(tester), contains('aşağı'));
  });

  testWidgets('the button of the current turret state turns orange', (
    tester,
  ) async {
    await _pumpSolved(tester);
    String label(Key k) =>
        tester.widget<MenzilSecondaryButton>(find.byKey(k)).label;
    bool active(Key k) =>
        tester.widget<MenzilSecondaryButton>(find.byKey(k)).active;
    expect(label(ScopeDialKeys.dialSolution), 'Çözümü kuleye kur');
    expect(label(ScopeDialKeys.reset), 'Kuleler sıfırda');
    expect(active(ScopeDialKeys.reset), isTrue);

    await tester.ensureVisible(find.byKey(ScopeDialKeys.dialSolution));
    await tester.tap(find.byKey(ScopeDialKeys.dialSolution));
    await tester.pumpAndSettle();
    expect(label(ScopeDialKeys.dialSolution), 'Çözüm kuleye kurulu');
    expect(active(ScopeDialKeys.dialSolution), isTrue);
    expect(label(ScopeDialKeys.reset), 'Kuleleri sıfırla');
    expect(active(ScopeDialKeys.reset), isFalse);

    await tester.tap(find.byKey(ScopeDialKeys.reset));
    await tester.pumpAndSettle();
    expect(label(ScopeDialKeys.dialSolution), 'Çözümü kuleye kur');
    expect(active(ScopeDialKeys.dialSolution), isFalse);
    expect(label(ScopeDialKeys.reset), 'Kuleler sıfırda');
  });

  testWidgets('windage clicks move the impact sideways', (tester) async {
    await _pumpSolved(tester);
    await tester.ensureVisible(find.byKey(ScopeDialKeys.dialSolution));
    await tester.tap(find.byKey(ScopeDialKeys.dialSolution));
    await tester.pumpAndSettle();

    // "Çözümü kuleye kur" already slid the windage turret open.
    expect(find.byKey(const ValueKey('windage-open')), findsOneWidget);
    await tester.tap(find.byTooltip('Rüzgâr kulesi 1 klik sağa'));
    await tester.pumpAndSettle();
    // 0.1 mrad at 100 m = 1.0 cm to the right.
    expect(_impact(tester), contains('1.0 cm sağ'));
  });

  testWidgets('dragging the elevation drum changes the dialled clicks', (
    tester,
  ) async {
    await _pumpSolved(tester);
    final drum = find.byKey(ScopeDialKeys.elevationDrum);
    await tester.ensureVisible(drum);
    expect(find.textContaining('Kule: 0 klik'), findsOneWidget);
    await tester.drag(drum, const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kule: 0 klik'), findsNothing);
    expect(find.textContaining('klik yukarı'), findsOneWidget);
  });

  testWidgets('the scope works as soon as Atış opens, without Hesapla', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryProfileStore();
    await store.save(_profile);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: HomeScreen(
          profileStore: store,
          activeProfileStore: MemoryActiveProfileStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hedef'));
    await tester.pumpAndSettle();
    expect(_impact(tester), isNot(contains('bekleniyor')));
    expect(_impact(tester), contains('aşağı'));
  });

  testWidgets('a MOA profile shows MOA turret and reticle on a MRAD scope', (
    tester,
  ) async {
    await _pumpSolved(
      tester,
      profile: const RifleProfile(
        id: 'p-moa',
        name: 'MOA',
        rifleId: 'hatsan-hercules-635',
        ammunitionId: 'gmaz-51',
        scopeId: 'gazi-6-36',
        muzzleVelocityMps: 270,
        zeroRangeM: 25,
        sightHeightMm: 60,
        pressureBar: 200,
        angularUnit: AngularUnit.moa,
      ),
    );
    expect(find.textContaining('Profilde dürbün birimi MOA'), findsOneWidget);
    // The turret readout counts in MOA (the elevation box is gone).
    expect(
      tester.widget<Text>(find.textContaining('Kule:')).data,
      contains('MOA)'),
    );
    expect(find.byKey(ScopeDialKeys.workings), findsOneWidget);
    expect(find.textContaining('/ 0.25 ='), findsOneWidget);
  });

  testWidgets('SFP reticle marks scale with magnification', (tester) async {
    tester.view.physicalSize = const Size(430, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    Widget view(double mag) => MaterialApp(
      theme: MenzilTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScopeDialView(
            unit: AngularUnit.mrad,
            clickValue: 0.1,
            elevationClicks: 0,
            windageClicks: 0,
            maxElevationClicks: 100,
            maxWindageClicks: 100,
            onElevationChanged: (_) {},
            onWindageChanged: (_) {},
            requiredUp: 1.5,
            firstFocalPlane: false,
            minMagnification: 6,
            maxMagnification: 24,
            magnification: mag,
            onMagnificationChanged: (_) {},
            rangeM: 100,
            samples: const [],
            toDisplayRange: (m) => m,
            distanceUnit: 'm',
            metric: true,
          ),
        ),
      ),
    );
    await tester.pumpWidget(view(12));
    expect(
      find.textContaining('1 çizgi = 24 / 12 = 2.000 mrad'),
      findsOneWidget,
    );
    // 1.5 mrad low at 12x on a 24x-calibrated SFP = 0.75 marks.
    expect(find.textContaining('= 0.75 çizgi'), findsOneWidget);
    expect(find.byKey(ScopeDialKeys.magnification), findsOneWidget);

    await tester.pumpWidget(view(24));
    expect(
      find.textContaining('1 çizgi = 24 / 24 = 1.000 mrad'),
      findsOneWidget,
    );
  });

  testWidgets(
    'an impact outside the field is pointed at, the reticle keeps its scale',
    (tester) async {
      tester.view.physicalSize = const Size(430, 2400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      Widget view(double up) => MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScopeDialView(
              unit: AngularUnit.mrad,
              clickValue: 0.1,
              elevationClicks: 0,
              windageClicks: 0,
              maxElevationClicks: 130,
              maxWindageClicks: 130,
              travelKnown: true,
              halfElevationClicks: 130,
              onElevationChanged: (_) {},
              onWindageChanged: (_) {},
              requiredUp: up,
              firstFocalPlane: true,
              minMagnification: 6,
              maxMagnification: 36,
              magnification: 36,
              onMagnificationChanged: (_) {},
              rangeM: 424,
              samples: const [],
              toDisplayRange: (m) => m,
              distanceUnit: 'm',
              metric: true,
            ),
          ),
        ),
      );
      await tester.pumpWidget(view(3));
      expect(find.byKey(ScopeDialKeys.fitNote), findsNothing);
      expect(find.byKey(ScopeDialKeys.travelNote), findsNothing);

      // 113.7 mrad low at 36x (half field 10 mrad), and the 13 mrad turret
      // cannot dial it.
      await tester.pumpWidget(view(113.7));
      expect(find.byKey(ScopeDialKeys.fitNote), findsOneWidget);
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byKey(ScopeDialKeys.reticle),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as ScopeReticlePainter;
      // The reticle keeps its real scale (no zoom-out); the note names the
      // offset and the edge arrow points to it.
      expect(painter.trueHalfField, closeTo(10, 1e-9));
      expect(find.textContaining('113.70 mrad aşağıda'), findsOneWidget);
      expect(find.byKey(ScopeDialKeys.travelNote), findsOneWidget);
    },
  );
}
