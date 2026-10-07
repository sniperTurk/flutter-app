import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/catalog_repository.dart';
import '../../data/profile_catalog_integrity.dart';
import '../../models/domain.dart';
import '../../services/active_profile_store.dart';
import '../../services/profile_store.dart';
import '../../services/settings_store.dart';
import '../../services/user_catalog_loader.dart';
import '../../ui/menzil_icons.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import '../ballistics/ballistics_screen.dart';
import '../profiles/profile_recovery_dialog.dart';
import '../profiles/profiles_screen.dart';
import '../tools/tools_screen.dart';

/// Application shell: fixed Menzil top bar, four tabs (Profil, Hava Durumu,
/// Atış, Araçlar) and the active-profile state shared by all of them.
/// The app opens on Profil. Hava Durumu sits next to it so the conditions are
/// set before shooting; Atış switches between a single shot and the DOPE
/// table, as range-card apps do.
class HomeScreen extends StatefulWidget {
  final ProfileStore? profileStore;
  final ActiveProfileStore? activeProfileStore;

  /// Loads (and migrates) the personal manual catalog so profiles can use the
  /// user's own rifles, ammunition and scopes.
  final UserCatalogLoader? userCatalogLoader;

  const HomeScreen({
    super.key,
    this.profileStore,
    this.activeProfileStore,
    this.userCatalogLoader,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ProfileStore profiles =
      widget.profileStore ?? PersistentProfileStore();
  late final ActiveProfileStore activeStore =
      widget.activeProfileStore ?? PersistentActiveProfileStore();
  late final UserCatalogLoader userCatalog =
      widget.userCatalogLoader ?? UserCatalogLoader();

  List<RifleProfile> saved = [];
  RifleProfile? active;
  bool loading = true;
  bool choosingProfile = false;
  String? loadError;
  String? activeProfileWarning;
  String? userCatalogWarning;
  bool _userCatalogReady = false;
  int _loadGeneration = 0;

  /// Bumped whenever a selection could not be committed. The dropdown's
  /// FormField keeps its own value after a tap; re-keying it remounts the
  /// field from [active], so the visible profile never drifts away from the
  /// profile the ballistic workspace actually uses.
  int _selectorEpoch = 0;

  static const _tabProfile = 0;
  static const _tabEnvironment = 1;
  static const _tabShot = 2;

  static const _navItems = [
    MenzilNavItem(MenzilGlyph.profile, 'Profil'),
    MenzilNavItem(MenzilGlyph.environment, 'Hava Durumu'),
    MenzilNavItem(MenzilGlyph.shot, 'Atış'),
    MenzilNavItem(MenzilGlyph.tools, 'Araçlar'),
  ];

  int tab = _tabProfile;
  BallisticsView ballisticsView = BallisticsView.shot;

  /// Atış shows either the single shot or the DOPE table; the choice is kept
  /// while visiting other tabs.
  BallisticsView _shotMode = BallisticsView.shot;
  bool metric = true;
  int _profilesRevision = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadUnitPreference();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
        activeProfileWarning = null;
      });
    }
    try {
      final all = await profiles.all();
      // The personal catalog loads alongside; profiles never wait for it. A
      // profile built from personal records shows a loading state (not a
      // mismatch) until the catalog is installed, then re-resolves.
      unawaited(_loadUserCatalog(all, generation));
      final id = await activeStore.getActiveProfileId();
      if (!mounted || generation != _loadGeneration) return;
      RifleProfile? selected;
      for (final profile in all) {
        if (profile.id == id) {
          selected = profile;
          break;
        }
      }
      selected ??= all.isEmpty ? null : all.first;
      // Keep the persisted active-profile pointer consistent with the profile
      // collection. A deleted last profile used to leave a stale id behind,
      // which could be resurrected as an invalid selection on a later launch.
      final resolvedId = selected?.id;
      String? reconciliationWarning;
      if (resolvedId != id) {
        try {
          await activeStore.setActiveProfileId(resolvedId);
        } catch (_) {
          // The profiles themselves loaded successfully. A stale active-id
          // pointer must not make the whole application unusable merely
          // because its best-effort repair could not be persisted. Keep the
          // resolved in-memory selection and surface the degraded state.
          reconciliationWarning =
              'Aktif profil seçimi kalıcı olarak düzeltilemedi. '
              'Bu oturumda geçerli profil kullanılacak.';
        }
      }
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        saved = all;
        active = selected;
        activeProfileWarning = reconciliationWarning;
        loading = false;
        _profilesRevision++;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        loading = false;
        loadError = 'Profil verileri okunamadı. Kayıtlar değiştirilmedi.';
      });
    }
  }

  static bool _dependsOnPersonal(RifleProfile p) {
    bool builtIn(Iterable<String> ids, String id) => ids.contains(id);
    return !builtIn(CatalogRepository.rifles.map((r) => r.id), p.rifleId) ||
        !builtIn(
          CatalogRepository.ammunition.map((a) => a.id),
          p.ammunitionId,
        ) ||
        !builtIn(CatalogRepository.scopes.map((s) => s.id), p.scopeId);
  }

  /// Loads, migrates and installs the personal catalog, then rebuilds so
  /// profiles re-resolve. A read failure keeps the previously installed
  /// personal catalog and only warns when a saved profile depends on it.
  Future<void> _loadUserCatalog(List<RifleProfile> all, int generation) async {
    String? warning;
    try {
      warning = (await userCatalog.load()).warning;
    } catch (_) {
      warning = all.any(_dependsOnPersonal)
          ? 'Kişisel katalog okunamadı. Kişisel ekipman kullanan profiller '
                'bu oturumda hesaplamada kullanılamaz; kayıtlar değiştirilmedi.'
          : null;
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      userCatalogWarning = warning;
      _userCatalogReady = true;
    });
  }

  /// The error card replaces the tabs, so recovery must be reachable here too.
  Future<void> _recover() async {
    // ProfileRecovery is not a subtype of ProfileStore: promote via Object.
    final Object recovery = profiles;
    if (recovery is! ProfileRecovery) return;
    final reset = await showProfileRecoveryDialog(context, recovery);
    if (reset && mounted) await _load();
  }

  Future<void> _choose(RifleProfile? profile) async {
    if (choosingProfile) return;
    setState(() => choosingProfile = true);
    try {
      await activeStore.setActiveProfileId(profile?.id);
      if (mounted) {
        // Resolve to the instance held in `saved` (RifleProfile has no value
        // equality); a foreign instance would break the dropdown's
        // initialValue match. Unknown ids are never invented.
        final resolved = profile == null
            ? null
            : saved.where((x) => x.id == profile.id).firstOrNull;
        setState(() => active = resolved ?? profile);
      }
    } catch (_) {
      if (mounted) {
        // Roll the dropdown back to the still-active (previous) profile.
        setState(() => _selectorEpoch++);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktif profil kaydedilemedi. Önceki seçim korundu.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => choosingProfile = false);
    }
  }

  /// Display-only unit label for the top bar. Fails closed to metric, the
  /// same default the ballistic screen uses when settings cannot be read.
  Future<void> _loadUnitPreference() async {
    try {
      final loadedMetric = (await SettingsStore.open()).loadMetric();
      if (mounted && loadedMetric != metric) {
        setState(() => metric = loadedMetric);
      }
    } catch (_) {
      // Keep metric.
    }
  }

  void _selectTab(int index) {
    setState(() {
      tab = index;
      if (index == _tabShot) ballisticsView = _shotMode;
      if (index == _tabEnvironment) ballisticsView = BallisticsView.environment;
    });
  }

  void _selectShotMode(BallisticsView mode) {
    setState(() {
      _shotMode = mode;
      if (tab == _tabShot) ballisticsView = mode;
    });
  }

  ProfileCatalogResolution? get _activeResolution =>
      active == null ? null : const ProfileCatalogIntegrity().resolve(active!);

  @override
  Widget build(BuildContext context) {
    final themeController = MenzilThemeScope.maybeOf(context);
    final themeMode = themeController?.value ?? ThemeMode.system;
    // Full-screen progress only until the first successful load; later
    // reloads keep every tab (and its in-progress input) mounted.
    final firstLoad = loading && _profilesRevision == 0;

    return Scaffold(
      appBar: MenzilTopBar(
        profileSelector: _profileSelector(context),
        themeLabel: MenzilThemeController.labelFor(themeMode),
        onThemeTap: themeController?.cycle,
        showBrand: tab != _tabProfile,
      ),
      bottomNavigationBar: MenzilBottomNavigation(
        items: _navItems,
        currentIndex: tab,
        onSelected: _selectTab,
      ),
      body: firstLoad
          ? Center(
              child: Semantics(
                label: 'Profiller yükleniyor',
                liveRegion: true,
                child: const CircularProgressIndicator(),
              ),
            )
          : loadError != null
          ? MenzilStateMessage(
              icon: Icons.error_outline,
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
                  if (profiles is ProfileRecovery) ...[
                    const SizedBox(height: MenzilSpace.md),
                    MenzilSecondaryButton(
                      key: const Key('home-recover'),
                      label: 'Kayıtları kurtar',
                      icon: Icons.healing,
                      onPressed: _recover,
                    ),
                  ],
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (loading) const LinearProgressIndicator(minHeight: 2),
                if (activeProfileWarning != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      MenzilSpace.gutter,
                      MenzilSpace.md,
                      MenzilSpace.gutter,
                      0,
                    ),
                    child: Semantics(
                      liveRegion: true,
                      child: MenzilNotice(
                        tone: MenzilNoticeTone.warning,
                        icon: Icons.warning_amber_rounded,
                        title: 'Aktif profil uyarısı',
                        message: activeProfileWarning!,
                      ),
                    ),
                  ),
                if (userCatalogWarning != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      MenzilSpace.gutter,
                      MenzilSpace.md,
                      MenzilSpace.gutter,
                      0,
                    ),
                    child: Semantics(
                      liveRegion: true,
                      child: MenzilNotice(
                        tone: MenzilNoticeTone.warning,
                        icon: Icons.warning_amber_rounded,
                        title: 'Kişisel katalog uyarısı',
                        message: userCatalogWarning!,
                      ),
                    ),
                  ),
                if (tab == _tabShot && active != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      MenzilSpace.gutter,
                      MenzilSpace.md,
                      MenzilSpace.gutter,
                      0,
                    ),
                    child: _ShotModeSwitch(
                      selected: _shotMode,
                      onSelected: _selectShotMode,
                    ),
                  ),
                Expanded(
                  key: const ValueKey('menzil-tabs'),
                  child: IndexedStack(
                    // 0: Profil, 1: Hava Durumu/Atış (one workspace), 2: Araçlar.
                    index: tab == _tabProfile
                        ? 0
                        : tab <= _tabShot
                        ? 1
                        : 2,
                    children: [
                      ProfilesScreen(
                        embedded: true,
                        store: profiles,
                        activeProfileId: active?.id,
                        revision: _profilesRevision,
                        onActivate: _choose,
                        onProfilesChanged: _load,
                        onContinue: () => _selectTab(_tabEnvironment),
                      ),
                      _ballisticsTab(context),
                      ToolsScreen(
                        onProfilesChanged: _load,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _profileSelector(BuildContext context) {
    final c = MenzilColors.of(context);
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(MenzilRadius.chip),
      borderSide: BorderSide(color: c.line),
    );
    final nameStyle = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: c.ink,
    );
    if (saved.isEmpty) {
      return Semantics(
        button: true,
        label: 'Profil oluştur',
        child: ExcludeSemantics(
          child: Material(
            color: c.surface,
            shape: StadiumBorder(side: BorderSide(color: c.line)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: loading ? null : () => _selectTab(_tabProfile),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      loading ? '…' : 'Profil yok',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle.copyWith(color: c.ink2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      label: 'Aktif tüfek profili',
      button: true,
      child: DropdownButtonFormField<RifleProfile>(
        key: ValueKey(('active-profile', active?.id, _selectorEpoch)),
        initialValue: active,
        isExpanded: true,
        isDense: true,
        borderRadius: BorderRadius.circular(MenzilRadius.input),
        dropdownColor: c.surface,
        icon: Icon(Icons.expand_more, color: c.ink2, size: 20),
        decoration: InputDecoration(
          filled: true,
          fillColor: c.surface,
          contentPadding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
          border: pill,
          enabledBorder: pill,
          focusedBorder: pill,
          disabledBorder: pill,
        ),
        selectedItemBuilder: (context) => saved
            .map(
              (profile) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nameStyle,
                ),
              ),
            )
            .toList(),
        items: saved
            .map(
              (profile) => DropdownMenuItem(
                value: profile,
                child: Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: choosingProfile ? null : _choose,
      ),
    );
  }

  /// Hava Durumu and Atış (single shot and table) share one ballistic workspace so inputs and the
  /// last validated solve survive tab switches. A different active profile
  /// or unit preference creates a fresh workspace (fresh profile defaults).
  Widget _ballisticsTab(BuildContext context) {
    final profile = active;
    final resolution = _activeResolution;
    if (profile != null &&
        resolution == null &&
        !_userCatalogReady &&
        _dependsOnPersonal(profile)) {
      return Center(
        child: Semantics(
          label: 'Kişisel katalog yükleniyor',
          liveRegion: true,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (profile == null || resolution == null) {
      return MenzilPage(
        children: [
          MenzilToolTile(
            icon: Icons.track_changes,
            title: 'Balistik / DOPE',
            subtitle: profile == null
                ? 'DOPE için önce aktif profil oluşturun'
                : 'Aktif profil katalogla eşleşmiyor; '
                      'Profiller ekranında yeniden doğrulayın',
            enabled: false,
            onTap: null,
          ),
          MenzilCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  saved.isEmpty
                      ? 'Önce bir tüfek profili oluştur.'
                      : 'Aktif profili Profil sekmesinde düzenleyip yeniden kaydedin.',
                  style: MenzilType.body(MenzilColors.of(context).ink),
                ),
                const SizedBox(height: MenzilSpace.md),
                MenzilPrimaryButton(
                  label: saved.isEmpty ? 'Profil oluştur' : 'Profile git',
                  icon: Icons.arrow_forward,
                  onPressed: () => _selectTab(_tabProfile),
                ),
              ],
            ),
          ),
        ],
      );
    }
    // Keyed on the profile's values (not object identity): a profile reload
    // that changed nothing keeps the user's in-progress inputs.
    return BallisticsScreen(
      key: ValueKey((
        profile.id,
        profile.rifleId,
        profile.ammunitionId,
        profile.scopeId,
        profile.muzzleVelocityMps,
        profile.zeroRangeM,
        profile.sightHeightMm,
        profile.angularUnit,
        // Personal catalog records can be edited without changing the
        // profile; the workspace must then start again from the new values.
        (
          resolution.rifle.caliberMm,
          resolution.ammunition.grain,
          resolution.ammunition.ballisticCoefficient,
          resolution.ammunition.ballisticModel,
          resolution.scope.clickValue,
          resolution.scope.clickUnit,
        ),
        metric,
      )),
      profile: profile,
      view: ballisticsView,
    );
  }
}

/// "Tek atış | Tablo" switch above the Atış workspace. Each half is a full
/// 44 pt tap target and announces its selected state to VoiceOver.
class _ShotModeSwitch extends StatelessWidget {
  final BallisticsView selected;
  final ValueChanged<BallisticsView> onSelected;

  const _ShotModeSwitch({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    Widget half(BallisticsView value, String label, IconData icon) {
      final on = value == selected;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: Material(
            color: on ? c.ink : c.surface,
            child: InkWell(
              key: Key('shot-mode-${value.name}'),
              onTap: () => onSelected(value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: on ? c.bg : c.ink2),
                      const SizedBox(width: MenzilSpace.xs),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: on ? c.bg : c.ink2,
                          ),
                        ),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(MenzilRadius.chip),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(MenzilRadius.chip),
        ),
        child: Row(
          children: [
            half(BallisticsView.shot, 'Tek atış', Icons.gps_fixed),
            half(BallisticsView.table, 'Tablo', Icons.table_rows_outlined),
          ],
        ),
      ),
    );
  }
}
