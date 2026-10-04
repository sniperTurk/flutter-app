import '../models/domain.dart';
import '../core/production_limits.dart';
import 'catalog_repository.dart';

/// Resolves and validates every catalog reference used by a saved profile.
///
/// Profiles are persisted across app/catalog upgrades, so an old profile can
/// outlive a renamed/removed catalog id. Ballistics must fail closed in that
/// case rather than silently substituting another rifle, ammunition or scope.
class ProfileCatalogResolution {
  final Rifle rifle;
  final Ammunition ammunition;
  final ScopeOptic scope;
  const ProfileCatalogResolution({
    required this.rifle,
    required this.ammunition,
    required this.scope,
  });
}

class ProfileCatalogIntegrity {
  const ProfileCatalogIntegrity();

  ProfileCatalogResolution? resolve(RifleProfile profile) {
    final rifle = _one(
      CatalogRepository.rifles,
      (x) => x.id == profile.rifleId,
    );
    final ammunition = _one(
      CatalogRepository.ammunition,
      (x) => x.id == profile.ammunitionId,
    );
    final scope = _one(
      CatalogRepository.scopes,
      (x) => x.id == profile.scopeId,
    );
    if (rifle == null || ammunition == null || scope == null) return null;

    // A profile is only coherent when rifle and ammunition belong to the same
    // platform and caliber. This also protects migrated/hand-edited data.
    if (rifle.platform != ammunition.platform) return null;
    if ((rifle.caliberMm - ammunition.caliberMm).abs() >= 0.001) return null;
    if (rifle.platform == WeaponPlatform.pcp && profile.pressureBar == null)
      return null;
    if (rifle.platform == WeaponPlatform.firearm && profile.pressureBar != null)
      return null;

    // Persisted profiles may predate current validation rules or be externally
    // modified. Reject unsafe numeric state here before ballistics can consume it.
    if (!_positiveAtMost(
      profile.muzzleVelocityMps,
      ProductionLimits.maxMuzzleVelocityMps,
    ))
      return null;
    if (!_positiveAtMost(profile.zeroRangeM, ProductionLimits.maxRangeM))
      return null;
    if (!profile.sightHeightMm.isFinite ||
        profile.sightHeightMm <= 0 ||
        profile.sightHeightMm >= ProductionLimits.maxSightHeightMm)
      return null;
    if (profile.pressureBar != null &&
        !_positiveAtMost(
          profile.pressureBar!,
          ProductionLimits.maxPcpPressureBar,
        ))
      return null;

    return ProfileCatalogResolution(
      rifle: rifle,
      ammunition: ammunition,
      scope: scope,
    );
  }

  bool _positiveAtMost(double value, double max) =>
      value.isFinite && value > 0 && value <= max;

  T? _one<T>(Iterable<T> values, bool Function(T) predicate) {
    T? found;
    for (final value in values) {
      if (!predicate(value)) continue;
      if (found != null) return null; // duplicate references are not safe
      found = value;
    }
    return found;
  }
}
