import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
void main(){TestWidgetsFlutterBinding.ensureInitialized();test('profile survives store re-instantiation',() async{SharedPreferences.setMockInitialValues({});final a=PersistentProfileStore();const p=RifleProfile(id:'1',name:'Hercules',rifleId:'r',ammunitionId:'a',scopeId:'s',muzzleVelocityMps:250,zeroRangeM:25,sightHeightMm:65,pressureBar:200);await a.save(p);final b=PersistentProfileStore();final all=await b.all();expect(all.single.name,'Hercules');expect(all.single.pressureBar,200);});

test('corrupt primary profile JSON recovers last known-good backup', () async {
  const key = 'sniper_turk.rifle_profiles.v1';
  const backupKey = 'sniper_turk.rifle_profiles.v1.backup';
  const good = '[{"id":"p1","name":"Recovered","rifleId":"r","ammunitionId":"a","scopeId":"s","muzzleVelocityMps":250,"zeroRangeM":25,"sightHeightMm":65,"pressureBar":200,"angularUnit":"mrad"}]';
  SharedPreferences.setMockInitialValues({key: '{broken-json', backupKey: good});
  final all = await PersistentProfileStore().all();
  expect(all, hasLength(1));
  expect(all.single.name, 'Recovered');
});

test('saving a profile keeps previous valid snapshot as backup', () async {
  SharedPreferences.setMockInitialValues({});
  final store = PersistentProfileStore();
  const first = RifleProfile(id:'1',name:'First',rifleId:'r',ammunitionId:'a',scopeId:'s',muzzleVelocityMps:250,zeroRangeM:25,sightHeightMm:65);
  const second = RifleProfile(id:'2',name:'Second',rifleId:'r',ammunitionId:'a',scopeId:'s',muzzleVelocityMps:250,zeroRangeM:25,sightHeightMm:65);
  await store.save(first);
  await store.save(second);
  final prefs = await SharedPreferences.getInstance();
  final backup = prefs.getString('sniper_turk.rifle_profiles.v1.backup');
  expect(backup, contains('First'));
  expect(backup, isNot(contains('Second')));
});

test('recovery self-heals corrupt primary snapshot', () async {
  const key = 'sniper_turk.rifle_profiles.v1';
  const backupKey = 'sniper_turk.rifle_profiles.v1.backup';
  const good = '[{"id":"p1","name":"Recovered","rifleId":"r","ammunitionId":"a","scopeId":"s","muzzleVelocityMps":250,"zeroRangeM":25,"sightHeightMm":65,"angularUnit":"mrad"}]';
  SharedPreferences.setMockInitialValues({key: '{broken-json', backupKey: good});
  final store = PersistentProfileStore();
  expect((await store.all()).single.name, 'Recovered');
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString(key), good);
});

test('duplicate persisted profile ids collapse to newest record', () async {
  const key = 'sniper_turk.rifle_profiles.v1';
  const duplicate = '[{"id":"p1","name":"Old","rifleId":"r","ammunitionId":"a","scopeId":"s","muzzleVelocityMps":250,"zeroRangeM":25,"sightHeightMm":65},{"id":"p1","name":"New","rifleId":"r","ammunitionId":"a","scopeId":"s","muzzleVelocityMps":251,"zeroRangeM":25,"sightHeightMm":65}]';
  SharedPreferences.setMockInitialValues({key: duplicate});
  final all = await PersistentProfileStore().all();
  expect(all, hasLength(1));
  expect(all.single.name, 'New');
  expect(all.single.muzzleVelocityMps, 251);
});


test('saving an existing profile id updates instead of duplicating', () async {
  final store = MemoryProfileStore();
  const original = RifleProfile(id:'same',name:'Original',rifleId:'r',ammunitionId:'a',scopeId:'s',muzzleVelocityMps:250,zeroRangeM:25,sightHeightMm:65);
  const edited = RifleProfile(id:'same',name:'Edited',rifleId:'r',ammunitionId:'a',scopeId:'s',muzzleVelocityMps:260,zeroRangeM:30,sightHeightMm:70);
  await store.save(original);
  await store.save(edited);
  final all = await store.all();
  expect(all, hasLength(1));
  expect(all.single.name, 'Edited');
  expect(all.single.muzzleVelocityMps, 260);
});


