import '../../models/domain.dart';

/// PRF-2 / PRF-6: ids of the rifle, ammunition and scope records that a
/// profile other than [exceptProfileId] points at. A personal record in this
/// set is never written in place: the saving profile gets its own copy under
/// a new id. Used by Profili Düzenle and Hız Doğrulama.
Set<String> sharedRecordIdsOf(
  Iterable<RifleProfile> profiles, {
  String? exceptProfileId,
}) => {
  for (final x in profiles)
    if (x.id != exceptProfileId) ...[x.rifleId, x.ammunitionId, x.scopeId],
};
