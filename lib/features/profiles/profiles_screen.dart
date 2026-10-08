import 'package:flutter/material.dart';

import '../../core/production_limits.dart';
import '../../core/profile_input.dart';
import '../../core/scope_dial.dart';
import '../../core/unit_system.dart';
import '../../core/units.dart';
import '../../data/catalog_repository.dart';
import '../../data/user_catalog.dart';
import '../../models/domain.dart';
import '../../services/app_settings.dart';
import '../../services/manual_catalog_store.dart';
import '../../services/profile_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'profile_field_info.dart';
import 'profile_recovery_dialog.dart';

/// Profile list and management.
///
/// [embedded] renders the page body for the shell's Profil tab (the shell owns
/// the top bar, the active-profile state and persistence of the active id).
/// Without it the screen is a stand-alone route with its own app bar.
class ProfilesScreen extends StatefulWidget {
  final ProfileStore? store;
  final bool embedded;
  final String? activeProfileId;
  final Future<void> Function(RifleProfile? profile)? onActivate;
  final Future<void> Function()? onProfilesChanged;

  /// Shell only: next step after choosing a profile (Hava Durumu). When set,
  /// the active-profile summary offers a button for it.
  final VoidCallback? onContinue;

  /// Bumped by the shell whenever it reloaded profiles, so this list stays in
  /// sync with changes made elsewhere.
  final int revision;

