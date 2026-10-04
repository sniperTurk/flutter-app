// Separate file on purpose: PersistentProfileStore serialises mutations on a
// process-wide static future; each test file runs in its own isolate, so a
// FakeAsync zone from another test cannot leave that chain unresolved.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HomeScreen error card (tabs hidden) still offers recovery', (
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
        home: HomeScreen(
          profileStore: PersistentProfileStore(),
          activeProfileStore: MemoryActiveProfileStore(),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.byKey(const Key('home-recover')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-recover')));
    await _settle(tester);
    await tester.tap(find.text('Kapat'));
    await _settle(tester);
    expect(await _stringsWithPrefix(_key), before, reason: 'Kapat: no write');

    await tester.tap(find.byKey(const Key('home-recover')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('recovery-start-empty')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('recovery-confirm-empty')));
    await _settle(tester);

    expect(find.byKey(const Key('home-recover')), findsNothing);
    expect(find.text('Tekrar dene'), findsNothing);
    final copies = await _stringsWithPrefix('$_key.corrupt.');
    expect(copies.values, containsAll(['{broken-primary', '[broken-backup']));
  });
}
