import 'package:flutter/material.dart';

import '../../core/drag_curve.dart';
import '../../core/drag_table.dart';
import '../../core/production_limits.dart';
import '../../core/profile_input.dart';
import '../../core/scope_dial.dart';
import '../../core/unit_system.dart';
import '../../data/catalog_repository.dart';
import '../../data/user_catalog.dart';
import '../../models/domain.dart';
import '../../services/manual_catalog_store.dart';
import '../../services/profile_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import '../home/empty_states.dart';
import 'drag_curve_field.dart';
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

  /// Shell only: bumped when another page asks to create a profile; opens
  /// the new-profile form.
  final int createRequest;

  const ProfilesScreen({
    super.key,
    this.store,
    this.embedded = false,
    this.activeProfileId,
    this.onActivate,
    this.onProfilesChanged,
    this.onContinue,
    this.revision = 0,
    this.createRequest = 0,
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
    if (oldWidget.createRequest != widget.createRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _add();
      });
    }
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
      distanceUnit: p.distanceUnit,
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
    // First start (or every profile deleted): a welcome page instead of an
    // empty list (owner, 2026-10-10).
    if (items.isEmpty && widget.embedded) {
      return MenzilPage(children: [WelcomePanel(onCreate: _add)]);
    }
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
                              'Sıfır ${_zeroText(profile)}',
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

/// Total clicks of the top (elevation) turret in the profile's unit, with
/// the same click Hedef uses (the catalog click when the units match,
/// otherwise 0.1 MRAD / ¼ MOA / ¼ SMOA); null when the travel is unknown.
int? _topTurretClicks(ScopeOptic s, AngularUnit unit) {
  final mrad = s.elevationRangeMrad;
  if (mrad == null || mrad <= 0 || s.clickValue <= 0) return null;
  final click = s.clickUnit == unit ? s.clickValue : unit.standardClick;
  return (unit.fromMrad(mrad) / click).round();
}

/// The zero in the profile's own distance unit ("25" m, "27.3" yd).
String _zeroValue(RifleProfile p) {
  final v = p.distanceUnit.fromMeters(p.zeroRangeM);
  // Same style as the other summary numbers (66.0 mm): a dot.
  return p.distanceUnit == DistanceUnit.yard
      ? v.toStringAsFixed(1)
      : v.toStringAsFixed(0);
}

String _zeroText(RifleProfile p) => '${_zeroValue(p)} ${p.distanceUnit.symbol}';

String _ammoTypeName(AmmunitionType t) => switch (t) {
  AmmunitionType.pellet => 'Pellet',
  AmmunitionType.slug => 'Slug',
  AmmunitionType.bullet => 'Bullet',
};

