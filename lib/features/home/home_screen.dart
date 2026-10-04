import 'package:flutter/material.dart';

import '../../data/profile_catalog_integrity.dart';
import '../../models/domain.dart';
import '../../services/active_profile_store.dart';
import '../../services/profile_store.dart';
import '../../services/settings_store.dart';
import '../../ui/menzil_icons.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import '../ballistics/ballistics_screen.dart';
import '../profiles/profiles_screen.dart';
import '../settings/settings_screen.dart';
import '../tools/tools_screen.dart';

/// Application shell: fixed Menzil top bar, five tabs (Atış, Tablo, Ortam,
/// Profil, Araçlar) and the active-profile state shared by all of them.
class HomeScreen extends StatefulWidget {
  final ProfileStore? profileStore;
  final ActiveProfileStore? activeProfileStore;

  const HomeScreen({super.key, this.profileStore, this.activeProfileStore});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ProfileStore profiles =
      widget.profileStore ?? PersistentProfileStore();
  late final ActiveProfileStore activeStore =
      widget.activeProfileStore ?? PersistentActiveProfileStore();

  List<RifleProfile> saved = [];
  RifleProfile? active;
  bool loading = true;
  bool choosingProfile = false;
  String? loadError;
  String? activeProfileWarning;
  int _loadGeneration = 0;

  static const _tabShot = 0;
  static const _tabTable = 1;
  static const _tabEnvironment = 2;
  static const _tabProfile = 3;

  static const _navItems = [
    MenzilNavItem(MenzilGlyph.shot, 'Atış'),
    MenzilNavItem(MenzilGlyph.table, 'Tablo'),
    MenzilNavItem(MenzilGlyph.environment, 'Ortam'),
    MenzilNavItem(MenzilGlyph.profile, 'Profil'),
    MenzilNavItem(MenzilGlyph.tools, 'Araçlar'),
  ];

  int tab = _tabShot;
  BallisticsView ballisticsView = BallisticsView.shot;
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
      if (mounted && loadedMetric != metric)
        setState(() => metric = loadedMetric);
    } catch (_) {
      // Keep metric.
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    // A changed unit preference re-creates the ballistic workspace (keyed on
    // `metric`), which re-runs its own atomic unit conversion on init.
    await _loadUnitPreference();
  }

  void _selectTab(int index) {
    setState(() {
      tab = index;
      if (index == _tabShot) ballisticsView = BallisticsView.shot;
      if (index == _tabTable) ballisticsView = BallisticsView.table;
      if (index == _tabEnvironment) ballisticsView = BallisticsView.environment;
    });
  }

  bool get _activeProfileValid =>
      active != null &&
      const ProfileCatalogIntegrity().resolve(active!) != null;

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
        unitLabel: metric ? 'm' : 'yd',
        onUnitTap: _openSettings,
        themeLabel: MenzilThemeController.labelFor(themeMode),
        onThemeTap: themeController?.cycle,
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
              action: MenzilPrimaryButton(
                label: 'Tekrar dene',
                onPressed: _load,
                icon: Icons.refresh,
                expand: false,
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
                Expanded(
                  key: const ValueKey('menzil-tabs'),
                  child: IndexedStack(
                    index: tab <= _tabEnvironment ? 0 : tab - _tabEnvironment,
                    children: [
                      _ballisticsTab(context),
                      ProfilesScreen(
                        embedded: true,
                        store: profiles,
                        activeProfileId: active?.id,
                        revision: _profilesRevision,
                        onActivate: _choose,
                        onProfilesChanged: _load,
                      ),
                      ToolsScreen(
                        onSettingsClosed: _loadUnitPreference,
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
        key: ValueKey('active-profile-${active?.id}'),
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

  /// Atış, Tablo and Ortam share one ballistic workspace so inputs and the
  /// last validated solve survive tab switches. A different active profile
  /// or unit preference creates a fresh workspace (fresh profile defaults).
  Widget _ballisticsTab(BuildContext context) {
    final profile = active;
    if (profile == null || !_activeProfileValid) {
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
        metric,
      )),
      profile: profile,
      view: ballisticsView,
    );
  }
}
