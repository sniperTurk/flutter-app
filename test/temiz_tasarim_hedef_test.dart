// Temiz tasarım, Hedef / Hava Durumu / Pro Ayarlar (owner, 2026-10-15).
// The approved design is docs/design/clean-2026-10-15 on the design branch:
// Hedef page title, "Kuleleri kur" | "Kuleleri sıfırla" on one line, the
// top turret row [48][‹ 28][drum][› 28][L-R 48] centred over the reticle,
// the long slim side turret with its arrows outside the drum box, the
// collapsible "Hesap dökümü", Hava Durumu "Hava" / "Hava özeti", no icons in
// buttons, done buttons in the shared done style (also after reopening),
// the Rüzgâr ⓘ guide and the wind clock's orange.
// Report: docs/reports/temiz_tasarim_hedef.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/ballistics/wind_clock_picker.dart';
import 'package:sniper_turk/features/ballistics/wind_guide.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/pro_sections.dart';
import 'support/tool_fakes.dart';

// Gazi Sniper 6–36×56 FFP, shown in MOA (the profile's unit).
const _profile = RifleProfile(
  id: 'p-temiz',
  name: 'Temiz',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
);

class _Rig {
  final TestClock clock = TestClock(DateTime(2026, 10, 15, 10, 30));
  late final TestWeather weather = TestWeather(
    observation(fetchedAt: clock.current.toUtc()),
  );
  final TestPressure pressure = TestPressure(const PressureRead(998.4));
  final TestLocation location = TestLocation(
    const LocationFix(39.9, 32.8, altitudeM: 900),
  );