/// Read-only summary of the active profile plus the catalog values it
/// resolves to. Purely informational: nothing here feeds the solver.
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
        // Order and names set by the owner (2026-10-09). Regülatör, Odak
        // düzlemi, Klik değeri and the name card have no box any more.
        MenzilMetricGrid(
          columns: 2,
          metrics: [
            // The separate Tüfek/Mühimmat/Dürbün name card was removed
            // (owner, 2026-10-09); brand and model have their own boxes.
            if (rifle != null) MenzilMetric('Tüfek Marka', rifle.brand),
            if (rifle != null) MenzilMetric('Tüfek Model', rifle.model),
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
              _zeroValue(profile),
              profile.distanceUnit.symbol,
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
            MenzilMetric('Dürbün birimi', profile.angularUnit.label),
            if (scope != null &&
                _topTurretClicks(scope, profile.angularUnit) != null)
              MenzilMetric(
                'Dürbün üst kule',
                '${_topTurretClicks(scope, profile.angularUnit)}',
                'klik',
              ),
            if (ammo != null)
              MenzilMetric(
                'Mühimmat Marka',
                // Personal ammunition keeps its whole name in the brand.
                '${ammo.brand} ${ammo.model}'.trim(),
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

  /// Hides the Ağırlık example while the box is being typed in.
  final FocusNode _grainFocus = FocusNode();

  /// Kalibre lists (owner, 2026-10-09). Firearm calibers are the ones of the
  /// app's firearm rifle/ammunition records.
  static const _pcpCalibers = <(double, String)>[
    (4.5, '4.50 mm'),
    (5.5, '5.50 mm'),
    (6.35, '6.35 mm'),
    (7.62, '7.62 mm'),
    (9.0, '9.00 mm'),
  ];
  // Bullet diameters (owner, 2026-10-10: the list was too short; .308 is a
  // 7.82 mm bullet, 7.62 is the bore).
  static const _firearmCalibers = <(double, String)>[
    (4.37, '.17 HMR (4.37 mm)'),
    (5.69, '.22 LR / .22 WMR (5.69 mm)'),
    (5.7, '.222 Rem / .223 / .22-250 (5.70 mm)'),
    (6.17, '.243 Win / 6mm Creedmoor (6.17 mm)'),
    (6.71, '6.5 Creedmoor / 6.5x55 / 6.5 PRC (6.71 mm)'),
    (7.04, '.270 Win / .270 WSM (7.04 mm)'),
    (7.21, '7mm-08 / 7x64 / 7mm Rem Mag / 7mm PRC (7.21 mm)'),
    (7.82, '.308 Win / .30-06 / .300 Win Mag / .300 PRC (7.82 mm)'),
    (7.92, '7.62x39 / 7.62x54R / .303 British (7.92 mm)'),
    (8.22, '8x57 JS / 8mm Mauser (8.22 mm)'),
    (8.59, '.338 Lapua / .338 Win Mag (8.59 mm)'),
    (9.3, '9.3x62 / 9.3x74R (9.30 mm)'),
    (9.53, '.375 H&H (9.53 mm)'),
    (12.95, '.50 BMG (12.95 mm)'),
  ];

  /// "Diğer (elle yaz)": a caliber not on the list, typed in mm.
  static const _otherCaliber = -1.0;
  bool _caliberOther = false;

  List<(double, String)> get _caliberList =>
      platform == WeaponPlatform.firearm ? _firearmCalibers : _pcpCalibers;

  double? _caliberItem(double mm) {
    for (final (v, _) in _caliberList) {
      if ((v - mm).abs() < 1e-6) return v;
    }
    return null;
  }

  /// The list plus a saved value that is not on it, so it is never lost.
  List<(double, String)> get _caliberChoices {
    final cal = _parse(rifleCaliber);
    if (cal == null || _caliberItem(cal) != null) return _caliberList;
    return [..._caliberList, (cal, '${_trimDot(cal)} mm')];
  }

  double? get _selectedCaliber {
    if (_caliberOther) return _otherCaliber;
    final cal = _parse(rifleCaliber);
    if (cal == null) return null;
    return _caliberItem(cal) ?? cal;
  }

  /// BC model choices per rifle type (owner, 2026-10-10: the other public
  /// BRL drag laws). A stored model of the other type stays selectable.
  List<(BallisticModel, String)> get _bcModelChoices {
    final list = platform == WeaponPlatform.firearm
        ? const [
            (BallisticModel.g1, 'G1'),
            (BallisticModel.g7, 'G7'),
            (BallisticModel.ra4, 'RA4 (.22 LR rimfire)'),
            (BallisticModel.g2, 'G2'),
            (BallisticModel.g5, 'G5'),
            (BallisticModel.g6, 'G6'),
            (BallisticModel.g8, 'G8'),
            (BallisticModel.gi, 'GI (Ingalls)'),
          ]
        : const [
            (BallisticModel.g1, 'G1'),
            (BallisticModel.g7, 'G7'),
            (BallisticModel.ga, 'GA (saçma)'),
            (BallisticModel.gs, 'GS (bilye)'),
          ];
    final m = ammoBcModel;
    if (m == null || list.any((e) => e.$1 == m)) return list;
    return [...list, (m, m.label)];
  }

  static String _trimDot(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();
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

  /// Hıza göre BC (çoklu BC, owner 2026-10-09): up to two steps "below
  /// this speed (fps) the BC is …". Empty rows = single BC.
  late final List<TextEditingController> ammoBandFps;
  late final List<TextEditingController> ammoBandBc;
  AmmunitionType? ammoType;
  BallisticModel? ammoBcModel;

  /// BC modeli "Özel eğri (Mach–Cd)": the bullet's own drag curve replaces
  /// BC, BC model and the speed bands (owner, 2026-10-10).
  bool _customCurve = false;
  List<DragSample>? _dragCurve;
  static const _customKey = 'custom';
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

  /// Metre or yard for the zero (and every distance of this profile).
  late DistanceUnit distanceUnit;

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
    rifle = initialRifle;
    ammo = p == null
        ? null
        : _allAmmunition.where((a) => a.id == p.ammunitionId).firstOrNull;
    // Platform of an unresolved rifle comes from its ammunition, else PCP.
    // (It used to be guessed from the pressure, but new PCP profiles carry
    // no pressure since 2026-10-09, so "no pressure" no longer means
    // firearm.)
    platform = initialRifle?.platform ?? ammo?.platform ?? WeaponPlatform.pcp;
    scope = p == null
        ? null
        : _allScopes.where((o) => o.id == p.scopeId).firstOrNull;
    String num(double? v) =>
        v == null ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString());
    rifleBrand = TextEditingController(text: initialRifle?.brand ?? '');
    rifleModel = TextEditingController(text: initialRifle?.model ?? '');
    rifleCaliber = TextEditingController(text: num(initialRifle?.caliberMm));
    _grainFocus.addListener(() => setState(() {}));
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
    // turret, recovered from the stored travel with the SAME unit and click
    // the form saves with (a MRAD catalog scope on a MOA profile used to
    // come back 27 % shorter after a save).
    String travel(double? mrad) {
      final click = double.tryParse(scopeClick.text);
      if (mrad == null || mrad <= 0 || click == null || click <= 0) return '';
      return (_fromMrad(mrad, angularUnit) / click).round().toString();
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
    // Stored bands are fastest first: [(s1, main), (s2, bc1), (0, bc2)].
    // Row i shows "below s(i+1) fps -> bc(i+1)".
    final bands = a0?.bcBands ?? const <BcBand>[];
    String fps(double mps) => UnitSystem.mpsToFps(mps).round().toString();
    ammoBandFps = [
      for (var i = 0; i < 2; i++)
        TextEditingController(
          text: i + 1 < bands.length ? fps(bands[i].minVelocityMps) : '',
        ),
    ];
    ammoBandBc = [
      for (var i = 0; i < 2; i++)
        TextEditingController(
          text: i + 1 < bands.length ? num(bands[i + 1].bc) : '',
        ),
    ];
    ammoType = a0?.type;
    ammoBcModel = a0?.ballisticModel;
    _dragCurve = a0?.dragCurve;
    _customCurve = _dragCurve != null;
    // The stored "BC" of a curve is the sectional density; not shown.
    if (_customCurve) ammoBc.text = '';
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
    distanceUnit = p?.distanceUnit ?? DistanceUnit.meter;
    zero = TextEditingController(
      text: p == null
          ? ''
          : num(_round1(distanceUnit.fromMeters(p.zeroRangeM))),
    );
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
  String? get _zeroError => _rangeError(
    zero,
    1,
    distanceUnit.fromMeters(ProductionLimits.maxRangeM).floorToDouble(),
  );

  static double _round1(double v) => (v * 10).roundToDouble() / 10;

  /// The typed zero in metres (the profile stores and solves in metres).
  String get _zeroMetersText {
    final v = _parse(zero);
    return v == null ? zero.text : distanceUnit.toMeters(v).toString();
  }

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
      if (_customCurve)
        (_dragCurve != null, 'Sürüklenme eğrisi')
      else ...[
        (_bcError == null, 'BC'),
        (ammoBcModel != null, 'BC modeli'),
        (_bandsValid, 'Hıza göre BC'),
      ],
    ]);
    return out;
  }

  static double _defaultClick(AngularUnit u) => u.standardClick;

  @override
  void dispose() {
    rifleBrand.dispose();
    rifleModel.dispose();
    rifleCaliber.dispose();
    _grainFocus.dispose();
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
    for (final c in [...ammoBandFps, ...ammoBandBc]) {
      c.dispose();
    }
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
  String? get _twistError => _rangeError(rifleTwist, _minTwistIn, _maxTwistIn);

  bool get _rifleValid =>
      _brandError == null &&
      _modelError == null &&
      _caliberError == null &&
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
  String? get _clickError => angularUnit.moaFamily
      ? _rangeError(scopeClick, 0.05, 1)
      : _rangeError(scopeClick, 0.01, 0.5);

  /// Turret travel is optional; when typed it must be plausible.
  String? _travelError(TextEditingController c) {
    if (c.text.trim().isEmpty) return null;
    final v = _parse(c);
    if (v != null && v != v.roundToDouble()) return 'Tam sayı girin.';
    return _rangeError(c, 10, 3000);
  }

  static double _toMrad(double v, AngularUnit u) => u.toMrad(v);
  static double _fromMrad(double v, AngularUnit u) => u.fromMrad(v);

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

  /// A band row is optional, but half a row (speed without BC or the other
  /// way round) is an error.
  String? _bandFpsError(int i) {
    final f = ammoBandFps[i], b = ammoBandBc[i];
    if (f.text.trim().isEmpty && b.text.trim().isEmpty) return null;
    final e = _rangeError(f, 100, 4000);
    if (e != null) return e;
    // Thresholds must fall row by row.
    if (i == 1 && _parse(ammoBandFps[0]) != null) {
      if (_parse(f)! >= _parse(ammoBandFps[0])!) {
        return '1. eşikten düşük olmalı.';
      }
    }
    return null;
  }

  String? _bandBcError(int i) {
    final f = ammoBandFps[i], b = ammoBandBc[i];
    if (f.text.trim().isEmpty && b.text.trim().isEmpty) return null;
    return _rangeError(b, 0.005, 1.5);
  }

  bool get _bandsValid {
    for (var i = 0; i < 2; i++) {
      if (_bandFpsError(i) != null || _bandBcError(i) != null) return false;
    }
    // Row 2 needs row 1.
    final r1 = ammoBandFps[0].text.trim().isNotEmpty;
    final r2 = ammoBandFps[1].text.trim().isNotEmpty;
    return r1 || !r2;
  }

  /// Bands to store: main BC from the first threshold up, each row below
  /// its threshold; the last band starts at 0.
  List<Map<String, double>> get _bandEntries {
    final rows = <(double, double)>[
      for (var i = 0; i < 2; i++)
        if (_parse(ammoBandFps[i]) != null && _parse(ammoBandBc[i]) != null)
          (
            UnitSystem.fpsToMps(_parse(ammoBandFps[i])!),
            _parse(ammoBandBc[i])!,
          ),
    ];
    if (rows.isEmpty) return const [];
    final main = _parse(ammoBc)!;
    return [
      {'mps': rows[0].$1, 'bc': main},
      for (var i = 0; i < rows.length; i++)
        {'mps': i + 1 < rows.length ? rows[i + 1].$1 : 0.0, 'bc': rows[i].$2},
    ];
  }

  /// PCP: pellet or slug must be chosen; firearms always use bullets.
  AmmunitionType? get _effectiveAmmoType => platform == WeaponPlatform.firearm
      ? AmmunitionType.bullet
      : (ammoType == AmmunitionType.bullet ? null : ammoType);

  bool get _ammoValid =>
      _ammoBrandError == null &&
      _grainError == null &&
      (_customCurve
          ? _dragCurve != null && _curveSd != null
          : _bcError == null && _bandsValid && ammoBcModel != null) &&
      _effectiveAmmoType != null;

  /// Sectional density for a custom curve, from the grain and the caliber.
  double? get _curveSd {
    final g = _parse(ammoGrain), d = _parse(rifleCaliber);
    if (g == null || d == null || g <= 0 || d <= 0) return null;
    return DragCurve.sectionalDensity(grain: g, diameterMm: d);
  }

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
      if (_customCurve) ...{
        'bc': _curveSd,
        'bcModel': BallisticModel.g1.name,
        'dragCurve': DragCurve.toJson(_dragCurve!),
      } else ...{
        'bc': _parse(ammoBc),
        'bcModel': ammoBcModel!.name,
        if (_bandEntries.isNotEmpty) 'bcBands': _bandEntries,
      },
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
        zeroRangeText: _zeroMetersText,
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
        distanceUnit: distanceUnit,
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
                    // A caliber of the other list does not carry over.
                    final cal = _parse(rifleCaliber);
                    if (cal != null && _caliberItem(cal) == null) {
                      rifleCaliber.text = '';
                    }
                    _caliberOther = false;
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
                // Kalibre is picked from a list per rifle type (owner,
                // 2026-10-09); a saved odd value (e.g. 5.52) stays selectable.
                KeyedSubtree(
                  key: const Key('rifle-caliber'),
                  child: MenzilSelect<double>(
                    key: ValueKey(
                      'rifle-caliber-${platform.name}-${rifleCaliber.text}',
                    ),
                    info: platform == WeaponPlatform.firearm
                        ? ProfileFieldInfo.caliberFirearm
                        : ProfileFieldInfo.caliber,
                    label: 'Kalibre',
                    initialValue: _selectedCaliber,
                    items: [
                      for (final (mm, name) in _caliberChoices)
                        DropdownMenuItem(value: mm, child: Text(name)),
                      const DropdownMenuItem(
                        value: _otherCaliber,
                        child: Text('Diğer (elle yaz)'),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _caliberOther = v == _otherCaliber;
                      rifleCaliber.text = v == null || _caliberOther
                          ? ''
                          : _trimDot(v);
                    }),
                  ),
                ),
                if (_caliberOther)
                  MenzilInput(
                    key: const Key('rifle-caliber-other'),
                    info: ProfileFieldInfo.caliberOther,
                    controller: rifleCaliber,
                    label: 'Mermi çapı',
                    unit: 'mm',
                    hintText: '7.82',
                    onChanged: (_) => setState(() {}),
                    errorText: _shown(_caliberError, rifleCaliber),
                  ),
                MenzilInput(
                  key: const Key('rifle-twist-rate'),
                  info: ProfileFieldInfo.twistRate,
                  controller: rifleTwist,
                  label: 'Yiv oranı (1:…)',
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
                  onChanged: (_) => setState(() {}),
                  helperText: 'Merkezden merkeze ölçtüğünüz değeri girin.',
                  errorText: sight.text.isNotEmpty && !_validSight
                      ? '0–300 mm arasında geçerli bir değer girin.'
                      : null,
                ),
                MenzilSelect<DistanceUnit>(
                  key: const Key('profile-distance-unit'),
                  info: ProfileFieldInfo.distanceUnit,
                  label: 'Mesafe birimi',
                  initialValue: distanceUnit,
                  items: const [
                    DropdownMenuItem(
                      value: DistanceUnit.meter,
                      child: Text('Metre'),
                    ),
                    DropdownMenuItem(
                      value: DistanceUnit.yard,
                      child: Text('Yard'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    final next = v ?? DistanceUnit.meter;
                    // The typed zero keeps its real distance.
                    final typed = _parse(zero);
                    if (typed != null && next != distanceUnit) {
                      final v = _round1(
                        next.fromMeters(distanceUnit.toMeters(typed)),
                      );
                      // Same style as the prefilled value ("27.3").
                      zero.text = v % 1 == 0
                          ? v.toStringAsFixed(0)
                          : v.toString();
                    }
                    distanceUnit = next;
                  }),
                ),
                MenzilInput(
                  key: const Key('profile-zero'),
                  controller: zero,
                  label: 'Sıfırlama mesafesi',
                  info: ProfileFieldInfo.zero,
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
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_minMagError, scopeMinMag),
                ),
                MenzilInput(
                  key: const Key('scope-max-mag'),
                  info: ProfileFieldInfo.maxMag,
                  controller: scopeMaxMag,
                  label: 'Maksimum büyütme',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_maxMagError, scopeMaxMag),
                ),
                MenzilInput(
                  key: const Key('scope-objective'),
                  info: ProfileFieldInfo.objective,
                  controller: scopeObjective,
                  label: 'Mercek çapı',
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
                  initialValue: mountCant,
                  // Closed box: just "0 MOA" / "30 MOA"; the list keeps
                  // "Normal" and the click gain.
                  selectedLabels: [
                    for (final moa in ProductionLimits.mountCantOptionsMoa)
                      '${_trimNum(moa)} MOA',
                  ],
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
                    // "1/4 IN @ 100 YDS" turrets (owner, 2026-10-09).
                    DropdownMenuItem(
                      value: AngularUnit.smoa,
                      child: Text('SMOA'),
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
                  // A pellet example only on PCP; empty for a firearm
                  // (owner, 2026-10-09).
                  hintText: platform == WeaponPlatform.pcp
                      ? 'JSB King Heavy'
                      : null,
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
                  info: platform == WeaponPlatform.firearm
                      ? ProfileFieldInfo.grainFirearm
                      : ProfileFieldInfo.grain,
                  controller: ammoGrain,
                  focusNode: _grainFocus,
                  label: 'Ağırlık',
                  // An example of how to write it; gone once the box is
                  // tapped (owner, 2026-10-09).
                  hintText: _grainFocus.hasFocus
                      ? null
                      : platform == WeaponPlatform.firearm
                      ? '168 gr'
                      : '25.39 gr',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_grainError, ammoGrain),
                ),
                if (!_customCurve)
                  MenzilInput(
                    key: const Key('ammo-bc'),
                    info: platform == WeaponPlatform.firearm
                        ? ProfileFieldInfo.bcFirearm
                        : ProfileFieldInfo.bc,
                    controller: ammoBc,
                    label: 'BC (balistik katsayı)',
                    hintText: platform == WeaponPlatform.firearm
                        ? '0,45'
                        : '0,035',
                    onChanged: (_) => setState(() {}),
                    errorText: _shown(_bcError, ammoBc),
                  ),
                MenzilSelect<String>(
                  key: const Key('ammo-bc-model'),
                  info:
                      (platform == WeaponPlatform.firearm
                          ? ProfileFieldInfo.bcModelFirearm
                          : ProfileFieldInfo.bcModel) +
                      ProfileFieldInfo.bcModelCustom,
                  label: 'BC modeli',
                  initialValue: _customCurve ? _customKey : ammoBcModel?.name,
                  items: [
                    for (final (m, text) in _bcModelChoices)
                      DropdownMenuItem(value: m.name, child: Text(text)),
                    const DropdownMenuItem(
                      value: _customKey,
                      child: Text('Özel eğri (Mach–Cd)'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _customCurve = v == _customKey;
                    if (!_customCurve) {
                      ammoBcModel = BallisticModel.values
                          .where((m) => m.name == v)
                          .firstOrNull;
                    }
                  }),
                ),
                if (_customCurve)
                  MenzilFullWidth(
                    child: DragCurveField(
                      key: const Key('ammo-curve'),
                      curve: _dragCurve,
                      errorText: _showErrors && _dragCurve == null
                          ? 'Eğriyi yükleyin.'
                          : null,
                      onChanged: (v) => setState(() => _dragCurve = v),
                    ),
                  ),
                if (!_customCurve) ...[
                  MenzilFullWidth(
                    child: Text(
                      'Hıza göre BC (isteğe bağlı)',
                      key: const Key('ammo-bands-title'),
                      style: MenzilType.body(c.ink),
                    ),
                  ),
                  for (var i = 0; i < 2; i++) ...[
                    MenzilInput(
                      key: Key('ammo-band-fps-$i'),
                      info: ProfileFieldInfo.bandSpeed,
                      controller: ammoBandFps[i],
                      label: '${i + 1}. eşik hızı (fps)',
                      hintText: i == 0
                          ? (platform == WeaponPlatform.firearm
                                ? '2200'
                                : '800')
                          : (platform == WeaponPlatform.firearm
                                ? '1800'
                                : '700'),
                      onChanged: (_) => setState(() {}),
                      errorText: _shown(_bandFpsError(i), ammoBandFps[i]),
                    ),
                    MenzilInput(
                      key: Key('ammo-band-bc-$i'),
                      info: ProfileFieldInfo.bandBc,
                      controller: ammoBandBc[i],
                      label: 'Eşik altı BC',
                      hintText: platform == WeaponPlatform.firearm
                          ? '0,42'
                          : '0,031',
                      onChanged: (_) => setState(() {}),
                      errorText: _shown(_bandBcError(i), ammoBandBc[i]),
                    ),
                  ],
                ],
                MenzilFullWidth(
                  child: Text(
                    '${typedCaliber == null ? 'Kalibre: tüfek bilgilerinden alınır.' : 'Kalibre: ${_trimNum(typedCaliber)} mm (tüfekten).'}'
                    '${platform == WeaponPlatform.firearm ? ' Tip: mermi (ateşli tüfekte otomatik).' : ''}',
                    key: const Key('ammo-caliber-note'),
                    style: MenzilType.caption(c.ink2),
                  ),
                ),
                if (_showErrors &&
                    ((!_customCurve && ammoBcModel == null) ||
                        _effectiveAmmoType == null))
                  const MenzilFullWidth(
                    child: MenzilNotice(
                      tone: MenzilNoticeTone.danger,
                      message:
                          'Mühimmat tipini ve BC modelini (G1/G7/GA) seçin.',
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
  const _ProfileUnits();

  static _ProfileUnits of(BuildContext context) => const _ProfileUnits();

  // Muzzle velocity is entered and shown in fps on Profil (owner decision,
  // 2026-10-07). Distances follow the profile's own unit (_zeroText).
  String get velocityUnit => 'fps';

  String velocityValue(double mps) =>
      UnitSystem.mpsToFps(mps).toStringAsFixed(0);

  String velocity(double mps) => '${velocityValue(mps)} $velocityUnit';
}