test('concurrent saves across store instances do not lose profiles', () async {
  SharedPreferences.setMockInitialValues({});
  final firstStore = PersistentProfileStore();
  final secondStore = PersistentProfileStore();
  const first = RifleProfile(id:'concurrent-1',name:'First concurrent',rifleId:'r',ammunitionId:'a',scopeId:'s',muzzleVelocityMps:250,zeroRangeM:25,sightHeightMm:65);
  const second = RifleProfile(id:'concurrent-2',name:'Second concurrent',rifleId:'r',ammunitionId:'a',scopeId:'s',muzzleVelocityMps:251,zeroRangeM:25,sightHeightMm:65);

  await Future.wait([firstStore.save(first), secondStore.save(second)]);

  final all = await PersistentProfileStore().all();
  expect(all.map((profile) => profile.id).toSet(), {'concurrent-1', 'concurrent-2'});
});

test('corrupt-primary recovery cannot overwrite a queued save', () async {
  const key = 'sniper_turk.rifle_profiles.v1';
  const backupKey = 'sniper_turk.rifle_profiles.v1.backup';
  const backup = '[{"id":"old","name":"Recovered","rifleId":"r","ammunitionId":"a","scopeId":"s","muzzleVelocityMps":250,"zeroRangeM":25,"sightHeightMm":65}]';
  SharedPreferences.setMockInitialValues({key: '{broken-json', backupKey: backup});
  final reader = PersistentProfileStore();
  final writer = PersistentProfileStore();
  const fresh = RifleProfile(id:'fresh',name:'Fresh',rifleId:'r',ammunitionId:'a',scopeId:'s',muzzleVelocityMps:255,zeroRangeM:25,sightHeightMm:65);

  final results = await Future.wait<dynamic>([reader.all(), writer.save(fresh)]);
  // Ordering between the reader and the queued writer is not part of the
  // contract; the reader may see the repaired backup alone or the backup plus
  // the queued save. It must never lose the recovered profile.
  expect((results.first as List<RifleProfile>).map((p) => p.id), contains('old'));
  final all = await PersistentProfileStore().all();
  expect(all.map((profile) => profile.id).toSet(), {'old', 'fresh'});
});


test('corrupt primary and corrupt backup fail closed instead of returning empty profiles', () async {
  const key = 'sniper_turk.rifle_profiles.v1';
  const backupKey = 'sniper_turk.rifle_profiles.v1.backup';
  SharedPreferences.setMockInitialValues({
    key: '{broken-primary',
    backupKey: '{broken-backup',
  });

  final store = PersistentProfileStore();
  await expectLater(store.all(), throwsA(isA<StateError>()));

  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString(key), '{broken-primary');
  expect(prefs.getString(backupKey), '{broken-backup');
});

test('save refuses to overwrite profiles when both persisted snapshots are corrupt', () async {
  const key = 'sniper_turk.rifle_profiles.v1';
  const backupKey = 'sniper_turk.rifle_profiles.v1.backup';
  SharedPreferences.setMockInitialValues({
    key: '{broken-primary',
    backupKey: '{broken-backup',
  });
  const fresh = RifleProfile(id:'fresh-after-corruption',name:'Fresh',rifleId:'r',ammunitionId:'a',scopeId:'s',muzzleVelocityMps:255,zeroRangeM:25,sightHeightMm:65);

  await expectLater(PersistentProfileStore().save(fresh), throwsA(isA<StateError>()));

  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString(key), '{broken-primary');
  expect(prefs.getString(backupKey), '{broken-backup');
});


