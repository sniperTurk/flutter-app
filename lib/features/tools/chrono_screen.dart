import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/powder_temperature.dart';
import '../../core/unit_system.dart';
import '../../core/velocity_series.dart';
import '../../data/profile_catalog_integrity.dart';
import '../../models/domain.dart';
import '../../services/active_profile_store.dart';
import '../../services/app_settings.dart';
import '../../services/chrono_store.dart';
import '../../services/profile_store.dart';
import '../../services/shot_settings_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'chrono_field_info.dart';
import 'tool_support.dart';

/// Kronograf (Ö3, 2026-10-12): the shooter types the velocities a
/// chronograph showed, one per line. The page gives mean, SD, ES and n (and
/// on a PCP the slope along the string), and on request writes the mean to
/// the profile, the SD to WEZ (Pro > Hız farkı) and — from strings saved at
/// different cartridge temperatures — the powder temperature coefficient.
/// Nothing is written to the profile or to WEZ without an old -> new
/// confirmation; a saved string can be deleted from the list.
class ChronoScreen extends StatefulWidget {
  /// Injected in tests; default to the persistent stores.
  final ProfileStore? profileStore;
  final ActiveProfileStore? activeProfileStore;
  const ChronoScreen({super.key, this.profileStore, this.activeProfileStore});

  @override
  State<ChronoScreen> createState() => _ChronoScreenState();
}

class _ChronoScreenState extends State<ChronoScreen> {
  late final ProfileStore _profiles =
      widget.profileStore ?? PersistentProfileStore();
  late final ActiveProfileStore _activeStore =
      widget.activeProfileStore ?? PersistentActiveProfileStore();
  static const _chrono = ChronoStore();
  static const _shotStore = ShotSettingsStore();

  final _ammoTemp = TextEditingController();
  final _velocities = TextEditingController();

  bool _loading = true;
  RifleProfile? _profile;
  ProfileCatalogResolution? _resolution;
  ShotSettings? _shot;
  List<ChronoSession> _sessions = const [];

  /// Hız birimi; null until chosen ("Seçiniz").
  bool? _fps;

