import '../data/catalog_repository.dart';
import '../data/user_catalog.dart';
import '../models/domain.dart';
import 'manual_catalog_store.dart';
import 'profile_store.dart';

/// "Örnek profille dene" (owner, 2026-10-10): two ready profiles with
/// typical values, so a first-time user sees the whole app working without
/// typing anything. They are ordinary personal records: editable, deletable.
abstract final class SampleProfiles {
  static const pcpId = 'sample-pcp';
  static const firearmId = 'sample-308';

  /// Pro "Atış mesafesi" the PCP sample opens Hedef with (dialled).
  static const pcpRangeM = 75.0;

  static bool isSample(RifleProfile? p) =>
      p != null && (p.id == pcpId || p.id == firearmId);

  static const _entries = <Map<String, dynamic>>[
    {
      'id': 'manual_rifle_sample_pcp',
      'kind': 'rifle',
      'platform': 'pcp',
      'brand': 'Örnek PCP',
      'model': '.22 (5,5 mm)',
      'caliberMm': 5.5,
      'twistDirection': 'right',
      'twistRateIn': 18,
      'sourceName': userCatalogSourceName,
    },
    {
      'id': 'manual_ammo_sample_pcp',
      'kind': 'ammo',
      'platform': 'pcp',
      'brand': 'Diabolo saçma 18,1 gr',
      'model': '',
      'caliberMm': 5.5,
      'grain': 18.1,
      'ammoType': 'pellet',
      'bc': 0.033,
      'bcModel': 'g1',
      'sourceName': userCatalogSourceName,
    },
    {
      'id': 'manual_scope_sample_pcp',
      'kind': 'scope',
      'platform': 'pcp',
      'brand': 'Örnek dürbün',
      'model': '4-16 x 50 FFP',
      'objectiveMm': 50,
      'click': 0.1,
      'clickUnit': 'mrad',
      'focal': 'ffp',
      'minMag': 4,
      'maxMag': 16,
      'magnification': '4-16x',
      'elevationRangeMrad': 29,
      'sourceName': userCatalogSourceName,
    },
    {
      'id': 'manual_rifle_sample_308',
      'kind': 'rifle',
      'platform': 'firearm',
      'brand': 'Örnek tüfek',
      'model': '.308 Win',
      'caliberMm': 7.62,
      'twistDirection': 'right',
      'twistRateIn': 11,
      'sourceName': userCatalogSourceName,
    },
    {
      'id': 'manual_ammo_sample_308',
      'kind': 'ammo',
      'platform': 'firearm',
      'brand': '.308 Win 168 gr HPBT',
      'model': '',
      'caliberMm': 7.62,
      'grain': 168,
      'ammoType': 'bullet',
      'bc': 0.462,
      'bcModel': 'g1',
      'sourceName': userCatalogSourceName,
    },
    {
      'id': 'manual_scope_sample_308',
      'kind': 'scope',
      'platform': 'firearm',
      'brand': 'Örnek dürbün',
      'model': '5-25 x 56 FFP',
      'objectiveMm': 56,
      'click': 0.1,
      'clickUnit': 'mrad',
      'focal': 'ffp',
      'minMag': 5,
      'maxMag': 25,
      'magnification': '5-25x',
      'elevationRangeMrad': 30,
      'sourceName': userCatalogSourceName,
    },
  ];

  static const pcp = RifleProfile(
    id: pcpId,
    name: 'Örnek PCP .22',
    rifleId: 'manual_rifle_sample_pcp',
    ammunitionId: 'manual_ammo_sample_pcp',
    scopeId: 'manual_scope_sample_pcp',
    muzzleVelocityMps: 280,
    zeroRangeM: 30,
    sightHeightMm: 50,
  );

  static const firearm = RifleProfile(
    id: firearmId,
    name: 'Örnek .308',
    rifleId: 'manual_rifle_sample_308',
    ammunitionId: 'manual_ammo_sample_308',
    scopeId: 'manual_scope_sample_308',
    muzzleVelocityMps: 800,
    zeroRangeM: 100,
    sightHeightMm: 45,
  );

  /// Writes the records and both profiles; returns the profile to open
  /// first (PCP). Existing samples are overwritten with the same values.
  static Future<RifleProfile> install({
    required ProfileStore profiles,
    ManualCatalogStore? manual,
  }) async {
    final store = manual ?? ManualCatalogStore();
    for (final e in _entries) {
      await store.upsert(Map<String, dynamic>.from(e));
    }
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries(await store.all()),
    );
    await profiles.save(firearm);
    await profiles.save(pcp);
    return pcp;
  }
}
