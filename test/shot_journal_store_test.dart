// Ö9 Atış günlüğü deposu: telefonda JSON, bozuk kayıt atlanır, sınır 1000,
// soğuk namlu onayı profil + susturucu başına.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/services/shot_journal_store.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';

ShotRecord _rec(String id, {String profile = 'p1', int minute = 0}) =>
    ShotRecord(
      id: id,
      time: DateTime.utc(2026, 10, 12, 10, minute),
      profileId: profile,
      rangeM: 300,
      firstShot: true,
      suppressor: false,
      missUpCm: 4,
      missRightCm: -1,
      elevationText: '2,1',
      windageText: '',
      unitLabel: 'MRAD',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('add, load newest first per profile, delete', () async {
    const store = ShotJournalStore();
    await store.add(_rec('a', minute: 1));
    await store.add(_rec('b', minute: 5));
    await store.add(_rec('c', profile: 'p2'));
    final p1 = await store.load(profileId: 'p1');
    expect(p1.map((r) => r.id), ['b', 'a']);
    expect(p1.first.missRightCm, -1);
    expect(p1.first.elevationText, '2,1');
    await store.delete('b');
    expect((await store.load(profileId: 'p1')).map((r) => r.id), ['a']);
    expect((await store.load()).length, 2);
  });

  test(
    'damaged storage: unreadable JSON is empty, bad records skipped',
    () async {
      SharedPreferences.setMockInitialValues({ShotJournalStore.key: '{nope'});
      expect(await const ShotJournalStore().load(), isEmpty);
      SharedPreferences.setMockInitialValues({
        ShotJournalStore.key: jsonEncode([
          _rec('ok').toJson(),
          {'id': 'bad', 'rangeM': 'x'},
          {..._rec('nan').toJson(), 'rangeM': -5},
        ]),
      });
      expect((await const ShotJournalStore().load()).map((r) => r.id), ['ok']);
    },
  );

  test('keeps at most maxRecords, dropping the oldest', () async {
    final many = [
      for (var i = 0; i < ShotJournalStore.maxRecords; i++)
        _rec('r$i', minute: 0).toJson(),
    ];
    SharedPreferences.setMockInitialValues({
      ShotJournalStore.key: jsonEncode(many),
    });
    const store = ShotJournalStore();
    await store.add(_rec('new', minute: 30));
    final all = await store.load();
    expect(all.length, ShotJournalStore.maxRecords);
    expect(all.first.id, 'new');
  });

  test('cold bore approval per profile and suppressor state', () async {
    const store = ShotJournalStore();
    expect(await store.isApproved('p1', suppressor: true), isFalse);
    await store.setApproved('p1', suppressor: true, approved: true);
    expect(await store.isApproved('p1', suppressor: true), isTrue);
    expect(await store.isApproved('p1', suppressor: false), isFalse);
    await store.setApproved('p1', suppressor: true, approved: false);
    expect(await store.isApproved('p1', suppressor: true), isFalse);
  });

  test('zero offset update keeps the other Pro values and notifies', () async {
    const settings = ShotSettingsStore();
    await settings.save(
      'p1',
      const ShotSettings(cantDeg: 2, groupText: '3', zeroUpText: '9'),
    );
    final before = ShotSettingsStore.changes.value;
    await settings.updateZeroOffset('p1', upText: '1,2', rightText: '-0,4');
    final s = (await settings.load('p1'))!;
    expect(s.zeroUpText, '1,2');
    expect(s.zeroRightText, '-0,4');
    expect(s.cantDeg, 2);
    expect(s.groupText, '3');
    expect(ShotSettingsStore.changes.value, before + 1);
  });
}
