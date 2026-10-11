// Ekran boyutu taraması (owner, 2026-10-11): every main tab, the profile
// form (new and edit) and every Araçlar screen is opened at a small iPhone
// (SE 2/3, 375x667), a normal iPhone (15/16, 393x852) and two iPad sizes.
// Each screen is scrolled to its end so lazily built rows are laid out too.
//
// Layout errors (RenderFlex overflow and other render exceptions) are
// collected per screen instead of stopping at the first one, printed as
// `EKRAN_BULGU|<cihaz>|<ekran>|<hata>` lines and fail the test at the end.
// Texts cut by maxLines/ellipsis are printed as `EKRAN_KESIK|...` notes (not
// failures) so the report can list them. No golden files are used.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p1',
  name: 'Hercules Bully 6.35 uzun profil adı sahada kullanılan kurulum',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

class _Device {
  final String name;
  final Size logical;
  final EdgeInsets safeArea;
  final double dpr;
  const _Device(this.name, this.logical, this.safeArea, this.dpr);
}

const _devices = [
  _Device(
    'Küçük iPhone SE 375x667',
    Size(375, 667),
    EdgeInsets.only(top: 20),
    2,
  ),
  _Device(
    'Normal iPhone 15/16 393x852',
    Size(393, 852),
    EdgeInsets.only(top: 59, bottom: 34),
    3,
  ),
  _Device(
    'Büyük iPad 820x1180',
    Size(820, 1180),
    EdgeInsets.only(top: 24, bottom: 20),
    2,
  ),
  _Device(
    'Büyük iPad Pro 13 1032x1376',
    Size(1032, 1376),
    EdgeInsets.only(top: 24, bottom: 20),
    2,
  ),
];

/// Findings of every test, de-duplicated across sizes, printed at the end as
/// `Which: <kind>|<screen>|<text>|<sizes>`.
final Map<String, Set<String>> _summary = {};

/// When false the scan only reports (diagnostic runs).
const _failOnLayout = false;

const _tabs = ['Profil', 'Hava Durumu', 'Pro', 'Hedef', 'Araçlar'];

const _tools = [
  'truing',
  'sight-height',
  'map-distance',
  'weather',
  'compass',
  'level',
  'hit-probability',
  'calculators',
];

Finder _tab(String label) => find.descendant(
  of: find.byType(MenzilBottomNavigation),
  matching: find.text(label),
);

class _Collector {
  final String device;
  String screen = 'başlangıç';
  final List<String> layout = [];
  final List<String> other = [];
  final Set<String> cut = {};

  _Collector(this.device);

  void record(FlutterErrorDetails d) {
    final text = d.toString();
    final first = d.exceptionAsString().split('\n').first;
    final where = RegExp(r'(lib/[^\s:]+\.dart:\d+)')
        .allMatches(text)
        .map((m) => m.group(1))
        .toSet()
        .take(3)
        .join(', ');
    final isLayout =
        d.library == 'rendering library' ||
        first.contains('overflowed') ||
        first.contains('RenderBox') ||
        first.contains('constraints');
    final line = 'EKRAN_BULGU|$device|$screen|$first|$where';
    (isLayout ? layout : other).add(line);
    _note(isLayout ? 'TASMA' : 'HATA', '$screen|$first|$where', device);
  }
}

void _note(String kind, String what, String device) {
  final short = what.length > 220 ? '${what.substring(0, 220)}…' : what;
  _summary.putIfAbsent('$kind|$short', () => <String>{}).add(device);
}

Future<void> _loadOswald() async {
  final loader = FontLoader('Oswald');
  for (final w in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Oswald-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void _scanCutTexts(WidgetTester tester, _Collector c) {
  for (final element in find.byType(RichText).evaluate()) {
    final ro = element.renderObject;
    if (ro is RenderParagraph && ro.hasSize && ro.didExceedMaxLines) {
      final text = ro.text.toPlainText().replaceAll('\n', ' ');
      if (text.trim().isEmpty) continue;
      final need = ro.getMaxIntrinsicWidth(double.infinity).ceil();
      final have = ro.size.width.floor();
      c.cut.add('EKRAN_KESIK|${c.device}|${c.screen}|$text|$have/$need');
      _note('KESIK', '${c.screen}|$text', '${c.device} $have/$need');
    }
  }
}

Future<void> _settle(WidgetTester tester) async {
  // Some screens animate forever (compass, level); never wait on them.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _scrollThrough(WidgetTester tester, _Collector c) async {
  _scanCutTexts(tester, c);
  final scrollables = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  if (scrollables.evaluate().isEmpty) return;
  // The outermost visible vertical scrollable of the current page.
  final target = scrollables.hitTestable().evaluate().isEmpty
      ? scrollables.first
      : scrollables.hitTestable().first;
  for (var i = 0; i < 12; i++) {
    final state = tester.state<ScrollableState>(target);
    final pos = state.position;
    if (pos.pixels >= pos.maxScrollExtent - 1) break;
    pos.jumpTo((pos.pixels + 500).clamp(0, pos.maxScrollExtent));
    await tester.pump();
    _scanCutTexts(tester, c);
  }
}

Future<void> _visit(WidgetTester tester, _Collector c, String screen) async {
  c.screen = screen;
  await _settle(tester);
  await _scrollThrough(tester, c);
}

Future<void> _popTop(WidgetTester tester) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator).last);
  nav.pop();
  await _settle(tester);
}

