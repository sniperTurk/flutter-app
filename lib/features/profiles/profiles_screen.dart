import 'package:flutter/material.dart';

import '../../core/production_limits.dart';
import '../../core/profile_input.dart';
import '../../data/catalog_repository.dart';
import '../../data/user_catalog.dart';
import '../../models/domain.dart';
import '../../services/profile_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
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
        builder: (_) => _ProfileDialog(initial: existing),
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
        if (selected != null) ...[
          const SizedBox(height: MenzilSpace.lg),
          _ActiveProfileDetails(
            profile: selected,
            onEdit: () => _edit(selected),
          ),
        ],
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
                              '${profile.muzzleVelocityMps.toStringAsFixed(1)} m/s • '
                              'Zero ${profile.zeroRangeM.toStringAsFixed(0)} m'
                              '${profile.pressureBar == null ? '' : ' • ${profile.pressureBar!.toStringAsFixed(0)} bar'}',
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

/// Personal (manual catalog) records are never presented as manufacturer
/// data: every place that names one also says it is the user's own entry.
String _optionLabel(String name, bool userEntered) =>
    userEntered ? '$name (kişisel kayıt)' : name;

String _labelled(String? name, bool? userEntered, String fallbackId) =>
    name == null
    ? fallbackId
    : userEntered == true
    ? '$name — kişisel kayıt, üretici doğrulaması yok'
    : name;

/// Read-only summary of the active profile plus the catalog values it
/// resolves to. Purely informational: nothing here feeds the solver.
class _ActiveProfileDetails extends StatelessWidget {
  final RifleProfile profile;
  final VoidCallback onEdit;

