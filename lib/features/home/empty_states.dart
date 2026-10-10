import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ballistic_engine.dart';
import '../../core/ballistic_input.dart';
import '../../core/reticle_holds.dart';
import '../../core/scope_dial.dart';
import '../../models/domain.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import '../ballistics/environment_field_info.dart';
import '../ballistics/pro_section_info.dart';
import '../ballistics/scope_dial_view.dart';
import '../tools/map_distance_screen.dart';

/// Pages shown before the first profile exists (owner, 2026-10-10): instead
/// of empty locked cards, each page says what it does and offers the next
/// step: create a profile.
abstract final class EmptyStateKeys {
  static const welcome = Key('empty-welcome');
  static const create = Key('empty-create-profile');
  static const shotPreview = Key('empty-shot-preview');
  static const proPreview = Key('empty-pro-preview');
}

/// The action every empty page offers.
class _EmptyActions extends StatelessWidget {
  final VoidCallback? onCreate;
  final String createLabel;

  const _EmptyActions({
    required this.onCreate,
    this.createLabel = 'Profil oluştur',
  });

  @override
  Widget build(BuildContext context) => MenzilPrimaryButton(
    key: EmptyStateKeys.create,
    label: createLabel,
    icon: Icons.add,
    amber: true,
    onPressed: onCreate,
  );
}

/// Profil page without profiles: logo, what the app does, how it works.
class WelcomePanel extends StatelessWidget {
  final VoidCallback? onCreate;

  const WelcomePanel({super.key, this.onCreate});

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget step(String n, String title, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MenzilSpace.sm),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.amberSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              style: TextStyle(fontWeight: FontWeight.w800, color: c.amberInk),
            ),
          ),
          const SizedBox(width: MenzilSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MenzilType.heading(c.ink, size: 16)),
                const SizedBox(height: 2),
                Text(text, style: MenzilType.caption(c.ink2)),
              ],
            ),
          ),
        ],
      ),
    );
    return Column(
      key: EmptyStateKeys.welcome,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MenzilCard(
          child: Column(
            children: [
              Image.asset(
                dark
                    ? 'assets/branding/logo_line_dark.png'
                    : 'assets/branding/logo_line.png',
                width: 104,
                height: 104,
                semanticLabel: 'SNIPER TÜRK',
              ),
              const SizedBox(height: MenzilSpace.md),
              Text(
                'Mesafeyi gir,\ndürbünün kurulu gelsin.',
                textAlign: TextAlign.center,
                style: MenzilType.heading(c.ink, size: 22),
              ),
              const SizedBox(height: MenzilSpace.xs),
              Text(
                'PCP ve Ateşli Tüfekler için Pro balistik hesaplama',
                textAlign: TextAlign.center,
                style: MenzilType.body(c.ink2),
              ),
            ],
          ),
        ),
        const SizedBox(height: MenzilSpace.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MenzilSpace.xs),
          child: Text(
            'Nasıl çalışır?',
            style: MenzilType.heading(c.ink, size: 17),
          ),
        ),
        const SizedBox(height: MenzilSpace.sm),
        MenzilCard(
          child: Column(
            children: [
              step(
                '1',
                'Tüfeğini tanıt',
                'Tüfek, mermi ve dürbün bilgilerini bir kez gir.',
              ),
              step(
                '2',
                'Pro ayarlarını yap',
                'Açı, rüzgâr bölgeleri, Coriolis ve spin drift: '
                    'profesyonellerin hesabı artık cebinde.',
              ),
              step(
                '3',
                'Havayı al',
                'Konumundan sıcaklık, basınç ve rüzgâr otomatik gelir.',
              ),
              step(
                '4',
                'Dürbünün kurulu gelsin',
                'Mesafeyi yaz; kaç klik çevireceğini gösterir.',
              ),
            ],
          ),
        ),
        const SizedBox(height: MenzilSpace.md),
        _EmptyActions(onCreate: onCreate, createLabel: 'İlk profilimi oluştur'),
      ],
    );
  }
}