  /// Why the last button did nothing (e.g. the cartridge temperature is
  /// missing); cleared by the next edit.
  String? _actionError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _ammoTemp.dispose();
    _velocities.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    RifleProfile? profile;
    try {
      final id = await _activeStore.getActiveProfileId();
      if (id != null) {
        for (final p in await _profiles.all()) {
          if (p.id == id) profile = p;
        }
      }
    } catch (_) {
      profile = null;
    }
    List<ChronoSession> sessions = const [];
    ShotSettings? shot;
    if (profile != null) {
      try {
        sessions = await _chrono.load(profile.id);
        shot = await _shotStore.load(profile.id);
      } catch (_) {
        // No storage: no saved strings, no legacy Pro values.
      }
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _profile = profile;
      _resolution = profile == null
          ? null
          : const ProfileCatalogIntegrity().resolve(profile);
      _sessions = sessions;
      _shot = shot;
    });
  }

  bool get _firearm => _resolution?.rifle.platform == WeaponPlatform.firearm;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /// Namlu çıkış hızı is always shown in fps, as on Profil (owner rule).
  static String _profileFps(double mps) =>
      '${UnitSystem.mpsToFps(mps).toStringAsFixed(0)} fps';

  String get _unit => _fps == true ? 'fps' : 'm/s';

  /// A velocity (or difference) in the chosen unit.
  String _speed(double mps, {int? fpsDigits}) => _fps == true
      ? ToolFormat.dec(UnitSystem.mpsToFps(mps), fpsDigits ?? 0)
      : ToolFormat.dec(mps, 1);

  /// The cartridge temperature in °C, or null when empty / unreadable /
  /// outside the accepted band.
  double? _ammoC(bool metric) {
    final v = double.tryParse(_ammoTemp.text.trim().replaceAll(',', '.'));
    if (v == null || !v.isFinite) return null;
    final c = metric ? v : UnitSystem.fahrenheitToCelsius(v);
    return c < PowderTemperature.minTempC || c > PowderTemperature.maxTempC
        ? null
        : c;
  }

  ({VelocitySeries? series, String? error}) _parse() {
    final fps = _fps;
    if (fps == null || _velocities.text.trim().isEmpty) {
      return (series: null, error: null);
    }
    try {
      return (
        series: VelocitySeries.parse(_velocities.text, fps: fps),
        error: null,
      );
    } on VelocitySeriesFormatException catch (e) {
      return (series: null, error: e.message);
    }
  }

  ({double? coef, double? referenceC, bool fromProfile}) get _powder =>
      PowderTemperature.forProfile(
        profile: _profile,
        platform: _resolution?.rifle.platform,
        legacyCoefText: _shot?.powderCoefText ?? '',
        legacyTempText: _shot?.powderTempText ?? '',
      );

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              key: const Key('chrono-confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Uygula'),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _saveProfile(RifleProfile updated, String done) async {
    try {
      await _profiles.save(updated);
      if (!mounted) return;
      setState(() => _profile = updated);
      _snack(done);
    } catch (_) {
      if (mounted) _snack('Profil kaydedilemedi. Mevcut değer korundu.');
    }
  }

  /// Mean -> profile. The profile velocity is the one at the powder
  /// reference temperature, so with a coefficient the mean is taken back to
  /// it; that needs the cartridge temperature of the string.
  Future<void> _applyVelocity(VelocitySeries s, bool metric) async {
    final p = _profile;
    if (p == null) return;
    var f = 1.0;
    final powder = _powder;
    if (_firearm && powder.coef != null && powder.referenceC != null) {
      final t = _ammoC(metric);
      if (t == null) {
        setState(
          () => _actionError =
              'Profilde barut sıcaklık katsayısı var. Hızın ölçüm '
              'sıcaklığına çevrilmesi için mühimmat sıcaklığını girin.',
        );
        return;
      }
      f = PowderTemperature.factor(
        coefPercentPer15C: powder.coef,
        referenceTempC: powder.referenceC,
        todayTempC: t,
      );
    }
    final v = double.parse((s.meanMps / f).toStringAsFixed(1));
    final note = f == 1
        ? ''
        : '\nSeri ortalaması ${_profileFps(s.meanMps)}; profile '
              '${ToolFormat.dec(powder.referenceC!, 1)} °C\'deki hız yazılır.';
    final ok = await _confirm(
      'Profile uygula',
      '${p.name}\nNamlu çıkış hızı: ${_profileFps(p.muzzleVelocityMps)}'
          ' → ${_profileFps(v)}$note',
    );
    if (!ok || !mounted) return;
    final RifleProfile updated;
    try {
      updated = ToolProfileUpdate.apply(p, muzzleVelocityMps: v);
    } on FormatException catch (e) {
      _snack(e.message);
      return;
    }
    await _saveProfile(updated, 'Seri ortalaması profile uygulandı.');
  }

  /// SD -> Pro > Hız farkı (SD), which is in fps; other Pro values stay.
  Future<void> _applySd(double sdMps) async {
    final p = _profile;
    if (p == null) return;
    final text = ToolFormat.dec(UnitSystem.mpsToFps(sdMps), 1);
    ShotSettings? current;
    try {
      current = await _shotStore.load(p.id);
    } catch (_) {
      current = null;
    }
    if (!mounted) return;
    final old = current?.sdText ?? '';
    final ok = await _confirm(
      'WEZ\'e aktar',
      '${p.name}\nHız farkı SD: ${old.isEmpty ? 'boş' : '$old fps'} → '
          '$text fps',
    );
    if (!ok || !mounted) return;
    try {
      await _shotStore.save(
        p.id,
        ShotSettings.fromJson({
          ...(current ?? const ShotSettings()).toJson(),
          'sd': text,
        }),
      );
      ShotSettingsStore.notifyExternalWrite();
      if (mounted) _snack('SD WEZ\'e aktarıldı.');
    } catch (_) {
      if (mounted) _snack('Kaydedilemedi. Mevcut değer korundu.');
    }
  }

  Future<void> _saveSeries(VelocitySeries s, bool metric) async {
    final p = _profile;
    if (p == null) return;
    final t = _ammoC(metric);
    if (t == null) {
      setState(
        () => _actionError =
            'Seriyi kaydetmek için mühimmat sıcaklığını girin; barut '
            'katsayısı sıcaklık farkından bulunur.',
      );
      return;
    }
    final session = ChronoSession(
      date: DateTime.now().toUtc(),
      tempC: t,
      mps: s.mps,
    );
    try {
      await _chrono.add(p.id, session);
      final sessions = await _chrono.load(p.id);
      if (!mounted) return;
      setState(() => _sessions = sessions);
      _snack('Seri kaydedildi.');
    } catch (_) {
      if (mounted) _snack('Seri kaydedilemedi.');
    }
  }

  Future<void> _removeSeries(int index) async {
    final p = _profile;
    if (p == null) return;
    final s = _sessions[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seriyi sil'),
        content: Text(
          '${ToolFormat.dateTime(s.date)} · ${ToolFormat.dec(s.tempC, 1)} °C · '
          '${s.mps.length} atış',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('chrono-session-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _chrono.removeAt(p.id, index);
      final sessions = await _chrono.load(p.id);
      if (mounted) setState(() => _sessions = sessions);
    } catch (_) {
      if (mounted) _snack('Seri silinemedi.');
    }
  }

  ({double coefPercentPer15C, double referenceC, double v0Mps})? get _fit =>
      fitPowderCoefficient([
        for (final s in _sessions)
          (
            tempC: s.tempC,
            meanMps: VelocitySeries(s.mps).meanMps,
            n: s.mps.length,
          ),
      ]);

  Future<void> _applyCoef(
    ({double coefPercentPer15C, double referenceC, double v0Mps}) fit,
  ) async {
    final p = _profile;
    if (p == null) return;
    final k = double.parse(fit.coefPercentPer15C.toStringAsFixed(2));
    final t0 = double.parse(fit.referenceC.toStringAsFixed(1));
    final v0 = double.parse(fit.v0Mps.toStringAsFixed(1));
    String coefText(double? c) =>
        c == null ? 'yok' : '%${ToolFormat.dec(c, 2)} / 15 °C';
    final ok = await _confirm(
      'Profile uygula',
      '${p.name}\n'
          'Barut katsayısı: ${coefText(p.powderTempCoefPercentPer15C)} → '
          '${coefText(k)}\n'
          'Hız ölçüm sıcaklığı: '
          '${p.powderTempReferenceC == null ? 'yok' : '${ToolFormat.dec(p.powderTempReferenceC!, 1)} °C'}'
          ' → ${ToolFormat.dec(t0, 1)} °C\n'
          'Namlu çıkış hızı: ${_profileFps(p.muzzleVelocityMps)} → '
          '${_profileFps(v0)}',
    );
    if (!ok || !mounted) return;
    final RifleProfile updated;
    try {
      updated = ToolProfileUpdate.apply(
        p,
        muzzleVelocityMps: v0,
        powderCoef: k,
        powderReferenceC: t0,
      );
    } on FormatException catch (e) {
      _snack(e.message);
      return;
    }
    await _saveProfile(updated, 'Barut katsayısı profile uygulandı.');
  }

  void _edited() => setState(() => _actionError = null);

  @override
  Widget build(BuildContext context) {
    final metric = AppSettingsScope.metricOf(context);
    final c = MenzilColors.of(context);
    final p = _profile;
    final res = _resolution;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Kronograf'),
      body: MenzilPage(
        children: [
          const MenzilNotice(
            message:
                'Kronografın gösterdiği hızları atış sırasıyla girin. '
                'Ortalama profile, SD WEZ\'e onayınızla aktarılır.',
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(MenzilSpace.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (p == null || res == null)
            const MenzilNotice(
              key: Key('chrono-no-profile'),
              tone: MenzilNoticeTone.warning,
              message:
                  'Aktif profil yok veya katalog kaydı bulunamadı. Önce Profil '
                  'sekmesinde bir profil seçin.',
            )
          else ...[
            MenzilCard(
              child: Text(
                '${p.name}\n'
                '${res.ammunition.displayName}\n'
                'Namlu çıkış hızı: ${_profileFps(p.muzzleVelocityMps)}',
                style: MenzilType.body(c.ink),
              ),
            ),
            ..._inputs(metric),
            ..._results(metric),
            if (_firearm) ..._sessionsSection(),
          ],
        ],
      ),
    );
  }

  List<Widget> _inputs(bool metric) {
    final unitSelect = MenzilSelect<bool>(
      key: const Key('chrono-unit'),
      label: 'Hız birimi',
      info: ChronoFieldInfo.unit,
      initialValue: _fps,
      hint: 'Seçiniz',
      items: const [
        DropdownMenuItem(value: false, child: Text('m/s')),
        DropdownMenuItem(value: true, child: Text('fps')),
      ],
      onChanged: (v) => setState(() {
        _fps = v;
        _actionError = null;
      }),
    );
    return [
      MenzilFieldGrid(
        children: [
          unitSelect,
          if (_firearm)
            MenzilInput(
              key: const Key('chrono-ammo-temp'),
              controller: _ammoTemp,
              label: 'Mühimmat sıcaklığı',
              unit: metric ? '°C' : '°F',
              info: ChronoFieldInfo.ammoTemperature,
              onChanged: (_) => _edited(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
        ],
      ),
      MenzilInput(
        key: const Key('chrono-velocities'),
        controller: _velocities,
        label: 'Hızlar',
        unit: _fps == null ? null : _unit,
        info: ChronoFieldInfo.velocities,
        minLines: 5,
        maxLines: 12,
        keyboardType: TextInputType.multiline,
        onChanged: (_) => _edited(),
      ),
    ];
  }

  List<Widget> _results(bool metric) {
    if (_fps == null && _velocities.text.trim().isNotEmpty) {
      return const [
        MenzilNotice(
          key: Key('chrono-need-unit'),
          tone: MenzilNoticeTone.warning,
          message: 'Hız birimini seçin.',
        ),
      ];
    }
    final parsed = _parse();
    if (parsed.error != null) {
      return [
        MenzilNotice(
          key: const Key('chrono-error'),
          tone: MenzilNoticeTone.warning,
          message: parsed.error!,
        ),
      ];
    }
    final s = parsed.series;
    if (s == null || s.n == 0) return const [];
    final sd = s.sdMps;
    final slope = s.slopeMpsPerShot;
    final showSlope = !_firearm && s.n >= 5 && slope != null;
    return [
      const MenzilSectionHeader(
        'Sonuç',
        padding: EdgeInsets.only(top: MenzilSpace.xs, bottom: MenzilSpace.sm),
      ),
      MenzilMetricGrid(
        key: const Key('chrono-result'),
        columns: 2,
        metrics: [
          MenzilMetric('Ortalama', _speed(s.meanMps), _unit),
          MenzilMetric(
            'SD',
            sd == null ? '–' : _speed(sd, fpsDigits: 1),
            sd == null ? null : _unit,
          ),
          MenzilMetric('ES', _speed(s.esMps), _unit),
          MenzilMetric('Atış sayısı', '${s.n}'),
          if (showSlope) ...[
            MenzilMetric(
              'Dizi eğimi',
              _signed(slope, digits: 1),
              '$_unit/atış',
            ),
            MenzilMetric(
              'Dizide değişim',
              _signed(slope * (s.n - 1), digits: _fps == true ? 0 : 1),
              _unit,
            ),
          ],
        ],
      ),
      if (s.n < 3)
        const MenzilNotice(
          key: Key('chrono-need-three'),
          message: 'SD ve aktarım için en az 3 atış girin.',
        ),
      if (_actionError != null)
        MenzilNotice(
          key: const Key('chrono-error'),
          tone: MenzilNoticeTone.warning,
          message: _actionError!,
        ),
      if (s.n >= 3) ...[
        MenzilSecondaryButton(
          key: const Key('chrono-apply-velocity'),
          label: 'Profile hız olarak aktar',
          icon: Icons.save_alt,
          expand: true,
          onPressed: () => _applyVelocity(s, metric),
        ),
        const SizedBox(height: MenzilSpace.sm),
        MenzilSecondaryButton(
          key: const Key('chrono-apply-sd'),
          label: 'SD\'yi WEZ\'e aktar',
          icon: Icons.track_changes_outlined,
          expand: true,
          onPressed: () => _applySd(sd!),
        ),
        if (_firearm) ...[
          const SizedBox(height: MenzilSpace.sm),
          MenzilSecondaryButton(
            key: const Key('chrono-save-series'),
            label: 'Seriyi kaydet',
            icon: Icons.playlist_add,
            expand: true,
            onPressed: () => _saveSeries(s, metric),
          ),
        ],
      ],
    ];
  }

  /// A change with its sign in the chosen unit ("−2,3").
  String _signed(double mps, {required int digits}) {
    final v = _fps == true ? UnitSystem.mpsToFps(mps) : mps;
    final text = ToolFormat.dec(v.abs(), digits);
    if (text == ToolFormat.dec(0, digits)) return text;
    return '${v < 0 ? '−' : '+'}$text';
  }

  List<Widget> _sessionsSection() {
    if (_sessions.isEmpty) return const [];
    final c = MenzilColors.of(context);
    final fit = _fit;
    return [
      const MenzilSectionHeader(
        'Kayıtlı seriler',
        padding: EdgeInsets.only(top: MenzilSpace.md, bottom: MenzilSpace.sm),
      ),
      MenzilCard(
        key: const Key('chrono-sessions'),
        child: Column(
          children: [
            for (var i = 0; i < _sessions.length; i++)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${ToolFormat.dateTime(_sessions[i].date)} · '
                      '${ToolFormat.dec(_sessions[i].tempC, 1)} °C · '
                      '${_sessions[i].mps.length} atış · '
                      '${_profileFps(VelocitySeries(_sessions[i].mps).meanMps)}',
                      style: MenzilType.body(c.ink),
                    ),
                  ),
                  IconButton(
                    key: Key('chrono-session-delete-$i'),
                    tooltip: 'Seriyi sil',
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeSeries(i),
                  ),
                ],
              ),
          ],
        ),
      ),
      if (fit == null)
        MenzilNotice(
          key: const Key('chrono-fit-missing'),
          message: _sessions.length < 2
              ? 'Barut katsayısı için en az 10 °C farklı bir sıcaklıkta bir '
                    'seri daha kaydedin.'
              : 'Barut katsayısı bulunamadı: seriler en az 10 °C farklı '
                    'sıcaklıkta olmalı ve sonuç ±10 %/15 °C içinde kalmalı.',
        )
      else ...[
        MenzilMetricGrid(
          key: const Key('chrono-fit'),
          columns: 2,
          metrics: [
            MenzilMetric(
              'Barut katsayısı',
              ToolFormat.dec(fit.coefPercentPer15C, 1),
              '%/15 °C',
            ),
            MenzilMetric(
              'Ölçüm sıcaklığı',
              ToolFormat.dec(fit.referenceC, 1),
              '°C',
            ),
          ],
        ),
        MenzilSecondaryButton(
          key: const Key('chrono-apply-coef'),
          label: 'Katsayıyı profile aktar',
          icon: Icons.save_alt,
          expand: true,
          onPressed: () => _applyCoef(fit),
        ),
      ],
    ];
  }
}
