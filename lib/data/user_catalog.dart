import '../models/domain.dart';
import 'catalog_repository.dart';

/// Source label shown for every record the user typed in. It deliberately
/// names the user, never a manufacturer.
const userCatalogSourceName = 'Kullanıcı girdisi';
const userCatalogSourceDocument = 'Kişisel kayıt; üretici doğrulaması yok';

/// A personal catalog record that exists but cannot be used in a profile yet,
/// together with the reason shown to the user.
class UserCatalogIssue {
  final String id;

  /// 'rifle', 'ammunition' or 'scope'.
  final String kind;
  final WeaponPlatform? platform;
  final String label;
  final String reason;
  const UserCatalogIssue({
    required this.id,
    required this.kind,
    required this.platform,
    required this.label,
    required this.reason,
  });
}

/// The user's manual catalog converted into the same domain types the profile
/// editor and solver use. Conversion is fail-closed: a record that lacks a
/// value the app needs is never completed with a guess; it is listed in
/// [blocked] with the missing fields instead.
class UserCatalog {
  final List<Rifle> rifles;
  final List<Ammunition> ammunition;
  final List<ScopeOptic> scopes;
  final List<UserCatalogIssue> blocked;

  const UserCatalog({
    this.rifles = const [],
    this.ammunition = const [],
    this.scopes = const [],
    this.blocked = const [],
  });

  static const empty = UserCatalog();

  bool get isEmpty =>
      rifles.isEmpty && ammunition.isEmpty && scopes.isEmpty && blocked.isEmpty;

  /// Converts records persisted by `ManualCatalogStore` (already validated by
  /// that store's persistence boundary).
  factory UserCatalog.fromManualEntries(
    Iterable<Map<String, dynamic>> entries,
  ) {
    final rifles = <Rifle>[];
    final ammunition = <Ammunition>[];
    final scopes = <ScopeOptic>[];
    final blocked = <UserCatalogIssue>[];
    final builtInIds = <String>{
      for (final r in CatalogRepository.rifles) r.id,
      for (final a in CatalogRepository.ammunition) a.id,
      for (final s in CatalogRepository.scopes) s.id,
    };

    for (final e in entries) {
      final id = e['id'];
      final kind = e['kind'];
      if (id is! String || kind is! String) continue;
      final platform = _platform(e['platform']);
      final brand = (e['brand'] as String? ?? '').trim();
      final model = (e['model'] as String? ?? '').trim();
      final label = [brand, model].where((s) => s.isNotEmpty).join(' ');
      final issueKind = kind == 'rifle'
          ? 'rifle'
          : kind == 'scope'
          ? 'scope'
          : 'ammunition';

      void block(String reason) => blocked.add(
        UserCatalogIssue(
          id: id,
          kind: issueKind,
          platform: issueKind == 'scope' ? null : platform,
          label: label.isEmpty ? id : label,
          reason: reason,
        ),
      );

      if (builtInIds.contains(id)) {
        block(
          'Kimliği bir katalog kaydıyla çakışıyor; kaydı yeniden oluşturun.',
        );
        continue;
      }

      switch (kind) {
        case 'rifle':
          final caliber = _positive(e['caliberMm']);
          if (platform == null || caliber == null) {
            block('Platform ve kalibre gerekli.');
            continue;
          }
          rifles.add(
            Rifle(
              id: id,
              brand: brand,
              model: model,
              platform: platform,
              caliberMm: caliber,
              barrelLengthMm: _positive(e['barrelLengthMm']),
              airCapacityCc: _positive(e['airCapacityCc']),
              sourceName: userCatalogSourceName,
              sourceDocument: userCatalogSourceDocument,
              userEntered: true,
            ),
          );
        case 'ammo':
        case 'custom_ammunition':
          final custom = kind == 'custom_ammunition';
          final caliber = _positive(e['caliberMm']);
          final grain = _positive(e['grain']);
          final type = _ammoType(e['ammoType']);
          final missing = <String>[
            if (platform == null) 'platform',
            if (caliber == null) 'kalibre',
            if (grain == null) 'ağırlık (grain)',
            if (type == null) 'mühimmat tipi',
          ];
          if (missing.isNotEmpty) {
            block(
              '${custom ? 'Özel yapım mermide' : 'Mühimmatta'} '
              '${missing.join(', ')} eksik; profilde kullanmak için kaydı '
              'Katalog ekranında tamamlayın.',
            );
            continue;
          }
          // A BC is only meaningful together with its drag model. Without an
          // explicit G1/G7 model the value is not attached to the record.
          final bcModel = custom ? _ballisticModel(e['bcModel']) : null;
          final bc = bcModel == null ? null : _positive(e['bc']);
          ammunition.add(
            Ammunition(
              id: id,
              brand: brand.isEmpty ? 'Özel yapım' : brand,
              model: model,
              platform: platform!,
              caliberMm: caliber!,
              grain: grain!,
              type: type!,
              ballisticCoefficient: bc,
              ballisticModel: bc == null ? null : bcModel,
              sourceName: userCatalogSourceName,
              sourceDocument: custom
                  ? 'Özel yapım mühimmat; doğrulanmamış kişisel kayıt'
                  : userCatalogSourceDocument,
              userEntered: true,
            ),
          );
        case 'scope':
          final objective = _positive(e['objectiveMm']);
          final click = _positive(e['click']);
          final unit = _angularUnit(e['clickUnit']);
          final missing = <String>[
            if (objective == null) 'objektif çapı',
            if (click == null) 'klik değeri',
            if (unit == null) 'klik birimi (MRAD/MOA)',
          ];
          if (missing.isNotEmpty) {
            block(
              'Dürbünde ${missing.join(', ')} eksik; profilde kullanmak için '
              'kaydı Katalog ekranında tamamlayın.',
            );
            continue;
          }
          scopes.add(
            ScopeOptic(
              id: id,
              brand: brand,
              model: model,
              objectiveDiameterMm: objective!,
              clickValue: click!,
              clickUnit: unit!,
              firstFocalPlane: switch (e['focal']) {
                'ffp' => true,
                'sfp' => false,
                _ => null,
              },
              sourceName: userCatalogSourceName,
              sourceDocument: userCatalogSourceDocument,
              userEntered: true,
            ),
          );
        default:
          continue;
      }
    }
    return UserCatalog(
      rifles: List.unmodifiable(rifles),
      ammunition: List.unmodifiable(ammunition),
      scopes: List.unmodifiable(scopes),
      blocked: List.unmodifiable(blocked),
    );
  }

  static double? _positive(Object? v) =>
      v is num && v.isFinite && v > 0 ? v.toDouble() : null;

  static WeaponPlatform? _platform(Object? v) => switch (v) {
    'pcp' => WeaponPlatform.pcp,
    'firearm' => WeaponPlatform.firearm,
    _ => null,
  };

  static AmmunitionType? _ammoType(Object? v) => switch (v) {
    'pellet' => AmmunitionType.pellet,
    'slug' => AmmunitionType.slug,
    'bullet' => AmmunitionType.bullet,
    _ => null,
  };

  static AngularUnit? _angularUnit(Object? v) => switch (v) {
    'mrad' => AngularUnit.mrad,
    'moa' => AngularUnit.moa,
    _ => null,
  };

  static BallisticModel? _ballisticModel(Object? v) {
    if (v is! String) return null;
    return switch (v.trim().toUpperCase()) {
      'G1' => BallisticModel.g1,
      'G7' => BallisticModel.g7,
      _ => null,
    };
  }
}
