import 'package:flutter/material.dart';

import '../../core/ballistic_input.dart';
import '../../core/mpbr.dart';
import '../../data/profile_catalog_integrity.dart';
import '../../models/domain.dart';
import '../../services/active_profile_store.dart';
import '../../services/profile_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'tool_support.dart';

/// ⓘ texts of the Avcı Sıfırı page (owner rule, 2026-10-07).
abstract final class MpbrFieldInfo {
  static const zone =
      'Vurmak istediğiniz bölgenin çapı. Uygulama, yörüngenin bu bölgeden '
      'çıkmadığı en uzun menzili ve sıfır mesafesini bulur; bu aralıkta '
      'tutuş gerekmez. Hesap profil hızı ve standart havayla yapılır. '
      'Örnek: domuz için 15 cm, PCP saçmayla küçük av için 2,5 cm.';
}

/// Ö7 Avcı Sıfırı (maximum point-blank range): for a chosen target zone the
/// zero range that gives the longest no-hold distance ([Mpbr]). Shown as a
/// suggestion; the profile is never written.
class MpbrScreen extends StatefulWidget {
  final ProfileStore? profileStore;
  final ActiveProfileStore? activeProfileStore;

  const MpbrScreen({super.key, this.profileStore, this.activeProfileStore});

  @override
  State<MpbrScreen> createState() => _MpbrScreenState();
}

class _MpbrScreenState extends State<MpbrScreen> {
  /// The zero is always solved in ICAO air (ballistic_input.dart); the
  /// suggestion uses the same air for the shot so it is a property of the
  /// rifle and load, not of today's weather.
  static const _icao = EnvironmentData(humidityPercent: 0);

  bool _loading = true;
  RifleProfile? _profile;
  ProfileCatalogResolution? _resolution;
  double? _zoneCm;
  MpbrResult? _result;
  bool _none = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    RifleProfile? p;
    try {
      final id =
          await (widget.activeProfileStore ?? PersistentActiveProfileStore())
              .getActiveProfileId();
      if (id != null) {
        for (final x
            in await (widget.profileStore ?? PersistentProfileStore()).all()) {
          if (x.id == id) p = x;
        }
      }
    } catch (_) {
      p = null;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _profile = p;
      _resolution = p == null
          ? null
          : const ProfileCatalogIntegrity().resolve(p);
    });
  }

  void _compute(double? zoneCm) {
    final p = _profile, res = _resolution;
    MpbrResult? r;
    if (p != null && res != null && zoneCm != null) {
      final ammo = res.ammunition;
      r = Mpbr.solve(
        build: (zeroM, ranges) => BallisticInput(
          muzzleVelocityMps: p.muzzleVelocityMps,
          grain: ammo.grain,
          zeroRangeM: zeroM,
          sightHeightMm: p.sightHeightMm,
          rangesM: ranges,
          environment: _icao,
          ballisticCoefficient: ammo.ballisticCoefficient,
          ballisticModel: ammo.ballisticModel,
          bcBands: ammo.bcBands,
          dragTable: ammo.dragTable,
        ),
        zoneDiameterM: zoneCm / 100,
        grid: res.rifle.platform == WeaponPlatform.pcp
            ? MpbrGrid.pcp
            : MpbrGrid.firearm,
      );
    }
    setState(() {
      _zoneCm = zoneCm;
      _result = r;
      _none = zoneCm != null && r == null;
    });
  }

  static String _cm(double v) => ToolFormat.dec(v, v % 1 == 0 ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final r = _result;
    final u = p?.distanceUnit ?? DistanceUnit.meter;
    final unit = u.symbol;
    String round(double m) => u.fromMeters(m).round().toString();
    String up(double m) => u.fromMeters(m).ceil().toString();
    String down(double m) => u.fromMeters(m).floor().toString();

    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Avcı Sıfırı'),
      body: MenzilPage(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(MenzilSpace.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (p == null || _resolution == null)
            const MenzilNotice(
              key: Key('mpbr-no-profile'),
              tone: MenzilNoticeTone.warning,
              message:
                  'Aktif profil yok veya katalog kaydı bulunamadı. Önce Profil '
                  'sekmesinde bir profil seçin.',
            )
          else ...[
            const MenzilSectionHeader(
              '1 · Hedef bölge',
              padding: EdgeInsets.only(bottom: MenzilSpace.sm),
            ),
            MenzilSelect<double>(
              key: const Key('mpbr-zone'),
              label: 'Hedef bölge çapı',
              info: MpbrFieldInfo.zone,
              initialValue: _zoneCm,
              items: [
                for (final d in Mpbr.zoneDiametersCm)
                  DropdownMenuItem(value: d, child: Text('${_cm(d)} cm')),
              ],
              onChanged: _compute,
            ),
            if (r != null) ...[
              const MenzilSectionHeader(
                '2 · Öneri',
                padding: EdgeInsets.only(
                  top: MenzilSpace.md,
                  bottom: MenzilSpace.sm,
                ),
              ),
              MenzilMetricGrid(
                key: const Key('mpbr-result'),
                columns: 2,
                metrics: [
                  MenzilMetric('Sıfır mesafesi', round(r.zeroM), unit),
                  if (r.nearZeroM != null)
                    MenzilMetric('Yakın kesişim', round(r.nearZeroM!), unit),
                  MenzilMetric(
                    'Tutuşsuz aralık',
                    '${up(r.nearM)}–${down(r.farM)}',
                    unit,
                  ),
                ],
              ),
              Text(
                'Sıfır ${round(r.zeroM)} $unit: ${up(r.nearM)}–${down(r.farM)} '
                '$unit arası tutuşsuz.',
                key: const Key('mpbr-line'),
                style: MenzilType.body(MenzilColors.of(context).cyanInk),
              ),
              const SizedBox(height: MenzilSpace.sm),
              MenzilNotice(
                key: const Key('mpbr-profile-zero'),
                message:
                    'Öneridir; profil değişmez. Profilinizdeki sıfır: '
                    '${round(p.zeroRangeM)} $unit.',
              ),
            ],
            if (_none)
              const MenzilNotice(
                key: Key('mpbr-none'),
                tone: MenzilNoticeTone.warning,
                message: 'Bu bölge çapında tutuşsuz menzil bulunamadı.',
              ),
          ],
        ],
      ),
    );
  }
}
