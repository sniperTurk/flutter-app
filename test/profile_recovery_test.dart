import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _key = 'sniper_turk.rifle_profiles.v1';
const _backupKey = 'sniper_turk.rifle_profiles.v1.backup';

Future<Map<String, String>> _stringsWithPrefix(String prefix) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    for (final k in prefs.getKeys().where((k) => k.startsWith(prefix)))
      k: prefs.getString(k)!,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('both records corrupt: empty start preserves exact bytes first', () async {
    SharedPreferences.setMockInitialValues({
      _key: '{broken-primary',
      _backupKey: '[broken-backup',
    });
    final store = PersistentProfileStore();
    await expectLater(store.all(), throwsStateError);

    final raw = await store.readCorruptData();
    expect(raw.primary, '{broken-primary');
    expect(raw.backup, '[broken-backup');

    await store.startEmptyKeepingCorruptCopy();

    expect(await store.all(), isEmpty);
    final primaryCopies = await _stringsWithPrefix('$_key.corrupt.primary.');
    final backupCopies = await _stringsWithPrefix('$_key.corrupt.backup.');
    expect(primaryCopies.values.single, '{broken-primary');
    expect(backupCopies.values.single, '[broken-backup');
  });

  test('refuses to start empty while storage is readable', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PersistentProfileStore();
    // Nothing stored at all: nothing to recover, nothing is written.
    await expectLater(
      store.startEmptyKeepingCorruptCopy(),
      throwsStateError,
    );
    SharedPreferences.setMockInitialValues({
      _key: '{broken-primary',
      _backupKey:
          '{"schemaVersion":1,"profiles":[]}',
    });
    final before = await _stringsWithPrefix(_key);
    // Valid backup => not corrupt (all() recovers it); refuse and change nothing.
    await expectLater(
      PersistentProfileStore().startEmptyKeepingCorruptCopy(),
      throwsStateError,
    );
    expect(await _stringsWithPrefix(_key), before);
  });

  testWidgets('Profil screen: Kapat writes nothing; confirmed empty start keeps copies', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      _key: '{broken-primary',
      _backupKey: '[broken-backup',
    });
    final before = await _stringsWithPrefix(_key);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: ProfilesScreen(embedded: true, store: PersistentProfileStore()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Kayıtlar değiştirilmedi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profiles-recover')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
    expect(await _stringsWithPrefix(_key), before, reason: 'Kapat: no write');

    await tester.tap(find.byKey(const Key('profiles-recover')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recovery-show-raw')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recovery-raw')), findsOneWidget);
    expect(find.textContaining('{broken-primary'), findsWidgets);
    expect(await _stringsWithPrefix(_key), before, reason: 'show raw: no write');

    await tester.tap(find.byKey(const Key('recovery-start-empty')));
    await tester.pumpAndSettle();
    expect(find.textContaining('saklanacak'), findsOneWidget);
    expect(await _stringsWithPrefix(_key), before, reason: 'not yet confirmed');
    await tester.tap(find.byKey(const Key('recovery-confirm-empty')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Henüz kayıtlı profil yok'), findsOneWidget);
    final copies = await _stringsWithPrefix('$_key.corrupt.');
    expect(copies.values, containsAll(['{broken-primary', '[broken-backup']));
  });
}
