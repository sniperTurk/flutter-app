import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/profile_catalog_integrity.dart';
import '../../models/domain.dart';
import '../../services/active_profile_store.dart';
import '../../services/profile_store.dart';
import '../../services/shot_settings_store.dart';
import '../../tools/domain/group_center.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'tool_support.dart';

/// ⓘ texts of the Sıfır Grubu page (owner rule: every entered value is
/// explained).
abstract final class ZeroGroupFieldInfo {
  static const range =
      'Grubu attığınız hedefin mesafesi; profilin sıfır mesafesiyle dolu '
      'gelir. Başka mesafede attıysanız telemetreyle ölçüp yazın; sonuç sıfır '
      'mesafesine açıyla çevrilir. Örnek: 100 m.';
  static const grid =
      'Hedef kâğıdındaki bir karenin kenarı. Kareli kâğıdın kenarında veya '
      'paketinde yazar. Ekrandaki hedef 10×10 karedir; vuruşları kâğıttaki '
      'kareye göre aynı yere dokunarak işaretleyin. Örnek: 2,5 cm.';
  static const target =
      'Ekrandaki artı nişan aldığınız noktadır. Kâğıttaki her deliği, artıya '
      'göre aynı kare konumuna dokunarak işaretleyin. Yanlış dokunuşu “Son '
      'vuruşu sil” ile geri alın. Örnek: artının 2 kare sağı, 1 kare üstü.';
}

/// Ö10 Sıfır grubu: holes are marked by tapping a squared target; the page
/// shows the group centre, sigma and the centre's uncertainty (sigma/√n)
/// and how many more shots bring it under one click. The centre goes to
/// Pro "Sıfır ofseti" only after an explicit old -> new confirmation.
class ZeroGroupScreen extends StatefulWidget {
  final ProfileStore? profileStore;
  final ActiveProfileStore? activeProfileStore;
  const ZeroGroupScreen({
    super.key,
    this.profileStore,
    this.activeProfileStore,
  });

  @override
  State<ZeroGroupScreen> createState() => _ZeroGroupScreenState();
}

class _ZeroGroupScreenState extends State<ZeroGroupScreen> {
  static const _gridSizes = <double>[1, 2.5, 5];
  static const _squares = 10;

  final _range = TextEditingController();
  bool _loading = true;
  RifleProfile? _profile;
  ScopeOptic? _scope;
  double? _gridCm;

  /// Taps in squares from the aim point (+ = right / up).
  final List<Offset> _taps = [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _range.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await loadActiveToolProfile(
      widget.profileStore ?? PersistentProfileStore(),
      widget.activeProfileStore ?? PersistentActiveProfileStore(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _profile = p;
      _scope = p == null
          ? null
          : const ProfileCatalogIntegrity().resolve(p)?.scope;
      if (p != null) _range.text = ToolFormat.dec(p.zeroRangeM, 0);
    });
  }

  double? get _rangeM {
    final v = double.tryParse(_range.text.trim().replaceAll(',', '.'));
    return v != null && v.isFinite && v > 0 && v <= 3000 ? v : null;
  }

  /// One click of the profile's scope in mrad; the unit's common click when
  /// the scope is not in the catalogue.
  double get _clickMrad {
    final s = _scope;
    if (s != null && s.clickValue > 0) return s.clickUnit.toMrad(s.clickValue);
    final u = _profile?.angularUnit ?? AngularUnit.mrad;
    return u.toMrad(u.standardClick);
  }

  GroupStats? get _stats {
    final g = _gridCm;
    if (g == null) return null;
    return GroupCenter.compute([
      for (final t in _taps) ImpactPoint(t.dx * g, t.dy * g),
    ]);
  }

  void _tap(Offset local, Size size) {
    final x = (local.dx - size.width / 2) / (size.width / _squares);
    final y = (size.height / 2 - local.dy) / (size.height / _squares);
    setState(() => _taps.add(Offset(x, y)));
  }