  const ProfilesScreen({
    super.key,
    this.store,
    this.embedded = false,
    this.activeProfileId,
    this.onActivate,
    this.onProfilesChanged,
    this.onContinue,
    this.revision = 0,
  });

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  late final ProfileStore store = widget.store ?? PersistentProfileStore();
  List<RifleProfile> items = [];
  bool loading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfilesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }
    try {
      final loaded = await store.all();
      if (mounted) {
        setState(() {
          items = loaded;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          loadError = 'Profiller okunamadı. Kayıtlar değiştirilmedi.';
        });
      }
    }
  }

  Future<void> _recover() async {
    // ProfileRecovery is not a subtype of ProfileStore, so promote via Object.
    final Object recovery = store;
    if (recovery is! ProfileRecovery) return;
    final reset = await showProfileRecoveryDialog(context, recovery);
    if (reset && mounted) await _changed();
  }

  Future<void> _changed() async {
    await _load();
    await widget.onProfilesChanged?.call();
  }

  Future<void> _add() async => _openEditor();

  Future<void> _edit(RifleProfile profile) async => _openEditor(profile);

  Future<void> _openEditor([RifleProfile? existing]) async {
    final p = await Navigator.push<RifleProfile>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ProfileDialog(
          initial: existing,
          takenNames: {for (final x in items) x.name},
        ),
      ),
    );
    if (p != null) {
      try {
        await store.save(p);
        await _changed();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                existing == null
                    ? 'Profil kaydedilemedi. Mevcut kayıtlar korunuyor.'
                    : 'Profil güncellenemedi. Mevcut kayıt korunuyor.',
              ),
            ),
          );
        }
      }
    }
  }

  /// Saves an independent copy (new id) through the same store API.
  Future<void> _duplicate(RifleProfile p) async {
    const suffix = ' (kopya)';
    const maxBase = ProductionLimits.maxProfileNameLength - suffix.length;
    final base = p.name.length > maxBase
        ? p.name.substring(0, maxBase).trimRight()
        : p.name;
    final copy = RifleProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '$base$suffix',
      rifleId: p.rifleId,
      ammunitionId: p.ammunitionId,
      scopeId: p.scopeId,
      muzzleVelocityMps: p.muzzleVelocityMps,
      zeroRangeM: p.zeroRangeM,
      sightHeightMm: p.sightHeightMm,
      pressureBar: p.pressureBar,
      angularUnit: p.angularUnit,
      mountCantMoa: p.mountCantMoa,
    );
    try {
      await store.save(copy);
      await _changed();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('“${copy.name}” oluşturuldu.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil kopyalanamadı. Mevcut kayıtlar korunuyor.'),
          ),
        );
      }
    }
  }

  /// Profile deletion is destructive and may remove the profile currently
  /// selected as active. Require an explicit confirmation before touching
  /// persistent storage so an accidental tap or swipe cannot destroy a
  /// carefully configured ballistic profile. Returns true when removed.
  Future<bool> _confirmAndRemove(RifleProfile p) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Profili sil?'),
            content: Text(
              '“${p.name}” profili kalıcı olarak silinecek. '
              'Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: MenzilColors.of(dialogContext).danger,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Profili sil'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return false;
    try {
      await store.remove(p.id);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil silinemedi. Kayıt korunuyor.')),
        );
      }
      return false;
    }
  }

  Future<void> _deleteViaButton(RifleProfile p) async {
    if (await _confirmAndRemove(p)) {
      if (mounted) {
        setState(() => items = items.where((x) => x.id != p.id).toList());
      }
      await widget.onProfilesChanged?.call();
    }
  }

  RifleProfile? get _selected {
    final id = widget.activeProfileId;
    if (id == null) return null;
    for (final p in items) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final body = loading
        ? const Center(child: CircularProgressIndicator())
        : loadError != null
        ? MenzilStateMessage(
            message: loadError!,
            action: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MenzilPrimaryButton(
                  label: 'Tekrar dene',
                  onPressed: _load,
                  icon: Icons.refresh,
                  expand: false,
                ),
                if (store is ProfileRecovery) ...[
                  const SizedBox(height: MenzilSpace.md),
                  MenzilSecondaryButton(
                    key: const Key('profiles-recover'),
                    label: 'Kayıtları kurtar',
                    icon: Icons.healing,
                    onPressed: _recover,
                  ),
                ],
              ],
            ),
          )
        : _content(context);
    if (widget.embedded) return body;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Profiller'),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Yeni profil',
        onPressed: loading ? null : _add,
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }

  Widget _content(BuildContext context) {
    final c = MenzilColors.of(context);
    final selected = _selected;
    return MenzilPage(
      children: [
        // The app opens here: the profile in use comes first, with the next
        // step one tap away; the list for switching or managing follows.
        if (selected != null) ...[
          _ActiveProfileDetails(
            profile: selected,
            onEdit: () => _edit(selected),
            onContinue: widget.embedded ? widget.onContinue : null,
          ),
          const SizedBox(height: MenzilSpace.lg),
        ],
        MenzilSectionHeader(
          'Profiller',
          subtitle: items.isEmpty ? null : '${items.length} kayıtlı profil',
          padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
        ),
        if (items.isEmpty)
          MenzilCard(
            child: Text(
              'Henüz kayıtlı profil yok.\nYeni profil ile ilk profilini oluştur.',
              textAlign: TextAlign.center,
              style: MenzilType.body(c.ink),
            ),
          )
        else
          for (final p in items)
            Dismissible(
              key: ValueKey(p.id),
              background: Container(
                margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
                decoration: BoxDecoration(
                  color: c.danger,
                  borderRadius: BorderRadius.circular(MenzilRadius.card),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.all(20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmAndRemove(p),
              onDismissed: (_) {
                setState(
                  () => items = items.where((x) => x.id != p.id).toList(),
                );
                widget.onProfilesChanged?.call();
              },
              child: _ProfileRow(
                profile: p,
                active: p.id == widget.activeProfileId,
                onTap: widget.embedded && widget.onActivate != null
                    ? () => widget.onActivate!(p)
                    : () => _edit(p),
                onEdit: () => _edit(p),
              ),
            ),
        const SizedBox(height: MenzilSpace.xs),
        Wrap(
          spacing: MenzilSpace.sm,
          runSpacing: MenzilSpace.sm,
          children: [
            MenzilPrimaryButton(
              label: 'Yeni profil',
              icon: Icons.add,
              amber: true,
              expand: false,
              onPressed: _add,
            ),
            if (selected != null) ...[
              MenzilSecondaryButton(
                label: 'Kopyala',
                icon: Icons.copy_outlined,
                onPressed: () => _duplicate(selected),
              ),
              MenzilSecondaryButton(
                label: 'Sil',
                icon: Icons.delete_outline,
                destructive: true,
                onPressed: () => _deleteViaButton(selected),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final RifleProfile profile;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ProfileRow({
    required this.profile,
    required this.active,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final shape = BorderRadius.circular(MenzilRadius.card);
    return Padding(
      padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
      child: Semantics(
        container: true,
        selected: active,
        button: true,
        label: active
            ? 'Aktif profil ${profile.name}'
            : 'Profil ${profile.name}',
        child: Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: shape,
            side: BorderSide(
              color: active ? c.ink : c.line,
              width: active ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: shape,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? c.amber : c.surface2,
                      ),
                    ),
                    const SizedBox(width: MenzilSpace.md),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: c.ink,
                              ),
                            ),
                            Text(
                              '${_ProfileUnits.of(context).velocity(profile.muzzleVelocityMps)} • '
                              'Sıfır ${_ProfileUnits.of(context).distance(profile.zeroRangeM)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MenzilType.caption(c.ink2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (active)
                      Padding(
                        padding: const EdgeInsets.only(left: MenzilSpace.xs),
                        child: Text(
                          'Aktif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.amberInk,
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Profili düzenle',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Personal records are never presented as manufacturer data.
String _labelled(String? name, bool? userEntered, String fallbackId) =>
    name == null
    ? fallbackId
    : userEntered == true
    ? '$name — kişisel kayıt, üretici doğrulaması yok'
    : name;

/// Read-only summary of the active profile plus the catalog values it
/// resolves to. Purely informational: nothing here feeds the solver.
/// "6-36 x 56 FFP" from the scope's magnification, objective and focal
/// plane; parts that are unknown are left out.
String _scopeSummary(ScopeOptic s) {
  final lo = s.minMagnification, hi = s.maxMagnification;
  final mag = lo == null || hi == null
      ? ''
      : lo == hi
      ? _trimNum(lo)
      : '${_trimNum(lo)}-${_trimNum(hi)}';
  final objective = s.objectiveDiameterMm > 0
      ? _trimNum(s.objectiveDiameterMm)
      : '';
  final size = [mag, objective].where((p) => p.isNotEmpty).join(' x ');
  final focal = s.firstFocalPlane == null
      ? ''
      : (s.firstFocalPlane! ? 'FFP' : 'SFP');
  return [size, focal].where((p) => p.isNotEmpty).join(' ');
}

/// Total clicks of the top (elevation) turret, from the stored travel and
/// the scope's click value; null when the travel is unknown.
int? _topTurretClicks(ScopeOptic s) {
  final mrad = s.elevationRangeMrad;
  if (mrad == null || mrad <= 0 || s.clickValue <= 0) return null;
  final travel = s.clickUnit == AngularUnit.moa ? Units.mradToMoa(mrad) : mrad;
  return (travel / s.clickValue).round();
}

String _ammoTypeName(AmmunitionType t) => switch (t) {
  AmmunitionType.pellet => 'Pellet',
  AmmunitionType.slug => 'Slug',
  AmmunitionType.bullet => 'Bullet',
};

class _ActiveProfileDetails extends StatelessWidget {
  final RifleProfile profile;
  final VoidCallback onEdit;
  final VoidCallback? onContinue;

  const _ActiveProfileDetails({
    required this.profile,
    required this.onEdit,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final rifle = CatalogRepository.allRifles
        .where((r) => r.id == profile.rifleId)
        .firstOrNull;
    final ammo = CatalogRepository.allAmmunition
        .where((a) => a.id == profile.ammunitionId)
        .firstOrNull;
    final scope = CatalogRepository.allScopes
        .where((o) => o.id == profile.scopeId)
        .firstOrNull;
    final barrelLengthMm = rifle?.barrelLengthMm;
    final ballisticCoefficient = ammo?.ballisticCoefficient;
    final ballisticModelName = ammo?.ballisticModel?.name.toUpperCase() ?? '';
    final units = _ProfileUnits.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MenzilSectionHeader(
          // The name is already in the top-bar selector and the list; it is
          // not repeated here (owner, 2026-10-08).
          'Aktif profil',
          trailing: TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Düzenle'),
          ),
          padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
        ),
        _KeyValueCard(
          rows: [
            (
              'Tüfek',
              _labelled(
                rifle?.displayName,
                rifle?.userEntered,
                profile.rifleId,
              ),
            ),
            (
              'Mühimmat',
              _labelled(
                ammo?.displayName,
                ammo?.userEntered,
                profile.ammunitionId,
              ),
            ),
            (
              'Dürbün',
              _labelled(
                scope?.displayName,
                scope?.userEntered,
                profile.scopeId,
              ),
            ),
          ],
        ),
        // Order and names set by the owner (2026-10-09). Regülatör, Odak
        // düzlemi and Klik değeri have no box of their own any more.
        MenzilMetricGrid(
          columns: 2,
          metrics: [
            MenzilMetric(
              'Namlu çıkış hızı',
              units.velocityValue(profile.muzzleVelocityMps),
              units.velocityUnit,
            ),
            if (rifle?.twistDirection != null)
              MenzilMetric(
                'Yiv yönü',
                rifle!.twistDirection == TwistDirection.right ? 'Sağ' : 'Sol',
              ),
            if (barrelLengthMm != null)
              MenzilMetric('Namlu boyu', _trimNum(barrelLengthMm / 10), 'cm'),
            if (rifle != null)
              MenzilMetric('Kalibre', rifle.caliberMm.toStringAsFixed(2), 'mm'),
            if (rifle?.twistRateIn != null)
              MenzilMetric(
                'Yiv oranı',
                '1:${_trimNum(rifle!.twistRateIn!)}',
                'inç',
              ),
            MenzilMetric(
              'Sight height',
              profile.sightHeightMm.toStringAsFixed(1),
              'mm',
            ),
            MenzilMetric(
              'Sıfırlama mesafesi',
              units.distanceValue(profile.zeroRangeM),
              units.distanceUnit,
            ),
            if (scope != null)
              MenzilMetric(
                'Dürbün Marka Model',
                // Personal scopes store the designation as their model;
                // it is shown in the Dürbün box, so only the brand here.
                scope.userEntered ? scope.brand : scope.displayName,
              ),
            if (scope != null && _scopeSummary(scope).isNotEmpty)
              MenzilMetric('Dürbün', _scopeSummary(scope)),
            MenzilMetric(
              'Dürbün ayağı',
              profile.mountCantMoa > 0 ? _trimNum(profile.mountCantMoa) : 'Yok',
              profile.mountCantMoa > 0 ? 'MOA' : null,
            ),
            MenzilMetric(
              'Dürbün birimi',
              profile.angularUnit == AngularUnit.moa ? 'MOA' : 'MRAD',
            ),
            if (scope != null && _topTurretClicks(scope) != null)
              MenzilMetric(
                'Dürbün üst kule',
                '${_topTurretClicks(scope)}',
                'klik',
              ),
            if (ammo != null)
              MenzilMetric(
                'Mühimmat',
                ammo.grain.toStringAsFixed(ammo.grain % 1 == 0 ? 0 : 1),
                'gr ${_ammoTypeName(ammo.type)}',
              ),
            MenzilMetric(
              'BC / model',
              ballisticCoefficient == null
                  ? '—'
                  : '$ballisticCoefficient $ballisticModelName'.trim(),
            ),
          ],
        ),
        Text(
          'Katalog değerleri bilgi amaçlıdır. Mühimmatın BC ve G1/G7 modeli '
          'varsa Atış hesabı sürüklenme çözücüsünü kullanır; yoksa vakum '
          'temel hesap çalışır ve bu ekranda belirtilir.',
          style: MenzilType.caption(MenzilColors.of(context).ink2),
        ),
        if (onContinue != null) ...[
          const SizedBox(height: MenzilSpace.md),
          MenzilPrimaryButton(
            key: const Key('profile-continue-weather'),
            label: 'Hava Durumu\'na geç',
            icon: Icons.arrow_forward,
            onPressed: onContinue,
          ),
        ],
      ],
    );
  }
}

class _KeyValueCard extends StatelessWidget {
  final List<(String, String)> rows;
  const _KeyValueCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return MenzilCard(
      padding: const EdgeInsets.symmetric(
        horizontal: MenzilSpace.lg,
        vertical: MenzilSpace.sm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(top: BorderSide(color: c.line)),
              ),
              padding: const EdgeInsets.symmetric(vertical: MenzilSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(rows[i].$1, style: MenzilType.label(c.ink2)),
                  ),
                  Expanded(
                    child: Text(rows[i].$2, style: MenzilType.body(c.ink)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-screen profile editor (create / edit). Returns the validated profile
/// via `Navigator.pop`; persistence stays with the caller.
/// Default name for a new profile that does not repeat an existing one:
/// "Yeni Profil", then "Yeni Profil 2", "Yeni Profil 3", ...
String defaultProfileName(Set<String> taken) {
  const base = 'Yeni Profil';
  if (!taken.contains(base)) return base;
  var n = 2;
  while (taken.contains('$base $n')) {
    n++;
  }
  return '$base $n';
}

class _ProfileDialog extends StatefulWidget {
  final RifleProfile? initial;

  /// Names already used by saved profiles (for the new-profile default).
  final Set<String> takenNames;
  const _ProfileDialog({this.initial, this.takenNames = const {}});

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  /// Records the profile pointed at when the editor opened (built-in or
  /// personal). They only prefill the forms; everything is typed in.
  final List<Rifle> _allRifles = CatalogRepository.allRifles;
  final List<Ammunition> _allAmmunition = CatalogRepository.allAmmunition;
  final List<ScopeOptic> _allScopes = CatalogRepository.allScopes;
  final ManualCatalogStore _manualStore = ManualCatalogStore();

  WeaponPlatform platform = WeaponPlatform.pcp;

  /// The rifle is typed in by the user (catalog rifle data proved
  /// unreliable). On save it is written as a personal record and the profile
  /// points at it. An existing personal record is updated in place.
  Rifle? rifle;
  late final TextEditingController rifleBrand;
  late final TextEditingController rifleModel;
  late final TextEditingController rifleCaliber;
  late final TextEditingController rifleBarrel;
  late final TextEditingController rifleTwist;
  TwistDirection? twistDirection;

  /// The scope is typed in too; stored as a personal scope record.
  late final TextEditingController scopeBrand;
  late final TextEditingController scopeMinMag;
  late final TextEditingController scopeMaxMag;
  late final TextEditingController scopeObjective;
  late final TextEditingController scopeClick;

  /// "Üst kule klik sayısı": total clicks of the top turret; optional. The
  /// side turret's travel is not asked (owner: it is not needed).
  late final TextEditingController scopeTravelElevation;

  /// true = FFP, false = SFP, null = not chosen yet.
  bool? firstFocalPlane;

  /// Ammunition is typed in too. A BC with its G1/G7 model lets the drag
  /// solver compute wind drift (the vacuum baseline keeps wind locked).
  late final TextEditingController ammoBrand;
  late final TextEditingController ammoGrain;
  late final TextEditingController ammoBc;
  AmmunitionType? ammoType;
  BallisticModel? ammoBcModel;
  bool _saving = false;
  Ammunition? ammo;
  ScopeOptic? scope;
  late final TextEditingController name;
  late final TextEditingController velocity;
  late final TextEditingController zero;
  late final TextEditingController sight;

  /// Dürbün ayağı in MOA, picked from [ProductionLimits.mountCantOptionsMoa].
  late double mountCant;
  String? validationError;
  late AngularUnit angularUnit;

  /// Editing an existing profile is fail-closed: a stored reference that no
  /// longer resolves is NEVER replaced by another record. Its form is left
  /// empty, the user is told, and saving stays disabled until they type the
  /// values in. Rifle, ammunition and scope are all typed in (no defaults).
  final List<String> _unresolved = <String>[];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    final initialRifle = p == null
        ? null
        : _allRifles.where((r) => r.id == p.rifleId).firstOrNull;
    // Platform of an unresolved rifle is inferred from the stored pressure
    // (only PCP profiles carry one) instead of defaulting silently.
    platform =
        initialRifle?.platform ??
        (p != null && p.pressureBar == null
            ? WeaponPlatform.firearm
            : WeaponPlatform.pcp);
    rifle = initialRifle;
    ammo = p == null
        ? null
        : _allAmmunition.where((a) => a.id == p.ammunitionId).firstOrNull;
    scope = p == null
        ? null
        : _allScopes.where((o) => o.id == p.scopeId).firstOrNull;
    String num(double? v) =>
        v == null ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString());
    rifleBrand = TextEditingController(text: initialRifle?.brand ?? '');
    rifleModel = TextEditingController(text: initialRifle?.model ?? '');
    rifleCaliber = TextEditingController(text: num(initialRifle?.caliberMm));
    // Barrel length is entered in cm (owner, 2026-10-07); stored as mm.
    final barrelMm = initialRifle?.barrelLengthMm;
    rifleBarrel = TextEditingController(
      text: barrelMm == null ? '' : num(barrelMm / 10),
    );
    rifleTwist = TextEditingController(text: num(initialRifle?.twistRateIn));
    twistDirection = initialRifle?.twistDirection;
    final s0 = scope;
    angularUnit = p?.angularUnit ?? s0?.clickUnit ?? AngularUnit.mrad;
    scopeBrand = TextEditingController(text: s0?.brand ?? '');
    scopeMinMag = TextEditingController(text: num(s0?.minMagnification));
    scopeMaxMag = TextEditingController(text: num(s0?.maxMagnification));
    scopeObjective = TextEditingController(text: num(s0?.objectiveDiameterMm));
    scopeClick = TextEditingController(
      text: s0 != null && s0.clickUnit == angularUnit
          ? num(s0.clickValue)
          : num(_defaultClick(angularUnit)),
    );
    firstFocalPlane = s0?.firstFocalPlane;
    // "Üst kule klik sayısı": total clicks from end to end of the top
    // turret, recovered from the stored travel and the scope's click value.
    String travel(double? mrad) {
      if (mrad == null || mrad <= 0 || s0 == null) return '';
      final clicks = _fromMrad(mrad, s0.clickUnit) / s0.clickValue;
      return clicks.round().toString();
    }

    scopeTravelElevation = TextEditingController(
      text: travel(s0?.elevationRangeMrad),
    );
    final a0 = ammo;
    // One "Marka Model" field (owner, 2026-10-09).
    ammoBrand = TextEditingController(
      text: a0 == null ? '' : '${a0.brand} ${a0.model}'.trim(),
    );
    ammoGrain = TextEditingController(text: num(a0?.grain));
    ammoBc = TextEditingController(text: num(a0?.ballisticCoefficient));
    ammoType = a0?.type;
    ammoBcModel = a0?.ballisticModel;
    if (p != null) {
      if (rifle == null) _unresolved.add('tüfek');
      if (ammo == null) _unresolved.add('mühimmat');
      if (scope == null) _unresolved.add('dürbün');
    }
    name = TextEditingController(
      text: p?.name ?? defaultProfileName(widget.takenNames),
    );
    // Muzzle velocity is entered in fps on Profil (owner decision); the
    // profile keeps storing m/s, so every calculation is unchanged.
    velocity = TextEditingController(
      text: p == null ? '' : _fpsText(p.muzzleVelocityMps),
    );
    // New profiles start empty: no placeholder value is ever taken for the
    // user's data (owner, 2026-10-07: "250 m/s nereden geliyor?").
    zero = TextEditingController(text: p == null ? '' : num(p.zeroRangeM));
    sight = TextEditingController(text: p == null ? '' : num(p.sightHeightMm));
    // 0 = normal mount; old profiles have no value.
    mountCant = p?.mountCantMoa ?? 0;
  }

  static String _fpsText(double mps) {
    final fps = UnitSystem.mpsToFps(mps);
    return fps.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }

  // 100–4900 fps (4900 fps ≈ 1494 m/s, inside the 1500 m/s production limit).
  String? get _velocityError => _rangeError(velocity, 100, 4900);
  String? get _zeroError => _rangeError(zero, 1, ProductionLimits.maxRangeM);

  /// What is still missing, per section, in the order of the page. Shown
  /// above Kaydet so a disabled button always says why.
  List<String> get _missing {
    final out = <String>[];
    void section(String name, List<(bool, String)> checks) {
      final m = [
        for (final (ok, label) in checks)
          if (!ok) label,
      ];
      if (m.isNotEmpty) out.add('$name: ${m.join(', ')}');
    }

    // Same order as the form (owner, 2026-10-09).
    section('Tüfek', [
      (_brandError == null, 'Marka'),
      (_modelError == null, 'Model'),
      (_velocityError == null, 'Namlu çıkış hızı'),
      (twistDirection != null, 'Yiv yönü'),
      (_barrelError == null, 'Namlu uzunluğu'),
      (_caliberError == null, 'Kalibre'),
      (_twistError == null, 'Yiv oranı'),
      (_validSight, 'Sight height'),
      (_zeroError == null, 'Sıfırlama mesafesi'),
    ]);
    section('Dürbün', [
      (_scopeBrandError == null, 'Marka'),
      (_minMagError == null, 'Min. büyütme'),
      (_maxMagError == null, 'Maks. büyütme'),
      (_objectiveError == null, 'Mercek çapı'),
      (firstFocalPlane != null, 'Odak düzlemi'),
      // Klik değeri is not asked; it follows the unit and is always valid.
      (_clickError == null, 'Klik değeri'),
      (_travelError(scopeTravelElevation) == null, 'Üst kule klik sayısı'),
    ]);
    section('Mühimmat', [
      (_ammoBrandError == null, 'Marka Model'),
      (_effectiveAmmoType != null, 'Tip'),
      (_grainError == null, 'Ağırlık'),
      (_bcError == null, 'BC'),
      (ammoBcModel != null, 'BC modeli'),
    ]);
    return out;
  }

  static double _defaultClick(AngularUnit u) =>
      u == AngularUnit.moa ? 0.25 : 0.1;

  @override
  void dispose() {
    rifleBrand.dispose();
    rifleModel.dispose();
    rifleCaliber.dispose();
    rifleBarrel.dispose();
    rifleTwist.dispose();
    scopeBrand.dispose();
    scopeMinMag.dispose();
    scopeMaxMag.dispose();
    scopeObjective.dispose();
    scopeClick.dispose();
    scopeTravelElevation.dispose();
    ammoBrand.dispose();
    ammoGrain.dispose();
    ammoBc.dispose();
    name.dispose();
    velocity.dispose();
    zero.dispose();
    sight.dispose();
    super.dispose();
  }

  /// One Dürbün ayağı choice with its ready click gain for the scope as
  /// entered now ("60 MOA · +240 klik"); just the angle while the click
  /// value is not valid yet.
  String _mountLabel(double moa) {
    if (moa == 0) return 'Normal (0 MOA)';
    final name = '${_trimNum(moa)} MOA';
    final click = _parse(scopeClick);
    if (click == null || !click.isFinite || click <= 0) return name;
    final clicks = ScopeDialMath.mountCantClicks(moa, click, angularUnit);
    return '$name · +$clicks klik';
  }

  /// Total travel in mrad from a typed click count (clicks × click value).
  double? _travelMrad(TextEditingController c) {
    final clicks = _parse(c);
    final click = _parse(scopeClick);
    if (clicks == null || clicks <= 0 || click == null || click <= 0) {
      return null;
    }
    return _toMrad(clicks * click, angularUnit);
  }

  bool get _validSight {
    final v = double.tryParse(sight.text.replaceAll(',', '.'));
    return v != null && v > 0 && v < 300;
  }

  static double? _parse(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    return v != null && v.isFinite ? v : null;
  }

  // Plausibility bounds for typed rifle data (application guardrails, not
  // claims about any rifle).
  static const _minCaliberMm = 2.0, _maxCaliberMm = 20.0;
  static const _minBarrelCm = 5.0, _maxBarrelCm = 150.0;
  static const _minTwistIn = 3.0, _maxTwistIn = 80.0;

  String? _textError(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return 'Gerekli.';
    if (t.length > 100) return 'En fazla 100 karakter.';
    return null;
  }

  String? _rangeError(TextEditingController c, double min, double max) {
    if (c.text.trim().isEmpty) return 'Gerekli.';
    final v = _parse(c);
    if (v == null || v < min || v > max) {
      String f(double x) => x % 1 == 0 ? x.toStringAsFixed(0) : '$x';
      return '${f(min)}–${f(max)} arasında bir değer girin.';
    }
    return null;
  }

  String? get _brandError => _textError(rifleBrand);
  String? get _modelError => _textError(rifleModel);
  String? get _caliberError =>
      _rangeError(rifleCaliber, _minCaliberMm, _maxCaliberMm);
  String? get _barrelError =>
      _rangeError(rifleBarrel, _minBarrelCm, _maxBarrelCm);
  String? get _twistError => _rangeError(rifleTwist, _minTwistIn, _maxTwistIn);

  bool get _rifleValid =>
      _brandError == null &&
      _modelError == null &&
      _caliberError == null &&
      _barrelError == null &&
      _twistError == null &&
      twistDirection != null;

  String? get _scopeBrandError => _textError(scopeBrand);
  String? get _minMagError => _rangeError(scopeMinMag, 1, 60);
  String? get _maxMagError {
    final e = _rangeError(scopeMaxMag, 1, 100);
    if (e != null) return e;
    final lo = _parse(scopeMinMag), hi = _parse(scopeMaxMag);
    if (lo != null && hi != null && hi < lo) {
      return 'Minimum büyütmeden küçük olamaz.';
    }
    return null;
  }

  String? get _objectiveError => _rangeError(scopeObjective, 10, 80);
  String? get _clickError => angularUnit == AngularUnit.moa
      ? _rangeError(scopeClick, 0.05, 1)
      : _rangeError(scopeClick, 0.01, 0.5);

  /// Turret travel is optional; when typed it must be plausible.
  String? _travelError(TextEditingController c) {
    if (c.text.trim().isEmpty) return null;
    final v = _parse(c);
    if (v != null && v != v.roundToDouble()) return 'Tam sayı girin.';
    return _rangeError(c, 10, 3000);
  }

  static double _toMrad(double v, AngularUnit u) =>
      u == AngularUnit.moa ? Units.moaToMrad(v) : v;
  static double _fromMrad(double v, AngularUnit u) =>
      u == AngularUnit.moa ? Units.mradToMoa(v) : v;

  bool get _scopeValid =>
      _travelError(scopeTravelElevation) == null &&
      _scopeBrandError == null &&
      _minMagError == null &&
      _maxMagError == null &&
      _objectiveError == null &&
      _clickError == null &&
      firstFocalPlane != null;

  String? get _ammoBrandError => _textError(ammoBrand);
  String? get _grainError => _rangeError(ammoGrain, 1, 800);
  String? get _bcError => _rangeError(ammoBc, 0.005, 1.5);

  /// PCP: pellet or slug must be chosen; firearms always use bullets.
  AmmunitionType? get _effectiveAmmoType => platform == WeaponPlatform.firearm
      ? AmmunitionType.bullet
      : (ammoType == AmmunitionType.bullet ? null : ammoType);

  bool get _ammoValid =>
      _ammoBrandError == null &&
      _grainError == null &&
      _bcError == null &&
      ammoBcModel != null &&
      _effectiveAmmoType != null;

  /// One-line designation, e.g. "6-24x56 FFP" (empty parts are skipped).
  String get _scopeDesignation {
    String part(TextEditingController c) {
      final v = _parse(c);
      return v == null ? '' : _trimNum(v);
    }

    final lo = part(scopeMinMag), hi = part(scopeMaxMag);
    final obj = part(scopeObjective);
    final zoom = lo.isEmpty && hi.isEmpty
        ? ''
        : lo == hi || hi.isEmpty
        ? lo
        : lo.isEmpty
        ? hi
        : '$lo-$hi';
    final body = zoom.isEmpty && obj.isEmpty
        ? ''
        : '${zoom}x${obj.isEmpty ? '' : obj}';
    final plane = firstFocalPlane == null
        ? ''
        : (firstFocalPlane! ? 'FFP' : 'SFP');
    return [body, plane].where((x) => x.isNotEmpty).join(' ');
  }

  /// Caliber typed so far, used to list matching ammunition.
  double? get _typedCaliber =>
      _caliberError == null ? _parse(rifleCaliber) : null;

  /// Show field errors only after the user typed something or tried to save.
  bool _showErrors = false;
  String? _shown(String? error, TextEditingController c) =>
      (_showErrors || c.text.isNotEmpty) ? error : null;

  Map<String, dynamic> _rifleEntry() {
    final existing = rifle;
    return <String, dynamic>{
      'id': existing != null && existing.userEntered
          ? existing.id
          : 'manual_rifle_${DateTime.now().microsecondsSinceEpoch}',
      'kind': 'rifle',
      'platform': platform.name,
      'brand': rifleBrand.text.trim(),
      'model': rifleModel.text.trim(),
      'caliberMm': _parse(rifleCaliber),
      'barrelLengthMm': _parse(rifleBarrel)! * 10,
      'twistDirection': twistDirection!.name,
      'twistRateIn': _parse(rifleTwist),
      'sourceName': userCatalogSourceName,
    };
  }

  Map<String, dynamic> _ammoEntry() {
    final existing = ammo;
    return <String, dynamic>{
      'id': existing != null && existing.userEntered
          ? existing.id
          : 'manual_ammo_${DateTime.now().microsecondsSinceEpoch}',
      'kind': 'ammo',
      'platform': platform.name,
      // The whole "Marka Model" text is the name (brand); model stays empty.
      'brand': ammoBrand.text.trim(),
      'model': '',
      // Caliber follows the rifle, so the pair can never mismatch.
      'caliberMm': _parse(rifleCaliber),
      'grain': _parse(ammoGrain),
      'ammoType': _effectiveAmmoType!.name,
      'bc': _parse(ammoBc),
      'bcModel': ammoBcModel!.name,
      'sourceName': userCatalogSourceName,
    };
  }

  Map<String, dynamic> _scopeEntry() {
    final existing = scope;
    final lo = _parse(scopeMinMag)!, hi = _parse(scopeMaxMag)!;
    return <String, dynamic>{
      'id': existing != null && existing.userEntered
          ? existing.id
          : 'manual_scope_${DateTime.now().microsecondsSinceEpoch}',
      'kind': 'scope',
      'platform': platform.name,
      'brand': scopeBrand.text.trim(),
      'model': _scopeDesignation,
      'objectiveMm': _parse(scopeObjective),
      'click': _parse(scopeClick),
      'clickUnit': angularUnit.name,
      'focal': firstFocalPlane! ? 'ffp' : 'sfp',
      'minMag': lo,
      'maxMag': hi,
      'magnification': lo == hi
          ? '${_trimNum(lo)}x'
          : '${_trimNum(lo)}-${_trimNum(hi)}x',
      // Total turret travel in mrad (optional). Windage defaults to the
      // elevation travel, as on most spec sheets.
      'elevationRangeMrad': _travelMrad(scopeTravelElevation),
      'sourceName': userCatalogSourceName,
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_rifleValid || !_ammoValid || !_scopeValid) {
      setState(() {
        _showErrors = true;
        validationError = !_rifleValid
            ? 'Tüfek bilgilerinde eksik veya hatalı alan var.'
            : !_ammoValid
            ? 'Mühimmat bilgilerinde eksik veya hatalı alan var.'
            : 'Dürbün bilgilerinde eksik veya hatalı alan var.';
      });
      return;
    }
    final velocityError = _velocityError;
    if (velocityError != null) {
      setState(() {
        _showErrors = true;
        validationError = 'Namlu çıkış hızı (fps): $velocityError';
      });
      return;
    }
    final mps = UnitSystem.fpsToMps(_parse(velocity)!);
    final ProfileInput input;
    try {
      input = ProfileInput.validate(
        name: name.text,
        muzzleVelocityText: mps.toString(),
        zeroRangeText: zero.text,
        sightHeightText: sight.text,
        platform: platform,
        // Regülatör basıncı is not asked any more (owner, 2026-10-09): no
        // calculation uses it.
        mountCantMoa: mountCant,
      );
    } on FormatException catch (e) {
      setState(() => validationError = e.message);
      return;
    }
    // Profile values are valid: only now write the rifle record, so a
    // rejected profile never leaves a personal record behind.
    setState(() => _saving = true);
    final entry = _rifleEntry();
    final rifleId = entry['id'] as String;
    final scopeRecord = _scopeEntry();
    final scopeId = scopeRecord['id'] as String;
    final ammoRecord = _ammoEntry();
    final ammoId = ammoRecord['id'] as String;
    try {
      await _manualStore.upsert(entry);
      await _manualStore.upsert(ammoRecord);
      await _manualStore.upsert(scopeRecord);
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries(await _manualStore.all()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        validationError =
            'Tüfek bilgileri kaydedilemedi. Profil kaydedilmedi; tekrar deneyin.';
      });
      return;
    }
    if (!mounted) return;
    if (!CatalogRepository.allRifles.any((r) => r.id == rifleId) ||
        !CatalogRepository.allAmmunition.any((a) => a.id == ammoId) ||
        !CatalogRepository.allScopes.any((o) => o.id == scopeId)) {
      setState(() {
        _saving = false;
        validationError =
            'Tüfek, mühimmat veya dürbün kaydı okunamadı. Profil kaydedilmedi.';
      });
      return;
    }
    final id =
        widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    Navigator.pop(
      context,
      RifleProfile(
        id: id,
        name: input.name,
        rifleId: rifleId,
        ammunitionId: ammoId,
        scopeId: scopeId,
        muzzleVelocityMps: input.muzzleVelocityMps,
        zeroRangeM: input.zeroRangeM,
        sightHeightMm: input.sightHeightMm,
        pressureBar: input.pressureBar,
        angularUnit: angularUnit,
        mountCantMoa: input.mountCantMoa,
      ),
    );
  }

  void _showSightHelp() => showDialog<void>(
    context: context,
    builder: (_) => const _SightHeightHelpDialog(),
  );

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final typedCaliber = _typedCaliber;
    final missing = _missing;
    final canSave =
        !_saving &&
        _rifleValid &&
        _ammoValid &&
        _scopeValid &&
        _validSight &&
        missing.isEmpty;

    return Scaffold(
      appBar: MenzilSubPageBar(
        title: widget.initial == null ? 'Profil Oluştur' : 'Profili Düzenle',
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MenzilSpace.gutter,
              MenzilSpace.sm,
              MenzilSpace.gutter,
              MenzilSpace.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (missing.isNotEmpty) ...[
                  Text(
                    'Kaydetmek için eksik: ${missing.join(' · ')}',
                    key: const Key('profile-missing'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: MenzilType.caption(c.danger),
                  ),
                  const SizedBox(height: MenzilSpace.xs),
                ],
                Row(
                  children: [
                    Expanded(
                      child: MenzilSecondaryButton(
                        label: 'İptal',
                        expand: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: MenzilSpace.md),
                    Expanded(
                      flex: 2,
                      child: MenzilPrimaryButton(
                        label: widget.initial == null ? 'Kaydet' : 'Güncelle',
                        onPressed: canSave ? _save : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: MenzilPage(
        children: [
          if (validationError != null)
            MenzilNotice(
              tone: MenzilNoticeTone.danger,
              message: validationError!,
            ),
          if (_unresolved.isNotEmpty)
            MenzilNotice(
              tone: MenzilNoticeTone.warning,
              message:
                  'Bu profilin kayıtlı ${_unresolved.join(', ')} bilgisi katalogda bulunamadı. '
                  'Başka bir kayıt sessizce seçilmedi; lütfen ilgili alanları kendiniz doldurun.',
            ),
          const MenzilSectionHeader(
            'Kimlik',
            padding: EdgeInsets.only(bottom: MenzilSpace.sm),
          ),
          MenzilCard(
            padding: const EdgeInsets.fromLTRB(
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.xxs,
            ),
            child: MenzilFieldGrid(
              children: [
                MenzilInput(
                  key: const Key('profile-name'),
                  controller: name,
                  label: 'Profil adı',
                  keyboardType: TextInputType.text,
                  maxLength: ProductionLimits.maxProfileNameLength,
                ),
                MenzilSelect<WeaponPlatform>(
                  label: 'Tür',
                  initialValue: platform,
                  items: WeaponPlatform.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e == WeaponPlatform.pcp
                                ? 'PCP Tüfek'
                                : 'Ateşli Tüfek',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    platform = v!;
                    // Pellet/slug only exist on PCP; firearms use bullets.
                    if (platform == WeaponPlatform.firearm) ammoType = null;
                  }),
                ),
              ],
            ),
          ),
          const MenzilSectionHeader(
            'Tüfek',
            subtitle: 'Tüfeğinizin bilgilerini kendiniz girin',
            padding: EdgeInsets.only(
              top: MenzilSpace.xxs,
              bottom: MenzilSpace.sm,
            ),
          ),
          MenzilCard(
            key: const Key('profile-rifle-form'),
            padding: const EdgeInsets.fromLTRB(
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.xxs,
            ),
            child: MenzilFieldGrid(
              children: [
                // Order set by the owner (2026-10-09), as on the summary.
                MenzilInput(
                  key: const Key('rifle-brand'),
                  controller: rifleBrand,
                  label: 'Marka',
                  keyboardType: TextInputType.text,
                  maxLength: 100,
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_brandError, rifleBrand),
                ),
                MenzilInput(
                  key: const Key('rifle-model'),
                  controller: rifleModel,
                  label: 'Model',
                  keyboardType: TextInputType.text,
                  maxLength: 100,
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_modelError, rifleModel),
                ),
                MenzilInput(
                  key: const Key('profile-velocity-fps'),
                  controller: velocity,
                  label: 'Namlu çıkış hızı',
                  info: ProfileFieldInfo.velocity,
                  unit: 'fps',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_velocityError, velocity),
                ),
                MenzilSelect<TwistDirection>(
                  key: const Key('rifle-twist-direction'),
                  info: ProfileFieldInfo.twistDirection,
                  label: 'Namlu yiv yönü',
                  initialValue: twistDirection,
                  items: const [
                    DropdownMenuItem(
                      value: TwistDirection.right,
                      child: Text('Sağ'),
                    ),
                    DropdownMenuItem(
                      value: TwistDirection.left,
                      child: Text('Sol'),
                    ),
                  ],
                  onChanged: (v) => setState(() => twistDirection = v),
                ),
                if (_showErrors && twistDirection == null)
                  const MenzilFullWidth(
                    child: MenzilNotice(
                      tone: MenzilNoticeTone.danger,
                      message: 'Namlu yiv yönünü seçin (Sağ / Sol).',
                    ),
                  ),
                MenzilInput(
                  key: const Key('rifle-barrel'),
                  info: ProfileFieldInfo.barrelLength,
                  controller: rifleBarrel,
                  label: 'Namlu uzunluğu',
                  unit: 'cm',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_barrelError, rifleBarrel),
                ),
                MenzilInput(
                  key: const Key('rifle-caliber'),
                  info: ProfileFieldInfo.caliber,
                  controller: rifleCaliber,
                  label: 'Kalibre',
                  unit: 'mm',
                  hintText: '5,5 / 6,35 / 7,62',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_caliberError, rifleCaliber),
                ),
                MenzilInput(
                  key: const Key('rifle-twist-rate'),
                  info: ProfileFieldInfo.twistRate,
                  controller: rifleTwist,
                  label: 'Yiv oranı (1:…)',
                  unit: 'inç',
                  hintText: '16',
                  helperText: '1:16" için 16 girin (bir tam dönüş, inç).',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_twistError, rifleTwist),
                ),
                MenzilInput(
                  key: const Key('scope-sight-height'),
                  info: ProfileFieldInfo.sightHeight,
                  controller: sight,
                  label: 'Sight height',
                  unit: 'mm',
                  onChanged: (_) => setState(() {}),
                  helperText: 'Merkezden merkeze ölçtüğünüz değeri girin.',
                  errorText: sight.text.isNotEmpty && !_validSight
                      ? '0–300 mm arasında geçerli bir değer girin.'
                      : null,
                ),
                MenzilInput(
                  key: const Key('profile-zero'),
                  controller: zero,
                  label: 'Sıfırlama mesafesi',
                  info: ProfileFieldInfo.zero,
                  unit: 'm',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_zeroError, zero),
                ),
                MenzilFullWidth(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _showSightHelp,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Sight height nasıl ölçülür?'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const MenzilSectionHeader(
            'Dürbün',
            subtitle: 'Dürbününüzün bilgilerini kendiniz girin',
            padding: EdgeInsets.only(
              top: MenzilSpace.xxs,
              bottom: MenzilSpace.sm,
            ),
          ),
          MenzilCard(
            key: const Key('profile-scope-form'),
            padding: const EdgeInsets.fromLTRB(
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.xxs,
            ),
            child: MenzilFieldGrid(
              children: [
                // Order set by the owner (2026-10-09). Klik değeri is not
                // shown: it follows Dürbün birimi.
                MenzilInput(
                  key: const Key('scope-brand'),
                  controller: scopeBrand,
                  label: 'Dürbün markası',
                  keyboardType: TextInputType.text,
                  maxLength: 100,
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_scopeBrandError, scopeBrand),
                ),
                MenzilInput(
                  key: const Key('scope-min-mag'),
                  info: ProfileFieldInfo.minMag,
                  controller: scopeMinMag,
                  label: 'Minimum büyütme',
                  unit: 'x',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_minMagError, scopeMinMag),
                ),
                MenzilInput(
                  key: const Key('scope-max-mag'),
                  info: ProfileFieldInfo.maxMag,
                  controller: scopeMaxMag,
                  label: 'Maksimum büyütme',
                  unit: 'x',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_maxMagError, scopeMaxMag),
                ),
                MenzilInput(
                  key: const Key('scope-objective'),
                  info: ProfileFieldInfo.objective,
                  controller: scopeObjective,
                  label: 'Mercek çapı',
                  unit: 'mm',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_objectiveError, scopeObjective),
                ),
                MenzilSelect<bool>(
                  key: const Key('scope-focal-plane'),
                  info: ProfileFieldInfo.focalPlane,
                  label: 'Odak düzlemi',
                  initialValue: firstFocalPlane,
                  items: const [
                    DropdownMenuItem(value: true, child: Text('FFP')),
                    DropdownMenuItem(value: false, child: Text('SFP')),
                  ],
                  onChanged: (v) => setState(() => firstFocalPlane = v),
                ),
                MenzilSelect<double>(
                  // Rebuilt when the click value/unit changes so every
                  // choice shows its ready click gain.
                  key: ValueKey(
                    'scope-mount-cant-${angularUnit.name}-${scopeClick.text}',
                  ),
                  info: ProfileFieldInfo.mountCant,
                  label: 'Dürbün ayağı',
                  unit: 'MOA',
                  initialValue: mountCant,
                  items: [
                    for (final moa in ProductionLimits.mountCantOptionsMoa)
                      DropdownMenuItem(
                        value: moa,
                        child: Text(
                          _mountLabel(moa),
                          key: Key('scope-mount-cant-${_trimNum(moa)}'),
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => mountCant = v ?? 0),
                ),
                MenzilSelect<AngularUnit>(
                  key: ValueKey('profile-angular-unit-${angularUnit.name}'),
                  info: ProfileFieldInfo.scopeUnit,
                  label: 'Dürbün birimi',
                  initialValue: angularUnit,
                  items: const [
                    DropdownMenuItem(
                      value: AngularUnit.mrad,
                      child: Text('MRAD'),
                    ),
                    DropdownMenuItem(
                      value: AngularUnit.moa,
                      child: Text('MOA'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    final next = v ?? AngularUnit.mrad;
                    // Klik değeri is not asked any more (owner, 2026-10-09):
                    // it follows the unit (0.1 MRAD, 1/4 MOA).
                    if (next != angularUnit) {
                      scopeClick.text = _trimNum(_defaultClick(next));
                    }
                    angularUnit = next;
                  }),
                ),
                MenzilInput(
                  key: const Key('scope-travel-elevation'),
                  info: ProfileFieldInfo.elevationTravel,
                  controller: scopeTravelElevation,
                  label: 'Üst kule klik sayısı',
                  unit: 'klik',
                  keyboardType: TextInputType.number,
                  helperText:
                      'Baştan sona toplam klik. Bilmiyorsanız boş bırakın.',
                  onChanged: (_) => setState(() {}),
                  errorText: _travelError(scopeTravelElevation),
                ),
                MenzilFullWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scopeDesignation.isEmpty
                            ? 'Dürbün: —'
                            : 'Dürbün: ${scopeBrand.text.trim()} $_scopeDesignation'
                                  .trim(),
                        key: const Key('scope-designation'),
                        style: MenzilType.body(c.ink),
                      ),
                      if (_showErrors && firstFocalPlane == null)
                        const MenzilNotice(
                          tone: MenzilNoticeTone.danger,
                          message: 'Odak düzlemini seçin (FFP / SFP).',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const MenzilSectionHeader(
            'Mühimmat',
            subtitle: 'BC ve G1/G7 modeli rüzgâr sapması hesabı için gerekir',
            padding: EdgeInsets.only(
              top: MenzilSpace.xxs,
              bottom: MenzilSpace.sm,
            ),
          ),
          MenzilCard(
            key: const Key('profile-ammo-form'),
            padding: const EdgeInsets.fromLTRB(
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.xxs,
            ),
            child: MenzilFieldGrid(
              children: [
                MenzilInput(
                  key: const Key('ammo-brand'),
                  controller: ammoBrand,
                  label: 'Marka Model',
                  hintText: 'JSB King Heavy',
                  keyboardType: TextInputType.text,
                  maxLength: 100,
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_ammoBrandError, ammoBrand),
                ),
                if (platform == WeaponPlatform.pcp)
                  MenzilSelect<AmmunitionType>(
                    key: const Key('ammo-type'),
                    info: ProfileFieldInfo.ammoType,
                    label: 'Tip',
                    initialValue: ammoType == AmmunitionType.bullet
                        ? null
                        : ammoType,
                    items: const [
                      DropdownMenuItem(
                        value: AmmunitionType.pellet,
                        child: Text('Pellet'),
                      ),
                      DropdownMenuItem(
                        value: AmmunitionType.slug,
                        child: Text('Slug'),
                      ),
                    ],
                    onChanged: (v) => setState(() => ammoType = v),
                  ),
                MenzilInput(
                  key: const Key('ammo-grain'),
                  info: ProfileFieldInfo.grain,
                  controller: ammoGrain,
                  label: 'Ağırlık',
                  unit: 'grain',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_grainError, ammoGrain),
                ),
                MenzilInput(
                  key: const Key('ammo-bc'),
                  info: ProfileFieldInfo.bc,
                  controller: ammoBc,
                  label: 'BC (balistik katsayı)',
                  hintText: '0,035',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_bcError, ammoBc),
                ),
                MenzilSelect<BallisticModel>(
                  key: const Key('ammo-bc-model'),
                  info: ProfileFieldInfo.bcModel,
                  label: 'BC modeli',
                  initialValue: ammoBcModel,
                  items: const [
                    DropdownMenuItem(
                      value: BallisticModel.g1,
                      child: Text('G1'),
                    ),
                    DropdownMenuItem(
                      value: BallisticModel.g7,
                      child: Text('G7'),
                    ),
                  ],
                  onChanged: (v) => setState(() => ammoBcModel = v),
                ),
                MenzilFullWidth(
                  child: Text(
                    typedCaliber == null
                        ? 'Kalibre: tüfek bilgilerinden alınır.'
                        : 'Kalibre: ${_trimNum(typedCaliber)} mm (tüfekten).',
                    key: const Key('ammo-caliber-note'),
                    style: MenzilType.caption(c.ink2),
                  ),
                ),
                if (_showErrors &&
                    (ammoBcModel == null || _effectiveAmmoType == null))
                  const MenzilFullWidth(
                    child: MenzilNotice(
                      tone: MenzilNoticeTone.danger,
                      message: 'Mühimmat tipini ve BC modelini (G1/G7) seçin.',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SightHeightHelpDialog extends StatelessWidget {
  const _SightHeightHelpDialog();

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return AlertDialog(
      title: const Text('Sight height nasıl ölçülür?'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Uygulama bu değeri hesaplamaz. Değeri siz ölçüp profil alanına girersiniz.',
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1.65,
                child: CustomPaint(
                  painter: _SightHeightDiagramPainter(
                    line: c.ink2,
                    accent: c.amber,
                    text: c.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Dürbünün optik eksen merkezini belirleyin.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                '2. Namlu deliğinin merkezini belirleyin. Namlu dış yüzeyini referans almayın.',
              ),
              const SizedBox(height: 6),
              const Text(
                '3. Bu iki merkez arasındaki dikey mesafeyi mm olarak ölçün.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Önemli: Ölçüm merkezden merkezedir; namlunun üst yüzeyinden dürbüne olan boşluk değildir.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anladım'),
        ),
      ],
    );
  }
}

class _SightHeightDiagramPainter extends CustomPainter {
  final Color line;
  final Color accent;
  final Color text;
  const _SightHeightDiagramPainter({
    required this.line,
    required this.accent,
    required this.text,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fg = Paint()
      ..color = line
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final red = Paint()
      ..color = accent
      ..strokeWidth = 3;
    final fill = Paint()..color = accent;
    final cx = size.width * .62;
    final scopeY = size.height * .27;
    final barrelY = size.height * .74;

    canvas.drawCircle(Offset(cx, scopeY), size.height * .14, fg);
    canvas.drawCircle(Offset(cx, barrelY), size.height * .105, fg);
    canvas.drawCircle(Offset(cx, scopeY), 4, fill);
    canvas.drawCircle(Offset(cx, barrelY), 4, fill);

    canvas.drawLine(Offset(cx, scopeY + 7), Offset(cx, barrelY - 7), red);
    canvas.drawLine(Offset(cx - 7, scopeY + 15), Offset(cx, scopeY + 7), red);
    canvas.drawLine(Offset(cx + 7, scopeY + 15), Offset(cx, scopeY + 7), red);
    canvas.drawLine(Offset(cx - 7, barrelY - 15), Offset(cx, barrelY - 7), red);
    canvas.drawLine(Offset(cx + 7, barrelY - 15), Offset(cx, barrelY - 7), red);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    void label(String t, Offset o) {
      tp.text = TextSpan(
        text: t,
        style: TextStyle(color: text, fontSize: 13),
      );
      tp.layout(maxWidth: size.width * .45);
      tp.paint(canvas, o);
    }

    label('Dürbün optik merkezi', Offset(8, scopeY - 10));
    label('Namlu deliği merkezi', Offset(8, barrelY - 10));
    label('merkezden\nmerkeze', Offset(cx + 18, (scopeY + barrelY) / 2 - 18));
  }

  @override
  bool shouldRepaint(covariant _SightHeightDiagramPainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.accent != accent ||
      oldDelegate.text != text;
}

String _trimNum(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toString().replaceAll('.', ',');

/// Shows the profile's SI values in the user's unit system (Ayarlar). The
/// stored profile stays SI; only the display converts.
class _ProfileUnits {
  final bool metric;
  const _ProfileUnits(this.metric);

  static _ProfileUnits of(BuildContext context) =>
      _ProfileUnits(AppSettingsScope.metricOf(context));

  // Muzzle velocity is entered and shown in fps on Profil in both unit
  // systems (owner decision, 2026-10-07).
  String get velocityUnit => 'fps';
  String get distanceUnit => metric ? 'm' : 'yd';

  String velocityValue(double mps) =>
      UnitSystem.mpsToFps(mps).toStringAsFixed(0);

  String distanceValue(double m) => metric
      ? m.toStringAsFixed(0)
      : UnitSystem.metersToYards(m).toStringAsFixed(1);

  String velocity(double mps) => '${velocityValue(mps)} $velocityUnit';
  String distance(double m) => '${distanceValue(m)} $distanceUnit';
}
