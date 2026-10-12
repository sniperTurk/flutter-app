import 'package:flutter/material.dart';

import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import '../ballistics/environment_field_info.dart';
import '../ballistics/pro_section_info.dart';
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

  /// New phone: bring the profiles back from a backup file (owner,
  /// 2026-10-12). Hidden when null.
  final VoidCallback? onRestore;

  const WelcomePanel({super.key, this.onCreate, this.onRestore});

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
                'Tüfeğini Tanıt',
                'Tüfek, mermi ve dürbün bilgilerini bir kez gir.',
              ),
              step(
                '2',
                'Havayı Al',
                'Konumundan sıcaklık, basınç ve rüzgâr otomatik gelir.',
              ),
              step(
                '3',
                'Pro Ayarlarını Yap',
                'Açı, rüzgâr bölgeleri, Coriolis ve spin drift: '
                    'Profesyonellerin hesabı artık cebinde.',
              ),
              step(
                '4',
                'Dürbünün Kurulu Gelsin',
                'Mesafeyi yaz; kaç klik çevireceğini gösterir.',
              ),
            ],
          ),
        ),
        const SizedBox(height: MenzilSpace.md),
        _EmptyActions(onCreate: onCreate, createLabel: 'İlk profilimi oluştur'),
        if (onRestore != null) ...[
          const SizedBox(height: MenzilSpace.sm),
          MenzilSecondaryButton(
            label: 'Yedekten geri yükle',
            icon: Icons.download_outlined,
            expand: true,
            onPressed: onRestore,
          ),
        ],
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
          style: const TextStyle(fontWeight: FontWeight.w400),
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
            // No bold text in the Pro boxes (owner, 2026-10-11).
            style: MenzilType.body(c.ink).copyWith(fontWeight: FontWeight.w400),
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
                        // No bold box titles (owner, 2026-10-11): regular.
                        style: MenzilType.heading(
                          c.ink,
                          size: 18,
                        ).copyWith(fontWeight: FontWeight.w400),
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
              ),
              MenzilSecondaryButton(
                key: const Key('empty-pro-map'),
                label: 'Haritadan ölç',
                icon: Icons.map_outlined,
                expand: true,
                onPressed: _fromMap,
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
        _box('gravity', 'Yerçekimi', 'kapalı', const [ProSectionInfo.gravity]),
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

/// Hedef before any profile: only "Tahmin yok, hesap var." and "Profil
/// oluştur" (owner, 2026-10-11). The example .308 scope with its live
/// solution was removed so that no numbers show before a profile exists.
class ShotPreview extends StatelessWidget {
  final VoidCallback? onCreate;
  const ShotPreview({super.key, this.onCreate});

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: EmptyStateKeys.shotPreview,
    child: _SloganCard(onCreate: onCreate),
  );
}