  const _ActiveProfileDetails({required this.profile, required this.onEdit});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MenzilSectionHeader(
          'Aktif profil',
          subtitle: profile.name,
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
        MenzilMetricGrid(
          columns: 2,
          metrics: [
            MenzilMetric(
              'Çıkış hızı',
              profile.muzzleVelocityMps.toStringAsFixed(1),
              'm/s',
            ),
            MenzilMetric(
              'Sıfırlama mesafesi',
              profile.zeroRangeM.toStringAsFixed(0),
              'm',
            ),
            MenzilMetric(
              'Dürbün yüksekliği',
              profile.sightHeightMm.toStringAsFixed(1),
              'mm',
            ),
            MenzilMetric(
              'Dürbün birimi',
              profile.angularUnit == AngularUnit.moa ? 'MOA' : 'MRAD',
            ),
            if (profile.pressureBar != null)
              MenzilMetric(
                'Atış basıncı',
                profile.pressureBar!.toStringAsFixed(0),
                'bar',
              ),
            if (rifle != null)
              MenzilMetric('Çap', rifle.caliberMm.toStringAsFixed(2), 'mm'),
            if (ammo != null)
              MenzilMetric(
                'Ağırlık',
                ammo.grain.toStringAsFixed(ammo.grain % 1 == 0 ? 0 : 1),
                'gr',
              ),
            if (barrelLengthMm != null)
              MenzilMetric(
                'Namlu boyu',
                barrelLengthMm.toStringAsFixed(0),
                'mm',
              ),
            if (scope != null)
              MenzilMetric(
                'Klik değeri',
                scope.clickValue.toString(),
                scope.clickUnit == AngularUnit.moa ? 'MOA' : 'MRAD',
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
          'Katalog değerleri bilgi amaçlıdır. V1 vakum temel hesapta BC ve sürükleme modeli kullanılmaz.',
          style: MenzilType.caption(MenzilColors.of(context).ink2),
        ),
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
class _ProfileDialog extends StatefulWidget {
  final RifleProfile? initial;
  const _ProfileDialog({this.initial});

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  /// Catalog snapshot taken when the editor opens (built-in + personal).
  /// Dropdown values are matched by identity, so the editor must not see a
  /// reinstalled personal catalog half-way through an edit.
  final List<Rifle> _allRifles = CatalogRepository.allRifles;
  final List<Ammunition> _allAmmunition = CatalogRepository.allAmmunition;
  final List<ScopeOptic> _allScopes = CatalogRepository.allScopes;
  final List<UserCatalogIssue> _blockedPersonal =
      CatalogRepository.userCatalog.blocked;

  List<Rifle> _riflesFor(WeaponPlatform p) =>
      _allRifles.where((r) => r.platform == p).toList(growable: false);

  List<Ammunition> _ammunitionFor(WeaponPlatform p, double caliberMm) =>
      _allAmmunition
          .where(
            (a) => a.platform == p && (a.caliberMm - caliberMm).abs() < 0.001,
          )
          .toList(growable: false);

  WeaponPlatform platform = WeaponPlatform.pcp;
  Rifle? rifle;
  Ammunition? ammo;
  ScopeOptic? scope;
  late final TextEditingController name;
  late final TextEditingController velocity;
  late final TextEditingController zero;
  late final TextEditingController sight;
  late final TextEditingController pressure;
  String? validationError;
  late AngularUnit angularUnit;

  /// Editing an existing profile is fail-closed: a catalog reference that no
  /// longer resolves (or an ammunition that no longer matches the rifle's
  /// caliber) is NEVER replaced by "the first catalog entry". The field is left
  /// empty, the user is told, and saving stays disabled until they pick
  /// explicitly. Only brand-new profiles get convenience defaults.
  bool get _isEdit => widget.initial != null;
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
    if (p != null) {
      if (rifle == null) _unresolved.add('tüfek');
      if (ammo == null) {
        _unresolved.add('mühimmat');
      } else if (rifle != null &&
          !_ammunitionFor(platform, rifle!.caliberMm).contains(ammo)) {
        ammo = null;
        _unresolved.add('mühimmat (tüfek kalibresiyle uyumsuz)');
      }
      if (scope == null) _unresolved.add('dürbün');
    }
    name = TextEditingController(text: p?.name ?? 'Yeni Profil');
    velocity = TextEditingController(
      text: p?.muzzleVelocityMps.toString() ?? '250',
    );
    zero = TextEditingController(text: p?.zeroRangeM.toString() ?? '25');
    sight = TextEditingController(text: p?.sightHeightMm.toString() ?? '65');
    pressure = TextEditingController(
      text: p == null ? '200' : (p.pressureBar?.toString() ?? ''),
    );
    angularUnit = p?.angularUnit ?? AngularUnit.mrad;
  }

  @override
  void dispose() {
    name.dispose();
    velocity.dispose();
    zero.dispose();
    sight.dispose();
    pressure.dispose();
    super.dispose();
  }

  bool get _validSight {
    final v = double.tryParse(sight.text.replaceAll(',', '.'));
    return v != null && v > 0 && v < 300;
  }

  void _save() {
    if (rifle == null || ammo == null || scope == null) return;
    try {
      final input = ProfileInput.validate(
        name: name.text,
        muzzleVelocityText: velocity.text,
        zeroRangeText: zero.text,
        sightHeightText: sight.text,
        platform: platform,
        pressureText: pressure.text,
      );
      final id =
          widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString();
      Navigator.pop(
        context,
        RifleProfile(
          id: id,
          name: input.name,
          rifleId: rifle!.id,
          ammunitionId: ammo!.id,
          scopeId: scope!.id,
          muzzleVelocityMps: input.muzzleVelocityMps,
          zeroRangeM: input.zeroRangeM,
          sightHeightMm: input.sightHeightMm,
          pressureBar: input.pressureBar,
          angularUnit: angularUnit,
        ),
      );
    } on FormatException catch (e) {
      setState(() => validationError = e.message);
    }
  }

  void _showSightHelp() => showDialog<void>(
    context: context,
    builder: (_) => const _SightHeightHelpDialog(),
  );

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final rifles = _riflesFor(platform);
    // New profiles only: default to the first rifle that has catalog ammunition
    // of its caliber, so the default selection is saveable. Edits never do this.
    if (!_isEdit) {
      rifle ??= rifles.firstWhere(
        (r) => _ammunitionFor(platform, r.caliberMm).isNotEmpty,
        orElse: () => rifles.first,
      );
    }
    final ammos = rifle == null
        ? const <Ammunition>[]
        : _ammunitionFor(platform, rifle!.caliberMm);
    if (!_isEdit && !ammos.contains(ammo)) {
      ammo = ammos.isEmpty ? null : ammos.first;
    }
    if (!_isEdit) scope ??= CatalogRepository.scopes.first;
    final blockedHere = _blockedPersonal
        .where((b) => b.kind == 'scope' || b.platform == platform)
        .toList(growable: false);
    final canSave =
        rifle != null && ammo != null && scope != null && _validSight;

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
            child: Row(
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
          if (_unresolved.isNotEmpty &&
              (rifle == null || ammo == null || scope == null))
            MenzilNotice(
              tone: MenzilNoticeTone.warning,
              message:
                  'Bu profilin kayıtlı ${_unresolved.join(', ')} bilgisi katalogda bulunamadı. '
                  'Başka bir kayıt sessizce seçilmedi; lütfen ilgili alanları kendiniz seçin.',
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
                    rifle = null;
                    ammo = null;
                  }),
                ),
              ],
            ),
          ),
          const MenzilSectionHeader(
            'Ekipman',
            padding: EdgeInsets.only(
              top: MenzilSpace.xxs,
              bottom: MenzilSpace.sm,
            ),
          ),
          MenzilCard(
            padding: const EdgeInsets.fromLTRB(
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.xxs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MenzilSelect<Rifle>(
                  key: ValueKey('profile-rifle-${platform.name}'),
                  label: 'Tüfek',
                  initialValue: rifle,
                  items: rifles
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            _optionLabel(e.displayName, e.userEntered),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    rifle = v;
                    ammo = null;
                  }),
                ),
                if (rifle == null)
                  const MenzilNotice(
                    tone: MenzilNoticeTone.warning,
                    message: 'Mühimmat seçmek için önce tüfeği seçin.',
                  )
                else if (ammos.isNotEmpty)
                  MenzilSelect<Ammunition>(
                    key: ValueKey('profile-ammo-${rifle?.id}'),
                    label: 'Mühimmat',
                    initialValue: ammo,
                    items: ammos
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              _optionLabel(e.displayName, e.userEntered),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => ammo = v),
                  )
                else
                  const MenzilNotice(
                    tone: MenzilNoticeTone.warning,
                    message:
                        'Bu tüfeğin kalibresine uygun katalog mühimmatı yok; profil kaydedilemez.',
                  ),
                MenzilSelect<ScopeOptic>(
                  label: 'Dürbün',
                  initialValue: scope,
                  items: _allScopes
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            _optionLabel(e.displayName, e.userEntered),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => scope = v),
                ),
                if (rifle?.userEntered == true ||
                    ammo?.userEntered == true ||
                    scope?.userEntered == true)
                  const MenzilNotice(
                    tone: MenzilNoticeTone.info,
                    message:
                        'Kişisel kayıt seçildi: bu değerler kullanıcı '
                        'girdisidir, üretici tarafından doğrulanmamıştır.',
                  ),
                if (blockedHere.isNotEmpty)
                  MenzilNotice(
                    key: const ValueKey('profile-blocked-personal'),
                    tone: MenzilNoticeTone.warning,
                    title: 'Seçilemeyen kişisel kayıtlar',
                    message: blockedHere
                        .map((b) => '• ${b.label}: ${b.reason}')
                        .join('\n'),
                  ),
              ],
            ),
          ),
          const MenzilSectionHeader(
            'Atış değerleri',
            padding: EdgeInsets.only(
              top: MenzilSpace.xxs,
              bottom: MenzilSpace.sm,
            ),
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
                  controller: velocity,
                  label: 'Çıkış hızı',
                  unit: 'm/s',
                ),
                MenzilInput(
                  controller: zero,
                  label: 'Sıfırlama mesafesi',
                  unit: 'm',
                ),
                MenzilInput(
                  controller: sight,
                  label: 'Dürbün yüksekliği',
                  unit: 'mm',
                  onChanged: (_) => setState(() {}),
                  helperText: 'Merkezden merkeze ölçtüğünüz değeri girin.',
                  errorText: sight.text.isNotEmpty && !_validSight
                      ? '0–300 mm arasında geçerli bir değer girin.'
                      : null,
                ),
                MenzilSelect<AngularUnit>(
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
                  onChanged: (v) =>
                      setState(() => angularUnit = v ?? AngularUnit.mrad),
                ),
                if (platform == WeaponPlatform.pcp)
                  MenzilInput(
                    controller: pressure,
                    label: 'Atış basıncı',
                    unit: 'bar',
                  ),
                MenzilFullWidth(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _showSightHelp,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Dürbün yüksekliği nasıl ölçülür?'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _CatalogValues(rifle: rifle, ammo: ammo, scope: scope),
        ],
      ),
    );
  }
}