  late final ToolsServices services = testServices(
    location: location,
    weather: weather,
    pressure: pressure,
    clock: clock,
  );
}

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _show(
  WidgetTester tester,
  BallisticsView view, {
  _Rig? rig,
  double textScale = 1.0,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? MenzilTheme.light(),
      builder: (context, c) => ToolsServicesScope(
        services: rig?.services ?? testServices(),
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
      ),
      home: Scaffold(
        body: BallisticsScreen(
          profile: _profile,
          view: view,
          onContinueToPro: view == BallisticsView.environment ? () {} : null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

MenzilSecondaryButton _button(WidgetTester tester, Key key) =>
    tester.widget<MenzilSecondaryButton>(find.byKey(key));

/// The fill the button is drawn with (its OutlinedButton style).
Color? _fill(WidgetTester tester, Key key) => tester
    .widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(key),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      ),
    )
    .style
    ?.backgroundColor
    ?.resolve(<WidgetState>{});

String _readout(WidgetTester tester) =>
    tester.widget<Text>(find.textContaining('Kule: ').first).data!;

const _weatherBtn = Key('environment-fill-weather');
const _pressureBtn = Key('environment-phone-pressure');
const _windMaxBtn = Key('pro-wind-max-fill');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Hedef', () {
    testWidgets('the page title is "Hedef"', (tester) async {
      await _size(tester, const Size(390, 844));
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
      expect(find.byType(ScopeDialView), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('top-bar-title'))).data,
        'Hedef',
      );
      expect(find.text('Atış Çözümü'), findsNothing);
    });

    testWidgets('"Kuleleri kur" | "Kuleleri sıfırla" share one line', (
      tester,
    ) async {
      // Narrow phone, large text: still one line each, side by side.
      await _size(tester, const Size(320, 2400));
      await _show(tester, BallisticsView.shot, textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(_button(tester, ScopeDialKeys.dialSolution).label, 'Kuleleri kur');
      expect(_button(tester, ScopeDialKeys.reset).label, 'Kuleleri sıfırla');
      final kur = tester.getRect(find.byKey(ScopeDialKeys.dialSolution));
      final sifirla = tester.getRect(find.byKey(ScopeDialKeys.reset));
      expect(kur.top, moreOrLessEquals(sifirla.top, epsilon: 0.5));
      expect(kur.right, lessThan(sifirla.left));
      for (final k in [ScopeDialKeys.dialSolution, ScopeDialKeys.reset]) {
        expect(_button(tester, k).maxLabelLines, 1, reason: '$k');
        final label = tester.widget<Text>(
          find.descendant(of: find.byKey(k), matching: find.byType(Text)),
        );
        expect(label.maxLines, 1, reason: '$k');
        expect(label.softWrap, isFalse, reason: '$k');
      }
    });

    testWidgets('top turret row: [48][‹ 28][drum][› 28][L-R 48], centred', (
      tester,
    ) async {
      await _size(tester, const Size(390, 2400));
      await _show(tester, BallisticsView.shot);
      final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
      final turret = tester.getRect(find.byKey(ScopeDialKeys.elevationDrum));
      final toggle = tester.getRect(find.byKey(ScopeDialKeys.turretToggle));
      // The drum's zero sits over the reticle's vertical line.
      expect(
        turret.center.dx,
        moreOrLessEquals(reticle.center.dx, epsilon: 0.5),
      );
      // L-R: 48 pt, 4 pt right of the turret; an empty 48 pt slot balances
      // it on the left.
      expect(toggle.width, moreOrLessEquals(48, epsilon: 0.01));
      expect(toggle.height, moreOrLessEquals(48, epsilon: 0.01));
      expect(toggle.left - turret.right, moreOrLessEquals(4, epsilon: 0.5));
      final rowLeft = 2 * reticle.center.dx - toggle.right;
      expect(turret.left - rowLeft, moreOrLessEquals(48 + 4, epsilon: 0.5));
      // ‹ and ›: 28 pt columns at the drum's ends, 78 pt tall.
      final up = tester.getRect(
        find.byTooltip('Yükseklik kulesi 1 klik yukarı'),
      );
      final down = tester.getRect(
        find.byTooltip('Yükseklik kulesi 1 klik aşağı'),
      );
      expect(up.width, moreOrLessEquals(28, epsilon: 0.01));
      expect(down.width, moreOrLessEquals(28, epsilon: 0.01));
      expect(up.height, moreOrLessEquals(78, epsilon: 0.01));
      expect(up.left, moreOrLessEquals(turret.left, epsilon: 0.5));
      expect(down.right, moreOrLessEquals(turret.right, epsilon: 0.5));
      // The drum between them is wide enough for 2U · 0 · 2D (2 MOA labels
      // 72 pt either side of the zero).
      expect(down.left - up.right - 2 * 4, greaterThan(2 * 72 + 16));
      // Directions unchanged: ‹ dials U (up), › dials D (down).
      expect(_readout(tester), startsWith('Kule: 0 klik yukarı'));
      await _tap(tester, find.byTooltip('Yükseklik kulesi 1 klik yukarı'));
      expect(_readout(tester), startsWith('Kule: 1 klik yukarı'));
      await _tap(tester, find.byTooltip('Yükseklik kulesi 1 klik aşağı'));
      await _tap(tester, find.byTooltip('Yükseklik kulesi 1 klik aşağı'));
      expect(_readout(tester), startsWith('Kule: 1 klik aşağı'));
    });

    for (final width in [390.0, 430.0]) {
      testWidgets('side turret on a $width pt phone: long, slim, arrows '
          'outside the drum box', (tester) async {
        await _size(tester, Size(width, 2400));
        await _show(tester, BallisticsView.shot);
        expect(find.byKey(ScopeDialKeys.windageDrum), findsNothing);
        await _tap(tester, find.byKey(ScopeDialKeys.turretToggle));
        final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
        final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
        // 66 × 180 pt on the design's 334 pt reticle (yan kule küçük, owner
        // 2026-10-15 12:52; was 74 × 224); scales with it.
        final k = reticle.width / 334;
        expect(box.width, moreOrLessEquals(66 * k, epsilon: 0.5));
        expect(box.height, moreOrLessEquals(180 * k, epsilon: 0.5));
        expect(box.height / box.width, greaterThan(2.6));
        if (width == 390) {
          expect(box.width, moreOrLessEquals(66, epsilon: 1.5));
          expect(box.height, moreOrLessEquals(180, epsilon: 4));
        }
        // Zero on the reticle's horizontal line; the box sits centred in
        // the 74 pt arrow column at the right edge.
        expect(
          box.center.dy,
          moreOrLessEquals(reticle.center.dy, epsilon: 0.5),
        );
        expect(
          box.right,
          moreOrLessEquals(reticle.right - 4 * k, epsilon: 0.5),
        );
        // R up / L down, the arrows above and below the box, not in it.
        final right = find.byTooltip('Rüzgâr kulesi 1 klik sağa');
        final left = find.byTooltip('Rüzgâr kulesi 1 klik sola');
        expect(tester.getRect(right).bottom, lessThanOrEqualTo(box.top));
        expect(tester.getRect(left).top, greaterThanOrEqualTo(box.bottom));
        for (final arrow in [right, left]) {
          expect(
            find.descendant(
              of: find.byKey(ScopeDialKeys.windageDrumBox),
              matching: arrow,
            ),
            findsNothing,
          );
          // No box or background: only the chevron.
          for (final type in [Material, DecoratedBox, Ink, Container]) {
            expect(
              find.descendant(of: arrow, matching: find.byType(type)),
              findsNothing,
              reason: '$type',
            );
          }
        }
        // White chevron with a thin dark edge.
        for (final (key, dir) in [
          ('Rüzgâr kulesi-step-plus', AxisDirection.up),
          ('Rüzgâr kulesi-step-minus', AxisDirection.down),
        ]) {
          final paint = tester.widget<CustomPaint>(find.byKey(ValueKey(key)));
          final painter = paint.painter! as TurretChevronPainter;
          expect(painter.direction, dir);
          expect(TurretChevronPainter.fill, Colors.white);
          expect(TurretChevronPainter.edge, const Color(0xFF0F2230));
        }
        // The arrows step the windage.
        await _tap(tester, right);
        expect(_readout(tester), contains('· 1 klik sağ'));
        await _tap(tester, left);
        await _tap(tester, left);
        expect(_readout(tester), contains('· 1 klik sol'));
        // L-R closes it again.
        await _tap(tester, find.byKey(ScopeDialKeys.turretToggle));
        expect(find.byKey(ScopeDialKeys.windageDrum), findsNothing);
      });
    }

    testWidgets('from Pro with a distance: both turrets dialled, side '
        'turret open', (tester) async {
      await _size(tester, const Size(430, 3000));
      await _show(tester, BallisticsView.pro);
      final f = find.descendant(
        of: find.byKey(const Key('pro-shot-range')),
        matching: find.byType(TextField),
      );
      await tester.enterText(f, '80');
      await tester.pump();
      await _show(tester, BallisticsView.shot);
      final dial = tester.widget<ScopeDialView>(find.byType(ScopeDialView));
      expect(dial.rangeM, moreOrLessEquals(80, epsilon: 1e-9));
      expect(dial.elevationClicks, greaterThan(0));
      expect(find.byKey(ScopeDialKeys.windageDrumBox), findsOneWidget);
      expect(find.text('Vuruş noktası: artı işaretinde'), findsOneWidget);
    });

    testWidgets('"FFP · MOA · 31x" is drawn inside the reticle', (
      tester,
    ) async {
      await _size(tester, const Size(390, 2400));
      await _show(tester, BallisticsView.shot);
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(ScopeDialKeys.reticle),
          matching: find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is ScopeReticlePainter,
          ),
        ),
      );
      final painter = paint.painter! as ScopeReticlePainter;
      // 36x scope: 15 % under the top magnification, rounded.
      expect(painter.opticLine, 'FFP · MOA · 31x');
      expect(find.text('FFP · MOA · 31x'), findsNothing);
    });

    testWidgets('"Hesap dökümü" is a row that opens and closes, closed at '
        'first', (tester) async {
      await _size(tester, const Size(390, 2400));
      await _show(tester, BallisticsView.shot);
      final panel = find.byKey(ScopeDialKeys.workings);
      expect(panel, findsOneWidget);
      expect(
        find.descendant(of: panel, matching: find.text('Hesap dökümü')),
        findsOneWidget,
      );
      expect(find.textContaining('Kulede: '), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsWidgets);
      final row = tester.getRect(find.byKey(ScopeDialKeys.workingsToggle));
      expect(row.height, greaterThanOrEqualTo(44));

      await _tap(tester, find.byKey(ScopeDialKeys.workingsToggle));
      expect(find.textContaining('Kulede: '), findsOneWidget);
      expect(
        find.descendant(of: panel, matching: find.byIcon(Icons.expand_less)),
        findsOneWidget,
      );

      await _tap(tester, find.byKey(ScopeDialKeys.workingsToggle));
      expect(find.textContaining('Kulede: '), findsNothing);
    });

    testWidgets('the DOPE kartı button has no icon', (tester) async {
      await _size(tester, const Size(390, 2400));
      await _show(tester, BallisticsView.shot);
      expect(_button(tester, const Key('shot-dope-pdf')).icon, isNull);
    });
  });

  group('Hava Durumu', () {
    testWidgets('"Hava" over the top card, "Hava özeti" over the summary', (
      tester,
    ) async {
      await _size(tester, const Size(430, 3000));
      await _show(tester, BallisticsView.environment, rig: _Rig());
      final hava = find.byKey(const Key('environment-weather-header'));
      final ozet = find.byKey(const Key('environment-summary-header'));
      expect(
        find.descendant(of: hava, matching: find.text('Hava')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: ozet, matching: find.text('Hava özeti')),
        findsOneWidget,
      );
      // Same size as Basınç Ölçer / İrtifa / Rüzgâr (18).
      expect(tester.widget<MenzilSectionHeader>(hava).size, 18);
      expect(tester.widget<MenzilSectionHeader>(ozet).size, 18);
      // "Hava" sits above the Sıcaklık box; the summary card under its title
      // no longer repeats "Hava".
      expect(
        tester.getRect(hava).bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(BallisticsFieldKeys.temperature)).top,
        ),
      );
      final card = find.byKey(const Key('environment-summary-card'));
      expect(
        tester.getRect(ozet).bottom,
        lessThanOrEqualTo(tester.getRect(card).top),
      );
      expect(
        find.descendant(of: card, matching: find.text('Hava')),
        findsNothing,
      );
      expect(find.text('Hava'), findsOneWidget);
    });

    testWidgets('no icons in buttons; only "Hava verisi alındı" keeps ✓', (
      tester,
    ) async {
      await _size(tester, const Size(430, 3000));
      final rig = _Rig();
      await _show(tester, BallisticsView.environment, rig: rig);
      for (final k in const [
        _weatherBtn,
        _pressureBtn,
        Key('environment-map-altitude'),
        Key('environment-phone-altitude'),
        Key('environment-weather-reset'),
        Key('environment-pressure-reset'),
        Key('environment-altitude-reset'),
      ]) {
        expect(_button(tester, k).icon, isNull, reason: '$k');
      }
      await _tap(tester, find.byKey(_weatherBtn));
      await _tap(tester, find.byKey(_pressureBtn));
      expect(_button(tester, _weatherBtn).label, 'Hava verisi alındı');
      expect(_button(tester, _weatherBtn).icon, Icons.check);
      expect(_button(tester, _pressureBtn).label, 'Basınç alındı');
      expect(_button(tester, _pressureBtn).icon, isNull);
      await _tap(tester, find.byKey(const Key('environment-pressure-reset')));
      expect(
        _button(tester, const Key('environment-pressure-reset')).icon,
        isNull,
      );
    });

    testWidgets('done buttons: shared done style, "… alındı", kept when the '
        'page is reopened', (tester) async {
      await _size(tester, const Size(430, 3000));
      final rig = _Rig();
      await _show(tester, BallisticsView.environment, rig: rig);
      // The done style is the shared MenzilSecondaryButton one (dark blue
      // with the design/clean-profil task), not a local orange.
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: Scaffold(
            body: MenzilSecondaryButton(
              key: const Key('reference'),
              label: 'x',
              active: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      final shared = _fill(tester, const Key('reference'));
      expect(shared, isNotNull);
      // #318 (design/clean-profil) made the shared done fill dark blue.
      expect(shared, const Color(0xFF1F5F7A));
      expect(shared, isNot(WindClockPicker.orange));

      await _show(tester, BallisticsView.environment, rig: rig);
      await _tap(tester, find.byKey(_weatherBtn));
      expect(_button(tester, _weatherBtn).active, isTrue);
      expect(_fill(tester, _weatherBtn), shared);

      // Pro: "Düzeltme alındı" in the same done style, no icon.
      await _show(tester, BallisticsView.pro, rig: rig);
      await openProFor(tester, _windMaxBtn);
      await _tap(tester, find.byKey(_windMaxBtn));
      expect(_button(tester, _windMaxBtn).label, 'Düzeltme alındı');
      expect(_button(tester, _windMaxBtn).active, isTrue);
      expect(_button(tester, _windMaxBtn).icon, isNull);
      expect(_fill(tester, _windMaxBtn), shared);

      // Reopened: Hava Durumu and Pro still show "… alındı".
      await _show(tester, BallisticsView.shot, rig: rig);
      await _show(tester, BallisticsView.environment, rig: rig);
      expect(_button(tester, _weatherBtn).label, 'Hava verisi alındı');
      expect(_button(tester, _weatherBtn).active, isTrue);
      expect(_fill(tester, _weatherBtn), shared);
      await _show(tester, BallisticsView.pro, rig: rig);
      await openProFor(tester, _windMaxBtn);
      expect(_button(tester, _windMaxBtn).label, 'Düzeltme alındı');
      expect(_button(tester, _windMaxBtn).active, isTrue);
    });

    testWidgets('orange #E8590C stays on the wind clock', (tester) async {
      await _size(tester, const Size(430, 3000));
      await _show(tester, BallisticsView.environment, rig: _Rig());
      await _tap(tester, find.byKey(WindClockPicker.hourKey(3)));
      expect(
        tester.widget<Material>(find.byKey(WindClockPicker.hourKey(3))).color,
        const Color(0xFFE8590C),
      );
      expect(WindClockPicker.orange, const Color(0xFFE8590C));
    });

    testWidgets('the Rüzgâr ⓘ opens "Rüzgâr tahmini nasıl yapılır?"; no '
        'separate link', (tester) async {
      await _size(tester, const Size(430, 3000));
      await _show(tester, BallisticsView.environment, rig: _Rig());
      expect(find.byKey(const Key('wind-guide-link')), findsNothing);
      final info = find.byKey(const Key('environment-wind-info'));
      expect(
        find.descendant(
          of: find.ancestor(
            of: info,
            matching: find.byType(MenzilSectionHeader),
          ),
          matching: find.text('Rüzgâr'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<MenzilInfoButton>(info).tooltip,
        WindGuide.linkLabel,
      );
      await _tap(tester, info);
      expect(find.byKey(const Key('wind-guide-dialog')), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('wind-guide-line-$i')), findsOneWidget);
      }
      await _tap(tester, find.byKey(const Key('wind-guide-close')));
      expect(find.byKey(const Key('wind-guide-dialog')), findsNothing);
    });
  });
}
