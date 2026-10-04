import 'package:flutter/material.dart';

import '../../core/production_limits.dart';
import '../../core/unit_system.dart';
import '../../data/catalog_repository.dart';
import '../../models/domain.dart';
import '../../services/app_settings.dart';
import '../../services/profile_store.dart';
import '../../tools/domain/chronograph_stats.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'tool_support.dart';

/// Kronograf: Tüfek -> mühimmat (katalog veya manuel) -> hız girişleri ->
/// sonuç. Velocities are typed in from a chronograph device; the app does not
/// measure speed itself. The series lives only in this screen (session) and
/// the averaged velocity is written to a profile only after an explicit
/// confirmation, so no second copy of the velocity data is stored.
class ChronographScreen extends StatefulWidget {
  /// Injected in tests; defaults to the persistent store.
  final ProfileStore? profileStore;
  const ChronographScreen({super.key, this.profileStore});

  @override
  State<ChronographScreen> createState() => _ChronographScreenState();
}

class _ChronographScreenState extends State<ChronographScreen> {
  static const _minShotsForApply = 3;

  late final ProfileStore _profiles =
      widget.profileStore ?? PersistentProfileStore();
  final _catalog = const CatalogRepository();

  WeaponPlatform _platform = WeaponPlatform.pcp;
  String? _rifleId;
  String? _ammoId;
  bool _manualAmmo = false;
  final _manualName = TextEditingController();
  final _manualGrain = TextEditingController();
  final _velocity = TextEditingController();

  /// Optional PCP reservoir pressures for this session (bar). Display only;
  /// never written to a profile.
  final _startBar = TextEditingController();
  final _endBar = TextEditingController();

  /// Shots in m/s (canonical).
  final List<double> _shots = [];

  @override
  void dispose() {
    _manualName.dispose();
    _manualGrain.dispose();
    _velocity.dispose();
    _startBar.dispose();
    _endBar.dispose();
    super.dispose();
  }

  Rifle? get _rifle {
    for (final r in _catalog.riflesFor(_platform)) {
      if (r.id == _rifleId) return r;
    }
    return null;
  }