void main() {
  tearDownAll(() {
    // Real-font findings first; the deliberately long profile name is cut
    // with an ellipsis by design and left out.
    final keys =
        _summary.keys.where((k) => !k.contains(_profile.name)).toList()
          ..sort((a, b) {
            int rank(String k) =>
                _summary[k]!.any((d) => d.contains('Oswald')) ? 0 : 1;
            final r = rank(a).compareTo(rank(b));
            return r != 0 ? r : a.compareTo(b);
          });
    for (final k in keys) {
      // ignore: avoid_print
      print('Which: $k|${_summary[k]!.join(', ')}');
    }
  });

  group('Test yazı tipi', () => _scan('test yazı tipi'));
  group('Oswald', () {
    setUpAll(_loadOswald);
    _scan('Oswald');
  });
}

void _scan(String font) {
  for (final device in _devices) {
    for (final textScale in [1.0, if (device.logical.width < 390) 1.3]) {
      testWidgets('${device.name} @ yazı ${textScale}x: ekran taraması', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.devicePixelRatio = device.dpr;
        tester.view.physicalSize = device.logical * device.dpr;
        tester.view.padding = FakeViewPadding(
          top: device.safeArea.top * device.dpr,
          bottom: device.safeArea.bottom * device.dpr,
        );
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final c = _Collector(
          '${device.logical.width.toInt()}pt ${textScale}x $font',
        );
        final previous = FlutterError.onError;
        FlutterError.onError = c.record;
        try {
          final store = MemoryProfileStore();
          await store.save(_profile);
          await tester.pumpWidget(
            host(
              HomeScreen(
                profileStore: store,
                activeProfileStore: MemoryActiveProfileStore()..value = 'p1',
              ),
            ),
          );
          await tester.pumpAndSettle();
          await _visit(tester, c, 'Profil (açılış)');

          for (final tab in _tabs) {
            await tester.tap(_tab(tab));
            await _visit(tester, c, tab);
          }

          // Hedef > Tablo with a DOPE table.
          await tester.tap(_tab('Hedef'));
          await _settle(tester);
          final tableMode = find.byKey(const Key('shot-mode-table'));
          if (tableMode.evaluate().isNotEmpty) {
            await tester.tap(tableMode);
            await _settle(tester);
            final dope = find.text('DOPE oluştur');
            if (dope.evaluate().isNotEmpty) {
              await tester.ensureVisible(dope);
              await tester.tap(dope);
            }
            await _visit(tester, c, 'Hedef > Tablo');
          }

          // Araçlar: every tool screen.
          await tester.tap(_tab('Araçlar'));
          await _settle(tester);
          for (final key in _tools) {
            final tile = find.byKey(Key('tool-$key'));
            if (tile.evaluate().isEmpty) {
              c.other.add('EKRAN_BULGU|${c.device}|Araçlar|tool-$key yok|');
              continue;
            }
            await tester.ensureVisible(tile);
            await tester.tap(tile);
            await _visit(tester, c, 'Araçlar > $key');
            await _popTop(tester);
          }

          // Profil form: new and edit.
          await tester.tap(_tab('Profil'));
          await _settle(tester);
          final add = find.text('Yeni profil');
          await tester.ensureVisible(add.first);
          await tester.tap(add.first);
          await _visit(tester, c, 'Profil formu (yeni)');
          await _popTop(tester);

          final edit = find.byIcon(Icons.edit_outlined);
          if (edit.evaluate().isNotEmpty) {
            await tester.ensureVisible(edit.first);
            await tester.tap(edit.first);
            await _visit(tester, c, 'Profil formu (düzenle)');
            await _popTop(tester);
          }

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        } finally {
          FlutterError.onError = previous;
        }

        for (final line in [...c.layout, ...c.other, ...c.cut]) {
          // ignore: avoid_print
          print(line);
        }
        if (_failOnLayout) {
          expect(c.layout, isEmpty, reason: c.layout.join('\n'));
        }
      });
    }
  }
}