/// "Tahmin yok, hesap var." with its explanation and "Profil oluştur",
/// under the Pro and Hedef previews.
class _SloganCard extends StatelessWidget {
  final VoidCallback? onCreate;
  const _SloganCard({this.onCreate});

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return MenzilCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tahmin yok, hesap var.',
            textAlign: TextAlign.center,
            style: MenzilType.heading(c.ink, size: 22),
          ),
          const SizedBox(height: MenzilSpace.xs),
          Text(
            'Hava koşulları ve Pro hesaplamalarla, kaç klik çevireceğin her '
            'mesafe için hassas biçimde hesaplanır. Sonuç doğrudan '
            'retikülünün üzerinde görünür.',
            textAlign: TextAlign.center,
            style: MenzilType.body(c.ink2),
          ),
          const SizedBox(height: MenzilSpace.md),
          _EmptyActions(onCreate: onCreate),
        ],
      ),
    );
  }
}

/// Pro Ayarlar before any profile (owner, 2026-10-10): the real layout —
/// shot distance, "Haritadan ölç" and the closed boxes, each opening its
/// explanation — so the user sees what is inside.
class ProPreview extends StatefulWidget {
  final VoidCallback? onCreate;
  const ProPreview({super.key, this.onCreate});

  @override
  State<ProPreview> createState() => _ProPreviewState();
}

class _ProPreviewState extends State<ProPreview> {
  final TextEditingController _range = TextEditingController();
  String? _open;

  @override
  void dispose() {
    _range.dispose();
    super.dispose();
  }

  Future<void> _fromMap() async {
    final meters = await Navigator.push<double>(
      context,
      MaterialPageRoute<double>(
        builder: (_) => const MapDistanceScreen(returnDistance: true),
      ),
    );
    if (!mounted || meters == null || !meters.isFinite || meters <= 0) return;
    setState(() => _range.text = meters.round().toString());
  }

  Widget _explain(ProExplain e) {
    final c = MenzilColors.of(context);
    TextSpan part(String label, String text) => TextSpan(
      children: [
        TextSpan(
          text: '$label ',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        TextSpan(text: '$text\n'),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: MenzilSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            e.title,
            style: MenzilType.body(c.ink).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                part('Ne?', e.what),
                part('Neden önemli?', e.why),
                part('Nasıl?', e.how),
              ],
            ),
            style: MenzilType.caption(c.ink2).copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _box(String id, String title, String summary, List<ProExplain> info) {
    final c = MenzilColors.of(context);
    final open = _open == id;
    return MenzilCard(
      key: Key('empty-pro-box-$id'),
      margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              key: Key('empty-pro-section-$id'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _open = open ? null : id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: MenzilType.heading(c.ink, size: 18),
                      ),
                    ),
                    if (!open) Text(summary, style: MenzilType.caption(c.ink2)),
                    const SizedBox(width: MenzilSpace.xs),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      color: c.ink2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open) ...[for (final e in info) _explain(e)],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Column(
      key: EmptyStateKeys.proPreview,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MenzilCard(
          margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MenzilInput(
                key: const Key('empty-pro-range'),
                controller: _range,
                label: 'Atış mesafesi',
                unit: 'm',
                info: EnvironmentFieldInfo.proShotRange,
                hintText: 'örn. 300',
              ),
              MenzilSecondaryButton(
                key: const Key('empty-pro-map'),
                label: 'Haritadan ölç',
                icon: Icons.map_outlined,
                expand: true,
                onPressed: _fromMap,
              ),
              const SizedBox(height: MenzilSpace.xs),
              Text(
                'Mesafeyi bilmiyorsan haritadan ölç. Hedef\'e geçince dürbün '
                'bu mesafeye kurulmuş gelir.',
                style: MenzilType.caption(c.ink2),
              ),
            ],
          ),
        ),
        _box('angle', 'Açı', 'düz', const [
          ProSectionInfo.incline,
          ProSectionInfo.cant,
        ]),
        _box('wind', 'Rüzgâr', 'bölge yok', const [
          ProSectionInfo.windMax,
          ProSectionInfo.windZones,
        ]),
        _box('coriolis', 'Coriolis', 'kapalı', const [ProSectionInfo.coriolis]),
        _box('target', 'Hareketli hedef', 'kapalı', const [
          ProSectionInfo.movingTarget,
          ProSectionInfo.hitProbability,
        ]),
        _box('rifle', 'Tüfek düzeltmeleri', 'kapalı', const [
          ProSectionInfo.turretScale,
          ProSectionInfo.zeroOffset,
          ProSectionInfo.spinDrift,
          ProSectionInfo.powder,
        ]),
        _SloganCard(onCreate: widget.onCreate),
      ],
    );
  }
}