test('missing primary recovers surviving profile backup and self-heals', () async {
  const key = 'sniper_turk.rifle_profiles.v1';
  const backupKey = 'sniper_turk.rifle_profiles.v1.backup';
  const good = '[{"id":"p1","name":"Recovered missing primary","rifleId":"r","ammunitionId":"a","scopeId":"s","muzzleVelocityMps":250,"zeroRangeM":25,"sightHeightMm":65}]';
  SharedPreferences.setMockInitialValues({backupKey: good});
  final all = await PersistentProfileStore().all();
  expect(all.single.name, 'Recovered missing primary');
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString(key), good);
});

test('first profile write creates a recoverable backup', () async {
  const backupKey = 'sniper_turk.rifle_profiles.v1.backup';
  SharedPreferences.setMockInitialValues({});
  const first = RifleProfile(id:'first-backup',name:'First backup',rifleId:'r',ammunitionId:'a',scopeId:'s',muzzleVelocityMps:250,zeroRangeM:25,sightHeightMm:65);
  await PersistentProfileStore().save(first);
  final prefs = await SharedPreferences.getInstance();
  final backup = prefs.getString(backupKey);
  expect(backup, isNotNull);
  expect(backup, contains('first-backup'));
});



test('corrupt primary without backup fails closed', () async {
  const key = 'sniper_turk.rifle_profiles.v1';
  SharedPreferences.setMockInitialValues({key: '{broken-primary'});
  await expectLater(PersistentProfileStore().all(), throwsA(isA<StateError>()));
});

test('empty persisted primary is corruption, not an empty profile collection', () async {
  const key = 'sniper_turk.rifle_profiles.v1';
  SharedPreferences.setMockInitialValues({key: ''});
  await expectLater(PersistentProfileStore().all(), throwsA(isA<StateError>()));
});



  test('self-heal quarantines the corrupt primary bytes before overwriting them', () async {
    const key = 'sniper_turk.rifle_profiles.v1';
    const backupKey = 'sniper_turk.rifle_profiles.v1.backup';
    const quarantineKey = 'sniper_turk.rifle_profiles.v1.corrupt';
    const good = '[{"id":"p1","name":"Recovered","rifleId":"r","ammunitionId":"a","scopeId":"s","muzzleVelocityMps":250,"zeroRangeM":25,"sightHeightMm":65,"angularUnit":"mrad"}]';
    SharedPreferences.setMockInitialValues({key: '{broken-json', backupKey: good});
    expect((await PersistentProfileStore().all()).single.name, 'Recovered');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(key), good);
    expect(prefs.getString(quarantineKey), '{broken-json');
  });

  test('first quarantined evidence is never overwritten by later corruption', () async {
    const key = 'sniper_turk.rifle_profiles.v1';
    const backupKey = 'sniper_turk.rifle_profiles.v1.backup';
    const quarantineKey = 'sniper_turk.rifle_profiles.v1.corrupt';
    const good = '[{"id":"p1","name":"Recovered","rifleId":"r","ammunitionId":"a","scopeId":"s","muzzleVelocityMps":250,"zeroRangeM":25,"sightHeightMm":65,"angularUnit":"mrad"}]';
    SharedPreferences.setMockInitialValues({key: '{second-corruption', backupKey: good, quarantineKey: '{first-corruption'});
    await PersistentProfileStore().all();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(quarantineKey), '{first-corruption');
  });

  test('saving over a corrupt primary quarantines it first', () async {
    const key = 'sniper_turk.rifle_profiles.v1';
    const backupKey = 'sniper_turk.rifle_profiles.v1.backup';
    const quarantineKey = 'sniper_turk.rifle_profiles.v1.corrupt';
    const good = '[{"id":"p1","name":"Recovered","rifleId":"r","ammunitionId":"a","scopeId":"s","muzzleVelocityMps":250,"zeroRangeM":25,"sightHeightMm":65,"angularUnit":"mrad"}]';
    SharedPreferences.setMockInitialValues({key: '{broken-json', backupKey: good});
    const fresh = RifleProfile(id: 'n', name: 'N', rifleId: 'r', ammunitionId: 'a', scopeId: 's', muzzleVelocityMps: 255, zeroRangeM: 25, sightHeightMm: 65);
    await PersistentProfileStore().save(fresh);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(quarantineKey), '{broken-json');
  });
}
