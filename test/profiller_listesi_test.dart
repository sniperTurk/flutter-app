// Profil → "Profiller" listesi (owner, 2026-10-14 17:33–17:44, mockup B):
// "Profil ekle" right of the "Profiller" title, each row only a dot, the
// name (+ Aktif) and one "⋯" whose popup holds Düzenle, Kopyala, Sil; no
// velocity · Sıfır line, no button row under the list; Yedekle / Geri yükle
// hidden behind PROFILE_BACKUP_BUTTONS (not removed).
// See docs/reports/profiller_listesi.md.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _one = RifleProfile(
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

const _two = RifleProfile(
  id: 'p2',
  name: 'İki',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _three = RifleProfile(
  id: 'p3',
  name: 'Üç',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 290,
  zeroRangeM: 35,
  sightHeightMm: 60,
  pressureBar: 200,
);

/// Inter under the SF proxy names (as test/profil_ekle_arti_test.dart), so
/// text widths are close to the phone.
Future<void> _loadStandIn() async {
  final files = Directory('assets/fonts')
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('Inter-'))
      .toList();
  expect(files, isNotEmpty);
  for (final name in {MenzilType.textFamily, MenzilType.displayFamily}) {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }
}

Future<MemoryProfileStore> _pump(
  WidgetTester tester, {
  List<RifleProfile> profiles = const [_one, _two, _three],
  String? active = 'p1',
  double width = 393,
  double scale = 1.0,
  List<String>? activated,
}) async {
  tester.view.physicalSize = Size(width, 1600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  for (final p in profiles) {
    await store.save(p);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: ProfilesScreen(
          embedded: true,
          store: store,
          activeProfileId: active,
          onActivate: (p) async {
            activated?.add(p!.id);
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Finder _menu(String id) => find.byKey(Key('profile-menu-$id'));

/// The tappable card of a profile row.
Finder _row(String id) =>
    find.ancestor(of: _menu(id), matching: find.byType(InkWell)).first;

Future<void> _openMenu(WidgetTester tester, String id) async {
  await tester.ensureVisible(_menu(id));
  await tester.pumpAndSettle();
  await tester.tap(_menu(id));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadStandIn);
  tearDown(() => ProfilesScreen.debugShowBackupButtons = null);

  testWidgets('Profil ekle sits right of "Profiller" and opens the editor', (
    tester,
  ) async {
    await _pump(tester);
    final title = tester.getRect(find.text('Profiller'));
    final add = find.byKey(const Key('profiles-add'));
    expect(add, findsOneWidget);
    expect(
      find.descendant(of: add, matching: find.text('Profil ekle')),
      findsOneWidget,
    );
    expect(find.descendant(of: add, matching: find.byIcon(Icons.add)), findsOneWidget);
    expect(tester.widget<MenzilPrimaryButton>(add).amber, isTrue);
    final b = tester.getRect(add);
    expect(b.left, greaterThan(title.right));
    // Same row as the title.
    expect(b.top, lessThan(title.bottom));
    expect(b.bottom, greaterThan(title.top));
    expect(b.height, greaterThanOrEqualTo(44));
    // "N kayıtlı profil" stays under the title.
    final count = tester.getRect(find.text('3 kayıtlı profil'));
    expect(count.top, greaterThanOrEqualTo(title.bottom - 0.5));
    expect((count.left - title.left).abs(), lessThan(1));
    // Only one Profil ekle on the page (the button row under the list is
    // gone).
    expect(find.text('Profil ekle'), findsOneWidget);

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Profil Oluştur'), findsOneWidget);
  });

  testWidgets('rows: name and one ⋯ only, no velocity · Sıfır line', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.textContaining('• Sıfır'), findsNothing);
    expect(find.textContaining('fps •'), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    for (final p in const [_one, _two, _three]) {
      final row = _row(p.id);
      expect(
        find.descendant(of: row, matching: find.text(p.name)),
        findsOneWidget,
      );
      // One trailing control: the ⋯ (no edit / copy / delete icons).
      expect(
        find.descendant(of: row, matching: find.byIcon(Icons.more_horiz)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.byType(IconButton)),
        findsOneWidget,
      );
      final dots = tester.getRect(row);
      expect(dots.height, greaterThanOrEqualTo(44));
      final more = tester.getRect(
        find.descendant(of: row, matching: find.byType(IconButton)),
      );
      expect(more.width, greaterThanOrEqualTo(44));
      expect(more.height, greaterThanOrEqualTo(44));
      expect(more.right, lessThanOrEqualTo(dots.right));
    }
    // "Aktif" only on the active row.
    expect(
      find.descendant(of: _row('p1'), matching: find.text('Aktif')),
      findsOneWidget,
    );
    expect(find.text('Aktif'), findsOneWidget);
  });

  testWidgets('tapping a row makes it active', (tester) async {
    final activated = <String>[];
    await _pump(tester, activated: activated);
    await tester.ensureVisible(find.text('İki'));
    await tester.tap(find.text('İki'));
    await tester.pumpAndSettle();
    expect(activated, ['p2']);
  });

  testWidgets('⋯: Düzenle, Kopyala, Sil in order; rows do not move', (
    tester,
  ) async {
    await _pump(tester);
    Map<String, Rect> rows() => {
      for (final id in ['p1', 'p2', 'p3']) id: tester.getRect(_row(id)),
    };
    await tester.ensureVisible(_menu('p2'));
    await tester.pumpAndSettle();
    final before = rows();
    await tester.tap(_menu('p2'));
    await tester.pumpAndSettle();
    expect(rows(), before);

    final edit = tester.getRect(find.text('Düzenle'));
    final copy = tester.getRect(find.text('Kopyala'));
    final del = tester.getRect(find.text('Sil'));
    expect(edit.top, lessThan(copy.top));
    expect(copy.top, lessThan(del.top));
    // Icons: edit, content_copy, delete (red).
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.content_copy), findsOneWidget);
    final delIcon = tester.widget<Icon>(find.byIcon(Icons.delete_outline));
    final ctx = tester.element(find.text('Sil'));
    expect(delIcon.color, MenzilColors.of(ctx).danger);
    // Left-aligned items, menu as wide as its content (no full-width sheet).
    expect((edit.left - copy.left).abs(), lessThan(1));
    expect((copy.left - del.left).abs(), lessThan(1));
    for (final k in ['edit', 'copy', 'delete']) {
      final item = tester.getRect(find.byKey(Key('profile-menu-$k')));
      expect(item.height, greaterThanOrEqualTo(44));
      expect(item.width, lessThan(before['p2']!.width));
    }
    // Anchored to the ⋯ of that row.
    final more = tester.getRect(_menu('p2'));
    expect(edit.top, greaterThanOrEqualTo(more.top - 1));

    // Closing it leaves the rows where they were.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Düzenle'), findsNothing);
    expect(rows(), before);
  });

  testWidgets('Düzenle opens that profile', (tester) async {
    await _pump(tester);
    await _openMenu(tester, 'p3');
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    expect(find.text('Profili Düzenle'), findsOneWidget);
    final name = find.descendant(
      of: find.byKey(const Key('profile-name')),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(name).controller!.text, 'Üç');
  });

  testWidgets('Kopyala duplicates that profile', (tester) async {
    final store = await _pump(tester);
    await _openMenu(tester, 'p2');
    await tester.tap(find.text('Kopyala'));
    await tester.pumpAndSettle();
    final all = await store.all();
    expect(all, hasLength(4));
    final copy = all.singleWhere((p) => p.name == 'İki (kopya)');
    expect(copy.id, isNot('p2'));
    expect(copy.muzzleVelocityMps, _two.muzzleVelocityMps);
    expect(copy.zeroRangeM, _two.zeroRangeM);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('İki (kopya)'), findsOneWidget);
  });

  testWidgets('Sil asks "Profil silinsin mi?" (İptal / Sil), then deletes', (
    tester,
  ) async {
    final store = await _pump(tester);
    await _openMenu(tester, 'p3');
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil silinsin mi?'), findsOneWidget);
    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.text('İptal')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Sil')),
      findsOneWidget,
    );
    await tester.tap(find.descendant(of: dialog, matching: find.text('İptal')));
    await tester.pumpAndSettle();
    expect(await store.all(), hasLength(3), reason: 'İptal must not delete');

    await _openMenu(tester, 'p3');
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Sil')),
    );
    await tester.pumpAndSettle();
    expect((await store.all()).map((p) => p.id), ['p1', 'p2']);
    expect(find.text('Üç'), findsNothing);
    expect(find.text('2 kayıtlı profil'), findsOneWidget);
  });

  testWidgets('no button row under the list; backup hidden by default', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Kopyala'), findsNothing);
    expect(find.text('Sil'), findsNothing);
    expect(find.byIcon(Icons.copy_outlined), findsNothing);
    expect(find.text('Yedekle'), findsNothing);
    expect(find.text('Geri yükle'), findsNothing);
    expect(find.byTooltip('Bilgi: Yedekle ve Geri yükle'), findsNothing);
    expect(ProfilesScreen.showBackupButtonsFlag, isFalse);
  });

  testWidgets('PROFILE_BACKUP_BUTTONS on: Yedekle / Geri yükle and ⓘ shown', (
    tester,
  ) async {
    ProfilesScreen.debugShowBackupButtons = true;
    await _pump(tester);
    expect(find.text('Yedekle'), findsOneWidget);
    expect(find.text('Geri yükle'), findsOneWidget);
    expect(find.byTooltip('Bilgi: Yedekle ve Geri yükle'), findsOneWidget);
    // Still no Kopyala / Sil row.
    expect(find.text('Kopyala'), findsNothing);
  });

  testWidgets('empty list: text kept, header still has Profil ekle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 1200) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: ProfilesScreen(store: MemoryProfileStore()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Henüz kayıtlı profil yok.\nYeni profil ile ilk profilinizi oluşturun.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('profiles-add')), findsOneWidget);
    expect(find.text('Profiller'), findsWidgets);
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('320 pt, ×$scale: long name, no overflow, ⋯ on screen', (
      tester,
    ) async {
      const long = RifleProfile(
        id: 'long',
        name:
            'Çok uzun bir profil adı: Tikka T3x TACT A1 .308 Win 175 gr '
            'Sierra MatchKing kış atışı',
        rifleId: 'hatsan-hercules-635',
        ammunitionId: 'gmaz-51',
        scopeId: 'gazi-6-36',
        muzzleVelocityMps: 800,
        zeroRangeM: 100,
        sightHeightMm: 45,
      );
      await _pump(
        tester,
        profiles: const [_one, long],
        active: 'long',
        width: 320,
        scale: scale,
      );
      expect(tester.takeException(), isNull);
      for (final id in ['p1', 'long']) {
        final row = tester.getRect(_row(id));
        final more = tester.getRect(_menu(id));
        expect(row.right, lessThanOrEqualTo(320));
        expect(more.right, lessThanOrEqualTo(row.right));
        expect(more.width, greaterThanOrEqualTo(44));
        expect(more.height, greaterThanOrEqualTo(44));
      }
      // The long name stays inside its row, left of Aktif and ⋯.
      final name = tester.getRect(
        find.descendant(
          of: _row('long'),
          matching: find.byKey(const Key('profile-row-name')),
        ),
      );
      expect(name.right, lessThanOrEqualTo(tester.getRect(_menu('long')).left));
      final add = tester.getRect(find.byKey(const Key('profiles-add')));
      expect(add.right, lessThanOrEqualTo(320));
      expect(add.height, greaterThanOrEqualTo(44));
      await _openMenu(tester, 'long');
      expect(tester.takeException(), isNull);
      for (final t in ['Düzenle', 'Kopyala', 'Sil']) {
        final r = tester.getRect(find.text(t));
        expect(r.right, lessThanOrEqualTo(320), reason: t);
        expect(r.left, greaterThanOrEqualTo(0), reason: t);
      }
    });
  }
}
