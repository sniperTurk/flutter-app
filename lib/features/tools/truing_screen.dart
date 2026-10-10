import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ballistic_input.dart';
import '../../core/gravity.dart';
import '../../core/powder_temperature.dart';
import '../../core/unit_system.dart';
import '../../core/velocity_truing.dart';
import '../../data/catalog_repository.dart';
import '../../data/profile_catalog_integrity.dart';
import '../../data/user_catalog.dart';
import '../../models/domain.dart';
import '../../services/active_profile_store.dart';
import '../../services/app_settings.dart';
import '../../services/manual_catalog_store.dart';
import '../../services/profile_store.dart';
import '../../services/shot_settings_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import '../ballistics/environment_field_info.dart';
import 'tool_support.dart';

/// ⓘ texts of the Hız Doğrulama page (owner rule: every entered value is
/// explained).
abstract final class TruingFieldInfo {
  static const range =
      'Doğrulama atışını yaptığınız hedefin mesafesi; telemetre ile ölçün. '
      'Sıfır mesafesinden belirgin uzak olmalı: düşüm ne kadar büyükse hız '
      'o kadar iyi bulunur. Örnek: PCP için 75–100 m, ateşli için 500–800 m.';
  static const mode =
      'Namlu çıkış hızı: sıfırdan biraz uzak, orta bir mesafede (PCP 50–75 m, '
      'ateşli 300–500 m) ölçün; ilk adım budur. Balistik katsayı (BC): hız '
      'doğrulandıktan sonra, en uzak mesafede (PCP 100 m+, ateşli 700 m+) '
      'ölçün; uzak mesafedeki düşüşü asıl hava direnci belirler.';
  static const observed =
      'Grubu hedefin tam ortasına getiren, kuleden çevirdiğiniz yükseliş '
      'düzeltmesi (sıfırdan itibaren, yukarı pozitif). Tık sayısını tık '
      'değeriyle çarpın: 0,1 MRAD dürbünde 42 tık = 4,2 MRAD. Tek atışla '
      'değil, en az 3–5 atışlık grubun ortasıyla ölçün.';
}

/// Hız Doğrulama (truing): the shooter fires at a known range beyond the
/// zero, enters the elevation that actually centred the group and today's
/// atmosphere, and the page finds the muzzle velocity that makes the solver
/// agree ([MuzzleVelocityTruing]). Nothing is written to the profile before
/// an explicit old -> new confirmation.
class TruingScreen extends StatefulWidget {
  /// Injected in tests; default to the persistent stores.
  final ProfileStore? profileStore;
  final ActiveProfileStore? activeProfileStore;
  const TruingScreen({super.key, this.profileStore, this.activeProfileStore});

  @override
  State<TruingScreen> createState() => _TruingScreenState();
}

class _TruingScreenState extends State<TruingScreen> {
  late final ProfileStore _profiles =
      widget.profileStore ?? PersistentProfileStore();
  late final ActiveProfileStore _activeStore =
      widget.activeProfileStore ?? PersistentActiveProfileStore();

  final _range = TextEditingController();
  final _observed = TextEditingController();
  final _temperature = TextEditingController();
  final _pressure = TextEditingController();
  final _humidity = TextEditingController(text: '50');

  bool _loading = true;
  bool _metricApplied = false;
  RifleProfile? _profile;
  ProfileCatalogResolution? _resolution;
  TruingResult? _result;
  BcTruingResult? _bcResult;

  /// Pro Ayarlar of the profile (powder temperature data, firearms).
  ShotSettings? _shotSettings;

  /// Today's / reference velocity from the powder temperature model; 1 when
  /// it does not apply. Set by the last computation.
  double _powderFactor = 1;

