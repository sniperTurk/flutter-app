import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/drag_curve.dart';
import '../../core/drag_table.dart';
import '../../core/pcp_pressure.dart';
import '../../core/powder_temperature.dart';
import '../../core/production_limits.dart';
import '../../core/reticle.dart';
import '../../core/profile_input.dart';
import '../../core/scope_dial.dart';
import '../../core/unit_system.dart';
import '../../data/bullet_library.dart';
import '../../data/cartridges.dart';
import '../../data/catalog_repository.dart';
import '../../data/factory_ammo_library.dart';
import '../../data/factory_powder_temperature.dart';
import '../../data/measured_drag_lookup.dart';
import '../../data/reticle_catalog.dart';
import '../../data/rifle_library.dart';
import '../../data/user_catalog.dart';
import '../../models/domain.dart';
import '../../services/chrono_store.dart';
import '../../services/manual_catalog_store.dart';
import '../../services/profile_backup.dart';
import '../../services/profile_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import '../home/empty_states.dart';
import 'drag_curve_field.dart';
import 'profile_backup_actions.dart';
import 'profile_catalog_match.dart';
import 'profile_field_info.dart';
import 'profile_recovery_dialog.dart';
import 'rifle_picker_screen.dart';
import 'scope_picker_screen.dart';

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

  /// Personal catalog that goes into a backup with the profiles.
  final ManualCatalogStore? catalogStore;

  /// Injected in tests; default: system share sheet / document picker.
  final BackupShare? shareBackup;
  final BackupPick? pickBackup;

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
    this.catalogStore,
    this.shareBackup,
    this.pickBackup,
  });

  /// Yedekle / Geri yükle under the Profiller list, hidden (owner,
  /// 2026-10-14 17:33: they move to the user profile page later; 17:12
  /// "şimdilik silme yok"). Backup/restore code and saved data are kept.
  static const bool showBackupButtonsFlag = bool.fromEnvironment(
    'PROFILE_BACKUP_BUTTONS',
  );

  /// Tests only: overrides [showBackupButtonsFlag] (null = the flag).
  @visibleForTesting
  static bool? debugShowBackupButtons;

  static bool get showBackupButtons =>
      debugShowBackupButtons ?? showBackupButtonsFlag;

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  late final ProfileStore store = widget.store ?? PersistentProfileStore();
  late final ManualCatalogStore catalogStore =
      widget.catalogStore ?? ManualCatalogStore();
  final GlobalKey _backupButtonKey = GlobalKey();
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
          // PRF-2: records another profile also points at are never
          // overwritten; the edited profile gets its own copy instead.
          sharedRecordIds: {
            for (final x in items)
              if (x.id != existing?.id) ...[
                x.rifleId,
                x.ammunitionId,
                x.scopeId,
              ],
          },
        ),
      ),
    );
    if (p != null) {
      try {
        await store.save(p);
        await _changed();
        // The profile just created or edited becomes the active one: the
        // user goes on with it (owner, 2026-10-11: going back to pick the
        // new rifle by hand made no sense).
        await widget.onActivate?.call(p);
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

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Profiller → Yedekle: every profile and personal catalog entry in one
  /// file, handed to the share sheet (owner, 2026-10-12).
  Future<void> _backup() async {
    final String text;
    try {
      text = ProfileBackup.encode(
        await ProfileBackup.collect(store, catalogStore),
      );
    } catch (_) {
      _snack('Yedek hazırlanamadı. Kayıtlar değiştirilmedi.');
      return;
    }
    final box =
        _backupButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null || !box.hasSize
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      await (widget.shareBackup ?? shareBackupFile)(
        ProfileBackup.fileName(DateTime.now()),
        text,
        origin,
      );
    } catch (_) {
      _snack('Paylaşım ekranı açılamadı.');
    }
  }

  /// Profiller → Geri yükle: reads a backup the user picks, shows what is in
  /// it and adds it only after confirmation. Nothing is deleted.
  Future<void> _restore() async {
    final String? text;
    try {
      text = await (widget.pickBackup ?? pickBackupFile)();
    } catch (_) {
      _snack('Dosya açılamadı.');
      return;
    }
    if (text == null || !mounted) return;
    final ProfileBackupContents contents;
    try {
      contents = ProfileBackup.decode(text);
    } on FormatException catch (e) {
      _snack(e.message);
      return;
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Yedek geri yüklensin mi?'),
            content: Text(
              'Dosyada ${contents.profiles.length} profil ve '
              '${contents.catalog.length} kişisel kayıt var. Telefonda zaten '
              'olan profiller yedektekiyle güncellenir, hiçbir profil '
              'silinmez.',
              textAlign: TextAlign.start,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Geri yükle'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      final r = await ProfileBackup.restore(contents, store, catalogStore);
      await _changed();
      _snack(
        r.skipped == 0
            ? '${r.profiles} profil geri yüklendi.'
            : '${r.profiles} profil geri yüklendi; ${r.skipped} kayıt '
                  'okunamadığı için atlandı.',
      );
    } catch (_) {
      await _changed();
      _snack('Geri yükleme tamamlanamadı. Mevcut kayıtlar korunuyor.');
    }
  }

  /// Personal (user-entered) records of [p] copied under new ids, so
  /// editing the copy never changes the original (PRF-2). Catalog records
  /// are read-only and keep their catalog ids; an id missing from the
  /// personal store is kept as it is. Returns the ids the copy points at.
  Future<({String rifleId, String ammunitionId, String scopeId})>
  _copyPersonalRecords(RifleProfile p) async {
    final entries = await catalogStore.all();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    var n = 0;
    final written = <Map<String, dynamic>>[];
    String copyOf(String id, String prefix) {
      Map<String, dynamic>? found;
      for (final e in entries) {
        if (e['id'] == id) found = e;
      }
      if (found == null) return id;
      final newId = '${prefix}_${stamp + n++}';
      written.add({...found, 'id': newId});
      return newId;
    }

    final ids = (
      rifleId: copyOf(p.rifleId, 'manual_rifle'),
      ammunitionId: copyOf(p.ammunitionId, 'manual_ammo'),
      scopeId: copyOf(p.scopeId, 'manual_scope'),
    );
    for (final e in written) {
      await catalogStore.upsert(e);
    }
    if (written.isNotEmpty) {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries(await catalogStore.all()),
      );
    }
    return ids;
  }

  /// Saves an independent copy (new id) through the same store API. Its
  /// personal rifle / ammunition / scope records are copied too (PRF-2).
  Future<void> _duplicate(RifleProfile p) async {
    const suffix = ' (kopya)';
    const maxBase = ProductionLimits.maxProfileNameLength - suffix.length;
    final base = p.name.length > maxBase
        ? p.name.substring(0, maxBase).trimRight()
        : p.name;
    final ({String rifleId, String ammunitionId, String scopeId}) ids;
    try {
      ids = await _copyPersonalRecords(p);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil kopyalanamadı. Mevcut kayıtlar korunuyor.'),
          ),
        );
      }
      return;
    }
    final copy = RifleProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '$base$suffix',
      rifleId: ids.rifleId,
      ammunitionId: ids.ammunitionId,
      scopeId: ids.scopeId,
      muzzleVelocityMps: p.muzzleVelocityMps,
      zeroRangeM: p.zeroRangeM,
      sightHeightMm: p.sightHeightMm,
      pressureBar: p.pressureBar,
      tubePressureBar: p.tubePressureBar,
      pressureVelocityTable: p.pressureVelocityTable,
      angularUnit: p.angularUnit,
      distanceUnit: p.distanceUnit,
      mountCantMoa: p.mountCantMoa,
      powderTempCoefPercentPer15C: p.powderTempCoefPercentPer15C,
      powderTempReferenceC: p.powderTempReferenceC,
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
            // Owner, 2026-10-14: "Profil silinsin mi?" with İptal / Sil.
            title: const Text('Profil silinsin mi?'),
            content: Text(
              '“${p.name}” profili kalıcı olarak silinecek. '
              'Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('İptal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: MenzilColors.of(dialogContext).danger,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return false;
    try {
      await store.remove(p.id);
      // Its Kronograf strings go with it; a convenience store, so a failure
      // here never blocks the deletion.
      unawaited(
        const ChronoStore().deleteProfile(p.id).catchError((Object _) {}),
      );
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
      return MenzilPage(
        children: [WelcomePanel(onCreate: _add, onRestore: _restore)],
      );
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
        // "Profiller" left, Profil ekle right on the same row (owner,
        // 2026-10-14 17:39, mockup B); the button row under the list is gone.
        Padding(
          key: const Key('profiles-list-header'),
          padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
          child: Row(
            children: [
              Expanded(
                child: MenzilSectionHeader(
                  'Profiller',
                  subtitle: items.isEmpty
                      ? null
                      : '${items.length} kayıtlı profil',
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: MenzilSpace.sm),
              SizedBox(
                width: _addButtonWidth,
                child: MenzilPrimaryButton(
                  key: const Key('profiles-add'),
                  label: 'Profil ekle',
                  icon: Icons.add,
                  amber: true,
                  oneLine: true,
                  // + one character right, label right after it (owner,
                  // 2026-10-14).
                  iconLead: 8,
                  onPressed: _add,
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          MenzilCard(
            child: Text(
              'Henüz kayıtlı profil yok.\nYeni profil ile ilk profilinizi oluşturun.',
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
                onCopy: () => _duplicate(p),
                onDelete: () => _deleteViaButton(p),
              ),
            ),
        // Yedekle / Geri yükle: hidden behind PROFILE_BACKUP_BUTTONS (owner,
        // 2026-10-14 17:33), not removed.
        if (ProfilesScreen.showBackupButtons) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: MenzilSpace.sm),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: MenzilSecondaryButton(
                  key: _backupButtonKey,
                  label: 'Yedekle',
                  icon: Icons.ios_share,
                  expand: true,
                  onPressed: items.isEmpty ? null : _backup,
                ),
              ),
              const SizedBox(width: MenzilSpace.sm),
              Expanded(
                child: MenzilSecondaryButton(
                  label: 'Geri yükle',
                  icon: Icons.download_outlined,
                  expand: true,
                  // One line, set smaller if needed (owner, 2026-10-12).
                  twoLines: true,
                  onPressed: _restore,
                ),
              ),
              const SizedBox(width: MenzilSpace.sm),
              const Expanded(
                child: Center(
                  child: MenzilInfoButton(
                    title: 'Yedekle ve Geri yükle',
                    text: ProfileFieldInfo.backup,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Width of the header's Profil ekle button; the label is set smaller
  /// when a large text size does not fit (oneLine).
  static const double _addButtonWidth = 148;
}

/// What the "⋯" menu of a profile row does.
enum _ProfileAction { edit, copy, delete }

class _ProfileRow extends StatelessWidget {
  final RifleProfile profile;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _ProfileRow({
    required this.profile,
    required this.active,
    required this.onTap,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
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
                // Dot, name (+ Aktif) and one "⋯" (owner, 2026-10-14
                // 17:38–17:44, mockup B): no velocity · Sıfır line.
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
                        child: Text(
                          profile.name,
                          key: const Key('profile-row-name'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
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
                    _menu(context, c),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Düzenle, Kopyala, Sil in a popup anchored under "⋯": an overlay, so
  /// the rows never move (owner, 2026-10-14 17:36, 17:43).
  Widget _menu(BuildContext context, MenzilColors c) {
    PopupMenuItem<_ProfileAction> item(
      _ProfileAction value,
      IconData icon,
      String label, {
      Color? color,
    }) => PopupMenuItem(
      value: value,
      key: Key('profile-menu-${value.name}'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color ?? c.ink),
          const SizedBox(width: MenzilSpace.sm),
          Text(
            label,
            textAlign: TextAlign.start,
            style: TextStyle(color: color ?? c.ink),
          ),
        ],
      ),
    );
    return PopupMenuButton<_ProfileAction>(
      key: Key('profile-menu-${profile.id}'),
      tooltip: 'Profil işlemleri',
      icon: Icon(Icons.more_horiz, color: c.ink),
      position: PopupMenuPosition.under,
      // The menu is as wide as its items (no 112 pt minimum).
      constraints: const BoxConstraints(),
      onSelected: (a) {
        switch (a) {
          case _ProfileAction.edit:
            onEdit();
          case _ProfileAction.copy:
            onCopy();
          case _ProfileAction.delete:
            onDelete();
        }
      },
      itemBuilder: (_) => [
        item(_ProfileAction.edit, Icons.edit_outlined, 'Düzenle'),
        item(_ProfileAction.copy, Icons.content_copy, 'Kopyala'),
        item(
          _ProfileAction.delete,
          Icons.delete_outline,
          'Sil',
          color: c.danger,
        ),
      ],
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

/// The zero in the profile's own distance unit ("25" m, "27,3" yd).
String _zeroValue(RifleProfile p) {
  final v = p.distanceUnit.fromMeters(p.zeroRangeM);
  // Same style as the other summary numbers: a decimal comma (owner,
  // 2026-10-11: one separator on the Profil page).
  return p.distanceUnit == DistanceUnit.yard
      ? v.toStringAsFixed(1).replaceAll('.', ',')
      : v.toStringAsFixed(0);
}

String _ammoTypeName(AmmunitionType t) => switch (t) {
  AmmunitionType.pellet => 'Pellet',
  AmmunitionType.slug => 'Slug',
  AmmunitionType.bullet => 'Mermi',
};

/// Dürbün Marka and a clean Dürbün Model for the summary (owner,
/// 2026-10-11: no designation, reticle or unit repeated in the name).
(String, String) _scopeBrandModel(ScopeOptic s) {
  var brand = s.brand.trim();
  var rest = s.userEntered ? '' : s.model;
  if (s.userEntered) {
    // Personal scopes keep "Brand Series" in the brand.
    final brands = {for (final o in CatalogRepository.scopes) o.brand}.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final b in brands) {
      if (brand.toLowerCase().startsWith(b.toLowerCase())) {
        rest = brand.substring(b.length);
        brand = b;
        break;
      }
    }
  }
  var m = ScopePickerScreen.seriesOf(rest);
  final reticle = _summaryReticle(s);
  if (reticle != null) {
    for (final r in [
      reticle,
      reticle.replaceAll(RegExp(r'\s+(MRAD|MOA|MIL|SMOA)$'), ''),
    ]) {
      final i = m.toLowerCase().indexOf(r.toLowerCase());
      if (i >= 0) m = m.substring(0, i) + m.substring(i + r.length);
    }
  }
  m = m
      .replaceAll(RegExp(r'\((MRAD|MOA|MIL|SMOA)\)'), '')
      .replaceAll(RegExp(r'\b(MRAD|MOA|MIL|SMOA)\b'), '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
  m = m.replaceAll(RegExp(r'^[\s\-–/,]+|[\s\-–/,]+$'), '');
  return (brand, m);
}

/// Non-empty parts joined by a space ("Hatsan Hercules").
String _joinSummary(List<String> parts) =>
    parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(' ');

/// The scope's reticle name for the summary; a focal plane is not one.
String? _summaryReticle(ScopeOptic s) {
  final r = s.reticle?.trim();
  if (r == null || r.isEmpty || r == 'FFP' || r == 'SFP') return null;
  return r;
}

/// Mühimmat Model without the weight (it has its own box).
String _ammoModelName(Ammunition a) {
  final g = RegExp.escape(
    a.grain % 1 == 0 ? a.grain.toStringAsFixed(0) : a.grain.toString(),
  ).replaceAll(r'\.', '[.,]');
  return a.model
      .replaceAll(RegExp('\\b$g\\s*gr\\b'), '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .replaceAll(RegExp(r'^[\s·\-]+|[\s·\-]+$'), '')
      .trim();
}

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
    final scopeNames = scope == null ? null : _scopeBrandModel(scope);
    final reticle = scope == null ? null : _summaryReticle(scope);
    final ammoModel = ammo == null ? '' : _ammoModelName(ammo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // No "Aktif profil" title or Düzenle here (owner, 2026-10-12): the
        // list below shows the active profile with its edit pencil.
        // Three cards (owner, 2026-10-13): Tüfek, Dürbün and Mühimmat
        // bilgileri, each led by its marka and model on one line.
        const MenzilSectionHeader(
          'Tüfek bilgileri',
          size: 18,
          padding: EdgeInsets.only(bottom: MenzilSpace.sm),
        ),
        MenzilMetricGrid(
          key: const Key('profile-summary-rifle'),
          columns: 2,
          twoLineText: true,
          plain: true,
          lead: rifle == null
              ? null
              : MenzilMetric(
                  'Marka / Model',
                  _joinSummary([rifle.brand, rifle.model]),
                ),
          metrics: [
            if (rifle?.twistDirection != null)
              MenzilMetric(
                'Yiv yönü',
                rifle!.twistDirection == TwistDirection.right ? 'Sağ' : 'Sol',
              ),
            if (rifle != null)
              MenzilMetric(
                'Kalibre',
                rifle.caliberMm.toStringAsFixed(2).replaceAll('.', ','),
                'mm',
              ),
            if (rifle?.twistRateIn != null)
              MenzilMetric(
                'Yiv oranı',
                '1:${_trimNum(rifle!.twistRateIn!)}',
                'inç',
              ),
            MenzilMetric('Sight height', _trimNum(profile.sightHeightMm), 'mm'),
            MenzilMetric(
              'Sıfırlama mesafesi',
              _zeroValue(profile),
              profile.distanceUnit.symbol,
            ),
            // Namlu çıkış hızı last in the Tüfek card (owner, 2026-10-13).
            MenzilMetric(
              'Namlu çıkış hızı',
              units.velocityValue(profile.muzzleVelocityMps),
              units.velocityUnit,
            ),
          ],
        ),
        const MenzilSectionHeader('Dürbün bilgileri', size: 18),
        MenzilMetricGrid(
          key: const Key('profile-summary-scope'),
          columns: 2,
          twoLineText: true,
          plain: true,
          // Marka, model and the scope's data on one line (owner,
          // 2026-10-13), e.g. "Barska … 6-36 x 56 FFP · MRAD".
          lead: MenzilMetric(
            'Marka / Model',
            [
              if (scopeNames != null)
                _joinSummary([
                  scopeNames.$1,
                  scopeNames.$2,
                  if (_scopeSummary(scope!).isNotEmpty) _scopeSummary(scope),
                ]),
              profile.angularUnit.label,
            ].join(' · '),
          ),
          metrics: [
            if (reticle != null) MenzilMetric('Retikül', reticle),
            // "0 MOA" like the form's closed box, not "Yok" (owner,
            // 2026-10-13); "—" only when no value exists.
            mountCantSummary(profile.mountCantMoa),
            if (scope != null &&
                _topTurretClicks(scope, profile.angularUnit) != null)
              MenzilMetric(
                'Dürbün üst kule',
                '${_topTurretClicks(scope, profile.angularUnit)}',
                'klik',
              ),
          ],
        ),
        const MenzilSectionHeader('Mühimmat bilgileri', size: 18),
        MenzilMetricGrid(
          key: const Key('profile-summary-ammo'),
          columns: 2,
          twoLineText: true,
          plain: true,
          lead: ammo == null
              ? null
              : MenzilMetric(
                  'Marka / Model',
                  _joinSummary([ammo.brand, ammoModel]),
                ),
          metrics: [
            if (ammo != null) ...[
              MenzilMetric('Tip', _ammoTypeName(ammo.type)),
              MenzilMetric('Ağırlık', _trimNum(ammo.grain), 'gr'),
              // Hidden with the Profil box (owner, 2026-10-13 23:32): the
              // length is asked only in Pro > Mermi uzunluğu.
              if (ammo.lengthMm != null &&
                  _ProfileDialogState._showProfileAmmoLength)
                MenzilMetric('Uzunluk', _trimNum(ammo.lengthMm!), 'mm'),
            ],
            MenzilMetric(
              'BC / model',
              ballisticCoefficient == null
                  ? '—'
                  : '${_trimNum(ballisticCoefficient)} $ballisticModelName'
                        .trim(),
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

/// Full-screen profile editor (create / edit). Returns the validated profile
/// via `Navigator.pop`; persistence stays with the caller.
class _ProfileDialog extends StatefulWidget {
  final RifleProfile? initial;

  /// Names already used by saved profiles (for the new-profile default).
  final Set<String> takenNames;

  /// Rifle / ammunition / scope record ids other saved profiles point at.
  /// A personal record listed here is saved under a new id instead of being
  /// overwritten (PRF-2), so the other profile keeps its values.
  final Set<String> sharedRecordIds;
  const _ProfileDialog({
    this.initial,
    this.takenNames = const {},
    this.sharedRecordIds = const {},
  });

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

  // A new profile starts on Ateşli Tüfek (owner, 2026-10-11).
  WeaponPlatform platform = WeaponPlatform.firearm;

  /// The rifle is typed in by the user (catalog rifle data proved
  /// unreliable). On save it is written as a personal record and the profile
  /// points at it. An existing personal record is updated in place.
  Rifle? rifle;
  late final TextEditingController rifleBrand;
  late final TextEditingController rifleModel;
  late final TextEditingController rifleCaliber;

  /// Focus of the Ağırlık box (the form rebuilds on focus change).
  final FocusNode _grainFocus = FocusNode();

  /// Kalibre lists (owner, 2026-10-09). Firearm calibers are the ones of the
  /// app's firearm rifle/ammunition records.
  static const _pcpCalibers = Cartridges.pcp;

  /// Firearm cartridges, one per line, with the bullet diameter the
  /// solver uses (owner, 2026-10-11: one name per row, no free typing; .308
  /// is a 7.82 mm bullet, 7.62 is the bore). The first [_popularCount] are
  /// the common ones, the rest A-Z.
  static const _popularCount = Cartridges.popularCount;
  static const _firearmCartridges = Cartridges.firearm;

  /// The firearm cartridge chosen in the list (several share a diameter).
  String? _cartridge;

  static String? _cartridgeFor(double mm) {
    for (final (name, d) in _firearmCartridges) {
      if ((d - mm).abs() < 0.005) return name;
    }
    return null;
  }

  double? _caliberItem(double mm) {
    final list = platform == WeaponPlatform.firearm
        ? [for (final (_, d) in _firearmCartridges) (d, '')]
        : _pcpCalibers;
    for (final (v, _) in list) {
      if ((v - mm).abs() < 0.005) return v;
    }
    return null;
  }

  /// Select key of the current caliber: the cartridge name (firearm) or
  /// "mm:<value>"; a saved value not on the list stays selectable.
  String? get _caliberKey {
    final variants = _caliberFromModel
        ? _rifleVariants
        : const <LibraryRifle>[];
    if (variants.isNotEmpty) {
      final i = _rifleVariant == null ? -1 : variants.indexOf(_rifleVariant!);
      return i < 0 ? null : 'v:$i';
    }
    if (platform == WeaponPlatform.firearm && _caliberByDiameter) {
      return _noCartridgeKey;
    }
    final cal = _parse(rifleCaliber);
    if (cal == null) return null;
    if (platform == WeaponPlatform.firearm) {
      final c = _cartridge;
      if (c != null && _firearmCartridges.any((e) => e.$1 == c)) return c;
      return _cartridgeFor(cal) ?? 'mm:${_trimDot(cal)}';
    }
    return 'mm:${_trimDot(_caliberItem(cal) ?? cal)}';
  }

  static const _otherCaliberKey = '!other';
  static const _noCartridgeKey = '!nodia';

  /// Kalibre shows the chosen model's calibers (owner, 2026-10-11) until
  /// "Diğer kalibre" opens the whole list.
  bool get _caliberFromModel =>
      !_rifleManual && !_caliberAll && _rifleVariants.isNotEmpty;

  /// Kalibre entries with the text of the closed box: [full] when it fits
  /// the half-width box, [short] when it would have to shrink too much
  /// (owner, 2026-10-13: Namlu çıkış hızı | Kalibre on one row).
  List<({DropdownMenuItem<String> item, String full, String short})>
  get _caliberChoices {
    final cal = _parse(rifleCaliber);
    final out =
        <({DropdownMenuItem<String> item, String full, String short})>[];
    void add(
      String value,
      Widget child,
      String full, {
      String? short,
      bool enabled = true,
    }) => out.add((
      item: DropdownMenuItem(value: value, enabled: enabled, child: child),
      full: full,
      short: short ?? full,
    ));
    if (_caliberFromModel) {
      final variants = _rifleVariants;
      for (final (i, r) in variants.indexed) {
        final label = _variantLabel(r, variants);
        add(
          'v:$i',
          Text(label, maxLines: 2),
          label,
          short: _shortCartridge(r.cartridge),
        );
      }
      add(_otherCaliberKey, const Text('Diğer kalibre'), 'Diğer kalibre');
      return out;
    }
    if (platform == WeaponPlatform.firearm) {
      void header(String key, String text) => add(
        key,
        Text(text, style: const TextStyle(fontSize: 12)),
        text,
        enabled: false,
      );
      header('#popular', 'EN ÇOK KULLANILAN');
      for (final (i, (name, d)) in _firearmCartridges.indexed) {
        if (i == _popularCount) header('#all', 'DİĞERLERİ (A-Z)');
        add(
          name,
          // The list is as wide as the half box (owner, 2026-10-13): the
          // mm goes under the name when both do not fit on one line, so a
          // narrow list or large text never overflows.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MenzilSpace.xs,
              children: [
                Text(name),
                Text(
                  '${d.toStringAsFixed(2).replaceAll('.', ',')} mm',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          name,
          short: _shortCartridge(name),
        );
      }
      if (cal != null && !_caliberByDiameter && _cartridgeFor(cal) == null) {
        final mm = _trimDot(cal);
        add(
          'mm:$mm',
          Text('$mm mm (kayıtlı)'),
          '$mm mm (kayıtlı)',
          short: '$mm mm',
        );
      }
      add(
        _noCartridgeKey,
        const Text('Fişeğim listede yok'),
        'Fişeğim listede yok',
        short: 'Listede yok',
      );
      return out;
    }
    for (final (mm, name) in _pcpCalibers) {
      add('mm:${_trimDot(mm)}', Text(name), name);
    }
    if (cal != null && _caliberItem(cal) == null) {
      final mm = _trimDot(cal);
      add(
        'mm:$mm',
        Text('$mm mm (kayıtlı)'),
        '$mm mm (kayıtlı)',
        short: '$mm mm',
      );
    }
    return out;
  }

  /// The usual short form of a long cartridge name for the half-width
  /// Kalibre box (".338-378 Weatherby Mag" → ".338-378 Wby Mag").
  static String _shortCartridge(String name) => name
      .replaceAll('Weatherby', 'Wby')
      .replaceAll('Ackley Improved', 'AI')
      .replaceAll(' Springfield', '');

  void _onCaliberKey(String? key) {
    if (key == null || key.startsWith('#')) return;
    if (key == _otherCaliberKey) {
      _caliberAll = true;
      _rifleVariant = null;
      return;
    }
    if (key.startsWith('v:')) {
      _applyRifleVariant(_rifleVariants[int.parse(key.substring(2))]);
      return;
    }
    if (key == _noCartridgeKey) {
      _caliberByDiameter = true;
      _cartridge = null;
      final cal = _parse(rifleCaliber);
      if (cal != null &&
          !_bulletDiameters.any((d) => (d - cal).abs() < 0.005)) {
        rifleCaliber.text = '';
      }
      return;
    }
    _caliberByDiameter = false;
    if (key.startsWith('mm:')) {
      _cartridge = null;
      rifleCaliber.text = key.substring(3);
      return;
    }
    _cartridge = key;
    final mm = _firearmCartridges.firstWhere((e) => e.$1 == key).$2;
    rifleCaliber.text = _trimDot(mm);
  }

  /// "Fişeğim listede yok": the bullet diameters of the list, one per inch
  /// size (.224 in · 5,69 mm), smallest first.
  static final List<double> _bulletDiameters = () {
    final seen = <String>{};
    final out = <double>[];
    final all = [for (final (_, d) in Cartridges.firearm) d]..sort();
    for (final d in all) {
      if (seen.add((d / 25.4).toStringAsFixed(3))) out.add(d);
    }
    return out;
  }();

  static String _diameterLabel(double mm) =>
      '.${(mm / 25.4).toStringAsFixed(3).split('.').last} in · '
      '${mm.toStringAsFixed(2).replaceAll('.', ',')} mm';

  // ---- Tüfek Marka / Model / Kalibre lists (owner, 2026-10-11) ----

  /// True after "Listede yok": Marka and Model are typed.
  bool _rifleManual = false;

  /// The chosen rifle variant (one caliber of a model), or null.
  LibraryRifle? _rifleVariant;

  /// Kalibre: the whole cartridge list instead of the model's calibers.
  bool _caliberAll = false;

  /// Kalibre "Fişeğim listede yok": the bullet diameter is picked instead.
  bool _caliberByDiameter = false;

  /// Kimlik "Üretim": true = Yerli, false = İthal, null = all (owner,
  /// 2026-10-11). Filters the rifle Marka list.
  bool? _domestic;

  /// Rifle brands made in Türkiye.
  static const _domesticBrands = {
    'ATA Arms',
    'Aselkon Arms',
    'Balıklı',
    'Derya',
    'Effecto',
    'Ekol',
    'Hatsan',
    'Huğlu',
    'İstanbul Silah',
    'Kale Kalıp',
    'Kral Arms',
    'Kuzey Arms',
    'MKE',
    'Niksan Defence',
    'Retay',
    'Reximex',
    'Sarsılmaz',
    'Utaş Arms',
  };

  List<LibraryRifle> get _rifleLib => [
    for (final r in RifleLibrary.all)
      if (r.platform == platform &&
          (_domestic == null || _domesticBrands.contains(r.brand) == _domestic))
        r,
  ];

  static int _byName(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  List<String> get _rifleBrands =>
      {for (final r in _rifleLib) r.brand}.toList()..sort(_byName);

  List<String> _rifleModels(String brand) => {
    for (final r in _rifleLib)
      if (r.brand == brand) r.model,
  }.toList()..sort(_byName);

  List<LibraryRifle> get _rifleVariants => [
    for (final r in _rifleLib)
      if (r.brand == rifleBrand.text && r.model == rifleModel.text) r,
  ];

  void _applyRifleVariant(LibraryRifle r) {
    _rifleVariant = r;
    _caliberAll = false;
    _caliberByDiameter = false;
    rifleCaliber.text = _trimDot(r.diameterMm);
    _cartridge = r.platform == WeaponPlatform.firearm ? r.cartridge : null;
    if (r.twistRateIn != null) rifleTwist.text = _trimDot(r.twistRateIn!);
    if (r.twistDirection != null) twistDirection = r.twistDirection;
  }

  /// "6.5 Creedmoor", or with the barrel / twist when the model has the
  /// same caliber more than once.
  static String _variantLabel(LibraryRifle r, List<LibraryRifle> all) {
    if (all.where((v) => v.cartridge == r.cartridge).length < 2) {
      return r.cartridge;
    }
    final parts = <String>[r.cartridge];
    final b = r.barrelLengthMm;
    if (b != null) {
      final inch = b / 25.4;
      parts.add(
        '${inch.toStringAsFixed((inch - inch.round()).abs() < 0.05 ? 0 : 1)} in namlu',
      );
    }
    final t = r.twistRateIn;
    if (t != null) parts.add('1:${_trimDot(t)}');
    return parts.join(' · ');
  }

  /// The rifle variant a saved Marka / Model / caliber points to, if any.
  LibraryRifle? _variantFor(String brand, String model, double? cal) {
    final list = [
      for (final r in _rifleLib)
        if (r.brand == brand && r.model == model) r,
    ];
    if (list.isEmpty) return null;
    if (cal == null) return null;
    final c = _cartridge;
    return list
            .where(
              (r) =>
                  (r.diameterMm - cal).abs() < 0.005 &&
                  (c == null || r.cartridge == c) &&
                  (r.twistRateIn == null ||
                      r.twistRateIn == _parse(rifleTwist)),
            )
            .firstOrNull ??
        list.where((r) => (r.diameterMm - cal).abs() < 0.005).firstOrNull;
  }

  /// A listed ammunition belongs to its caliber: another caliber empties
  /// it (a typed one stays).
  void _keepAmmoInCaliber((String, String?) before) {
    if (before == (rifleCaliber.text, _cartridge)) return;
    if (!_ammoManual && ammoBrand.text.isNotEmpty) _clearAmmo();
  }

  /// Empties the rifle part chosen from the lists.
  void _clearRifleChoice() {
    _rifleVariant = null;
    _caliberAll = false;
    _caliberByDiameter = false;
    _cartridge = null;
    rifleCaliber.text = '';
  }

  // ---- Dürbün Marka / Model / Retikül lists (owner, 2026-10-11) ----

  /// True after "Aradığın dürbün listede yok mu?": the scope is typed in.
  bool _scopeManual = false;
  String? _scopeBrandSel;

  /// "Listede yok" in the scope Marka list, hidden (owner, 2026-10-13:
  /// "gizle, silme"); the link under the card opens the typed entry.
  static const bool _showScopeListedeYok = bool.fromEnvironment(
    'SCOPE_LISTEDE_YOK',
  );

  /// Profili Düzenle: the saved scope was found in the lists only by the
  /// tolerant rule (older naming, #235); its saved values are kept.
  bool _scopeTolerant = false;

  /// The catalog record the scope values came from (null: none chosen or a
  /// typed scope). Its missing values decide which hidden boxes show.
  ScopeOptic? _scopeRecord;

  /// Profili Düzenle of a catalog scope: Birim / Odak / Tüp / Büyütme stay
  /// hidden until Marka changes (owner, 2026-10-13).
  bool _scopeFiltersHidden = false;

  /// A catalog scope (picked from the lists): Minimum / Maksimum büyütme,
  /// Mercek çapı, Odak düzlemi and Dürbün birimi come from the record and
  /// are hidden (owner, 2026-10-13: "gizle, silme"). Only a value the
  /// record lacks shows its box so the user can fill it; before a Model is
  /// chosen they all stay hidden.
  bool get _scopeFromList => !_scopeManual && _scopeBrands.isNotEmpty;

  bool get _scopeMinMagShown =>
      !_scopeFromList ||
      (_scopeModelKey != null && _scopeRecord?.minMagnification == null);

  bool get _scopeMaxMagShown =>
      !_scopeFromList ||
      (_scopeModelKey != null && _scopeRecord?.maxMagnification == null);

  bool get _scopeObjectiveShown =>
      !_scopeFromList ||
      (_scopeModelKey != null &&
          ((_scopeRecord?.objectiveDiameterMm ?? 0) <= 0));

  bool get _scopeFocalShown =>
      !_scopeFromList ||
      (_scopeModelKey != null && _scopeRecord?.firstFocalPlane == null);

  bool get _scopeUnitShown =>
      !_scopeFromList ||
      (_scopeModelKey != null && (_scopeRecord == null || !_angularUnitSet));

  /// Opens the typed scope entry ("Aradığın dürbün listede yok mu?", and the
  /// hidden "Listede yok" item): every box starts on "Seçiniz".
  void _openScopeManual() {
    _scopeModelKey = null;
    scopeReticle = null;
    _scopePickToken++;
    _scopeManual = true;
    _scopeBrandSel = null;
    _scopeRecord = null;
    _scopeFiltersHidden = false;
    scopeBrand.text = '';
    for (final c in [
      scopeMinMag,
      scopeMaxMag,
      scopeObjective,
      scopeClick,
      scopeTravelElevation,
    ]) {
      c.clear();
    }
    firstFocalPlane = null;
    _angularUnitSet = false;
  }

  /// The chosen model: the catalog model without its reticle name.
  String? _scopeModelKey;

  static List<ScopeOptic> get _scopeLib => [
    for (final s in CatalogRepository.scopes)
      if (!s.userEntered) s,
  ];

  /// Reticle names of a record ("VPR-MIL / VHR-MIL" is two).
  static List<String> _reticlesOf(ScopeOptic s) =>
      ReticleCatalog.options(s.reticle);

  /// "Talos HMR 4-16x56 Center-X SFP MOA" -> "Talos HMR 4-16x56 SFP MOA":
  /// the reticles of one model are listed under Retikül.
  static String _scopeModelOf(ScopeOptic s) {
    var m = s.model;
    for (final r in _reticlesOf(s)) {
      final i = m.toLowerCase().indexOf(r.toLowerCase());
      if (i >= 0) m = m.substring(0, i) + m.substring(i + r.length);
    }
    return m.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  List<String> get _scopeBrands =>
      {for (final s in _scopeLib) s.brand}.toList()..sort(_byName);

  List<String> _scopeModels(String brand) => {
    for (final s in _scopeLib)
      if (s.brand == brand && _scopeFilterAccepts(s)) _scopeModelOf(s),
  }.toList()..sort(_byName);

  // ---- Dürbün filters (owner, 2026-10-13): what the user reads on the
  // scope or its box, narrowing step by step ("süzerek gider"): Marka →
  // Birim | Odak → Tüp | Büyütme → Model (no Objektif filter). Each list offers only
  // the values the scopes left over have, so the Model list is never empty.
  // "Seçiniz" = no filter.
  AngularUnit? _scopeUnitFilter;
  bool? _scopeFfpFilter;
  double? _scopeTubeFilter;
  String? _scopeMagFilter;

  static String _num(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toString().replaceAll('.', ',');

  static String _unitName(AngularUnit u) => switch (u) {
    AngularUnit.mrad => 'MRAD',
    AngularUnit.moa => 'MOA',
    AngularUnit.smoa => 'SMOA',
  };

  /// The magnification range as printed on the scope, e.g. "5-30x".
  static String? _magRange(ScopeOptic s) {
    final lo = s.minMagnification, hi = s.maxMagnification;
    if (hi == null) return null;
    return lo == null || lo == hi ? '${_num(hi)}x' : '${_num(lo)}-${_num(hi)}x';
  }

  /// [level]: how many filters apply (1 Birim, 2 Odak, 3 Tüp, 4 Büyütme).
  bool _scopeFilterAccepts(ScopeOptic s, [int level = 4]) {
    if (level >= 1 &&
        _scopeUnitFilter != null &&
        s.clickUnit != _scopeUnitFilter) {
      return false;
    }
    if (level >= 2 &&
        _scopeFfpFilter != null &&
        s.firstFocalPlane != _scopeFfpFilter) {
      return false;
    }
    if (level >= 3 &&
        _scopeTubeFilter != null &&
        s.tubeDiameterMm != _scopeTubeFilter) {
      return false;
    }
    if (level >= 4 &&
        _scopeMagFilter != null &&
        _magRange(s) != _scopeMagFilter) {
      return false;
    }
    return true;
  }

  /// Scopes of the chosen brand that pass the filters before [level].
  Iterable<ScopeOptic> _scopesBefore(int level) => _scopeLib.where(
    (s) => s.brand == _scopeBrandSel && _scopeFilterAccepts(s, level - 1),
  );

  List<AngularUnit> get _scopeUnitChoices {
    final have = {for (final s in _scopesBefore(1)) s.clickUnit};
    return [
      for (final u in AngularUnit.values)
        if (have.contains(u)) u,
    ];
  }

  List<bool> get _scopeFfpChoices {
    final have = {
      for (final s in _scopesBefore(2))
        if (s.firstFocalPlane != null) s.firstFocalPlane!,
    };
    return [
      for (final f in const [true, false])
        if (have.contains(f)) f,
    ];
  }

  List<String> get _scopeMagChoices {
    final byLow = <String, (double, double)>{};
    for (final s in _scopesBefore(4)) {
      final r = _magRange(s);
      if (r != null) {
        byLow[r] = (s.minMagnification ?? 0, s.maxMagnification ?? 0);
      }
    }
    return byLow.keys.toList()..sort((a, b) {
      final (la, ha) = byLow[a]!;
      final (lb, hb) = byLow[b]!;
      return la != lb ? la.compareTo(lb) : ha.compareTo(hb);
    });
  }

  List<double> get _scopeTubeChoices => {
    for (final s in _scopesBefore(3))
      if (s.tubeDiameterMm != null) s.tubeDiameterMm!,
  }.toList()..sort();

  /// After a change, a filter whose choice is no longer offered goes back
  /// to "Seçiniz" (checked in order, each against the ones before it).
  void _dropUnavailableScopeFilters() {
    if (_scopeUnitFilter != null &&
        !_scopeUnitChoices.contains(_scopeUnitFilter)) {
      _scopeUnitFilter = null;
    }
    if (_scopeFfpFilter != null &&
        !_scopeFfpChoices.contains(_scopeFfpFilter)) {
      _scopeFfpFilter = null;
    }
    if (_scopeTubeFilter != null &&
        !_scopeTubeChoices.contains(_scopeTubeFilter)) {
      _scopeTubeFilter = null;
    }
    if (_scopeMagFilter != null &&
        !_scopeMagChoices.contains(_scopeMagFilter)) {
      _scopeMagFilter = null;
    }
  }

  /// One line per model with its data (owner, 2026-10-13), e.g.
  /// "Continental x6 5-30x56i Fiber SFP · MOA".
  String _scopeModelLine(String brand, String model) {
    final s = _scopeLib
        .where(
          (x) =>
              x.brand == brand &&
              _scopeModelOf(x) == model &&
              _scopeFilterAccepts(x),
        )
        .firstOrNull;
    if (s == null) return model;
    // What the product name already says is not repeated (owner,
    // 2026-10-13: "CONTINENTAL X6 4-24X56 MBR FFP 34MM").
    final name = model.toLowerCase().replaceAll(' ', '');
    bool said(String t) => name.contains(t.toLowerCase().replaceAll(' ', ''));
    final unit = _unitName(s.clickUnit);
    final focal = s.firstFocalPlane == null
        ? null
        : s.firstFocalPlane!
        ? 'FFP'
        : 'SFP';
    // No brand and no tube on the line: too many parts made it tiny
    // (owner, 2026-10-13); the brand is chosen above anyway.
    return [
      model,
      if (!said(unit)) unit,
      if (focal != null && !said(focal)) focal,
    ].join(' · ');
  }

  List<Widget> _scopeFilterFields() {
    void changed(VoidCallback f) => setState(() {
      f();
      _dropUnavailableScopeFilters();
      // A chosen model that the filter drops goes back to "Seçiniz".
      final brand = _scopeBrandSel;
      if (brand != null &&
          _scopeModelKey != null &&
          !_scopeModels(brand).contains(_scopeModelKey)) {
        _scopeModelKey = null;
        scopeReticle = null;
      }
      _scopePickToken++;
    });
    String k(String name, Object? v) => 'scope-filter-$name-$_scopeBrandSel-$v';
    return [
      MenzilSelect<AngularUnit>(
        key: ValueKey(k('unit', _scopeUnitFilter)),
        label: 'Birim',
        hint: 'Seçiniz',
        info: ProfileFieldInfo.scopeFilterUnit,
        initialValue: _scopeUnitFilter,
        items: [
          const DropdownMenuItem<AngularUnit>(child: Text('Seçiniz')),
          for (final u in _scopeUnitChoices)
            DropdownMenuItem(value: u, child: Text(_unitName(u))),
        ],
        onChanged: (v) => changed(() => _scopeUnitFilter = v),
      ),
      MenzilSelect<bool>(
        key: ValueKey(k('ffp', _scopeFfpFilter)),
        label: 'Odak',
        hint: 'Seçiniz',
        info: ProfileFieldInfo.scopeFilterFocal,
        initialValue: _scopeFfpFilter,
        items: [
          const DropdownMenuItem<bool>(child: Text('Seçiniz')),
          for (final f in _scopeFfpChoices)
            DropdownMenuItem(value: f, child: Text(f ? 'FFP' : 'SFP')),
        ],
        onChanged: (v) => changed(() => _scopeFfpFilter = v),
      ),
      MenzilSelect<double>(
        key: ValueKey(k('tube', _scopeTubeFilter)),
        label: 'Tüp',
        hint: 'Seçiniz',
        info: ProfileFieldInfo.scopeFilterTube,
        initialValue: _scopeTubeFilter,
        items: [
          const DropdownMenuItem<double>(child: Text('Seçiniz')),
          for (final d in _scopeTubeChoices)
            DropdownMenuItem(value: d, child: Text('${_num(d)} mm')),
        ],
        onChanged: (v) => changed(() => _scopeTubeFilter = v),
      ),
      MenzilSelect<String>(
        key: ValueKey(k('mag', _scopeMagFilter)),
        label: 'Büyütme',
        hint: 'Seçiniz',
        info: ProfileFieldInfo.scopeFilterMag,
        initialValue: _scopeMagFilter,
        items: [
          const DropdownMenuItem<String>(child: Text('Seçiniz')),
          for (final r in _scopeMagChoices)
            DropdownMenuItem(value: r, child: Text(r)),
        ],
        onChanged: (v) => changed(() => _scopeMagFilter = v),
      ),
    ];
  }

  List<ScopeOptic> get _scopeGroup => [
    for (final s in _scopeLib)
      if (s.brand == _scopeBrandSel && _scopeModelOf(s) == _scopeModelKey) s,
  ];

  /// Retikül choices of the chosen model and the record each one belongs to.
  List<(String, ScopeOptic)> get _scopeReticleChoices {
    final out = <(String, ScopeOptic)>[];
    for (final s in _scopeGroup) {
      for (final r in _reticlesOf(s)) {
        if (!out.any((e) => e.$1 == r)) out.add((r, s));
      }
    }
    return out;
  }

  /// A plain reticle pattern that matches the scope's turret unit: MIL
  /// patterns for a MRAD scope, the MOA pattern for MOA / SMOA; Duplex fits
  /// both. A typed scope whose Dürbün birimi still says "Seçiniz" lists all
  /// five (owner, 2026-10-14): the hidden unit (MRAD in a new profile, the
  /// saved unit on edit) gave Profil Oluştur 4 and Profili Düzenle 2.
  bool _genericFitsUnit(String n) {
    if (!_scopeFromList && !_angularUnitSet) return true;
    if (n == Reticles.duplex) return true;
    final moa = angularUnit.moaFamily;
    return n == Reticles.hashMoa ? moa : !moa;
  }

  // ---- Dürbün values from lists (owner, 2026-10-11: select over typing).
  // Standard values of real scopes; a stored value outside the list is
  // added to it so an older profile still shows what it saved.

  /// Minimum büyütme: 1-6, 1.5-6, 2.5-15, 3-9, 4-16, 5-25, 6-24 …
  static const _minMagOptions = <double>[
    1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 7, 8, 10, 12, //
  ];

  /// Maksimum büyütme (a fixed-power scope has min = max).
  static const _maxMagOptions = <double>[
    4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 24, 25, 27, 28, //
    30, 32, 35, 36, 40, 42, 45, 48, 50, 56, 60, //
  ];

  /// Mercek çapı, mm.
  static const _objectiveOptions = <double>[
    20, 24, 28, 30, 32, 33, 36, 40, 42, 44, 45, 50, 52, 54, 56, 58, 60, //
    62, 64, 72, //
  ];

  /// Klik değeri of the turret, by unit: 0,1 / 0,05 mrad; 1/4, 1/8, 1/2 MOA.
  static List<(double, String)> _clickOptions(AngularUnit u) {
    final name = u == AngularUnit.smoa ? 'SMOA' : 'MOA';
    return u.moaFamily
        ? [(0.25, '1/4 $name'), (0.125, '1/8 $name'), (0.5, '1/2 $name')]
        : const [(0.1, '0,1 MRAD'), (0.05, '0,05 MRAD')];
  }

  /// A number picked from [options] into [controller] ("Seçiniz" while
  /// empty). [suffix] follows the number in the list ("x", " mm").
  Widget _numberSelect({
    required String key,
    required String label,
    required String info,
    required TextEditingController controller,
    required List<double> options,
    String suffix = '',
    String? errorText,
  }) {
    final current = _parse(controller);
    final values = [
      ...options,
      if (current != null && !options.contains(current)) current,
    ]..sort();
    return KeyedSubtree(
      key: Key(key),
      child: MenzilSelect<double>(
        key: ValueKey('$key-$_scopePickToken'),
        info: info,
        label: label,
        initialValue: current,
        errorText: errorText,
        items: [
          for (final v in values)
            DropdownMenuItem(value: v, child: Text('${_trimNum(v)}$suffix')),
        ],
        onChanged: (v) => setState(() {
          controller.text = v == null ? '' : _trimNum(v);
        }),
      ),
    );
  }

  /// Klik değeri, asked only for a typed scope ("Aradığın dürbün listede yok
  /// mu?"); a catalog
  /// scope brings its own. Empty until Dürbün birimi is chosen.
  Widget _clickSelect() {
    final options = _angularUnitSet
        ? _clickOptions(angularUnit)
        : const <(double, String)>[];
    final current = _parse(scopeClick);
    return KeyedSubtree(
      key: const Key('scope-click'),
      child: MenzilSelect<double>(
        key: ValueKey('scope-click-${angularUnit.name}-$_scopePickToken'),
        info: ProfileFieldInfo.clickValue,
        label: 'Klik değeri',
        initialValue: options.any((o) => o.$1 == current) ? current : null,
        errorText: _showErrors ? _clickError : null,
        items: [
          for (final (v, name) in options)
            DropdownMenuItem(value: v, child: Text(name)),
        ],
        onChanged: (v) => setState(() {
          scopeClick.text = v == null ? '' : _trimNum(v);
        }),
      ),
    );
  }

  /// Fills the scope form from a catalog record.
  void _applyScope(ScopeOptic s, {String? reticle}) {
    _angularUnitSet = true; // the catalog scope tells its unit
    final series = ScopePickerScreen.seriesOf(_scopeModelOf(s));
    _scopeRecord = s;
    scopeBrand.text = series.isEmpty ? s.brand : '${s.brand} $series';
    // A value the record lacks is emptied (not kept from an earlier model)
    // and its box is shown for the user to fill.
    scopeMinMag.text = s.minMagnification == null
        ? ''
        : _trimNum(s.minMagnification!);
    scopeMaxMag.text = s.maxMagnification == null
        ? ''
        : _trimNum(s.maxMagnification!);
    scopeObjective.text = s.objectiveDiameterMm > 0
        ? _trimNum(s.objectiveDiameterMm)
        : '';
    firstFocalPlane = s.firstFocalPlane;
    angularUnit = s.clickUnit;
    scopeClick.text = _trimNum(s.clickValue);
    final travel = s.elevationRangeMrad;
    scopeTravelElevation.text = travel == null || travel <= 0
        ? ''
        : (_fromMrad(travel, angularUnit) / s.clickValue).round().toString();
    scopeReticle = reticle;
    _scopePickToken++;
  }

  /// Marka and Model of the scope, each on its own row.
  List<Widget> _scopeNameFields() {
    final brands = _scopeBrands;
    if (_scopeManual || brands.isEmpty) {
      return [
        MenzilFullWidth(
          child: MenzilInput(
            key: const Key('scope-brand'),
            controller: scopeBrand,
            label: 'Dürbün markası',
            keyboardType: TextInputType.text,
            maxLength: 100,
            onChanged: (_) => setState(() {}),
            errorText: _shown(_scopeBrandError, scopeBrand),
          ),
        ),
        if (brands.isNotEmpty)
          MenzilFullWidth(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('scope-back-to-list'),
                onPressed: () => setState(() {
                  _scopeManual = false;
                  _scopeBrandSel = null;
                  _scopeModelKey = null;
                  _scopeRecord = null;
                  scopeBrand.text = '';
                  scopeClick.text = _trimNum(_defaultClick(angularUnit));
                  scopeReticle = null;
                  _scopePickToken++;
                }),
                icon: const Icon(Icons.list_alt, size: 18),
                label: const Text('Listeden seç'),
              ),
            ),
          ),
      ];
    }
    final brand = brands.contains(_scopeBrandSel) ? _scopeBrandSel : null;
    final models = brand == null ? const <String>[] : _scopeModels(brand);
    final model = models.contains(_scopeModelKey) ? _scopeModelKey : null;
    return [
      MenzilFullWidth(
        child: KeyedSubtree(
          key: const Key('scope-brand-select'),
          child: MenzilSelect<String>(
            key: ValueKey('scope-brand-select-$brand'),
            label: 'Marka',
            hint: 'Seçiniz',
            initialValue: brand,
            items: [
              for (final b in brands)
                DropdownMenuItem(value: b, child: Text(b)),
              if (_showScopeListedeYok)
                const DropdownMenuItem(
                  value: _manualKey,
                  child: Text('Listede yok'),
                ),
            ],
            onChanged: (v) => setState(() {
              if (v == _manualKey) {
                _openScopeManual();
                return;
              }
              _scopeModelKey = null;
              _scopeRecord = null;
              scopeReticle = null;
              _scopePickToken++;
              // A changed Marka shows the filters again (owner, 2026-10-13).
              _scopeFiltersHidden = false;
              _scopeBrandSel = v;
              scopeBrand.text = v ?? '';
              // A new brand starts every filter on "Seçiniz" (owner,
              // 2026-10-13).
              _scopeUnitFilter = null;
              _scopeFfpFilter = null;
              _scopeTubeFilter = null;
              _scopeMagFilter = null;
            }),
          ),
        ),
      ),
      if (brand != null && !_scopeFiltersHidden) ..._scopeFilterFields(),
      MenzilFullWidth(
        child: KeyedSubtree(
          key: const Key('scope-model-select'),
          child: MenzilSelect<String>(
            key: ValueKey(
              'scope-model-select-$brand-$model-$_scopeUnitFilter-'
              '$_scopeFfpFilter-$_scopeTubeFilter-$_scopeMagFilter',
            ),
            label: 'Model',
            hint: 'Seçiniz',
            initialValue: model,
            // Model and its data, no brand (owner, 2026-10-13). A long line
            // keeps its size and wraps, in the list (two lines) and in the
            // box, which grows (owner, 2026-10-14: like Mühimmat Model;
            // never smaller).
            wrapSelected: true,
            items: [
              for (final m in models)
                DropdownMenuItem(
                  value: m,
                  child: Text(_scopeModelLine(brand!, m), maxLines: 2),
                ),
            ],
            onChanged: (v) => setState(() {
              _scopeModelKey = v;
              final choices = _scopeReticleChoices;
              final group = _scopeGroup;
              if (group.isEmpty) return;
              // One reticle: chosen right away; otherwise Retikül waits.
              _applyScope(
                choices.length == 1 ? choices.first.$2 : group.first,
                reticle: choices.length == 1 ? choices.first.$1 : null,
              );
            }),
          ),
        ),
      ),
    ];
  }

  /// Namlu çıkış hızı, a half box beside Sıfırlama mesafesi on the last
  /// Tüfek row (owner, 2026-10-14 18:58; it sat left of Kalibre before).
  Widget _velocityField() => MenzilInput(
    key: const Key('profile-velocity-fps'),
    controller: velocity,
    label: 'Namlu çıkış hızı',
    info: platform == WeaponPlatform.firearm
        ? ProfileFieldInfo.velocityFirearm
        : ProfileFieldInfo.velocity,
    onChanged: (_) => setState(() {}),
    errorText: _shown(_velocityError, velocity),
  );

  /// Kalibre, full width and alone on its row under Marka and Model (owner,
  /// 2026-10-14 18:56–18:58: an exception to "two boxes per row" for Marka,
  /// Model and Kalibre). A long choice keeps its size and wraps; the box
  /// grows (like the Model boxes, #308).
  Widget _caliberField() {
    final choices = _caliberChoices;
    return MenzilFullWidth(
      child: KeyedSubtree(
        key: const Key('rifle-caliber'),
        child: MenzilSelect<String>(
          key: ValueKey(
            'rifle-caliber-${platform.name}-${rifleCaliber.text}-'
            '$_cartridge-${rifleBrand.text}-${rifleModel.text}-'
            '$_caliberAll-$_caliberByDiameter',
          ),
          info: platform == WeaponPlatform.firearm
              ? ProfileFieldInfo.caliberFirearm
              : ProfileFieldInfo.caliber,
          label: 'Kalibre',
          hint: 'Seçiniz',
          initialValue: _caliberKey,
          items: [for (final c in choices) c.item],
          wrapSelected: true,
          // The open list is as wide as the box, never wider (owner,
          // 2026-10-13: "kutudan dışarı çıkmasın"), so a long cartridge may
          // wrap there: its entry grows with it instead of keeping 48 pt and
          // spilling over the next one (a tap on its lower half chose
          // nothing).
          itemHeight: null,
          selectedLabels: [for (final c in choices) c.full],
          // Kept for the box's short form; unused while the text wraps.
          shortSelectedLabels: [for (final c in choices) c.short],
          onChanged: (v) => setState(() {
            final before = (rifleCaliber.text, _cartridge);
            _onCaliberKey(v);
            _keepAmmoInCaliber(before);
          }),
        ),
      ),
    );
  }

  /// "Listede yok" in the rifle Marka list, hidden (owner, 2026-10-14:
  /// "gizle, silme"); the link under Marka | Model opens the typed entry.
  static const bool _showRifleListedeYok = bool.fromEnvironment(
    'RIFLE_LISTEDE_YOK',
  );

  /// Opens the typed rifle entry ("Aradığın tüfek listede yok mu?", and the
  /// hidden "Listede yok" item): Marka and Model start empty; a listed
  /// ammunition of another caliber goes as before.
  void _openRifleManual() {
    final before = (rifleCaliber.text, _cartridge);
    rifleModel.text = '';
    _clearRifleChoice();
    _keepAmmoInCaliber(before);
    _rifleManual = true;
    rifleBrand.text = '';
  }

  /// Marka | Model of the rifle: two lists side by side; typed boxes after
  /// "Aradığın tüfek listede yok mu?" (owner, 2026-10-11, 2026-10-14).
  List<Widget> _rifleNameFields() {
    final brands = _rifleBrands;
    if (_rifleManual || brands.isEmpty) {
      return [
        MenzilFullWidth(
          child: MenzilInput(
            key: const Key('rifle-brand'),
            controller: rifleBrand,
            label: 'Marka',
            keyboardType: TextInputType.text,
            maxLength: 100,
            onChanged: (_) => setState(() {}),
            errorText: _shown(_brandError, rifleBrand),
          ),
        ),
        MenzilFullWidth(
          child: MenzilInput(
            key: const Key('rifle-model'),
            controller: rifleModel,
            label: 'Model',
            keyboardType: TextInputType.text,
            maxLength: 100,
            onChanged: (_) => setState(() {}),
            errorText: _shown(_modelError, rifleModel),
          ),
        ),
        if (brands.isNotEmpty)
          MenzilFullWidth(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('rifle-back-to-list'),
                onPressed: () => setState(() {
                  _rifleManual = false;
                  rifleBrand.text = '';
                  rifleModel.text = '';
                  _clearRifleChoice();
                }),
                icon: const Icon(Icons.list_alt, size: 18),
                label: const Text('Listeden seç'),
              ),
            ),
          ),
      ];
    }
    final brand = brands.contains(rifleBrand.text) ? rifleBrand.text : null;
    final models = brand == null ? const <String>[] : _rifleModels(brand);
    final model = models.contains(rifleModel.text) ? rifleModel.text : null;
    return [
      MenzilFullWidth(
        child: KeyedSubtree(
          key: const Key('rifle-brand-select'),
          child: MenzilSelect<String>(
            key: ValueKey('rifle-brand-select-${platform.name}-$brand'),
            label: 'Marka',
            hint: 'Seçiniz',
            initialValue: brand,
            // A long brand keeps its size and wraps; the box grows (owner,
            // 2026-10-14 18:58, like Model).
            wrapSelected: true,
            items: [
              for (final b in brands)
                DropdownMenuItem(value: b, child: Text(b)),
              if (_showRifleListedeYok)
                const DropdownMenuItem(
                  value: _manualKey,
                  child: Text('Listede yok'),
                ),
            ],
            onChanged: (v) => setState(() {
              if (v == _manualKey) {
                _openRifleManual();
                return;
              }
              final before = (rifleCaliber.text, _cartridge);
              rifleModel.text = '';
              _clearRifleChoice();
              _keepAmmoInCaliber(before);
              rifleBrand.text = v ?? '';
            }),
          ),
        ),
      ),
      MenzilFullWidth(
        child: KeyedSubtree(
          key: const Key('rifle-model-select'),
          child: MenzilSelect<String>(
            key: ValueKey('rifle-model-select-$brand-$model'),
            label: 'Model',
            hint: 'Seçiniz',
            initialValue: model,
            // A long model keeps its size and wraps; the box grows (owner,
            // 2026-10-14: like Mühimmat Model).
            wrapSelected: true,
            items: [
              for (final m in models)
                DropdownMenuItem(value: m, child: Text(m, maxLines: 2)),
            ],
            onChanged: (v) => setState(() {
              final before = (rifleCaliber.text, _cartridge);
              rifleModel.text = v ?? '';
              _clearRifleChoice();
              final variants = _rifleVariants;
              // One caliber: it is chosen right away.
              if (variants.length == 1) _applyRifleVariant(variants.first);
              _keepAmmoInCaliber(before);
            }),
          ),
        ),
      ),
      // Owner, 2026-10-14: the typed entry opens from this link instead of
      // a "Listede yok" item in the Marka list (Ateşli and PCP).
      MenzilFullWidth(
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('rifle-not-listed'),
            onPressed: () => setState(_openRifleManual),
            child: const Text('Aradığın tüfek listede yok mu?'),
          ),
        ),
      ),
    ];
  }

  /// BC model choices per rifle type (owner, 2026-10-10: the other public
  /// BRL drag laws). A stored model of the other type stays selectable.
  List<(BallisticModel, String)> get _bcModelChoices {
    final list = platform == WeaponPlatform.firearm
        ? const [
            // G1 first, then by number (owner, 2026-10-13), the others
            // last.
            (BallisticModel.g1, 'G1'),
            (BallisticModel.g2, 'G2'),
            (BallisticModel.g5, 'G5'),
            (BallisticModel.g6, 'G6'),
            (BallisticModel.g7, 'G7'),
            (BallisticModel.g8, 'G8'),
            (BallisticModel.gi, 'GI (Ingalls)'),
            (BallisticModel.ra4, 'RA4 (.22 LR rimfire)'),
          ]
        // PCP (owner, 2026-10-14 11:35/11:38): every standard table, G1
        // first; the ⓘ says which shape each one is.
        : const [
            (BallisticModel.g1, 'G1'),
            (BallisticModel.g7, 'G7'),
            (BallisticModel.g2, 'G2'),
            (BallisticModel.g5, 'G5'),
            (BallisticModel.g6, 'G6'),
            (BallisticModel.g8, 'G8'),
            (BallisticModel.gi, 'GI'),
            (BallisticModel.gs, 'GS'),
            (BallisticModel.ra4, 'RA4'),
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

  /// Mühimmat Model, separate from Marka (owner, 2026-10-11).
  late final TextEditingController ammoModel;

  /// True: Marka/Model are typed ("Listede yok"); false: picked from the
  /// library lists (owner, 2026-10-11: typed names are mistyped).
  bool _ammoManual = false;

  /// Typed firearm ammunition (owner, 2026-10-14): Marka is picked from
  /// every known brand; "Diğer" ([_ammoBrandOther]) opens the typed box.
  /// Ağırlık is picked from the maker weights of this Kalibre; "Listede
  /// yok" ([_grainOther]) opens a typed grain box with a plausibility range.
  bool _ammoBrandOther = false;
  bool _grainOther = false;
  late final TextEditingController ammoGrain;

  /// PCP projectile length in mm. Its box is shown only with
  /// PROFILE_AMMO_LENGTH; the value is still saved and loaded, but the
  /// calculation reads only Pro > Mermi uzunluğu (owner, 2026-10-13).
  late final TextEditingController ammoLength;
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
  final FocusNode _nameFocus = FocusNode();
  String _defaultName = '';
  late final TextEditingController velocity;
  late final TextEditingController zero;
  late final TextEditingController sight;

  /// Barut sıcaklığı (firearms): % per 15 °C and the air temperature (°C)
  /// the velocity was measured at, as typed. [_powderAutoFilled]: the boxes
  /// hold the maker's figure of the picked factory round, so another pick
  /// replaces them; typed values are never cleared by a pick.
  late final TextEditingController powderCoef;
  late final TextEditingController powderTemp;
  bool _powderAutoFilled = false;

  /// PCP tüp ve regülatör basıncı (bar) and basınca göre hız rows (bar |
  /// fps), as typed; PCP only, all optional (owner, 2026-10-12). An empty
  /// regülatör basıncı means an unregulated rifle.
  late final TextEditingController tubePressure;
  late final TextEditingController regulatorPressure;
  late final List<TextEditingController> pvBar;
  late final List<TextEditingController> pvFps;

  /// Dürbün ayağı in MOA, picked from [ProductionLimits.mountCantOptionsMoa].
  late double mountCant;
  String? validationError;
  late AngularUnit angularUnit;

  /// Retikül (owner, 2026-10-10): a catalog reticle name or one of
  /// [Reticles.genericNames]; null = not chosen (plain marks).
  String? scopeReticle;

  /// Metre or yard for the zero (and every distance of this profile).
  late DistanceUnit distanceUnit;

  /// A new profile shows "Seçiniz" in every list box until the user picks
  /// (owner, 2026-10-11); the stored default only keeps the form working.
  /// An edited profile starts with everything chosen.
  bool _distanceUnitSet = true;
  bool _angularUnitSet = true;
  bool _mountCantSet = true;
  bool _ammoSourceSet = true;

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
    platform = p == null
        ? WeaponPlatform.firearm
        : initialRifle?.platform ?? ammo?.platform ?? WeaponPlatform.pcp;
    scope = p == null
        ? null
        : _allScopes.where((o) => o.id == p.scopeId).firstOrNull;
    String num(double? v) =>
        v == null ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString());
    rifleBrand = TextEditingController(text: initialRifle?.brand ?? '');
    rifleModel = TextEditingController(text: initialRifle?.model ?? '');
    rifleCaliber = TextEditingController(text: num(initialRifle?.caliberMm));
    _cartridge = initialRifle == null
        ? null
        : RiflePickerScreen.cartridgeName(initialRifle);
    _grainFocus.addListener(() => setState(() {}));
    rifleTwist = TextEditingController(text: num(initialRifle?.twistRateIn));
    twistDirection = initialRifle?.twistDirection;
    // A saved rifle of the lists comes back in the lists; anything else in
    // the typed boxes (owner, 2026-10-11).
    if (rifleBrand.text.isNotEmpty) {
      var known = _rifleLib.any(
        (r) => r.brand == rifleBrand.text && r.model == rifleModel.text,
      );
      // Saved before the list names changed (#235, owner 2026-10-14):
      // matched tolerantly by Marka + Model, then the caliber. Marka and
      // Model take the list's spelling; the saved caliber and yiv stay.
      if (!known) {
        final match = ProfileCatalogMatch.rifle(
          rifleBrand.text,
          rifleModel.text,
          initialRifle?.caliberMm,
          _rifleLib,
        );
        if (match != null) {
          rifleBrand.text = match.brand;
          rifleModel.text = match.model;
          known = true;
        }
      }
      _rifleManual = !known;
      if (known) {
        // Üretim shows the saved rifle's origin, not "Seçiniz" (owner,
        // 2026-10-13). The rifle's brand is in the list of its own origin,
        // so Marka and Model keep their values. A typed rifle stays null.
        _domestic = _domesticBrands.contains(rifleBrand.text);
        _rifleVariant = _variantFor(
          rifleBrand.text,
          rifleModel.text,
          initialRifle?.caliberMm,
        );
        if (_rifleVariant != null) {
          _cartridge = _rifleVariant!.platform == WeaponPlatform.firearm
              ? _rifleVariant!.cartridge
              : null;
        } else {
          _caliberAll = true;
        }
      }
    }
    final s0 = scope;
    // A catalog scope comes back in the lists; a typed one in the typed box.
    if (s0 != null) {
      ScopeOptic? hit = s0.userEntered
          ? _scopeLib
                .where(
                  (r) =>
                      '${r.brand} ${ScopePickerScreen.seriesOf(_scopeModelOf(r))}'
                              .trim() ==
                          s0.brand.trim() &&
                      r.minMagnification == s0.minMagnification &&
                      r.maxMagnification == s0.maxMagnification &&
                      r.objectiveDiameterMm == s0.objectiveDiameterMm &&
                      (s0.reticle == null ||
                          _reticlesOf(r).contains(s0.reticle)),
                )
                .firstOrNull
          : s0;
      // Saved before the 13 Oct catalog update (#235) or under an older
      // naming (owner, 2026-10-14): matched tolerantly by Marka + series,
      // then büyütme / mercek çapı / odak / birim. The exact rule above
      // still goes first.
      if (hit == null && s0.userEntered) {
        hit = ProfileCatalogMatch.scope(s0, _scopeLib, _scopeModelOf);
        if (hit != null) _scopeTolerant = true;
      }
      if (hit == null) {
        _scopeManual = true;
      } else {
        _scopeBrandSel = hit.brand;
        _scopeModelKey = _scopeModelOf(hit);
        _scopeRecord = hit;
        // Profili Düzenle of a catalog scope: no filter boxes (owner,
        // 2026-10-13); they come back when Marka changes.
        _scopeFiltersHidden = true;
      }
    }
    angularUnit = p?.angularUnit ?? s0?.clickUnit ?? AngularUnit.mrad;
    // A built-in record carries its series in Model; the list shows (and
    // saves) "Marka Seri" as a new pick does, so the saved copy comes back
    // in the lists after a save (owner, 2026-10-14).
    final rec = _scopeRecord;
    final series = s0 != null && !s0.userEntered && rec != null
        ? ScopePickerScreen.seriesOf(_scopeModelOf(rec))
        : '';
    scopeBrand = TextEditingController(
      text: series.isEmpty ? (s0?.brand ?? '') : '${rec!.brand} $series',
    );
    // A tolerant match keeps every saved value; only a value the saved
    // record lacks is taken from the list record (nothing is overwritten).
    final fill = _scopeTolerant ? rec : null;
    scopeMinMag = TextEditingController(
      text: num(s0?.minMagnification ?? fill?.minMagnification),
    );
    scopeMaxMag = TextEditingController(
      text: num(s0?.maxMagnification ?? fill?.maxMagnification),
    );
    scopeObjective = TextEditingController(
      text: num(
        fill != null && (s0?.objectiveDiameterMm ?? 0) <= 0
            ? fill.objectiveDiameterMm
            : s0?.objectiveDiameterMm,
      ),
    );
    scopeClick = TextEditingController(
      text: s0 != null && s0.clickUnit == angularUnit
          ? num(s0.clickValue)
          : num(_defaultClick(angularUnit)),
    );
    firstFocalPlane = s0?.firstFocalPlane ?? fill?.firstFocalPlane;
    scopeReticle = s0?.reticle;
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
    // An ammunition of the other rifle type (a PCP slug saved with a
    // firearm) is not shown; the user picks a bullet again.
    if (ammo != null && ammo!.platform != platform) ammo = null;
    final a0 = ammo;
    // Marka and Model are separate boxes again (owner, 2026-10-11); a
    // personal record that kept the whole name in the brand shows it there.
    ammoBrand = TextEditingController(text: a0?.brand ?? '');
    ammoModel = TextEditingController(text: a0?.model ?? '');
    // A saved ammunition of the lists comes back in the lists; anything
    // else in the typed boxes (owner, 2026-10-11).
    if (a0 != null) {
      final inFactory = FactoryAmmoLibrary.all.any(
        (f) => f.brand == a0.brand && f.name == a0.model,
      );
      final inLibrary = BulletLibrary.all.any(
        (b) =>
            b.platform == a0.platform &&
            b.brand == a0.brand &&
            _modelOf(b) == a0.model,
      );
      _factoryAmmo = inFactory || !inLibrary;
      _ammoManual = !inFactory && !inLibrary;
    }
    ammoGrain = TextEditingController(text: num(a0?.grain));
    // A saved typed firearm round comes back in the typed boxes with its
    // values: an unknown brand as "Diğer" + typed, an unlisted weight as
    // "Listede yok" + typed (owner, 2026-10-14).
    if (a0 != null && _ammoManual && platform == WeaponPlatform.firearm) {
      _ammoBrandOther =
          ammoBrand.text.isNotEmpty &&
          !_allFirearmAmmoBrands.contains(ammoBrand.text);
      _grainOther =
          a0.grain > 0 && !_caliberWeights.contains(_parse(ammoGrain));
    }
    ammoLength = TextEditingController(text: num(a0?.lengthMm));
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
    // A PCP model picked without a BC is kept too (owner, 2026-10-14).
    ammoBcModel = a0?.ballisticModel ?? a0?.modelWithoutBc;
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
    // New profile (owner, 2026-10-12): a tap on Profil adı clears the
    // default name; leaving it empty puts the default back.
    _defaultName = name.text;
    if (p == null) {
      _nameFocus.addListener(() {
        if (_nameFocus.hasFocus && name.text == _defaultName) {
          name.clear();
        } else if (!_nameFocus.hasFocus && name.text.trim().isEmpty) {
          name.text = _defaultName;
        }
      });
    }
    // Muzzle velocity is entered in fps on Profil (owner decision); the
    // profile keeps storing m/s, so every calculation is unchanged.
    velocity = TextEditingController(
      text: p == null ? '' : _fpsText(p.muzzleVelocityMps),
    );
    // New profiles start empty: no placeholder value is ever taken for the
    // user's data (owner, 2026-10-07: "250 m/s nereden geliyor?").
    distanceUnit = p?.distanceUnit ?? DistanceUnit.meter;
    if (p == null) {
      _distanceUnitSet = false;
      _angularUnitSet = false;
      _mountCantSet = false;
      _ammoSourceSet = false;
    }
    zero = TextEditingController(
      text: p == null
          ? ''
          : num(_round1(distanceUnit.fromMeters(p.zeroRangeM))),
    );
    sight = TextEditingController(text: p == null ? '' : num(p.sightHeightMm));
    // 0 = normal mount; old profiles have no value.
    mountCant = p?.mountCantMoa ?? 0;
    powderCoef = TextEditingController(
      text: p?.powderTempCoefPercentPer15C == null
          ? ''
          : _trimNum(p!.powderTempCoefPercentPer15C!),
    );
    powderTemp = TextEditingController(
      text: p?.powderTempReferenceC == null
          ? ''
          : _trimNum(p!.powderTempReferenceC!),
    );
    // An older PCP profile's pressure (regülatör basıncı since V379) comes
    // back in its box, so saving keeps it.
    regulatorPressure = TextEditingController(
      text: p?.pressureBar == null ? '' : _trimNum(p!.pressureBar!),
    );
    tubePressure = TextEditingController(
      text: p?.tubePressureBar == null ? '' : _trimNum(p!.tubePressureBar!),
    );
    final pv = p?.pressureVelocityTable ?? const <PressureVelocityPoint>[];
    pvBar = [
      for (var i = 0; i < PcpPressure.tableRows; i++)
        TextEditingController(text: i < pv.length ? _trimNum(pv[i].bar) : ''),
    ];
    pvFps = [
      for (var i = 0; i < PcpPressure.tableRows; i++)
        TextEditingController(text: i < pv.length ? _fpsText(pv[i].mps) : ''),
    ];
  }

  // ---- PCP tüp ve regülatör basıncı (owner, 2026-10-12) -----------------

  static const double _minPcpBar = 10;

  String? _optionalBarError(TextEditingController c) => c.text.trim().isEmpty
      ? null
      : _rangeError(c, _minPcpBar, ProductionLimits.maxPcpPressureBar);

  String? get _tubePressureError => _optionalBarError(tubePressure);

  String? get _regulatorPressureError {
    final e = _optionalBarError(regulatorPressure);
    if (e != null || regulatorPressure.text.trim().isEmpty) return e;
    final tube = _parse(tubePressure);
    if (_tubePressureError == null &&
        tube != null &&
        _parse(regulatorPressure)! >= tube) {
      return 'Tüp basıncından küçük olmalı.';
    }
    return null;
  }

  bool _pvRowEmpty(int i) =>
      pvBar[i].text.trim().isEmpty && pvFps[i].text.trim().isEmpty;

  String? _pvBarError(int i) {
    if (_pvRowEmpty(i)) return null;
    final e = _rangeError(
      pvBar[i],
      _minPcpBar,
      ProductionLimits.maxPcpPressureBar,
    );
    if (e != null) return e;
    for (var j = 0; j < i; j++) {
      if (_parse(pvBar[j]) == _parse(pvBar[i])) {
        return 'Bu basınç başka satırda var.';
      }
    }
    return null;
  }

  String? _pvFpsError(int i) =>
      _pvRowEmpty(i) ? null : _rangeError(pvFps[i], 100, 4900);

  bool get _pcpPressureValid {
    if (platform != WeaponPlatform.pcp) return true;
    if (_tubePressureError != null || _regulatorPressureError != null) {
      return false;
    }
    for (var i = 0; i < PcpPressure.tableRows; i++) {
      if (_pvBarError(i) != null || _pvFpsError(i) != null) return false;
    }
    return true;
  }

  /// Barut sıcaklığı is optional; given, both boxes and the bands of
  /// [PowderTemperature] apply.
  String? get _powderCoefError {
    final t = powderCoef.text.trim();
    if (t.isEmpty) {
      return powderTemp.text.trim().isEmpty ? null : 'Katsayıyı da girin.';
    }
    final v = _parse(powderCoef);
    if (v == null || v.abs() > PowderTemperature.maxCoef) {
      return '-10 ile 10 arasında bir değer girin.';
    }
    return null;
  }

  String? get _powderTempError {
    final t = powderTemp.text.trim();
    if (t.isEmpty) {
      return powderCoef.text.trim().isEmpty ? null : 'Sıcaklığı da girin.';
    }
    final v = _parse(powderTemp);
    if (v == null ||
        v < PowderTemperature.minTempC ||
        v > PowderTemperature.maxTempC) {
      return '-50 ile 60 arasında bir değer girin.';
    }
    return null;
  }

  bool get _powderValid =>
      platform != WeaponPlatform.firearm ||
      (_powderCoefError == null && _powderTempError == null);

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
      (_caliberError == null, 'Kalibre'),
      (_twistError == null, 'Yiv oranı'),
      (twistDirection != null, 'Yiv yönü'),
      (_validSight, 'Sight height'),
      (_distanceUnitSet, 'Mesafe birimi'),
      (_zeroError == null, 'Sıfırlama mesafesi'),
      (_velocityError == null, 'Namlu çıkış hızı'),
    ]);
    // Only boxes the user can see are named (owner, 2026-10-14): a catalog
    // scope not chosen yet is "Model", not the five hidden boxes its record
    // fills in.
    final listScope = _scopeFromList;
    section('Dürbün', [
      (_scopeBrandError == null, 'Marka'),
      if (listScope) (_scopeModelKey != null, 'Model'),
      if (_scopeMinMagShown) (_minMagError == null, 'Min. büyütme'),
      if (_scopeMaxMagShown) (_maxMagError == null, 'Maks. büyütme'),
      if (_scopeObjectiveShown) (_objectiveError == null, 'Mercek çapı'),
      if (_scopeFocalShown) (firstFocalPlane != null, 'Odak düzlemi'),
      if (_scopeUnitShown) (_angularUnitSet, 'Dürbün birimi'),
      (_mountCantSet, 'Dürbün ayağı'),
      // Asked for a typed scope; a catalog scope brings its own.
      if (!listScope) (_clickError == null, 'Klik değeri'),
      (_travelError(scopeTravelElevation) == null, 'Üst kule klik sayısı'),
    ]);
    section('Mühimmat', [
      if (platform == WeaponPlatform.firearm) (_ammoSourceSet, 'Mühimmat türü'),
      (_ammoBrandError == null, 'Marka'),
      if (_typedFirearmAmmo) (_ammoModelError == null, 'Model'),
      (_effectiveAmmoType != null, 'Tip'),
      (_grainError == null, 'Ağırlık'),
      if (platform == WeaponPlatform.pcp && _showProfileAmmoLength)
        (_lengthError == null, 'Uzunluk'),
      if (_customCurve)
        (_dragCurve != null, 'Sürüklenme eğrisi')
      else ...[
        (_bcError == null, 'BC'),
        (_bcModelForSave != null, 'BC modeli'),
        (_bandsValid, 'Hıza göre BC'),
      ],
      if (platform == WeaponPlatform.firearm) (_powderValid, 'Barut sıcaklığı'),
      if (platform == WeaponPlatform.pcp) (_pcpPressureValid, 'Basınç'),
    ]);
    return out;
  }

  static double _defaultClick(AngularUnit u) => u.standardClick;

  @override
  void dispose() {
    _nameFocus.dispose();
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
    ammoModel.dispose();
    ammoGrain.dispose();
    ammoLength.dispose();
    ammoBc.dispose();
    powderCoef.dispose();
    powderTemp.dispose();
    tubePressure.dispose();
    regulatorPressure.dispose();
    for (final c in [...ammoBandFps, ...ammoBandBc, ...pvBar, ...pvFps]) {
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
      String f(double x) =>
          x % 1 == 0 ? x.toStringAsFixed(0) : '$x'.replaceAll('.', ',');
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

  /// PCP needs no Marka (owner, 2026-10-13: the brand adds nothing to the
  /// calculation); an empty one is saved as "Özel yapım".
  String? get _ammoBrandError =>
      platform == WeaponPlatform.pcp ? null : _textError(ammoBrand);

  /// Typed firearm ammunition needs its Model (owner, 2026-10-14: the same
  /// brand's other rounds would be mixed up otherwise).
  String? get _ammoModelError =>
      _typedFirearmAmmo ? _textError(ammoModel) : null;

  String? get _grainError =>
      _typedFirearmAmmo ? _typedGrainError : _rangeError(ammoGrain, 1, 800);

  // ---- Typed firearm ammunition (owner, 2026-10-14) ----------------------

  /// "Diğer" in the typed Marka list; "Listede yok" in the Ağırlık list.
  static const _otherKey = '__other';
  static const double _grainOtherKey = -1;

  /// Hız eşiğine göre BC for typed firearm ammunition, hidden (owner,
  /// 2026-10-14; hidden, not removed). Saved bands are kept and used.
  static const bool _showTypedBands = bool.fromEnvironment(
    'AMMO_BC_BANDS_TYPED',
  );

  /// The "Listede yok" item of the firearm ammo Marka list, hidden (owner,
  /// 2026-10-14): the typed entry opens from the "Aradığın mühimmat listede
  /// yok mu?" link instead.
  static const bool _showAmmoListedeYok = bool.fromEnvironment(
    'AMMO_LISTEDE_YOK',
  );

  /// Barut katsayısı (%/15 °C) and Hız ölçüm sıcaklığı (°C) lists.
  static const List<double> _powderCoefOptions = [
    0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, //
  ];
  static const List<double> _powderTempOptions = [
    -10, -5, 0, 5, 10, 15, 21, 25, 30, 35, 40, //
  ];

  /// Every firearm ammunition brand the app knows (factory rounds and the
  /// firearm bullets of the library), sorted.
  static final List<String> _allFirearmAmmoBrands = {
    for (final a in FactoryAmmoLibrary.all) a.brand,
    for (final b in BulletLibrary.all)
      if (b.platform == WeaponPlatform.firearm) b.brand,
  }.toList()..sort(_byName);

  /// Firearm ammunition the shooter types (link or nothing listed here).
  bool get _typedFirearmAmmo =>
      platform == WeaponPlatform.firearm && (_ammoManual || _ammoListEmpty);

  /// The firearm Marka list has nothing for this Kalibre (Fabrika fişeği
  /// without a Kalibre lists every round, so it is never empty).
  bool get _ammoListEmpty {
    if (platform != WeaponPlatform.firearm) return false;
    if (_factoryAmmo) {
      return _parse(rifleCaliber) != null && _factoryHere.isEmpty;
    }
    return _libraryHere.isEmpty;
  }

  String? _weightsKey;
  List<double> _weightsCache = const [];

  /// Maker weights (grain) in the app's data for this Kalibre: the factory
  /// rounds of the cartridge (else of the diameter) and the firearm library
  /// bullets of the diameter; unique, ascending. Empty without a Kalibre.
  List<double> get _caliberWeights {
    final cal = _parse(rifleCaliber);
    if (cal == null) return const [];
    final c = _cartridge;
    final key = '$cal|$c';
    if (key == _weightsKey) return _weightsCache;
    final set = <double>{
      for (final a in FactoryAmmoLibrary.all)
        if (c != null ? a.cartridge == c : (a.diameterMm - cal).abs() < 0.02)
          a.grain,
      for (final b in BulletLibrary.all)
        if (b.platform == WeaponPlatform.firearm &&
            (b.caliberMm - cal).abs() < 0.02)
          b.grain,
    };
    _weightsKey = key;
    return _weightsCache = set.toList()..sort();
  }

  /// "168 gr (10,9 g)": grain with its gram equivalent, Turkish comma.
  static String _grainLabel(double grain) =>
      '${_trimNum(grain)} gr (${_gramText(grain)} g)';

  static String _gramText(double grain) =>
      (grain * 0.06479891).toStringAsFixed(1).replaceAll('.', ',');

  /// Accepted typed weights for this Kalibre: 0,8 × lightest to 1,25 ×
  /// heaviest listed weight; without listed weights, a sectional density of
  /// 0,08–0,45 lb/in² (grain / (7000 · d²), d in inches).
  (double, double)? get _typedGrainRange {
    final cal = _parse(rifleCaliber);
    if (cal == null || cal <= 0) return null;
    final w = _caliberWeights;
    if (w.isNotEmpty) return (0.8 * w.first, 1.25 * w.last);
    final dIn = cal / 25.4;
    final k = 7000 * dIn * dIn;
    return (0.08 * k, 0.45 * k);
  }

  static const _implausibleGrain =
      'Bu ağırlık bu kalibre için mantıklı değil. Kutudaki değeri kontrol '
      'edin.';

  String? get _typedGrainError {
    if (_parse(rifleCaliber) == null) return 'Önce Kalibre seçin.';
    final g = _parse(ammoGrain);
    if (!_grainOther) {
      // Only a listed weight; a weight of another Kalibre (Kalibre changed
      // after the pick) is not taken silently.
      if (ammoGrain.text.trim().isEmpty) return 'Gerekli.';
      return g != null && _caliberWeights.contains(g)
          ? null
          : 'Ağırlığı listeden seçin.';
    }
    final e = _rangeError(ammoGrain, 1, 800);
    if (e != null) return e;
    final r = _typedGrainRange!;
    return g! < r.$1 || g > r.$2 ? _implausibleGrain : null;
  }

  /// "Federal Gold Medal · .308 Win · 168 gr (10,9 g) · BC 0,462 G1", once
  /// Marka, Model, Ağırlık, BC and BC modeli are valid; else null.
  String? get _typedAmmoSummary {
    if (!_typedFirearmAmmo || _customCurve) return null;
    final model = _bcModelForSave;
    final bc = _parse(ammoBc), g = _parse(ammoGrain);
    if (_ammoBrandError != null ||
        _ammoModelError != null ||
        _grainError != null ||
        _bcError != null ||
        model == null ||
        bc == null ||
        g == null) {
      return null;
    }
    final cal = _parse(rifleCaliber)!;
    final caliber = _cartridge ?? '${_trimNum(cal)} mm';
    final name = '${ammoBrand.text.trim()} ${ammoModel.text.trim()}';
    return '$name · $caliber · ${_grainLabel(g)} · '
        'BC ${_trimNum(bc)} ${model.name.toUpperCase()}';
  }

  /// Opens the typed firearm entry from the "listede yok mu?" link.
  void _openAmmoManual() {
    _clearAmmo();
    _ammoManual = true;
  }

  /// Uzunluk is optional; a typed one must be a plausible pellet/slug.
  String? get _lengthError =>
      ammoLength.text.trim().isEmpty ? null : _rangeError(ammoLength, 1, 60);

  /// A typed BC far outside every manufacturer BC of its kind in the
  /// library (owner, 2026-10-13: "1,2" for a 130 gr bullet). Bounds are
  /// the form factor i = SD / BC seen in lib/data/bullet_library.dart
  /// (2026-10-13), widened by about 10 %: firearm G1 0.36–4.15, G7
  /// 0.70–1.61, PCP slug G1 0.40–1.23, pellet G1 1.05–4.28. A warning,
  /// never a block.
  String? get _bcPlausibilityWarning {
    if (_customCurve) return null;
    final bc = _parse(ammoBc), grain = _parse(ammoGrain);
    final cal = _parse(rifleCaliber);
    if (bc == null || bc <= 0 || grain == null || cal == null || cal <= 0) {
      return null;
    }
    final model = _bcModelForSave;
    final type = _effectiveAmmoType;
    final (double lo, double hi)? range = switch ((platform, type, model)) {
      (WeaponPlatform.firearm, _, BallisticModel.g1) => (0.32, 4.6),
      (WeaponPlatform.firearm, _, BallisticModel.g7) => (0.63, 1.8),
      (WeaponPlatform.pcp, AmmunitionType.slug, BallisticModel.g1) => (
        0.36,
        1.4,
      ),
      (WeaponPlatform.pcp, AmmunitionType.pellet, BallisticModel.g1) => (
        0.95,
        4.7,
      ),
      _ => null,
    };
    if (range == null) return null;
    final dIn = cal / 25.4;
    final i = grain / (7000 * dIn * dIn) / bc;
    if (i < range.$1) {
      return 'Bu BC, bu kalibre ve ağırlık için çok yüksek görünüyor. '
          'Kutudaki değeri kontrol edin; yanlışsa uzak mesafede düşüş '
          'olduğundan az hesaplanır.';
    }
    if (i > range.$2) {
      return 'Bu BC, bu kalibre ve ağırlık için çok düşük görünüyor. '
          'Kutudaki değeri kontrol edin.';
    }
    return null;
  }

  /// The BC plausibility warning, full width.
  Widget get _bcWarningNotice => MenzilFullWidth(
    child: MenzilNotice(
      key: const Key('ammo-bc-warning'),
      tone: MenzilNoticeTone.warning,
      message: _bcPlausibilityWarning!,
    ),
  );

  /// PCP: BC may be left empty (owner, 2026-10-12: most Turkish pellets
  /// publish none); a typed one is still range-checked.
  String? get _bcError =>
      platform == WeaponPlatform.pcp && ammoBc.text.trim().isEmpty
      ? null
      : _rangeError(ammoBc, 0.005, 1.5);

  /// PCP: the BC modeli the user picked; G1 while none is known (owner,
  /// 2026-10-14: "G1 seçili kalsın"). Firearm: as chosen, null = not yet.
  BallisticModel? get _bcModelForSave => platform == WeaponPlatform.pcp
      ? ammoBcModel ?? BallisticModel.g1
      : ammoBcModel;

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
    final main = _parse(ammoBc);
    if (rows.isEmpty || main == null) return const [];
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
      _ammoModelError == null &&
      _grainError == null &&
      (_customCurve
          ? _dragCurve != null && _curveSd != null
          : _bcError == null && _bandsValid && _bcModelForSave != null) &&
      _effectiveAmmoType != null &&
      _powderValid &&
      _pcpPressureValid;

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

  /// Show field errors only after the user typed something or tried to save.
  bool _showErrors = false;
  String? _shown(String? error, TextEditingController c) =>
      (_showErrors || c.text.isNotEmpty) ? error : null;

  /// A list box shows its error after a save attempt, or once [c] holds a
  /// picked value (Maksimum below Minimum).
  String? _shownSelect(String? error, [TextEditingController? c]) =>
      (_showErrors || (c != null && c.text.isNotEmpty)) ? error : null;

  /// True when saving may update [record] in place: a personal record no
  /// other profile points at. A shared one is written under a new id
  /// (PRF-2); catalog records are read-only.
  bool _ownsRecord(String? id, {required bool userEntered}) =>
      id != null && userEntered && !widget.sharedRecordIds.contains(id);

  Map<String, dynamic> _rifleEntry() {
    final existing = rifle;
    return <String, dynamic>{
      'id':
          _ownsRecord(existing?.id, userEntered: existing?.userEntered == true)
          ? existing!.id
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

  /// Length written with the ammunition: the typed box when shown, else
  /// the length this ammunition already had (unused by the calculation,
  /// which asks only Pro > Mermi uzunluğu).
  double? get _savedLengthMm =>
      _showProfileAmmoLength ? _parse(ammoLength) : ammo?.lengthMm;

  Map<String, dynamic> _ammoEntry() {
    final existing = ammo;
    return <String, dynamic>{
      'id':
          _ownsRecord(existing?.id, userEntered: existing?.userEntered == true)
          ? existing!.id
          : 'manual_ammo_${DateTime.now().microsecondsSinceEpoch}',
      'kind': 'ammo',
      'platform': platform.name,
      'brand': ammoBrand.text.trim(),
      'model': ammoModel.text.trim(),
      // Caliber follows the rifle, so the pair can never mismatch.
      'caliberMm': _parse(rifleCaliber),
      'grain': _parse(ammoGrain),
      // Box hidden (owner, 2026-10-13 23:32): no new length is written; a
      // length saved before is kept so old data is not lost.
      if (platform == WeaponPlatform.pcp && _savedLengthMm != null)
        'lengthMm': _savedLengthMm,
      'ammoType': _effectiveAmmoType!.name,
      if (_customCurve) ...{
        'bc': _curveSd,
        'bcModel': BallisticModel.g1.name,
        'dragCurve': DragCurve.toJson(_dragCurve!),
      } else ...{
        'bc': _parse(ammoBc),
        'bcModel': _bcModelForSave!.name,
        if (_bandEntries.isNotEmpty) 'bcBands': _bandEntries,
      },
      'sourceName': userCatalogSourceName,
    };
  }

  Map<String, dynamic> _scopeEntry() {
    final existing = scope;
    final lo = _parse(scopeMinMag)!, hi = _parse(scopeMaxMag)!;
    return <String, dynamic>{
      'id':
          _ownsRecord(existing?.id, userEntered: existing?.userEntered == true)
          ? existing!.id
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
      if (scopeReticle != null) 'reticle': scopeReticle,
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
        name: name.text.trim().isEmpty ? _defaultName : name.text,
        muzzleVelocityText: mps.toString(),
        zeroRangeText: _zeroMetersText,
        sightHeightText: sight.text,
        platform: platform,
        // PCP only (ProfileInput drops them on a firearm): Regülatör
        // basıncı (empty = unregulated), Tüp basıncı, basınca göre hız.
        pressureText: regulatorPressure.text,
        tubePressureText: tubePressure.text,
        pressureTable: [
          for (var i = 0; i < PcpPressure.tableRows; i++)
            (pvBar[i].text, pvFps[i].text),
        ],
        mountCantMoa: mountCant,
        // Firearms only; ProfileInput drops it on PCP.
        powderCoefText: powderCoef.text,
        powderTempText: powderTemp.text,
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
        tubePressureBar: input.tubePressureBar,
        pressureVelocityTable: input.pressureVelocityTable,
        angularUnit: angularUnit,
        distanceUnit: distanceUnit,
        mountCantMoa: input.mountCantMoa,
        powderTempCoefPercentPer15C: input.powderTempCoefPercentPer15C,
        powderTempReferenceC: input.powderTempReferenceC,
      ),
    );
  }

  /// Rebuilds the scope selects after "Listeden seç" (their initial value
  /// is read once).
  int _scopePickToken = 0;

  /// Back from typed ammunition to the list (owner, 2026-10-12): asks
  /// before the typed values go and keeps Tip, so the brand list shows the
  /// listed pellets or slugs of this Kalibre.
  Future<void> _backToAmmoList() async {
    final typed = [
      ammoBrand,
      ammoModel,
      ammoGrain,
      if (_showProfileAmmoLength) ammoLength,
      ammoBc,
    ].any((c) => c.text.trim().isNotEmpty);
    if (typed) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Listeye dönülsün mü?'),
          content: const Text('Girdiğiniz mühimmat bilgileri silinecek.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Listeye dön'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() {
      final type = ammoType;
      _clearAmmo();
      ammoType = type;
      _ammoListToken++;
    });
  }

  /// Bumped when the ammunition list is shown again, so its selects start
  /// fresh ("Seçiniz") instead of keeping "Listede yok".
  int _ammoListToken = 0;

  /// Empties the ammunition part of the form (another rifle type).
  void _clearAmmo() {
    ammo = null;
    ammoBrand.text = '';
    ammoModel.text = '';
    _ammoManual = false;
    _ammoBrandOther = false;
    _grainOther = false;
    ammoGrain.text = '';
    ammoLength.text = '';
    ammoBc.text = '';
    ammoBcModel = null;
    ammoType = null;
    _customCurve = false;
    _dragCurve = null;
    for (var i = 0; i < 2; i++) {
      ammoBandFps[i].text = '';
      ammoBandBc[i].text = '';
    }
  }

  /// Fills the ammunition from a library record (list or library screen).
  void _applyBullet(LibraryBullet b, double? cal) {
    _ammoManual = false;
    {
      ammoBrand.text = b.brand;
      ammoModel.text = b.name.toLowerCase().startsWith(b.brand.toLowerCase())
          ? b.name.substring(b.brand.length).trim()
          : b.name;
      ammoGrain.text = _trimNum(b.grain);
      // No maker BC (2026-10-12): the box stays empty for the shooter's own.
      ammoBc.text = b.bc == null ? '' : _trimNum(b.bc!);
      ammoBcModel = b.model;
      // A library bullet carries its BC; one with a published measured
      // Cd–Mach curve also fills that curve (owner, 2026-10-11). The BC
      // stays filled for a switch back to G1/G7.
      final measured = MeasuredDragLookup.forBullet(b)?.samples;
      _customCurve = measured != null;
      _dragCurve = measured;
      if (platform == WeaponPlatform.pcp) ammoType = b.type;
      for (var i = 0; i < 2; i++) {
        final band = i < b.bands.length ? b.bands[i] : null;
        ammoBandFps[i].text = band == null ? '' : band.$1.toString();
        ammoBandBc[i].text = band == null ? '' : _trimNum(band.$2);
      }
      // The ammunition's caliber follows the rifle: a bullet of another
      // caliber sets it.
      if (cal == null || (cal - b.caliberMm).abs() > 0.02) {
        rifleCaliber.text = _trimDot(b.caliberMm);
        _cartridge = null;
      }
    }
  }

  /// PCP: no listed pellet or slug for this Kalibre and Tip.
  bool get _noPcpForCaliber =>
      platform == WeaponPlatform.pcp &&
      _parse(rifleCaliber) != null &&
      _libraryHere.isEmpty;

  /// Library records for this rifle type and caliber (Marka/Model lists).
  List<LibraryBullet> get _libraryHere {
    final cal = _parse(rifleCaliber);
    return [
      for (final b in BulletLibrary.all)
        if (b.platform == platform &&
            (cal == null || (b.caliberMm - cal).abs() < 0.02) &&
            (platform != WeaponPlatform.pcp ||
                ammoType == null ||
                b.type == ammoType))
          b,
    ];
  }

  /// Firearm ammunition: true = Fabrika fişeği (Marka/Model fill weight,
  /// BC and velocity), false = El dolumu (the bullet library; the shooter
  /// types the chronograph velocity). Owner, 2026-10-11.
  bool _factoryAmmo = true;

  /// Factory cartridges for the chosen Kalibre: the cartridge name when it
  /// is known, else the bullet diameter.
  List<FactoryAmmo> get _factoryHere {
    final cal = _parse(rifleCaliber);
    final c = _cartridge;
    // No Kalibre yet: every factory round, as El dolumu lists every bullet
    // (owner, 2026-10-11: Fabrika fişeği came up empty). Picking one fills
    // the Kalibre.
    return [
      for (final a in FactoryAmmoLibrary.all)
        if (c != null
            ? a.cartridge == c
            : cal == null || (a.diameterMm - cal).abs() < 0.02)
          a,
    ];
  }

  /// Fabrika fişeği with a Kalibre that has no listed round.
  bool get _noFactoryForCaliber =>
      platform == WeaponPlatform.firearm &&
      _factoryAmmo &&
      _parse(rifleCaliber) != null &&
      _factoryHere.isEmpty;

  static String _factoryLabel(FactoryAmmo a) {
    final g = _trimDot(a.grain);
    return a.name.contains('$g gr') ? a.name : '${a.name} · $g gr';
  }

  /// The manufacturer note of the listed factory round now in the form
  /// (e.g. "BC G1/G7 etiketi olmadan verilmiş; G1 kabul edildi…"), added to
  /// the BC ⓘ (owner, 2026-10-11: "bilgi notu olacak"); for a round whose BC
  /// is the NATO standard bullet's, first how that BC was taken (2026-10-12).
  String get _factoryBcNote {
    for (final a in _factoryHere) {
      if (a.brand != ammoBrand.text || a.name != ammoModel.text) continue;
      var nato = '';
      if (a.bcSource == 'nato-standard') {
        final t = ProfileFieldInfo.bcNatoStandard(
          brand: a.brand,
          standard: a.bcStandard!,
          report: a.bcReport!,
          probable: a.bcProbable,
        );
        nato = '\n\n$t';
      }
      final note = a.note == null ? '' : '\n\nBu fişek: ${a.note}';
      // A listed factory round whose maker publishes no BC (2026-10-14).
      final noBc =
          a.bc == null && platform == WeaponPlatform.firearm && _factoryAmmo
          ? '\n\nBu fişek: Üretici BC yayımlamıyor. Kendi atışlarınızdan '
                'bulduğunuz BC\'yi girin; BC modelini de seçin.'
          : '';
      if (nato.isNotEmpty || note.isNotEmpty || noBc.isNotEmpty) {
        return nato + note + noBc;
      }
    }
    // A listed bullet / pellet whose maker publishes no BC (2026-10-12).
    if (!(platform == WeaponPlatform.firearm && _factoryAmmo)) {
      for (final b in _libraryHere) {
        if (b.bc == null &&
            b.brand == ammoBrand.text &&
            _modelOf(b) == ammoModel.text) {
          return '\n\nBu mermi: Üretici BC yayımlamıyor. Kendi atışlarınızdan '
              'bulduğunuz BC\'yi girin.';
        }
      }
    }
    return '';
  }

  /// Fills the ammunition (and the velocity) from a factory cartridge.
  void _applyFactory(FactoryAmmo a) {
    _ammoSourceSet = true; // a listed factory round: Fabrika fişeği
    // Kalibre not chosen yet: the round tells it.
    if (_cartridge == null && rifleCaliber.text.trim().isEmpty) {
      _cartridge = a.cartridge;
      rifleCaliber.text = _trimDot(a.diameterMm);
    }
    _ammoManual = false;
    ammoBrand.text = a.brand;
    ammoModel.text = a.name;
    ammoGrain.text = _trimNum(a.grain);
    ammoBc.text = a.bc == null ? '' : _trimNum(a.bc!);
    ammoBcModel = a.model;
    _customCurve = false;
    _dragCurve = null;
    for (var i = 0; i < 2; i++) {
      ammoBandFps[i].text = '';
      ammoBandBc[i].text = '';
    }
    velocity.text = _trimNum(a.muzzleVelocityFps);
    // Barut sıcaklığı: the maker's figure when it publishes one; otherwise
    // only a previous automatic fill goes (typed values stay).
    final pt = FactoryPowderTempLibrary.lookup(a.brand, a.name);
    if (pt != null) {
      powderCoef.text = _trimNum(pt.coefPercentPer15C);
      powderTemp.text = _trimNum(pt.referenceTempC);
      _powderAutoFilled = true;
    } else if (_powderAutoFilled) {
      powderCoef.text = '';
      powderTemp.text = '';
      _powderAutoFilled = false;
    }
  }

  static String _modelOf(LibraryBullet b) =>
      b.name.toLowerCase().startsWith(b.brand.toLowerCase())
      ? b.name.substring(b.brand.length).trim()
      : b.name;

  static const _manualKey = '__manual';

  /// PCP Marka | Model lists, hidden (owner, 2026-10-13: "Pellet marka
  /// bullet marka almanın hiç bir faydası yok"; hidden, not removed). PCP
  /// asks only Tip, Ağırlık and BC.
  static const bool _showPcpAmmoBrand = bool.fromEnvironment('PCP_AMMO_BRAND');

  /// PCP Mühimmat "Uzunluk", hidden (owner, 2026-10-13 23:32: "Profilden
  /// çıkartın"; hidden, not removed). The length is asked only in Pro >
  /// Mermi uzunluğu, so one value never lives in two places.
  static const bool _showProfileAmmoLength = bool.fromEnvironment(
    'PROFILE_AMMO_LENGTH',
  );

  /// Marka | Model of the ammunition: two lists side by side (factory
  /// cartridges or the bullet library for this caliber); the typed boxes
  /// only after "Listede yok" or when nothing is listed here.
  List<Widget> _ammoNameFields({
    required Widget type,
    required Widget brandText,
    required Widget modelText,
  }) {
    final firearm = platform == WeaponPlatform.firearm;
    // PCP rows (owner, 2026-10-14: BC | BC modeli): Tip | Ağırlık, BC |
    // BC modeli; with Uzunluk, Tip takes its row and Ağırlık | Uzunluk.
    if (!firearm && !_showPcpAmmoBrand) {
      return [_showProfileAmmoLength ? MenzilFullWidth(child: type) : type];
    }
    // PCP: Marka | Tip; firearm: Mühimmat türü | Marka. Model gets a row.
    List<Widget> arrange(Widget brand, Widget model) => [
      if (firearm) ...[type, brand] else ...[brand, type],
      MenzilFullWidth(child: model),
    ];
    final factory = platform == WeaponPlatform.firearm && _factoryAmmo;
    final fHere = factory ? _factoryHere : const <FactoryAmmo>[];
    final lHere = factory ? const <LibraryBullet>[] : _libraryHere;
    // Without a Kalibre the factory list shows every round (picking one
    // fills the Kalibre), so it is never treated as empty.
    final noCaliber = factory && _parse(rifleCaliber) == null;
    final empty = !noCaliber && (factory ? fHere.isEmpty : lHere.isEmpty);
    if (firearm && (_ammoManual || empty)) {
      // Typed firearm round (owner, 2026-10-14): Marka from the list of
      // every known brand ("Diğer" types it), Model typed.
      final brandPick = KeyedSubtree(
        key: const Key('ammo-brand-pick'),
        child: MenzilSelect<String>(
          key: ValueKey(
            'ammo-brand-pick-$_ammoBrandOther-${_ammoBrandOther ? '' : ammoBrand.text}',
          ),
          label: 'Marka',
          hint: 'Seçiniz',
          info: empty
              ? '${ProfileFieldInfo.ammoBrandPick}\n\n'
                    '${ProfileFieldInfo.ammoNothingListed}'
              : ProfileFieldInfo.ammoBrandPick,
          initialValue: _ammoBrandOther
              ? _otherKey
              : (_allFirearmAmmoBrands.contains(ammoBrand.text)
                    ? ammoBrand.text
                    : null),
          items: [
            for (final b in _allFirearmAmmoBrands)
              DropdownMenuItem(value: b, child: Text(b)),
            const DropdownMenuItem(value: _otherKey, child: Text('Diğer')),
          ],
          errorText: _ammoBrandOther
              ? null
              : _shownSelect(_ammoBrandError, ammoBrand),
          onChanged: (v) => setState(() {
            if (v == null) return;
            final other = v == _otherKey;
            if (other && _ammoBrandOther) return;
            _ammoBrandOther = other;
            ammoBrand.text = other ? '' : v;
          }),
        ),
      );
      return [
        type,
        brandPick,
        if (_ammoBrandOther) ...[
          brandText,
          modelText,
        ] else
          MenzilFullWidth(child: modelText),
        if (!empty)
          MenzilFullWidth(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('ammo-back-to-list'),
                onPressed: _backToAmmoList,
                icon: const Icon(Icons.list_alt, size: 18),
                label: const Text('Listeye dön'),
              ),
            ),
          ),
      ];
    }
    if (_ammoManual || empty) {
      return [
        ...arrange(brandText, modelText),
        if (!empty)
          MenzilFullWidth(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('ammo-back-to-list'),
                onPressed: _backToAmmoList,
                icon: const Icon(Icons.list_alt, size: 18),
                // "Listeden seç" read like a model list for a brand that is
                // not listed (owner, 2026-10-12).
                label: const Text('Listeye dön'),
              ),
            ),
          ),
      ];
    }
    final brands = {
      if (factory)
        for (final a in fHere) a.brand
      else
        for (final b in lHere) b.brand,
    }.toList()..sort(_byName);
    final brand = brands.contains(ammoBrand.text) ? ammoBrand.text : null;
    final labels = <String>[];
    final picks = <void Function()>[];
    var modelIndex = -1;
    if (factory) {
      for (final a in fHere) {
        if (a.brand != brand) continue;
        if (a.name == ammoModel.text && _parse(ammoGrain) == a.grain) {
          modelIndex = labels.length;
        }
        labels.add(_factoryLabel(a));
        picks.add(() => _applyFactory(a));
      }
    } else {
      for (final b in lHere) {
        if (b.brand != brand) continue;
        if (_modelOf(b) == ammoModel.text && _parse(ammoGrain) == b.grain) {
          modelIndex = labels.length;
        }
        final m = _modelOf(b);
        final g = '${_trimDot(b.grain)} gr';
        labels.add(m.contains(g) ? m : '$m · $g');
        picks.add(() => _applyBullet(b, _parse(rifleCaliber)));
      }
    }
    final brandSelect = KeyedSubtree(
      key: const Key('ammo-brand-select'),
      child: MenzilSelect<String>(
        key: ValueKey(
          'ammo-brand-select-${platform.name}-$factory-'
          '${rifleCaliber.text}-$brand-$_ammoListToken',
        ),
        label: 'Marka',
        hint: 'Seçiniz',
        initialValue: brand,
        items: [
          for (final b in brands) DropdownMenuItem(value: b, child: Text(b)),
          // Firearm: hidden behind AMMO_LISTEDE_YOK (owner, 2026-10-14);
          // the link under Model opens the typed entry.
          if (!firearm || _showAmmoListedeYok)
            const DropdownMenuItem(
              value: _manualKey,
              child: Text('Listede yok'),
            ),
        ],
        onChanged: (v) => setState(() {
          if (v == _manualKey) {
            _clearAmmo();
            _ammoManual = true;
            return;
          }
          ammoBrand.text = v ?? '';
          ammoModel.text = '';
        }),
      ),
    );
    final modelSelect = KeyedSubtree(
      key: const Key('ammo-model-select'),
      child: MenzilSelect<int>(
        key: ValueKey(
          'ammo-model-select-$factory-$brand-${rifleCaliber.text}-$modelIndex',
        ),
        label: 'Model',
        hint: 'Seçiniz',
        initialValue: modelIndex < 0 ? null : modelIndex,
        items: [
          for (final (k, text) in labels.indexed)
            DropdownMenuItem(value: k, child: Text(text, maxLines: 2)),
        ],
        onChanged: (k) {
          if (k == null) return;
          setState(picks[k]);
        },
      ),
    );
    return [
      ...arrange(brandSelect, modelSelect),
      // Owner, 2026-10-14: like the scope's link (#269), the typed firearm
      // round opens from here instead of a "Listede yok" item.
      if (firearm)
        MenzilFullWidth(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('ammo-not-listed'),
              onPressed: () => setState(_openAmmoManual),
              child: const Text('Aradığın mühimmat listede yok mu?'),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
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
                MenzilFullWidth(
                  child: MenzilInput(
                    key: const Key('profile-name'),
                    controller: name,
                    focusNode: _nameFocus,
                    label: 'Profil adı',
                    keyboardType: TextInputType.text,
                    maxLength: ProductionLimits.maxProfileNameLength,
                  ),
                ),
                MenzilSelect<WeaponPlatform>(
                  key: const Key('profile-platform'),
                  label: 'Tür',
                  info: ProfileFieldInfo.platform,
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
                    final changed = v != platform;
                    platform = v!;
                    // Pellet/slug only exist on PCP; firearms use bullets.
                    if (platform == WeaponPlatform.firearm) ammoType = null;
                    // The ammunition belongs to the rifle type: an H&N slug
                    // must not stay in a firearm profile (owner,
                    // 2026-10-11). A rifle of the other type goes too.
                    if (changed) {
                      _clearAmmo();
                      _factoryAmmo = true;
                      // A rifle picked from the other type's lists goes.
                      if ((rifle != null && rifle!.platform != platform) ||
                          !_rifleManual) {
                        rifle = null;
                        rifleBrand.text = '';
                        rifleModel.text = '';
                      }
                      _rifleVariant = null;
                      _caliberAll = false;
                      _caliberByDiameter = false;
                    }
                    // A caliber of the other list does not carry over.
                    final cal = _parse(rifleCaliber);
                    if (cal != null && _caliberItem(cal) == null) {
                      rifleCaliber.text = '';
                    }
                    _cartridge = null;
                  }),
                ),
                KeyedSubtree(
                  key: const Key('rifle-origin'),
                  child: MenzilSelect<bool?>(
                    key: ValueKey('rifle-origin-$_domestic'),
                    info: ProfileFieldInfo.rifleOrigin,
                    label: 'Üretim',
                    initialValue: _domestic,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tümü')),
                      DropdownMenuItem(value: true, child: Text('Yerli')),
                      DropdownMenuItem(value: false, child: Text('İthal')),
                    ],
                    onChanged: (v) => setState(() {
                      _domestic = v;
                      // A listed rifle of the other origin goes.
                      if (!_rifleManual &&
                          rifleBrand.text.isNotEmpty &&
                          !_rifleBrands.contains(rifleBrand.text)) {
                        final before = (rifleCaliber.text, _cartridge);
                        rifleBrand.text = '';
                        rifleModel.text = '';
                        _clearRifleChoice();
                        _keepAmmoInCaliber(before);
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
          const MenzilSectionHeader(
            'Tüfek',
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
                // Owner, 2026-10-11: Marka, Model and Kalibre are picked
                // from lists. Order (owner, 2026-10-14 18:56–18:58): Marka,
                // Model, Kalibre each alone on a full row; then Yiv oranı |
                // Namlu yiv yönü, Sight height | Mesafe birimi, Sıfırlama
                // mesafesi | Namlu çıkış hızı.
                ..._rifleNameFields(),
                _caliberField(),
                if (platform == WeaponPlatform.firearm && _caliberByDiameter)
                  MenzilFullWidth(
                    child: KeyedSubtree(
                      key: const Key('rifle-bullet-diameter'),
                      child: MenzilSelect<double>(
                        key: ValueKey('rifle-diameter-${rifleCaliber.text}'),
                        info: ProfileFieldInfo.bulletDiameter,
                        label: 'Mermi çapı',
                        hint: 'Seçiniz',
                        initialValue: _bulletDiameters
                            .where(
                              (d) =>
                                  (d - (_parse(rifleCaliber) ?? -1)).abs() <
                                  0.005,
                            )
                            .firstOrNull,
                        items: [
                          for (final d in _bulletDiameters)
                            DropdownMenuItem(
                              value: d,
                              child: Text(_diameterLabel(d)),
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          final before = (rifleCaliber.text, _cartridge);
                          if (v != null) rifleCaliber.text = _trimDot(v);
                          _keepAmmoInCaliber(before);
                        }),
                      ),
                    ),
                  ),
                MenzilInput(
                  key: const Key('rifle-twist-rate'),
                  info: ProfileFieldInfo.twistRate,
                  controller: rifleTwist,
                  label: 'Yiv oranı',
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_twistError, rifleTwist),
                ),
                KeyedSubtree(
                  key: const Key('rifle-twist-direction'),
                  child: MenzilSelect<TwistDirection>(
                    // Rebuilt when a listed rifle fills the direction.
                    key: ValueKey('rifle-twist-direction-$twistDirection'),
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
                ),
                if (_showErrors && twistDirection == null)
                  const MenzilFullWidth(
                    child: MenzilNotice(
                      tone: MenzilNoticeTone.danger,
                      message: 'Namlu yiv yönünü seçin (Sağ / Sol).',
                    ),
                  ),
                MenzilInput(
                  key: const Key('scope-sight-height'),
                  info: platform == WeaponPlatform.firearm
                      ? ProfileFieldInfo.sightHeightFirearm
                      : ProfileFieldInfo.sightHeight,
                  controller: sight,
                  label: 'Sight height',
                  onChanged: (_) => setState(() {}),
                  errorText: sight.text.isNotEmpty && !_validSight
                      ? '0–300 mm arasında geçerli bir değer girin.'
                      : null,
                ),
                MenzilSelect<DistanceUnit>(
                  key: const Key('profile-distance-unit'),
                  info: ProfileFieldInfo.distanceUnit,
                  label: 'Mesafe birimi',
                  initialValue: _distanceUnitSet ? distanceUnit : null,
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
                    _distanceUnitSet = v != null;
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
                  info: platform == WeaponPlatform.firearm
                      ? ProfileFieldInfo.zeroFirearm
                      : ProfileFieldInfo.zero,
                  onChanged: (_) => setState(() {}),
                  errorText: _shown(_zeroError, zero),
                ),
                _velocityField(),
              ],
            ),
          ),
          const MenzilSectionHeader(
            'Dürbün',
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
                // Owner, 2026-10-11: Marka, then the models of that brand,
                // then only that model's reticles.
                ..._scopeNameFields(),
                // Owner, 2026-10-11: picked from standard values, not
                // typed; Minimum | Maksimum side by side.
                if (_scopeMinMagShown)
                  _numberSelect(
                    key: 'scope-min-mag',
                    label: 'Minimum büyütme',
                    info: ProfileFieldInfo.minMag,
                    controller: scopeMinMag,
                    options: _minMagOptions,
                    suffix: 'x',
                    errorText: _shownSelect(_minMagError),
                  ),
                if (_scopeMaxMagShown)
                  _numberSelect(
                    key: 'scope-max-mag',
                    label: 'Maksimum büyütme',
                    info: ProfileFieldInfo.maxMag,
                    controller: scopeMaxMag,
                    options: _maxMagOptions,
                    suffix: 'x',
                    errorText: _shownSelect(_maxMagError, scopeMaxMag),
                  ),
                if (_scopeObjectiveShown)
                  _numberSelect(
                    key: 'scope-objective',
                    label: 'Mercek çapı',
                    info: ProfileFieldInfo.objective,
                    controller: scopeObjective,
                    options: _objectiveOptions,
                    suffix: ' mm',
                    errorText: _shownSelect(_objectiveError),
                  ),
                if (_scopeFocalShown)
                  KeyedSubtree(
                    key: const Key('scope-focal-plane'),
                    child: MenzilSelect<bool>(
                      key: ValueKey('scope-focal-plane-$_scopePickToken'),
                      info: ProfileFieldInfo.focalPlane,
                      label: 'Odak düzlemi',
                      initialValue: firstFocalPlane,
                      items: const [
                        DropdownMenuItem(value: true, child: Text('FFP')),
                        DropdownMenuItem(value: false, child: Text('SFP')),
                      ],
                      onChanged: (v) => setState(() => firstFocalPlane = v),
                    ),
                  ),
                if (_scopeUnitShown)
                  KeyedSubtree(
                    key: const Key('scope-unit'),
                    child: MenzilSelect<AngularUnit>(
                      key: ValueKey(
                        'profile-angular-unit-${angularUnit.name}'
                        '${_scopePickToken == 0 ? '' : '-$_scopePickToken'}',
                      ),
                      info: ProfileFieldInfo.scopeUnit,
                      label: 'Dürbün birimi',
                      initialValue: _angularUnitSet ? angularUnit : null,
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
                        _angularUnitSet = v != null;
                        final next = v ?? AngularUnit.mrad;
                        // A catalog scope's click follows the unit (0.1 MRAD,
                        // 1/4 MOA; owner, 2026-10-09).
                        if (_scopeManual) {
                          // A typed scope picks its Klik değeri from the
                          // new unit's list; one that does not fit is cleared.
                          final click = _parse(scopeClick);
                          if (!_clickOptions(next).any((o) => o.$1 == click)) {
                            scopeClick.clear();
                          }
                        } else if (next != angularUnit) {
                          scopeClick.text = _trimNum(_defaultClick(next));
                        }
                        angularUnit = next;
                      }),
                    ),
                  ),
                // Typed scope: Dürbün birimi | Klik değeri side by side.
                if (_scopeManual || _scopeBrands.isEmpty) _clickSelect(),
                KeyedSubtree(
                  key: const Key('scope-mount'),
                  child: MenzilSelect<double>(
                    // Rebuilt when the click value/unit changes so every
                    // choice shows its ready click gain.
                    key: ValueKey(
                      'scope-mount-cant-${angularUnit.name}-${scopeClick.text}',
                    ),
                    info: ProfileFieldInfo.mountCant,
                    label: 'Dürbün ayağı',
                    initialValue: _mountCantSet ? mountCant : null,
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
                    onChanged: (v) => setState(() {
                      _mountCantSet = v != null;
                      mountCant = v ?? 0;
                    }),
                  ),
                ),
                MenzilInput(
                  key: const Key('scope-travel-elevation'),
                  info: ProfileFieldInfo.elevationTravel,
                  controller: scopeTravelElevation,
                  label: 'Üst kule klik sayısı',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  errorText: _travelError(scopeTravelElevation),
                ),
                MenzilFullWidth(
                  child: KeyedSubtree(
                    key: const Key('scope-reticle'),
                    child: Builder(
                      builder: (context) {
                        final choices = _scopeManual
                            ? const <(String, ScopeOptic)>[]
                            : _scopeReticleChoices;
                        if (choices.isNotEmpty) {
                          return MenzilSelect<String>(
                            key: ValueKey(
                              'scope-reticle-$_scopePickToken-$_scopeModelKey',
                            ),
                            info: ProfileFieldInfo.reticle,
                            label: 'Retikül',
                            hint: 'Seçiniz',
                            initialValue:
                                choices.any((e) => e.$1 == scopeReticle)
                                ? scopeReticle
                                : null,
                            items: [
                              for (final (r, _) in choices)
                                DropdownMenuItem(value: r, child: Text(r)),
                            ],
                            onChanged: (v) => setState(() {
                              final hit = choices
                                  .where((e) => e.$1 == v)
                                  .firstOrNull;
                              if (hit != null) {
                                _applyScope(hit.$2, reticle: hit.$1);
                              }
                            }),
                          );
                        }
                        return MenzilSelect<String>(
                          key: ValueKey('scope-reticle-$_scopePickToken'),
                          info: ProfileFieldInfo.reticle,
                          label: 'Retikül',
                          initialValue: scopeReticle,
                          items: [
                            if (scopeReticle != null &&
                                !Reticles.genericNames.contains(scopeReticle))
                              DropdownMenuItem(
                                value: scopeReticle,
                                child: Text(scopeReticle!),
                              ),
                            // The manufacturer names no reticle: only the
                            // plain patterns of the scope's unit (owner,
                            // 2026-10-11: a MRAD scope listed MOA too).
                            for (final n in Reticles.genericNames)
                              if (_genericFitsUnit(n) || n == scopeReticle)
                                DropdownMenuItem(value: n, child: Text(n)),
                          ],
                          onChanged: (v) => setState(() => scopeReticle = v),
                        );
                      },
                    ),
                  ),
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
                // Owner, 2026-10-13: the typed entry opens from this link
                // instead of a "Listede yok" item in the Marka list.
                if (_scopeFromList)
                  MenzilFullWidth(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const Key('scope-not-listed'),
                        onPressed: () => setState(_openScopeManual),
                        child: const Text('Aradığın dürbün listede yok mu?'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const MenzilSectionHeader(
            'Mühimmat',
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
                // Owner, 2026-10-11: firearm Mühimmat türü | Marka, Model on
                // its own row; PCP Tip only (Marka | Tip with PCP_AMMO_BRAND);
                // then Ağırlık | BC; BC modeli. Namlu çıkış hızı is on the
                // Tüfek card since 2026-10-13.
                ..._ammoNameFields(
                  type: platform == WeaponPlatform.firearm
                      ? KeyedSubtree(
                          key: const Key('ammo-source'),
                          child: MenzilSelect<bool>(
                            key: ValueKey('ammo-source-$_factoryAmmo'),
                            info: ProfileFieldInfo.ammoSource,
                            label: 'Mühimmat türü',
                            initialValue: _ammoSourceSet ? _factoryAmmo : null,
                            items: const [
                              DropdownMenuItem(
                                value: true,
                                child: Text('Fabrika fişeği'),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text('El dolumu'),
                              ),
                            ],
                            onChanged: (v) => setState(() {
                              if (v == null) return;
                              final was = _ammoSourceSet;
                              _ammoSourceSet = true;
                              if (was && v == _factoryAmmo) return;
                              _factoryAmmo = v;
                              _clearAmmo();
                            }),
                          ),
                        )
                      : KeyedSubtree(
                          key: const Key('ammo-type'),
                          child: MenzilSelect<AmmunitionType>(
                            key: ValueKey('ammo-type-$ammoType'),
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
                            onChanged: (v) => setState(() {
                              if (v == ammoType) return;
                              // A listed model of the other type goes; the
                              // brand stays.
                              if (!_ammoManual && ammoModel.text.isNotEmpty) {
                                final brand = ammoBrand.text;
                                _clearAmmo();
                                ammoBrand.text = brand;
                              }
                              ammoType = v;
                            }),
                          ),
                        ),
                  brandText: MenzilInput(
                    key: const Key('ammo-brand'),
                    controller: ammoBrand,
                    label: 'Marka',
                    // The list has no factory round for this Kalibre: say so
                    // instead of a silently typed box (owner, 2026-10-11).
                    info: _typedFirearmAmmo
                        ? ProfileFieldInfo.ammoBrandOther
                        : _noFactoryForCaliber
                        ? 'Bu kalibre için listede henüz fabrika fişeği yok. '
                              'Fişeğin markasını ve modelini kutunun üstünden '
                              'okuyup yazın; ağırlık, BC ve hız kutuda veya '
                              'üreticinin sitesinde yazar. Kendi doldurduğunuz '
                              'fişekse Mühimmat türünde El dolumu seçin.'
                        : _noPcpForCaliber
                        // Owner, 2026-10-12: the empty list must say why.
                        ? 'Bu kalibre ve tipte listede henüz ürün yok. '
                              'Markayı ve modeli kutunun üstünden okuyup '
                              'yazın. BC bilinmiyorsa boş bırakabilirsiniz.'
                        : null,
                    keyboardType: TextInputType.text,
                    maxLength: 60,
                    onChanged: (_) => setState(() {}),
                    errorText: _shown(_ammoBrandError, ammoBrand),
                  ),
                  modelText: MenzilInput(
                    key: const Key('ammo-model'),
                    controller: ammoModel,
                    label: 'Model',
                    info: _typedFirearmAmmo
                        ? ProfileFieldInfo.ammoModelTyped
                        : null,
                    keyboardType: TextInputType.text,
                    maxLength: 80,
                    onChanged: (_) => setState(() {}),
                    errorText: _shown(_ammoModelError, ammoModel),
                  ),
                ),
                if (_typedFirearmAmmo)
                  ..._typedGrainFields()
                else
                  MenzilInput(
                    key: const Key('ammo-grain'),
                    info: platform == WeaponPlatform.firearm
                        ? ProfileFieldInfo.grainFirearm
                        : ProfileFieldInfo.grain,
                    controller: ammoGrain,
                    focusNode: _grainFocus,
                    label: 'Ağırlık',
                    onChanged: (_) => setState(() {}),
                    errorText: _shown(_grainError, ammoGrain),
                  ),
                // Uzunluk | BC on PCP (owner, 2026-10-13); hidden behind
                // PROFILE_AMMO_LENGTH (owner, 2026-10-13 23:32).
                if (platform == WeaponPlatform.pcp && _showProfileAmmoLength)
                  MenzilInput(
                    key: const Key('ammo-length'),
                    controller: ammoLength,
                    label: 'Uzunluk',
                    unit: 'mm',
                    info: ProfileFieldInfo.ammoLength,
                    onChanged: (_) => setState(() {}),
                    errorText: _shown(_lengthError, ammoLength),
                  ),
                if (!_customCurve)
                  MenzilInput(
                    key: const Key('ammo-bc'),
                    info:
                        (platform == WeaponPlatform.firearm
                            ? ProfileFieldInfo.bcFirearm
                            : ProfileFieldInfo.bc) +
                        _factoryBcNote,
                    controller: ammoBc,
                    label: 'BC',
                    // A typed BC picks G1 when no model is chosen yet
                    // (owner, 2026-10-13); G7 or others stay selectable.
                    onChanged: (v) => setState(() {
                      // Typed firearm round: BC modeli is chosen on
                      // purpose (owner, 2026-10-14: starts "Seçiniz").
                      if (platform == WeaponPlatform.firearm &&
                          !_typedFirearmAmmo &&
                          !_customCurve &&
                          ammoBcModel == null &&
                          v.trim().isNotEmpty) {
                        ammoBcModel = BallisticModel.g1;
                      }
                    }),
                    errorText: _shown(_bcError, ammoBc),
                  ),
                // Firearm: the warning under BC as before; PCP: under BC |
                // BC modeli so the two stay on one row (owner, 2026-10-14).
                if (_bcPlausibilityWarning != null &&
                    platform != WeaponPlatform.pcp)
                  _bcWarningNotice,
                KeyedSubtree(
                  key: const Key('ammo-bc-model'),
                  child: MenzilSelect<String>(
                    key: ValueKey(
                      'ammo-bc-model-${_customCurve ? _customKey : ammoBcModel?.name}',
                    ),
                    info: platform == WeaponPlatform.firearm
                        ? ProfileFieldInfo.bcModelWithCustom
                        : ProfileFieldInfo.bcModel,
                    label: 'BC modeli',
                    hint: 'Seçiniz',
                    // PCP starts on G1 (owner, 2026-10-14: "G1 seçili
                    // kalsın"); a firearm starts on "Seçiniz" as before.
                    initialValue: _customCurve
                        ? _customKey
                        : platform == WeaponPlatform.pcp
                        ? _bcModelForSave!.name
                        : ammoBcModel?.name,
                    items: _typedFirearmAmmo
                        ? _typedBcModelItems
                        : [
                            for (final (m, text) in _bcModelChoices)
                              DropdownMenuItem(
                                value: m.name,
                                child: Text(text),
                              ),
                            if (platform == WeaponPlatform.firearm)
                              const DropdownMenuItem(
                                value: _customKey,
                                child: Text('Özel eğri (Mach–Cd)'),
                              )
                            else if (_customCurve)
                              const DropdownMenuItem(
                                value: _customKey,
                                child: Text('Özel eğri (kayıtlı)'),
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
                ),
                if (_bcPlausibilityWarning != null &&
                    platform == WeaponPlatform.pcp)
                  _bcWarningNotice,
                // PCP tüp ve regülatör basıncı (owner, 2026-10-12): never on
                // a firearm. Tüp | Regülatör on one row, then the optional
                // basınca göre hız rows (Basınç | Hız).
                if (platform == WeaponPlatform.pcp) ..._pcpPressureFields(c),
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
                // Ek mühimmat bilgileri (owner, 2026-10-14 18:07–18:20): the
                // optional powder and BC-band fields as their own always-open
                // sub-section at the end of Mühimmat; fields, keys, checks
                // and saving unchanged.
                if (_ammoExtraShown) _ammoExtraHeader(c),
                // Barut sıcaklığı: firearms only, never on PCP (owner,
                // 2026-10-11). Katsayı | Ölçüm sıcaklığı side by side.
                // Own row pair, so BC modeli above keeps its place (2026-10-13).
                if (platform == WeaponPlatform.firearm)
                  MenzilFullWidth(
                    child: MenzilFieldGrid(
                      children: [
                        // Lists, also for listed rounds (owner,
                        // 2026-10-14); empty = no temperature correction.
                        _powderSelect(
                          key: 'profile-powder-coef',
                          controller: powderCoef,
                          // Short label: "Barut sıcaklık katsayısı" next to
                          // its unit and ⓘ was cut ("…") on 375–393 pt
                          // phones; the ⓘ text starts with the full name.
                          // No unit beside it (owner, 2026-10-14): "%/15 °C"
                          // is in the ⓘ; the label stays on one line.
                          label: 'Barut katsayısı',
                          info: ProfileFieldInfo.powderCoef,
                          options: _powderCoefOptions,
                          error: _powderCoefError,
                        ),
                        _powderSelect(
                          key: 'profile-powder-temp',
                          controller: powderTemp,
                          label: 'Hız ölçüm sıcaklığı',
                          unit: '°C',
                          info: ProfileFieldInfo.powderTemp,
                          options: _powderTempOptions,
                          error: _powderTempError,
                        ),
                      ],
                    ),
                  ),
                // Hıza göre BC: hidden on PCP (owner, 2026-10-13: only Tip,
                // Ağırlık, BC).
                // Typed firearm round: hidden behind AMMO_BC_BANDS_TYPED
                // (owner, 2026-10-14); saved bands stay in the record.
                if (!_customCurve &&
                    platform != WeaponPlatform.pcp &&
                    (!_typedFirearmAmmo || _showTypedBands)) ...[
                  MenzilFullWidth(
                    child: Text(
                      'Hıza göre BC',
                      key: const Key('ammo-bands-title'),
                      style: MenzilType.body(c.ink),
                    ),
                  ),
                  for (var i = 0; i < 2; i++) ...[
                    MenzilInput(
                      key: Key('ammo-band-fps-$i'),
                      info: platform == WeaponPlatform.firearm
                          ? ProfileFieldInfo.bandSpeedFirearm
                          : ProfileFieldInfo.bandSpeed,
                      controller: ammoBandFps[i],
                      label: '${i + 1}. eşik hızı',
                      onChanged: (_) => setState(() {}),
                      errorText: _shown(_bandFpsError(i), ammoBandFps[i]),
                    ),
                    MenzilInput(
                      key: Key('ammo-band-bc-$i'),
                      info: ProfileFieldInfo.bandBc,
                      controller: ammoBandBc[i],
                      label: 'Eşik altı BC',
                      onChanged: (_) => setState(() {}),
                      errorText: _shown(_bandBcError(i), ammoBandBc[i]),
                    ),
                  ],
                ],
                if (_showErrors &&
                    ((!_customCurve && _bcModelForSave == null) ||
                        _effectiveAmmoType == null))
                  const MenzilFullWidth(
                    child: MenzilNotice(
                      tone: MenzilNoticeTone.danger,
                      message: 'Mühimmat tipini ve BC modelini (G1/G7) seçin.',
                    ),
                  ),
                // Read-only check line above Kaydet (owner, 2026-10-14).
                if (_typedAmmoSummary != null)
                  MenzilFullWidth(
                    child: MenzilCard(
                      key: const Key('ammo-typed-summary'),
                      padding: const EdgeInsets.all(MenzilSpace.md),
                      child: Text(
                        _typedAmmoSummary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: MenzilType.body(c.ink),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ek mühimmat bilgileri has something to show: Barut katsayısı | Hız
  /// ölçüm sıcaklığı (firearms) or the Hıza göre BC rows (same conditions
  /// as before the move).
  bool get _ammoExtraShown =>
      platform == WeaponPlatform.firearm ||
      (!_customCurve &&
          platform != WeaponPlatform.pcp &&
          (!_typedFirearmAmmo || _showTypedBands));

  /// "Ek mühimmat bilgileri  isteğe bağlı ⓘ", left-aligned and always open
  /// (owner, 2026-10-14 18:07–18:20): no chevron, one ⓘ with the long
  /// "Nedir? / Neden önemli?" text.
  Widget _ammoExtraHeader(MenzilColors c) => MenzilFullWidth(
    child: Padding(
      key: const Key('ammo-extra-header'),
      padding: const EdgeInsets.only(top: MenzilSpace.sm),
      child: Row(
        children: [
          Flexible(
            child: Semantics(
              header: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Ek mühimmat bilgileri',
                      style: MenzilType.heading(c.ink, size: 17),
                    ),
                    const TextSpan(text: '  '),
                    TextSpan(
                      text: 'isteğe bağlı',
                      style: MenzilType.caption(c.ink2),
                    ),
                  ],
                ),
                key: const Key('ammo-extra-title'),
                textAlign: TextAlign.start,
              ),
            ),
          ),
          const MenzilInfoButton(
            key: Key('ammo-extra-info'),
            title: 'Ek mühimmat bilgileri',
            text: ProfileFieldInfo.ammoExtra,
          ),
        ],
      ),
    ),
  );

  /// Typed firearm Ağırlık (owner, 2026-10-14): the maker weights of this
  /// Kalibre as "168 gr (10,9 g)"; "Listede yok" adds a typed grain box
  /// under it that shows the grams and accepts only a plausible weight.
  /// Without a Kalibre only a notice (no free typing).
  List<Widget> _typedGrainFields() {
    final cal = _parse(rifleCaliber);
    if (cal == null) {
      return const [
        MenzilFullWidth(
          child: MenzilNotice(
            key: Key('ammo-grain-need-caliber'),
            tone: MenzilNoticeTone.info,
            message:
                'Ağırlık listesi kalibreye göre gelir. Önce Tüfek bölümünde '
                'Kalibre seçin.',
          ),
        ),
      ];
    }
    final weights = _caliberWeights;
    final g = _parse(ammoGrain);
    final select = KeyedSubtree(
      key: const Key('ammo-grain-select'),
      child: MenzilSelect<double>(
        key: ValueKey(
          'ammo-grain-select-$cal-$_grainOther-'
          '${_grainOther ? '' : ammoGrain.text}',
        ),
        label: 'Ağırlık',
        hint: 'Seçiniz',
        info: ProfileFieldInfo.grainPick,
        initialValue: _grainOther
            ? _grainOtherKey
            : (g != null && weights.contains(g) ? g : null),
        items: [
          for (final w in weights)
            DropdownMenuItem(value: w, child: Text(_grainLabel(w))),
          const DropdownMenuItem(
            value: _grainOtherKey,
            child: Text('Listede yok'),
          ),
        ],
        errorText: _grainOther ? null : _shownSelect(_grainError, ammoGrain),
        onChanged: (v) => setState(() {
          if (v == null) return;
          if (v == _grainOtherKey) {
            if (!_grainOther) ammoGrain.text = '';
            _grainOther = true;
            return;
          }
          _grainOther = false;
          ammoGrain.text = _trimNum(v);
        }),
      ),
    );
    if (!_grainOther) return [MenzilFullWidth(child: select)];
    // Each on its own row: the gram text next to the unit and ⓘ does not
    // fit a half-width box on a phone.
    return [
      MenzilFullWidth(child: select),
      MenzilFullWidth(
        child: MenzilInput(
          key: const Key('ammo-grain'),
          controller: ammoGrain,
          label: 'Kutudaki ağırlık',
          // The gram equivalent in the unit area, so a gram value typed as
          // grain stands out (owner: "Ağırlığın doğru yazılması çok önemli").
          unit: g == null || g <= 0 ? 'gr' : 'gr = ${_gramText(g)} g',
          info: ProfileFieldInfo.grainTyped,
          onChanged: (_) => setState(() {}),
          errorText: _shown(_grainError, ammoGrain),
        ),
      ),
    ];
  }

  /// BC modeli of a typed firearm round: G1 or G7 (owner, 2026-10-14); a
  /// saved other model or curve stays selectable so the record is kept.
  List<DropdownMenuItem<String>> get _typedBcModelItems => [
    const DropdownMenuItem(value: 'g1', child: Text('G1')),
    const DropdownMenuItem(value: 'g7', child: Text('G7')),
    if (!_customCurve &&
        ammoBcModel != null &&
        ammoBcModel != BallisticModel.g1 &&
        ammoBcModel != BallisticModel.g7)
      DropdownMenuItem(
        value: ammoBcModel!.name,
        child: Text('${ammoBcModel!.name.toUpperCase()} (kayıtlı)'),
      ),
    if (_customCurve)
      const DropdownMenuItem(
        value: _customKey,
        child: Text('Özel eğri (kayıtlı)'),
      ),
  ];

  /// Barut katsayısı / Hız ölçüm sıcaklığı as a list (owner, 2026-10-14).
  /// Starts on "Seçiniz" (empty = no correction; "Seçiniz" in the list
  /// empties it again). A value not in [options] (an older profile, a
  /// maker figure) is listed as "(kayıtlı)" / "(üretici)" and kept.
  Widget _powderSelect({
    required String key,
    required TextEditingController controller,
    required String label,
    String? unit,
    required String info,
    required List<double> options,
    required String? error,
  }) {
    final cur = _parse(controller);
    final extra = cur != null && !options.contains(cur);
    final values = [...options, if (cur != null && extra) cur]..sort();
    final tag = _powderAutoFilled ? 'üretici' : 'kayıtlı';
    return KeyedSubtree(
      key: Key(key),
      child: MenzilSelect<String>(
        key: ValueKey('$key-${controller.text}'),
        label: label,
        unit: unit,
        info: info,
        hint: 'Seçiniz',
        initialValue: cur == null ? null : _trimNum(cur),
        items: [
          const DropdownMenuItem(value: '', child: Text('Seçiniz')),
          for (final v in values)
            DropdownMenuItem(
              value: _trimNum(v),
              child: Text(
                extra && v == cur ? '${_trimNum(v)} ($tag)' : _trimNum(v),
              ),
            ),
        ],
        errorText: _shownSelect(error, controller),
        onChanged: (v) => setState(() {
          controller.text = v ?? '';
          _powderAutoFilled = false;
        }),
      ),
    );
  }

  /// PCP: Tüp basıncı | Regülatör basıncı, then "Basınca göre hız" rows.
  /// Each pair sits in its own full-width grid so the two boxes share a row
  /// whatever comes before them.
  List<Widget> _pcpPressureFields(MenzilColors c) => [
    MenzilFullWidth(
      child: MenzilFieldGrid(
        children: [
          MenzilInput(
            key: const Key('profile-tube-pressure'),
            controller: tubePressure,
            label: 'Tüp basıncı',
            unit: 'bar',
            info: ProfileFieldInfo.tubePressure,
            onChanged: (_) => setState(() {}),
            errorText: _shown(_tubePressureError, tubePressure),
          ),
          MenzilInput(
            key: const Key('profile-regulator-pressure'),
            controller: regulatorPressure,
            label: 'Regülatör basıncı',
            unit: 'bar',
            info: ProfileFieldInfo.regulatorPressure,
            onChanged: (_) => setState(() {}),
            errorText: _shown(_regulatorPressureError, regulatorPressure),
          ),
        ],
      ),
    ),
    MenzilFullWidth(
      child: Padding(
        padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
        child: Text(
          'Basınca göre hız',
          key: const Key('profile-pv-title'),
          style: MenzilType.body(c.ink),
        ),
      ),
    ),
    MenzilFullWidth(
      child: MenzilFieldGrid(
        children: [
          for (var i = 0; i < PcpPressure.tableRows; i++) ...[
            MenzilInput(
              key: Key('profile-pv-bar-$i'),
              controller: pvBar[i],
              label: '${i + 1}. basınç',
              unit: 'bar',
              info: ProfileFieldInfo.pvBar,
              onChanged: (_) => setState(() {}),
              errorText: _shown(_pvBarError(i), pvBar[i]),
            ),
            MenzilInput(
              key: Key('profile-pv-fps-$i'),
              controller: pvFps[i],
              label: '${i + 1}. hız',
              unit: 'fps',
              info: ProfileFieldInfo.pvFps,
              onChanged: (_) => setState(() {}),
              errorText: _shown(_pvFpsError(i), pvFps[i]),
            ),
          ],
        ],
      ),
    ),
  ];
}

/// Profil summary tile for Dürbün ayağı: "0 MOA", "15 MOA", "30 MOA" —
/// the same text as the form's closed box — and "—" when no value is set.
@visibleForTesting
MenzilMetric mountCantSummary(double? moa) =>
    moa == null || !moa.isFinite || moa < 0
    ? const MenzilMetric('Dürbün ayağı', '—')
    : MenzilMetric('Dürbün ayağı', _trimNum(moa), 'MOA');

String _trimNum(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toString().replaceAll('.', ',');

/// Display units of the Profil summary. The stored profile stays SI; the
/// velocity is shown in fps, distances in the profile's own unit.
class _ProfileUnits {
  const _ProfileUnits();

  static _ProfileUnits of(BuildContext context) => const _ProfileUnits();

  // Muzzle velocity is entered and shown in fps on Profil (owner decision,
  // 2026-10-07). Distances follow the profile's own unit (_zeroValue).
  String get velocityUnit => 'fps';

  String velocityValue(double mps) =>
      UnitSystem.mpsToFps(mps).toStringAsFixed(0);

  String velocity(double mps) => '${velocityValue(mps)} $velocityUnit';
}
