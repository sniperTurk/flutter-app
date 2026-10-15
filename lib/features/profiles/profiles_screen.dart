import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/drag_curve.dart';
import '../../core/drag_table.dart';
import '../../core/estimated_bc.dart';
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
import 'shared_records.dart';

part 'profile_editor.dart';
part 'profile_editor_ammo.dart';
part 'profile_editor_ammo_extra.dart';
part 'profile_editor_rifle.dart';
part 'profile_editor_scope.dart';
part 'profile_summary.dart';

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
          sharedRecordIds: sharedRecordIdsOf(
            items,
            exceptProfileId: existing?.id,
          ),
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
    final unchanged = (
      rifleId: p.rifleId,
      ammunitionId: p.ammunitionId,
      scopeId: p.scopeId,
    );
    // Only a profile with a user-entered record reads the personal store.
    final personal =
        CatalogRepository.allRifles.any(
          (r) => r.userEntered && r.id == p.rifleId,
        ) ||
        CatalogRepository.allAmmunition.any(
          (a) => a.userEntered && a.id == p.ammunitionId,
        ) ||
        CatalogRepository.allScopes.any(
          (s) => s.userEntered && s.id == p.scopeId,
        );
    if (!personal) return unchanged;
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
        // The Profiller list is the top of the page (owner, 2026-10-15
        // 12:49 "profilleri yukarı al"): "Profiller" left, Profil ekle right
        // (amber, text only: no icon, no "+"); no "N kayıtlı profil" line.
        Padding(
          key: const Key('profiles-list-header'),
          padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
          child: Row(
            children: [
              Expanded(
                child: MenzilSectionHeader(
                  'Profiller',
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: MenzilSpace.sm),
              SizedBox(
                width: _addButtonWidth,
                child: MenzilPrimaryButton(
                  key: const Key('profiles-add'),
                  label: 'Profil ekle',
                  amber: true,
                  oneLine: true,
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
                summary: profileListSummary(p),
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
        // The active profile's Tüfek / Dürbün / Mühimmat summaries follow
        // the list, with the next step one tap away.
        if (selected != null) ...[
          const SizedBox(height: MenzilSpace.lg),
          _ActiveProfileDetails(
            profile: selected,
            onEdit: () => _edit(selected),
            onContinue: widget.embedded ? widget.onContinue : null,
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

  /// "6,35 mm, sıfır 25 m, 900 fps, BC 0,08 G1" ([profileListSummary]).
  final String summary;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _ProfileRow({
    required this.profile,
    required this.summary,
    required this.active,
    required this.onTap,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
  });

  /// Width of the amber left edge of the active card (owner, 2026-10-15).
  static const double activeBarWidth = 4;

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
        value: summary.isEmpty ? null : summary,
        child: Material(
          color: c.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: shape,
            side: BorderSide(color: c.line),
          ),
          child: InkWell(
            borderRadius: shape,
            onTap: onTap,
            // Name (+ Aktif), the summary line under it and one "⋯"; the
            // active card has a 4 pt amber left edge (owner, 2026-10-15
            // 12:49, Profil.png). Every card keeps the same text inset.
            child: Stack(
              children: [
                if (active)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: activeBarWidth,
                    child: ColoredBox(
                      key: const Key('profile-active-bar'),
                      color: c.amber,
                    ),
                  ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      activeBarWidth + 12,
                      10,
                      4,
                      10,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _texts(c)),
                        _menu(context, c),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _texts(MenzilColors c) => ExcludeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                profile.name,
                key: const Key('profile-row-name'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ),
            if (active)
              Padding(
                padding: const EdgeInsets.only(left: MenzilSpace.sm),
                child: Text(
                  'Aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.amberInk,
                  ),
                ),
              ),
          ],
        ),
        if (summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              summary,
              key: const Key('profile-row-summary'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: MenzilType.caption(c.ink2),
            ),
          ),
      ],
    ),
  );

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

/// One-line summary of a saved profile for its card in the Profiller list
/// (owner, 2026-10-15): "kalibre, sıfır N m|yd, hız, BC x G1|G7", e.g.
/// "6,35 mm, sıfır 25 m, 900 fps, BC 0,08 G1". The zero is in the
/// profile's own distance unit, the velocity in the Profil page's unit
/// ([_ProfileUnits]); a part whose value is missing is left out. Read only:
/// nothing here is saved or feeds the solver.
String profileListSummary(RifleProfile p) {
  final rifle = CatalogRepository.allRifles
      .where((r) => r.id == p.rifleId)
      .firstOrNull;
  final ammo = CatalogRepository.allAmmunition
      .where((a) => a.id == p.ammunitionId)
      .firstOrNull;
  bool ok(double? v) => v != null && v.isFinite && v > 0;
  const units = _ProfileUnits();
  final bc = ammo?.ballisticCoefficient;
  return [
    if (ok(rifle?.caliberMm))
      '${rifle!.caliberMm.toStringAsFixed(2).replaceAll('.', ',')} mm',
    if (ok(p.zeroRangeM)) 'sıfır ${_zeroValue(p)} ${p.distanceUnit.symbol}',
    if (ok(p.muzzleVelocityMps)) units.velocity(p.muzzleVelocityMps),
    if (ok(bc))
      _joinSummary(['BC', _trimNum(bc!), ammo!.ballisticModel?.label ?? '']),
  ].join(', ');
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