  Future<void> _apply(GroupStats s, double rangeM) async {
    final profile = _profile!;
    const store = ShotSettingsStore();
    final up = GroupCenter.toZeroRangeCm(
      cm: s.centerUpCm,
      rangeM: rangeM,
      zeroRangeM: profile.zeroRangeM,
    );
    final right = GroupCenter.toZeroRangeCm(
      cm: s.centerRightCm,
      rangeM: rangeM,
      zeroRangeM: profile.zeroRangeM,
    );
    final upText = ToolFormat.dec(up, 1);
    final rightText = ToolFormat.dec(right, 1);
    String old(String t) => t.isEmpty ? 'boş' : '$t cm';
    final current = await store.load(profile.id).catchError((Object _) => null);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sıfır ofsetine aktar'),
        content: Text(
          '${profile.name}, sıfır ${ToolFormat.dec(profile.zeroRangeM, 0)} m\n'
          'Yukarı: ${old(current?.zeroUpText ?? '')} → $upText cm\n'
          'Sağa: ${old(current?.zeroRightText ?? '')} → $rightText cm',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await store.updateZeroOffset(
        profile.id,
        upText: upText,
        rightText: rightText,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sıfır ofseti güncellendi.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sıfır ofseti kaydedilemedi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Sıfır Grubu'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? const MenzilStateMessage(
              key: Key('zg-no-profile'),
              icon: Icons.person_outline,
              message: 'Önce Profil sekmesinde bir profil oluşturun.',
            )
          : _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final c = MenzilColors.of(context);
    final profile = _profile!;
    final s = _stats;
    final range = _rangeM;
    final clickCm = range == null
        ? null
        : GroupCenter.clickCm(clickMrad: _clickMrad, rangeM: range);
    return MenzilPage(
      children: [
        Text(
          'Profil: ${profile.name} · sıfır ${ToolFormat.dec(profile.zeroRangeM, 0)} m',
          style: MenzilType.body(c.ink2),
        ),
        const SizedBox(height: MenzilSpace.sm),
        MenzilFieldGrid(
          children: [
            MenzilInput(
              key: const Key('zg-range'),
              controller: _range,
              label: 'Mesafe',
              unit: 'm',
              info: ZeroGroupFieldInfo.range,
              onChanged: (_) => setState(() {}),
            ),
            MenzilSelect<double>(
              key: const Key('zg-grid'),
              label: 'Kare boyu',
              unit: 'cm',
              initialValue: _gridCm,
              // The closed box shows the number; its unit is beside it in
              // the box (owner, 2026-10-17), so "cm" is not shown twice.
              // The open list keeps "1 cm".
              selectedLabels: [
                for (final g in _gridSizes)
                  ToolFormat.dec(g, g == g.roundToDouble() ? 0 : 1),
              ],
              info: ZeroGroupFieldInfo.grid,
              items: [
                for (final g in _gridSizes)
                  DropdownMenuItem(
                    value: g,
                    child: Text(
                      '${ToolFormat.dec(g, g == g.roundToDouble() ? 0 : 1)} cm',
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _gridCm = v),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(child: Text('Hedef', style: MenzilType.label(c.ink2))),
            const MenzilInfoButton(
              title: 'Hedef',
              text: ZeroGroupFieldInfo.target,
            ),
          ],
        ),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, box) {
              final size = Size(box.maxWidth, box.maxHeight);
              return Semantics(
                label: 'Hedef, ${_taps.length} vuruş işaretli',
                child: GestureDetector(
                  key: const Key('zg-target'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _tap(d.localPosition, size),
                  child: CustomPaint(
                    size: size,
                    painter: _TargetPainter(
                      taps: List.of(_taps),
                      center: s == null || _gridCm == null
                          ? null
                          : Offset(
                              s.centerRightCm / _gridCm!,
                              s.centerUpCm / _gridCm!,
                            ),
                      colors: c,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: MenzilSpace.md),
        Row(
          children: [
            Expanded(
              child: MenzilSecondaryButton(
                key: const Key('zg-undo'),
                label: 'Son vuruşu sil',
                expand: true,
                onPressed: _taps.isEmpty
                    ? null
                    : () => setState(_taps.removeLast),
              ),
            ),
            const SizedBox(width: MenzilSpace.md),
            Expanded(
              child: MenzilSecondaryButton(
                key: const Key('zg-clear'),
                label: 'Temizle',
                expand: true,
                onPressed: _taps.isEmpty ? null : () => setState(_taps.clear),
              ),
            ),
          ],
        ),
        const SizedBox(height: MenzilSpace.md),
        ..._results(context, s, range, clickCm),
      ],
    );
  }

  List<Widget> _results(
    BuildContext context,
    GroupStats? s,
    double? range,
    double? clickCm,
  ) {
    final c = MenzilColors.of(context);
    if (_gridCm == null || range == null) {
      return [
        Text(
          'Mesafe ve Kare boyu seçilince sonuç görünür.',
          style: MenzilType.caption(c.ink2),
        ),
      ];
    }
    if (s == null) {
      return [
        Text(
          'Hedefe dokunarak vuruşları işaretleyin.',
          style: MenzilType.caption(c.ink2),
        ),
      ];
    }
    String side(double v, String plus, String minus) => v.abs() < 0.05
        ? '0 cm'
        : '${ToolFormat.dec(v.abs(), 1)} cm ${v > 0 ? plus : minus}';
    final click = clickCm!;
    final more = GroupCenter.moreShots(s, clickCm: click);
    final se = s.centerUncertaintyCm;
    final String message;
    if (s.n < GroupCenter.minShots) {
      message = 'En az ${GroupCenter.minShots} vuruş gerekir: $more atış daha.';
    } else if (more > 0) {
      message =
          'Merkez belirsizliği ${ToolFormat.dec(se! / click, 1)} klik, '
          '1 klikten büyük: $more atış daha.';
    } else {
      message =
          'Merkez belirsizliği ${ToolFormat.dec(se! / click, 1)} klik; '
          'yeterli.';
    }
    final canApply = s.n >= GroupCenter.minShots;
    return [
      MenzilMetricGrid(
        columns: 2,
        metrics: [
          MenzilMetric('Atış', '${s.n}'),
          MenzilMetric('Klik', ToolFormat.dec(click, 2), 'cm'),
          MenzilMetric('Merkez dikey', side(s.centerUpCm, 'yukarı', 'aşağı')),
          MenzilMetric('Merkez yatay', side(s.centerRightCm, 'sağ', 'sol')),
          MenzilMetric(
            'σ',
            s.sigmaCm == null ? '—' : ToolFormat.dec(s.sigmaCm!, 1),
            s.sigmaCm == null ? null : 'cm',
          ),
          MenzilMetric(
            'Merkez belirsizliği',
            se == null ? '—' : ToolFormat.dec(se, 1),
            se == null ? null : 'cm',
          ),
        ],
      ),
      const SizedBox(height: MenzilSpace.sm),
      MenzilCard(
        accent: more > 0 ? c.amber : null,
        child: Text(
          message,
          key: const Key('zg-more'),
          style: MenzilType.body(c.ink),
        ),
      ),
      const SizedBox(height: MenzilSpace.md),
      MenzilPrimaryButton(
        key: const Key('zg-apply'),
        label: 'Sıfır ofsetine aktar',
        onPressed: canApply ? () => _apply(s, range) : null,
      ),
      const SizedBox(height: MenzilSpace.sm),
      Text(
        'Model: vuruşlar merkez çevresinde dairesel normal dağılır; σ iki '
        'eksenden birlikte, merkez belirsizliği σ/√n. Kaynak: Grubbs 1964; '
        'NIST e-Handbook.',
        style: MenzilType.caption(c.ink2),
      ),
    ];
  }
}

class _TargetPainter extends CustomPainter {
  final List<Offset> taps;
  final Offset? center;
  final MenzilColors colors;
  const _TargetPainter({
    required this.taps,
    required this.center,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sq = size.width / 10;
    final mid = Offset(size.width / 2, size.height / 2);
    Offset at(Offset squares) =>
        mid + Offset(squares.dx * sq, -squares.dy * sq);
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.paperFace);
    final thin = Paint()
      ..color = colors.line
      ..strokeWidth = 1;
    for (var i = 1; i < 10; i++) {
      canvas.drawLine(Offset(i * sq, 0), Offset(i * sq, size.height), thin);
      canvas.drawLine(Offset(0, i * sq), Offset(size.width, i * sq), thin);
    }
    final ink = Paint()
      ..color = colors.ink
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, ink);
    canvas.drawLine(Offset(mid.dx, 0), Offset(mid.dx, size.height), ink);
    canvas.drawLine(Offset(0, mid.dy), Offset(size.width, mid.dy), ink);
    canvas.drawCircle(mid, sq / 2, ink);
    final hole = Paint()..color = colors.amber;
    for (final t in taps) {
      canvas.drawCircle(at(t), 6, hole);
      canvas.drawCircle(at(t), 6, ink..strokeWidth = 1);
    }
    final c = center;
    if (c != null) {
      final p = at(c);
      final red = Paint()
        ..color = colors.danger
        ..strokeWidth = 2.5;
      canvas.drawLine(p - const Offset(10, 0), p + const Offset(10, 0), red);
      canvas.drawLine(p - const Offset(0, 10), p + const Offset(0, 10), red);
    }
  }

  @override
  bool shouldRepaint(covariant _TargetPainter old) =>
      old.taps.length != taps.length ||
      old.center != center ||
      old.colors != colors;
}
