// Temiz tasarım (owner, 2026-10-15; docs/design/clean-2026-10-15 on branch
// design/clean-2026-10-15): Profil Oluştur, shared list box and buttons,
// Araçlar icons.
//
// If one of these fails, a later change has undone an owner decision: change
// the code back, or get the owner's word before changing the test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/features/tools/tools_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';
import 'support/tool_fakes.dart';

void _view(WidgetTester tester, {double width = 430, double height = 2600}) {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _openNew(WidgetTester tester) async {
  _view(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  expect(find.text('Profil Oluştur'), findsOneWidget);
}

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(Key(key)));

/// The open list and its entries (see MenzilSelect's list widgets).
final Finder _menu = find.byWidgetPredicate(
  (w) => w.runtimeType.toString().startsWith('_DropdownMenu<'),
);
final Finder _entries = find.byWidgetPredicate(
  (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
);

/// Opens [select] and picks the entry at [index] of its open list.
Future<void> _pickAt(WidgetTester tester, Finder select, int index) async {
  await tester.ensureVisible(select);
  await tester.pumpAndSettle();
  await tester.tap(select);
  await tester.pumpAndSettle();
  expect(_menu, findsOneWidget);
  await tester.tap(_entries.at(index));
  await tester.pumpAndSettle();
}

Finder _prefix(String p) => find.byWidgetPredicate(
  (w) =>
      w is MenzilSelect &&
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(p),
);

Object? _value(WidgetTester tester, Finder select) =>
    tester.state<MenzilSelectState<dynamic>>(select).value;

void main() {
  group('Profil Oluştur: başlangıç değerleri', () {
    testWidgets('every list box says "Seçiniz", every text box is empty', (
      tester,
    ) async {
      await _openNew(tester);
      final selects = find.byWidgetPredicate((w) => w is MenzilSelect);
      expect(selects, findsWidgets);
      for (var i = 0; i < selects.evaluate().length; i++) {
        final s = selects.at(i);
        final label = tester.widget<MenzilSelect<dynamic>>(s).label;
        expect(_value(tester, s), isNull, reason: label);
        expect(
          find.descendant(of: s, matching: find.text('Seçiniz')),
          findsWidgets,
          reason: label,
        );
      }
      // Tür included (it used to show "Ateşli Tüfek").
      expect(selectedValue<WeaponPlatform>(tester, 'profile-platform'), isNull);
      // Text boxes: empty, Profil adı aside (its default name is kept).
      final fields = find.byType(TextField);
      for (var i = 0; i < fields.evaluate().length; i++) {
        final f = fields.at(i);
        final inName = find
            .ancestor(of: f, matching: find.byKey(const Key('profile-name')))
            .evaluate()
            .isNotEmpty;
        if (inName) continue;
        expect(tester.widget<TextField>(f).controller!.text, isEmpty);
      }
    });

    testWidgets('picking a Tür shows it; the form stays Ateşli until then', (
      tester,
    ) async {
      await _openNew(tester);
      // Firearm form under "Seçiniz", as before: Mühimmat türü is there.
      expect(find.byKey(const Key('ammo-source')), findsOneWidget);
      await chooseInSelect(tester, 'profile-platform', 'PCP Tüfek');
      expect(
        selectedValue<WeaponPlatform>(tester, 'profile-platform'),
        WeaponPlatform.pcp,
      );
      expect(find.byKey(const Key('ammo-source')), findsNothing);
    });
  });

  group('Açılan liste: kutunun altında, 4 pt boşluk, kutu genişliğinde', () {
    Widget select(String key) => MenzilSelect<String>(
      key: Key(key),
      label: 'Model',
      initialValue: null,
      items: [
        for (final t in ['Bir', 'İki', 'Üç'])
          DropdownMenuItem(value: t, child: Text(t)),
      ],
      onChanged: (_) {},
    );

    Rect box(WidgetTester tester, String key) => tester.getRect(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(InputDecorator),
      ),
    );

    testWidgets('full width and half width boxes', (tester) async {
      _view(tester, width: 390, height: 844);
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.dark(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  select('full'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: select('left')),
                      const SizedBox(width: 12),
                      Expanded(child: select('right')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final key in ['full', 'left', 'right']) {
        final b = box(tester, key);
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        final m = tester.getRect(_menu);
        expect(
          m.top - b.bottom,
          moreOrLessEquals(4, epsilon: 0.5),
          reason: key,
        );
        expect(m.left, moreOrLessEquals(b.left, epsilon: 0.5), reason: key);
        expect(m.width, moreOrLessEquals(b.width, epsilon: 0.5), reason: key);
        // A pick closes the list and shows the choice in the box.
        await tester.tap(find.text('İki').last);
        await tester.pumpAndSettle();
        expect(_menu, findsNothing);
        expect(
          find.descendant(of: find.byKey(Key(key)), matching: find.text('İki')),
          findsOneWidget,
        );
      }
    });

    testWidgets('a tap on the box ends typing in another box first', (
      tester,
    ) async {
      _view(tester, width: 390, height: 844);
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.dark(),
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focus),
                select('after-typing'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      await tester.tap(find.byKey(const Key('after-typing')));
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isFalse);
      expect(_menu, findsOneWidget);
      // The keyboard coming or going (metrics change, same width) keeps the
      // list open; it used to close it under the finger on the simulator.
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      await tester.pumpAndSettle();
      expect(_menu, findsOneWidget);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(_menu, findsOneWidget);
      await tester.tap(find.text('Üç').last);
      await tester.pumpAndSettle();
      expect(_menu, findsNothing);
    });

    testWidgets('a box near the bottom: the page scrolls, list still below', (
      tester,
    ) async {
      _view(tester, width: 390, height: 844);
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.dark(),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 740),
                select('low'),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = box(tester, 'low');
      expect(before.bottom, greaterThan(844 - 120));
      await tester.tap(find.byKey(const Key('low')));
      await tester.pumpAndSettle();
      final b = box(tester, 'low');
      final m = tester.getRect(_menu);
      expect(b.top, lessThan(before.top), reason: 'page scrolled up');
      expect(m.top - b.bottom, moreOrLessEquals(4, epsilon: 0.5));
      expect(m.width, moreOrLessEquals(b.width, epsilon: 0.5));
      expect(m.bottom, lessThanOrEqualTo(844));
      // All three entries fit under the box.
      expect(_entries, findsNWidgets(3));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(_menu, findsNothing);
    });
  });

  group('Profil Oluştur: satırlar ve bölümler', () {
    testWidgets('Kalibre is one full-width row', (tester) async {
      await _openNew(tester);
      final cal = _rect(tester, 'rifle-caliber');
      final brand = _rect(tester, 'rifle-brand-select');
      expect(cal.left, moreOrLessEquals(brand.left, epsilon: 1));
      expect(cal.width, moreOrLessEquals(brand.width, epsilon: 1));
    });

    testWidgets('Dürbün: Üst kule klik sayısı | Dürbün ayağı (ayak sağda)', (
      tester,
    ) async {
      await _openNew(tester);
      final travel = _rect(tester, 'scope-travel-elevation');
      final mount = _rect(tester, 'scope-mount');
      expect((travel.top - mount.top).abs(), lessThan(1));
      expect(travel.right, lessThan(mount.left));
    });

    testWidgets('Ek mühimmat bilgileri: own heading and own card', (
      tester,
    ) async {
      await _openNew(tester);
      final ammoCard = find.byKey(const Key('profile-ammo-form'));
      final extraCard = find.byKey(const Key('profile-ammo-extra-form'));
      expect(extraCard, findsOneWidget);
      for (final k in ['profile-powder-coef', 'profile-powder-temp']) {
        expect(
          find.descendant(of: extraCard, matching: find.byKey(Key(k))),
          findsOneWidget,
          reason: k,
        );
        expect(
          find.descendant(of: ammoCard, matching: find.byKey(Key(k))),
          findsNothing,
          reason: k,
        );
      }
      final header = find.byKey(const Key('ammo-extra-header'));
      expect(find.descendant(of: ammoCard, matching: header), findsNothing);
      final h = tester.getRect(header);
      final a = tester.getRect(ammoCard);
      final e = tester.getRect(extraCard);
      expect(h.top, greaterThanOrEqualTo(a.bottom));
      expect(e.top, greaterThanOrEqualTo(h.bottom - 0.5));
      // Title at the left; "isteğe bağlı" and the ⓘ at the right end.
      final title = _rect(tester, 'ammo-extra-title');
      final optional = _rect(tester, 'ammo-extra-optional');
      final info = _rect(tester, 'ammo-extra-info');
      expect(title.left, moreOrLessEquals(e.left, epsilon: 1));
      expect(optional.left, greaterThan(title.left));
      expect(info.left, greaterThanOrEqualTo(optional.right - 1));
      expect(info.right, moreOrLessEquals(e.right, epsilon: 1));
      expect(
        tester.widget<Text>(find.byKey(const Key('ammo-extra-optional'))).data,
        'isteğe bağlı',
      );
      // Never folded: no chevron in the heading.
      for (final icon in [Icons.expand_more, Icons.expand_less]) {
        expect(
          find.descendant(of: header, matching: find.byIcon(icon)),
          findsNothing,
        );
      }
    });

    testWidgets('Eşik altı BC has no unit', (tester) async {
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      for (var i = 0; i < 2; i++) {
        final input = tester.widget<MenzilInput>(
          find.byKey(Key('ammo-band-bc-$i')),
        );
        expect(input.label, 'Eşik altı BC');
        expect(input.unit, isNull);
        expect(
          find.descendant(
            of: find.byKey(const Key('profile-ammo-extra-form')),
            matching: find.byKey(Key('ammo-band-bc-$i')),
          ),
          findsOneWidget,
        );
      }
    });
  });

  testWidgets('Dürbün Marka change resets every scope filter, Model and '
      'Retikül to "Seçiniz"', (tester) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'scope-brand-select', 'Element Optics');
    final filters = [
      'scope-filter-unit-',
      'scope-filter-ffp-',
      'scope-filter-tube-',
      'scope-filter-mag-',
    ];
    for (final f in filters) {
      await _pickAt(tester, _prefix(f), 1);
      expect(_value(tester, _prefix(f)), isNotNull, reason: f);
    }
    final model = find.descendant(
      of: find.byKey(const Key('scope-model-select')),
      matching: find.byWidgetPredicate((w) => w is MenzilSelect),
      matchRoot: true,
    );
    // Index 0 is the "Seçiniz" row (owner, 2026-10-16).
    await _pickAt(tester, model, 1);
    expect(selectedValue<String>(tester, 'scope-model-select'), isNotNull);
    await chooseInSelect(tester, 'scope-brand-select', 'Athlon');
    for (final f in filters) {
      expect(_prefix(f), findsOneWidget, reason: f);
      expect(_value(tester, _prefix(f)), isNull, reason: f);
    }
    expect(selectedValue<String>(tester, 'scope-model-select'), isNull);
    expect(selectedValue<String>(tester, 'scope-reticle'), isNull);
  });

  group('Düğmeler', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.dark(),
          home: Scaffold(body: Center(child: child)),
        ),
      );
      await tester.pumpAndSettle();
    }

    ButtonStyle style(WidgetTester tester) =>
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).style!;

    testWidgets('done ("… alındı"): #1F5F7A fill, #2E7FA0 border, white', (
      tester,
    ) async {
      for (final enabled in [true, false]) {
        await pump(
          tester,
          MenzilSecondaryButton(
            label: 'Haritadan alındı',
            active: true,
            icon: Icons.terrain,
            onPressed: enabled ? () {} : null,
          ),
        );
        final states = enabled ? <WidgetState>{} : {WidgetState.disabled};
        final s = style(tester);
        expect(s.backgroundColor!.resolve(states), const Color(0xFF1F5F7A));
        expect(s.side!.resolve(states)!.color, const Color(0xFF2E7FA0));
        expect(s.foregroundColor!.resolve(states), Colors.white);
        expect(
          s.backgroundColor!.resolve(states),
          isNot(MenzilColors.stateOrange),
        );
        // No icon on the button.
        expect(find.byIcon(Icons.terrain), findsNothing);
        expect(find.text('Haritadan alındı'), findsOneWidget);
      }
    });

    testWidgets('no icons; only the ✓ of a done button', (tester) async {
      await pump(
        tester,
        MenzilSecondaryButton(
          label: 'Haritadan al',
          icon: Icons.terrain,
          onPressed: () {},
        ),
      );
      expect(find.byIcon(Icons.terrain), findsNothing);
      expect(find.byType(Icon), findsNothing);
      await pump(
        tester,
        MenzilSecondaryButton(
          label: 'Hava verisi alındı',
          icon: Icons.check,
          active: true,
          onPressed: () {},
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  testWidgets('Araçlar: tool icons white #E7EFF3 on #1B3245', (tester) async {
    _view(tester, width: 390);
    await tester.pumpWidget(host(const Scaffold(body: ToolsScreen())));
    await tester.pumpAndSettle();
    final tiles = find.byType(MenzilToolTile);
    expect(tiles, findsWidgets);
    for (var i = 0; i < tiles.evaluate().length; i++) {
      final tile = tester.widget<MenzilToolTile>(tiles.at(i));
      final icon = tester.widget<Icon>(
        find.descendant(of: tiles.at(i), matching: find.byIcon(tile.icon)),
      );
      expect(icon.color, const Color(0xFFE7EFF3), reason: tile.title);
      final box = tester.widget<Container>(
        find
            .ancestor(
              of: find.descendant(
                of: tiles.at(i),
                matching: find.byIcon(tile.icon),
              ),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        (box.decoration! as BoxDecoration).color,
        const Color(0xFF1B3245),
        reason: tile.title,
      );
    }
  });
}
