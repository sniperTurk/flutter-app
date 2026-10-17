part of 'profiles_screen.dart';

// Active-profile summary on the Profil page (moved out of
// profiles_screen.dart, behaviour unchanged).

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
        // Three cards (owner, 2026-10-13), each led by its marka and model
        // on one line. No section titles above them (owner, 2026-10-17):
        // the lead label names the card ("Tüfek Marka/Model", ...), and the
        // cards are spaced by MenzilSpace.lg, the gap above the first card.
        MenzilMetricGrid(
          key: const Key('profile-summary-rifle'),
          columns: 2,
          twoLineText: true,
          plain: true,
          lead: rifle == null
              ? null
              : MenzilMetric(
                  'Tüfek Marka/Model',
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
        const SizedBox(height: MenzilSpace.lg),
        MenzilMetricGrid(
          key: const Key('profile-summary-scope'),
          columns: 2,
          twoLineText: true,
          plain: true,
          // Marka, model and the scope's data on one line (owner,
          // 2026-10-13), e.g. "Barska … 6-36 x 56 FFP · MRAD".
          lead: MenzilMetric(
            'Dürbün Marka/Model',
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
        const SizedBox(height: MenzilSpace.lg),
        MenzilMetricGrid(
          key: const Key('profile-summary-ammo'),
          columns: 2,
          twoLineText: true,
          plain: true,
          lead: ammo == null
              ? null
              : MenzilMetric(
                  'Mühimmat Marka/Model',
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
            onPressed: onContinue,
          ),
        ],
      ],
    );
  }
}