  /// What the observation trues: muzzle velocity (first step) or the BC at
  /// a far range (second step, owner 2026-10-09).
  bool _trueBc = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadActiveProfile());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_metricApplied) return;
    _metricApplied = true;
    final metric = AppSettingsScope.metricOf(context);
    _temperature.text = metric ? '15' : '59';
    _pressure.text = metric ? '1013,25' : '29,92';
  }

  @override
  void dispose() {
    _range.dispose();
    _observed.dispose();
    _temperature.dispose();
    _pressure.dispose();
    _humidity.dispose();
    super.dispose();
  }

  Future<void> _loadActiveProfile() async {
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
    if (!mounted) return;
    if (profile != null) unawaited(_loadShotSettings(profile.id));
    setState(() {
      _loading = false;
      _profile = profile;
      _resolution = profile == null
          ? null
          : const ProfileCatalogIntegrity().resolve(profile);
    });
  }

  /// Powder temperature data from Pro Ayarlar; loaded in the background so
  /// the page never waits on storage.
  Future<void> _loadShotSettings(String profileId) async {
    try {
      final shot = await const ShotSettingsStore().load(profileId);
      if (mounted) _shotSettings = shot;
    } catch (_) {
      // No storage: powder temperature is simply not applied.
    }
  }

  /// Namlu çıkış hızı is always shown in fps, as on Profil (owner rule).
  static String _fps(double mps) =>
      '${UnitSystem.mpsToFps(mps).toStringAsFixed(0)} fps';

  static double? _parse(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    return v != null && v.isFinite ? v : null;
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  static double? _num(String? text) {
    final v = double.tryParse((text ?? '').trim().replaceAll(',', '.'));
    return v != null && v.isFinite ? v : null;
  }

  /// Pro "Kule ölçek katsayısı", same rule as Atış; 1 when empty.
  static double _turretScale(ShotSettings? shot) {
    final v = _num(shot?.turretScaleText);
    return v != null && v >= 0.8 && v <= 1.2 ? v : 1.0;
  }

  /// Pro "Sıfır ofseti" upward part in mrad, same rule as Atış.
  static double _zeroUpMrad(ShotSettings? shot, double zeroM, bool metric) {
    final v = _num(shot?.zeroUpText);
    if (zeroM <= 0 || v == null || v.abs() > 100) return 0;
    final m = metric ? v / 100 : UnitSystem.inchesToMillimeters(v) / 1000;
    return math.atan(m / zeroM) * 1000;
  }

  /// Pro "Yerçekimi", same rule as Atış; standard when off.
  static double _gravity(ShotSettings? shot) {
    if (shot == null || !shot.gravityOn) return Gravity.standard;
    final v = _num(shot.gravityText);
    return v != null && v >= 9.7 && v <= 9.9 ? v : Gravity.standard;
  }

  void _compute(bool metric) {
    final p = _profile, res = _resolution;
    if (p == null || res == null) return;
    final ammo = res.ammunition;
    final rangeShown = _parse(_range);
    final observedShown = _parse(_observed);
    final t = _parse(_temperature);
    final pr = _parse(_pressure);
    final h = _parse(_humidity);
    if (rangeShown == null || rangeShown <= 0) {
      _fail('Geçerli bir doğrulama mesafesi girin.');
      return;
    }
    if (observedShown == null) {
      _fail('Gözlenen düzeltmeyi girin.');
      return;
    }
    if (t == null || pr == null || pr <= 0 || h == null || h < 0 || h > 100) {
      _fail('Atmosfer alanlarını kontrol edin; nem %0–100 olmalı.');
      return;
    }
    final todayC = metric ? t : UnitSystem.fahrenheitToCelsius(t);
    // Same powder temperature model as Atış: the profile velocity is the
    // one at the reference temperature (firearms only).
    final shot = _shotSettings;
    final f = res.rifle.platform == WeaponPlatform.firearm && shot != null
        ? PowderTemperature.factor(
            coefPercentPer15C: double.tryParse(
              shot.powderCoefText.trim().replaceAll(',', '.'),
            ),
            referenceTempC: double.tryParse(
              shot.powderTempText.trim().replaceAll(',', '.'),
            ),
            todayTempC: todayC,
          )
        : 1.0;
    final BallisticInput base;
    try {
      base = BallisticInput(
        muzzleVelocityMps: p.muzzleVelocityMps * f,
        zeroMuzzleVelocityMps: f == 1 ? null : p.muzzleVelocityMps,
        grain: ammo.grain,
        zeroRangeM: p.zeroRangeM,
        sightHeightMm: p.sightHeightMm,
        rangesM: [p.zeroRangeM],
        environment: EnvironmentData(
          temperatureC: todayC,
          pressureHpa: metric ? pr : UnitSystem.inHgToHpa(pr),
          humidityPercent: h,
        ),
        ballisticCoefficient: ammo.ballisticCoefficient,
        ballisticModel: ammo.ballisticModel,
        bcBands: ammo.bcBands,
        dragTable: ammo.dragTable,
        gravityMps2: _gravity(shot),
      );
    } on ArgumentError {
      _fail('Atmosfer değerleri geçerli aralığın dışında.');
      return;
    }
    try {
      final rangeM = p.distanceUnit.toMeters(rangeShown);
      // The shooter enters what the turret showed. Atış dials
      // (true − zero offset) / turret scale, so the true correction the
      // solver must match is dialled × scale + zero offset (audit
      // 2026-10-11). Truing is done in calm air, so there is no
      // aerodynamic jump to add.
      final observedMrad =
          p.angularUnit.toMrad(observedShown) * _turretScale(shot) +
          _zeroUpMrad(shot, p.zeroRangeM, metric);
      if (_trueBc) {
        final r = BallisticCoefficientTruing.solve(
          base: base,
          rangeM: rangeM,
          observedCorrectionMrad: observedMrad,
        );
        setState(() {
          _bcResult = r;
          _result = null;
          _error = null;
        });
      } else {
        final today = MuzzleVelocityTruing.solve(
          base: base,
          rangeM: rangeM,
          observedCorrectionMrad: observedMrad,
        );
        // Back to the reference temperature: that is what the profile
        // stores and what Atış scales again.
        final result = f == 1
            ? today
            : TruingResult(
                baseMps: p.muzzleVelocityMps,
                truedMps: double.parse((today.truedMps / f).toStringAsFixed(1)),
                rangeM: today.rangeM,
                predictedMrad: today.predictedMrad,
                observedMrad: today.observedMrad,
                truedPredictedMrad: today.truedPredictedMrad,
              );
        setState(() {
          _powderFactor = f;
          _result = result;
          _bcResult = null;
          _error = null;
        });
      }
    } on TruingFailure catch (f) {
      _fail(f.message);
    } on ArgumentError {
      _fail('Mesafe geçerli aralığın dışında.');
    }
  }

  void _fail(String message) => setState(() {
    _result = null;
    _bcResult = null;
    _error = message;
  });

  /// Writes the trued BC into the personal ammunition record (catalog
  /// records are never edited), after an old -> new confirmation.
  Future<void> _applyBc(BcTruingResult r) async {
    final res = _resolution;
    if (res == null) return;
    final ammo = res.ammunition;
    if (!ammo.userEntered) {
      _snack(
        'Bu mühimmat katalog kaydı; BC değiştirilemez. Profilde kendi '
        'mühimmatınızı girin.',
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mühimmata uygula'),
        content: Text(
          '${ammo.displayName}\n'
          'BC: ${r.baseBc} → ${r.truedBc} '
          '(${ammo.ballisticModel?.name.toUpperCase() ?? ''})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('truing-bc-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final store = ManualCatalogStore();
      final entries = await store.all();
      final entry = entries.where((e) => e['id'] == ammo.id).firstOrNull;
      if (entry == null) throw StateError('record missing');
      // Speed bands carry the drag whenever they exist, so they scale with
      // the main BC (the same rule as BallisticInput.withBallisticCoefficient);
      // otherwise the trued BC would change nothing (audit 2026-10-11).
      final ratio = r.truedBc / r.baseBc;
      final bands = entry['bcBands'];
      await store.upsert({
        ...entry,
        'bc': r.truedBc,
        if (bands is List)
          'bcBands': [
            for (final b in bands)
              if (b is Map) {...b, 'bc': (b['bc'] as num) * ratio} else b,
          ],
      });
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries(await store.all()),
      );
      if (!mounted) return;
      setState(() {
        _resolution = const ProfileCatalogIntegrity().resolve(_profile!);
        _bcResult = null;
      });
      _snack('Doğrulanmış BC mühimmata uygulandı.');
    } catch (_) {
      if (mounted) _snack('Mühimmat kaydedilemedi. Mevcut BC korundu.');
    }
  }

  Future<void> _apply(TruingResult r, bool metric) async {
    final p = _profile;
    if (p == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile uygula'),
        content: Text(
          '${p.name}\n'
          'Namlu çıkış hızı: ${_fps(p.muzzleVelocityMps)}'
          ' → ${_fps(r.truedMps)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('truing-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final RifleProfile updated;
    try {
      updated = ToolProfileUpdate.apply(p, muzzleVelocityMps: r.truedMps);
    } on FormatException catch (e) {
      _snack(e.message);
      return;
    }
    try {
      await _profiles.save(updated);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _result = null;
      });
      _snack('Doğrulanmış hız profile uygulandı.');
    } catch (_) {
      if (mounted) _snack('Profil kaydedilemedi. Mevcut değer korundu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final metric = AppSettingsScope.metricOf(context);
    final c = MenzilColors.of(context);
    final p = _profile;
    final res = _resolution;
    final bcMissing =
        res != null &&
        (res.ammunition.ballisticCoefficient == null ||
            res.ammunition.ballisticModel == null);

    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Hız Doğrulama'),
      body: MenzilPage(
        children: [
          MenzilNotice(
            message:
                'Sıfır mesafesinden uzak, bilinen bir mesafede grup atın. '
                'Grubu ortaya getiren gerçek düzeltmeyi girin; uygulama, '
                'hesabın bu sonuca uyması için gereken '
                '${_trueBc ? 'balistik katsayıyı bulur. Namlu çıkış hızı değiştirilmez.' : 'namlu çıkış hızını bulur. Balistik katsayı değiştirilmez.'}',
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(MenzilSpace.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (p == null || res == null)
            const MenzilNotice(
              key: Key('truing-no-profile'),
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
                'Namlu çıkış hızı: ${_fps(p.muzzleVelocityMps)}'
                ' · Sıfır: ${ToolFormat.dec(p.distanceUnit.fromMeters(p.zeroRangeM), 0)} ${p.distanceUnit.symbol}',
                style: MenzilType.body(c.ink),
              ),
            ),
            if (bcMissing)
              const MenzilNotice(
                key: Key('truing-no-bc'),
                tone: MenzilNoticeTone.warning,
                message:
                    'Bu mühimmatta balistik katsayı (BC) ve model yok. Hava '
                    'direnci hesaba girmeden yapılan doğrulama yanıltıcı olur; '
                    'önce mühimmata BC girin.',
              )
            else ...[
              MenzilSelect<bool>(
                key: ValueKey('truing-mode-$_trueBc'),
                label: 'Doğrulanacak değer',
                info: TruingFieldInfo.mode,
                initialValue: _trueBc,
                items: const [
                  DropdownMenuItem(
                    value: false,
                    child: Text('Namlu çıkış hızı'),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text('Balistik katsayı (BC)'),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _trueBc = v ?? false;
                  _result = null;
                  _bcResult = null;
                  _error = null;
                }),
              ),
              const MenzilSectionHeader(
                '1 · Gözlem',
                padding: EdgeInsets.only(bottom: MenzilSpace.sm),
              ),
              MenzilFieldGrid(
                children: [
                  MenzilInput(
                    key: const Key('truing-range'),
                    controller: _range,
                    label: 'Mesafe',
                    unit: p.distanceUnit.symbol,
                    info: TruingFieldInfo.range,
                  ),
                  MenzilInput(
                    key: const Key('truing-observed'),
                    controller: _observed,
                    label: 'Gerçek düzeltme',
                    unit: p.angularUnit.label,
                    info: TruingFieldInfo.observed,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ],
              ),
              const MenzilSectionHeader(
                '2 · Atış anındaki hava',
                padding: EdgeInsets.only(bottom: MenzilSpace.sm),
              ),
              MenzilFieldGrid(
                children: [
                  MenzilInput(
                    key: const Key('truing-temperature'),
                    controller: _temperature,
                    label: 'Sıcaklık',
                    unit: metric ? '°C' : '°F',
                    info: EnvironmentFieldInfo.temperature,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                  MenzilInput(
                    key: const Key('truing-pressure'),
                    controller: _pressure,
                    label: 'Basınç',
                    unit: metric ? 'hPa' : 'inHg',
                    info: EnvironmentFieldInfo.pressure,
                  ),
                  MenzilInput(
                    key: const Key('truing-humidity'),
                    controller: _humidity,
                    label: 'Nem',
                    unit: '%',
                    info: EnvironmentFieldInfo.humidity,
                  ),
                ],
              ),
              MenzilPrimaryButton(
                key: const Key('truing-compute'),
                label: _trueBc ? 'BC\'yi hesapla' : 'Hızı hesapla',
                icon: Icons.tune,
                onPressed: () => _compute(metric),
              ),
              if (_error != null)
                MenzilNotice(
                  key: const Key('truing-error'),
                  tone: MenzilNoticeTone.warning,
                  message: _error!,
                ),
              if (_result != null) ..._resultSection(_result!, p, metric),
              if (_bcResult != null) ..._bcResultSection(_bcResult!, p),
            ],
          ],
        ],
      ),
    );
  }

  List<Widget> _bcResultSection(BcTruingResult r, RifleProfile p) {
    final u = p.angularUnit;
    String angle(double mrad) => ToolFormat.dec(u.fromMrad(mrad), 2);
    final sign = r.changePercent >= 0 ? '+' : '−';
    return [
      const MenzilSectionHeader(
        '3 · Sonuç',
        padding: EdgeInsets.only(top: MenzilSpace.md, bottom: MenzilSpace.sm),
      ),
      MenzilMetricGrid(
        key: const Key('truing-bc-result'),
        columns: 2,
        metrics: [
          MenzilMetric('Hesaplanan', angle(r.predictedMrad), u.label),
          MenzilMetric('Gözlenen', angle(r.observedMrad), u.label),
          MenzilMetric('Mühimmat BC', r.baseBc.toString()),
          MenzilMetric('Doğrulanmış BC', r.truedBc.toString()),
          MenzilMetric(
            'Değişim',
            '$sign${ToolFormat.dec(r.changePercent.abs(), 1)}',
            '%',
          ),
          MenzilMetric('Kalan fark', angle(r.residualMrad.abs()), u.label),
        ],
      ),
      if (r.changePercent.abs() > 10)
        const MenzilNotice(
          tone: MenzilNoticeTone.warning,
          message:
              '%10’dan büyük bir değişim. Önce hızı orta mesafede doğruladığınızdan '
              've ölçümün doğru olduğundan emin olun.',
        ),
      MenzilSecondaryButton(
        key: const Key('truing-bc-apply'),
        label: 'Doğrulanmış BC\'yi mühimmata uygula',
        icon: Icons.save_alt,
        onPressed: () => _applyBc(r),
      ),
    ];
  }

  List<Widget> _resultSection(TruingResult r, RifleProfile p, bool metric) {
    final u = p.angularUnit;
    String angle(double mrad) => ToolFormat.dec(u.fromMrad(mrad), 2);
    final sign = r.changeMps >= 0 ? '+' : '−';
    return [
      const MenzilSectionHeader(
        '3 · Sonuç',
        padding: EdgeInsets.only(top: MenzilSpace.md, bottom: MenzilSpace.sm),
      ),
      MenzilMetricGrid(
        key: const Key('truing-result'),
        columns: 2,
        metrics: [
          MenzilMetric('Hesaplanan', angle(r.predictedMrad), u.label),
          MenzilMetric('Gözlenen', angle(r.observedMrad), u.label),
          MenzilMetric('Profil hızı', _fps(r.baseMps)),
          MenzilMetric('Doğrulanmış hız', _fps(r.truedMps)),
          MenzilMetric(
            'Değişim',
            '$sign${ToolFormat.dec(r.changePercent.abs(), 1)}',
            '%',
          ),
          MenzilMetric('Kalan fark', angle(r.residualMrad.abs()), u.label),
        ],
      ),
      if (_powderFactor != 1)
        MenzilNotice(
          key: const Key('truing-powder-note'),
          tone: MenzilNoticeTone.info,
          message:
              'Barut sıcaklığı hesaba katıldı (Pro Ayarlar). Bugünkü hız '
              '${_fps(r.truedMps * _powderFactor)}; profile, ölçüm '
              'sıcaklığındaki hız (${_fps(r.truedMps)}) yazılır.',
        ),
      if (r.changePercent.abs() > 5)
        const MenzilNotice(
          tone: MenzilNoticeTone.warning,
          message:
              '%5’ten büyük bir değişim. Kronografla hızı ölçmek, sıfırı ve '
              'dürbün yüksekliğini kontrol etmek iyi olur.',
        ),
      MenzilSecondaryButton(
        key: const Key('truing-apply'),
        label: 'Doğrulanmış hızı profile uygula',
        icon: Icons.save_alt,
        onPressed: () => _apply(r, metric),
      ),
    ];
  }
}
