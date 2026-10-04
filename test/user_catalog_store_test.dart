import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/services/user_catalog_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('malformed non-map user catalog record fails closed as FormatException', () async {
    SharedPreferences.setMockInitialValues({
      UserCatalogStore.key: jsonEncode(['not-a-map']),
    });

    await expectLater(
      UserCatalogStore().all(),
      throwsA(isA<FormatException>()),
    );
  });

  test('persisted user catalog entries are revalidated before use', () async {
    SharedPreferences.setMockInitialValues({
      UserCatalogStore.key: jsonEncode([
        {
          'kind': 'ammunition',
          'id': 'bad-ammo',
          'brand': 'User',
          'model': 'Bad',
          'platform': 'firearm',
          'caliberMm': 6.35,
          'grain': 48,
          'type': 'slug',
        }
      ]),
    });

    await expectLater(
      UserCatalogStore().all(),
      throwsA(isA<FormatException>()),
    );
  });

  test('save and remove work on a list returned by all()', () async {
    SharedPreferences.setMockInitialValues({});
    final store = UserCatalogStore();
    Map<String, dynamic> scope(String id) => {
          'kind': 'scope',
          'id': id,
          'brand': 'User',
          'model': id,
          'objectiveDiameterMm': 50,
          'clickValue': 0.1,
          'clickUnit': 'mrad',
        };

    await store.save(scope('a'));
    await store.save(scope('b'));
    expect((await store.all()).map((e) => e['id']), ['a', 'b']);

    await store.remove('a');
    expect((await store.all()).map((e) => e['id']), ['b']);
  });
  test('valid backup recovers and self-heals a corrupt primary catalog', () async {
    final valid = jsonEncode([
      {
        'kind': 'scope',
        'id': 'recovered-scope',
        'brand': 'User',
        'model': 'Recovered',
        'objectiveDiameterMm': 50,
        'clickValue': 0.1,
        'clickUnit': 'mrad',
      }
    ]);
    SharedPreferences.setMockInitialValues({
      UserCatalogStore.key: '{broken-json',
      UserCatalogStore.backupKey: valid,
    });

    final items = await UserCatalogStore().all();
    expect(items.single['id'], 'recovered-scope');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(UserCatalogStore.key), valid);
  });

  test('missing primary with a valid backup is restored, not treated as empty', () async {
    final valid = jsonEncode([
      {
        'kind': 'scope',
        'id': 'kept-scope',
        'brand': 'User',
        'model': 'Kept',
        'objectiveDiameterMm': 50,
        'clickValue': 0.1,
        'clickUnit': 'mrad',
      }
    ]);
    SharedPreferences.setMockInitialValues({UserCatalogStore.backupKey: valid});

    final items = await UserCatalogStore().all();
    expect(items.single['id'], 'kept-scope');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(UserCatalogStore.key), valid);
  });

  test('invalid optional rifle numeric fields fail closed', () async {
    SharedPreferences.setMockInitialValues({
      UserCatalogStore.key: jsonEncode([
        {
          'kind': 'rifle',
          'id': 'bad-rifle',
          'brand': 'User',
          'model': 'Bad optional fields',
          'platform': 'pcp',
          'caliberMm': 6.35,
          'barrelLengthMm': '800',
          'airCapacityCc': -1,
        }
      ]),
    });

    await expectLater(
      UserCatalogStore().all(),
      throwsA(isA<FormatException>()),
    );
  });

}