/// Catalog-derived values for the current selection (read-only).
class _CatalogValues extends StatelessWidget {
  final Rifle? rifle;
  final Ammunition? ammo;
  final ScopeOptic? scope;

  const _CatalogValues({
    required this.rifle,
    required this.ammo,
    required this.scope,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return MenzilAccordion(
      title: 'Katalogdan gelen değerler',
      subtitle: 'Seçime göre otomatik; düzenlenmez',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MenzilMetricGrid(
            columns: 2,
            metrics: [
              if (rifle != null)
                MenzilMetric('Çap', rifle!.caliberMm.toStringAsFixed(2), 'mm'),
              if (ammo != null)
                MenzilMetric(
                  'Ağırlık',
                  ammo!.grain.toStringAsFixed(ammo!.grain % 1 == 0 ? 0 : 1),
                  'gr',
                ),
              MenzilMetric(
                'Sürükleme modeli',
                ammo?.ballisticModel?.name.toUpperCase() ?? '—',
              ),
              MenzilMetric('BC', ammo?.ballisticCoefficient?.toString() ?? '—'),
              MenzilMetric(
                'Namlu boyu',
                rifle?.barrelLengthMm?.toStringAsFixed(0) ?? '—',
                rifle?.barrelLengthMm == null ? null : 'mm',
              ),
              if (scope != null)
                MenzilMetric(
                  'Klik değeri',
                  scope!.clickValue.toString(),
                  scope!.clickUnit == AngularUnit.moa ? 'MOA' : 'MRAD',
                ),
            ],
          ),
          Text(
            'Bilgi amaçlıdır. V1 vakum temel hesapta BC ve sürükleme modeli kullanılmaz.',
            style: MenzilType.caption(c.ink2),
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
      title: const Text('Dürbün yüksekliği nasıl ölçülür?'),
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