  List<Ammunition> get _ammoChoices {
    final r = _rifle;
    return r == null
        ? const []
        : _catalog.ammunitionFor(_platform, caliberMm: r.caliberMm);
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  void _addShot(bool metric) {
    final raw = double.tryParse(_velocity.text.trim().replaceAll(',', '.'));
    if (raw == null || !raw.isFinite || raw <= 0) {
      _snack('Geçerli bir hız girin.');
      return;
    }
    final mps = metric ? raw : UnitSystem.fpsToMps(raw);
    if (mps > ChronographStats.maxPlausibleMps) {
      _snack('Hız makul aralığın dışında.');
      return;
    }
    setState(() {
      _shots.add(mps);
      _velocity.clear();
    });
  }

  Future<void> _applyToProfile(VelocityStats stats) async {
    final rifleId = _rifleId, ammoId = _ammoId;
    if (rifleId == null || ammoId == null) return;
    final List<RifleProfile> all;
    try {
      all = await _profiles.all();
    } catch (_) {
      if (mounted) _snack('Profiller okunamadı.');
      return;
    }
    final matches = all
        .where((p) => p.rifleId == rifleId && p.ammunitionId == ammoId)
        .toList(growable: false);
    if (!mounted) return;
    if (matches.isEmpty) {
      _snack(
        'Bu tüfek ve mühimmat için kayıtlı profil yok. Önce Profil sekmesinde oluşturun.',
      );
      return;
    }
    final metric = AppSettingsScope.metricOf(context);
    final pick = await showDialog<_PickResult>(
      context: context,
      builder: (_) => _ProfilePickDialog(
        profiles: matches,
        newVelocityText: ToolFormat.velocity(stats.meanMps, metric: metric),
        metric: metric,
        startPressureBar: _validStartPressureBar,
      ),
    );
    if (pick == null || !mounted) return;
    final chosen = pick.profile;
    final RifleProfile updated;
    try {
      updated = ToolProfileUpdate.apply(
        chosen,
        muzzleVelocityMps: double.parse(stats.meanMps.toStringAsFixed(1)),
        pressureBar: pick.writePressure ? _validStartPressureBar : null,
      );
    } on FormatException catch (e) {
      _snack(e.message);
      return;
    }
    try {
      await _profiles.save(updated);
      if (mounted) _snack('Ortalama hız profile uygulandı.');
    } catch (_) {
      if (mounted) _snack('Profil kaydedilemedi. Mevcut değer korundu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final metric = AppSettingsScope.metricOf(context);
    final c = MenzilColors.of(context);
    final stats = ChronographStats.compute(_shots);
    final rifles = _catalog.riflesFor(_platform);
    final ammo = _ammoChoices;
    final canApply =
        stats != null &&
        stats.count >= _minShotsForApply &&
        !_manualAmmo &&
        _rifleId != null &&
        _ammoId != null;

    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Kronograf'),
      body: MenzilPage(
        children: [
          const MenzilSectionHeader(
            '1 · Tüfek',
            padding: EdgeInsets.only(bottom: MenzilSpace.sm),
          ),
          SegmentedButton<WeaponPlatform>(
            key: const Key('chrono-platform'),
            segments: const [
              ButtonSegment(value: WeaponPlatform.pcp, label: Text('PCP')),
              ButtonSegment(
                value: WeaponPlatform.firearm,
                label: Text('Ateşli'),
              ),
            ],
            selected: {_platform},
            showSelectedIcon: false,
            style: const ButtonStyle(
              minimumSize: WidgetStatePropertyAll(
                Size(44, MenzilSpace.control),
              ),
            ),
            onSelectionChanged: (s) => setState(() {
              _platform = s.first;
              _rifleId = null;
              _ammoId = null;
              _shots.clear();
            }),
          ),
          const SizedBox(height: MenzilSpace.md),
          MenzilSelect<String>(
            key: ValueKey('chrono-rifle-${_platform.name}'),
            label: 'Tüfek',
            initialValue: _rifleId,
            items: [
              for (final r in rifles)
                DropdownMenuItem(
                  value: r.id,
                  child: Text(r.displayName, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() {
              _rifleId = v;
              _ammoId = null;
              _shots.clear();
            }),
          ),
          const MenzilSectionHeader(
            '2 · Mühimmat',
            padding: EdgeInsets.only(bottom: MenzilSpace.sm),
          ),
          SwitchListTile(
            key: const Key('chrono-manual-switch'),
            contentPadding: EdgeInsets.zero,
            value: _manualAmmo,
            title: Text('Manuel mühimmat', style: MenzilType.body(c.ink)),
            subtitle: Text(
              'Katalogda yoksa ad ve ağırlık girin (profile aktarılamaz).',
              style: MenzilType.caption(c.ink2),
            ),
            onChanged: (v) => setState(() {
              _manualAmmo = v;
              _ammoId = null;
              _shots.clear();
            }),
          ),
          if (_manualAmmo)
            MenzilFieldGrid(
              children: [
                MenzilInput(controller: _manualName, label: 'Mühimmat adı'),
                MenzilInput(
                  controller: _manualGrain,
                  label: 'Ağırlık',
                  unit: 'grain',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            )
          else
            MenzilSelect<String>(
              key: ValueKey('chrono-ammo-${_rifleId ?? '-'}'),
              label: 'Mühimmat',
              initialValue: _ammoId,
              items: [
                for (final a in ammo)
                  DropdownMenuItem(
                    value: a.id,
                    child: Text(a.displayName, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _rifleId == null
                  ? null
                  : (v) => setState(() {
                      _ammoId = v;
                      _shots.clear();
                    }),
            ),
          const MenzilSectionHeader(
            '3 · Ölçüm',
            padding: EdgeInsets.only(bottom: MenzilSpace.sm),
          ),
          if (_platform == WeaponPlatform.pcp)
            MenzilFieldGrid(
              children: [
                MenzilInput(
                  key: const Key('chrono-start-bar'),
                  controller: _startBar,
                  label: 'Başlangıç basıncı',
                  unit: 'bar',
                  helperText: 'İsteğe bağlı',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                MenzilInput(
                  key: const Key('chrono-end-bar'),
                  controller: _endBar,
                  label: 'Bitiş basıncı',
                  unit: 'bar',
                  helperText: 'Seri sonunda',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          const MenzilNotice(
            tone: MenzilNoticeTone.info,
            message:
                'Hızlar kronograf cihazından elle girilir; uygulama hız ölçmez. Seri yalnızca bu oturumda tutulur.',
          ),
          MenzilInput(
            key: const Key('chrono-velocity'),
            controller: _velocity,
            label: 'Atış hızı',
            unit: metric ? 'm/s' : 'fps',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
          ),
          MenzilPrimaryButton(
            label: 'Atış ekle',
            icon: Icons.add,
            onPressed: () => _addShot(metric),
          ),
          const SizedBox(height: MenzilSpace.md),
          for (var i = 0; i < _shots.length; i++)
            MenzilCard(
              margin: const EdgeInsets.only(bottom: MenzilSpace.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: MenzilSpace.lg,
                vertical: MenzilSpace.xxs,
              ),
              child: Row(
                children: [
                  Text('#${i + 1}', style: MenzilType.number(c.ink2, size: 18)),
                  const SizedBox(width: MenzilSpace.md),
                  Expanded(
                    child: Text(
                      ToolFormat.velocity(_shots[i], metric: metric),
                      style: MenzilType.number(c.ink, size: 22),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atış ${i + 1} sil',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _shots.removeAt(i)),
                  ),
                ],
              ),
            ),
          if (stats != null) ...[
            const MenzilSectionHeader(
              '4 · Sonuç',
              padding: EdgeInsets.only(
                top: MenzilSpace.md,
                bottom: MenzilSpace.sm,
              ),
            ),
            MenzilMetricGrid(
              metrics: [
                MenzilMetric('Atış', '${stats.count}'),
                MenzilMetric('Ortalama', _v(stats.meanMps, metric)),
                MenzilMetric(
                  'SD',
                  stats.sdMps == null ? '—' : _v(stats.sdMps!, metric),
                ),
                MenzilMetric('ES', _v(stats.esMps, metric)),
                MenzilMetric('Min', _v(stats.minMps, metric)),
                MenzilMetric('Maks', _v(stats.maxMps, metric)),
              ],
            ),
            if (_pressureDropBar != null)
              MenzilMetricGrid(
                key: const Key('chrono-pressure'),
                columns: 2,
                metrics: [
                  MenzilMetric(
                    'Basınç düşüşü',
                    _pressureDropBar!.toStringAsFixed(0),
                    'bar',
                  ),
                  MenzilMetric(
                    'Atış başına',
                    ToolFormat.dec(_pressureDropBar! / stats.count, 1),
                    'bar',
                  ),
                ],
              ),
            MenzilSecondaryButton(
              label: 'Ortalamayı profile uygula',
              icon: Icons.save_alt,
              onPressed: canApply ? () => _applyToProfile(stats) : null,
            ),
            if (!canApply)
              Padding(
                padding: const EdgeInsets.only(top: MenzilSpace.xs),
                child: Text(
                  _manualAmmo
                      ? 'Manuel mühimmat profile aktarılamaz.'
                      : (_rifleId == null || _ammoId == null)
                      ? 'Aktarım için katalogdan tüfek ve mühimmat seçin.'
                      : 'Aktarım için en az $_minShotsForApply atış gerekir.',
                  style: MenzilType.caption(c.ink2),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Start − end pressure when both are valid (PCP only), otherwise null.
  double? get _pressureDropBar {
    if (_platform != WeaponPlatform.pcp) return null;
    double? parse(TextEditingController c) =>
        double.tryParse(c.text.trim().replaceAll(',', '.'));
    final start = parse(_startBar), end = parse(_endBar);
    if (start == null || end == null || !start.isFinite || !end.isFinite)
      return null;
    if (end < 0 || start <= end || start > ProductionLimits.maxPcpPressureBar)
      return null;
    return start - end;
  }

  double? get _validStartPressureBar {
    if (_platform != WeaponPlatform.pcp || _pressureDropBar == null)
      return null;
    final value = double.tryParse(_startBar.text.trim().replaceAll(',', '.'));
    if (value == null ||
        !value.isFinite ||
        value <= 0 ||
        value > ProductionLimits.maxPcpPressureBar)
      return null;
    return value;
  }

  String _v(double mps, bool metric) => metric
      ? ToolFormat.dec(mps, 1)
      : ToolFormat.dec(UnitSystem.mpsToFps(mps), 0);
}

/// Lets the user pick which profile receives the new velocity and shows
/// exactly what will change before anything is saved.
class _PickResult {
  final RifleProfile profile;
  final bool writePressure;
  const _PickResult(this.profile, this.writePressure);
}

class _ProfilePickDialog extends StatefulWidget {
  final List<RifleProfile> profiles;
  final String newVelocityText;
  final bool metric;
  final double? startPressureBar;
  const _ProfilePickDialog({
    required this.profiles,
    required this.newVelocityText,
    required this.metric,
    this.startPressureBar,
  });

  @override
  State<_ProfilePickDialog> createState() => _ProfilePickDialogState();
}

class _ProfilePickDialogState extends State<_ProfilePickDialog> {
  RifleProfile? _selected;
  bool _writePressure = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Profile uygula'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yeni namlu çıkış hızı: ${widget.newVelocityText}'),
          const SizedBox(height: MenzilSpace.sm),
          RadioGroup<RifleProfile>(
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v),
            child: Column(
              children: [
                for (final p in widget.profiles)
                  RadioListTile<RifleProfile>(
                    value: p,
                    title: Text(p.name),
                    subtitle: Text(
                      'Şimdiki: ${ToolFormat.velocity(p.muzzleVelocityMps, metric: widget.metric)}',
                    ),
                  ),
              ],
            ),
          ),
          if (widget.startPressureBar != null)
            CheckboxListTile(
              key: const Key('chrono-write-pressure'),
              contentPadding: EdgeInsets.zero,
              value: _writePressure,
              onChanged: (v) => setState(() => _writePressure = v ?? false),
              title: Text(
                'Atış basıncını ${widget.startPressureBar!.toStringAsFixed(0)} bar yap',
              ),
              subtitle: const Text(
                'İşaretlemezseniz profilin basıncı değişmez.',
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Vazgeç'),
      ),
      FilledButton(
        onPressed: _selected == null
            ? null
            : () => Navigator.pop(
                context,
                _PickResult(_selected!, _writePressure),
              ),
        child: const Text('Uygula'),
      ),
    ],
  );
}