/// Hedef before any profile (owner, 2026-10-10): the real scope with open
/// turrets that can be turned, the distance and its slider on top — solved
/// live for an example .308 load that is never saved.
class ShotPreview extends StatefulWidget {
  final VoidCallback? onCreate;
  const ShotPreview({super.key, this.onCreate});

  @override
  State<ShotPreview> createState() => _ShotPreviewState();
}

class _ShotPreviewState extends State<ShotPreview> {
  static const _click = 0.1;
  static const _maxRange = 1000;
  int _range = 300;
  int _elev = 0, _wind = 0, _reveal = 0;
  late final List<CorrectionSample> _samples;
  double? _mpsPerMil;
  TrajectoryPoint? _shot;

  static BallisticInput _input(List<double> ranges) => BallisticInput(
    muzzleVelocityMps: 800,
    grain: 168,
    zeroRangeM: 100,
    sightHeightMm: 45,
    rangesM: ranges,
    ballisticCoefficient: 0.462,
    ballisticModel: BallisticModel.g1,
    environment: const EnvironmentData(windMps: 3, windDirectionDeg: 90),
  );

  @override
  void initState() {
    super.initState();
    _samples = [
      for (final p in ReticleHolds.sample(_input(const [100])))
        ScopeDialMath.sampleOf(p, AngularUnit.mrad),
    ];
    _solve();
    // Turrets start at zero (owner, 2026-10-10); the right one is opened
    // after the first frame (a token change opens the drum).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _reveal++);
    });
  }

  void _solve() {
    try {
      _shot = const BallisticEngine().solve(_input([_range.toDouble()])).single;
      _mpsPerMil = ReticleHolds.crosswindForMil(
        base: _input([_range.toDouble()]),
        rangeM: _range.toDouble(),
        mil: 1,
      );
    } on Object {
      _shot = null;
    }
  }

  void _setRange(int v) => setState(() {
    _range = math.max(1, math.min(_maxRange, v));
    _solve();
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    Widget step(String label, int d) => MenzilStepButton(
      label: label,
      semanticLabel: 'Mesafe $label',
      onPressed: () => _setRange(_range + d),
    );
    final shot = _shot;
    return Column(
      key: EmptyStateKeys.shotPreview,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            step('−5', -5),
            const SizedBox(width: MenzilSpace.xs),
            step('−1', -1),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$_range',
                      style: MenzilType.display(c.ink, size: 52),
                    ),
                    TextSpan(text: ' m', style: MenzilType.unit(c.ink2)),
                  ],
                ),
                key: const Key('empty-shot-range'),
                textAlign: TextAlign.center,
              ),
            ),
            step('+1', 1),
            const SizedBox(width: MenzilSpace.xs),
            step('+5', 5),
          ],
        ),
        Slider(
          value: _range.toDouble(),
          min: 1,
          max: _maxRange.toDouble(),
          onChanged: (v) => _setRange(v.round()),
        ),
        MenzilCard(
          margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
          child: ScopeDialView(
            unit: AngularUnit.mrad,
            clickValue: _click,
            elevationClicks: _elev,
            windageClicks: _wind,
            maxElevationClicks: 300,
            maxWindageClicks: 150,
            onElevationChanged: (v) => setState(() => _elev = v),
            onWindageChanged: (v) => setState(() => _wind = v),
            windageRevealToken: _reveal,
            onSolutionDialed: () => setState(() => _reveal++),
            requiredUp: shot?.correctionMrad,
            requiredRight: shot?.windMrad ?? 0,
            windMpsPerUnit: _mpsPerMil,
            windText: (mps) => mps.toStringAsFixed(1),
            firstFocalPlane: true,
            minMagnification: 5,
            maxMagnification: 25,
            magnification: 25,
            rangeM: _range.toDouble(),
            samples: _samples,
            toDisplayRange: (m) => m,
            distanceUnit: 'm',
            metric: true,
          ),
        ),
        _SloganCard(onCreate: widget.onCreate),
      ],
    );
  }
}
