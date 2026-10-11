import 'package:flutter/material.dart';

import '../../data/catalog_repository.dart';
import '../../models/domain.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// "Listeden seç" for the rifle (owner, 2026-10-10): the manufacturer-sourced
/// rifles of the catalog; brand, model and Kalibre fill the form.
class RiflePickerScreen extends StatefulWidget {
  final WeaponPlatform platform;

  const RiflePickerScreen({super.key, required this.platform});

  /// The Kalibre list value for [r]: firearm rifles store the bore (7.62 for
  /// .308), the profile wants the bullet diameter; PCP 4.52/5.52 go to the
  /// nominal list value. Anything else stays as stored.
  static double profileCaliber(Rifle r) {
    final m = r.model.toLowerCase();
    if (r.platform == WeaponPlatform.firearm) {
      if (m.contains('.338')) return 8.59;
      if (m.contains('6.5')) return 6.71;
      if (m.contains('.243')) return 6.17;
      if (m.contains('7.62x39')) return 7.92;
      if (r.caliberMm >= 5.5 && r.caliberMm <= 5.6) return 5.7;
      if ((r.caliberMm - 7.62).abs() < 0.01) return 7.82;
      return r.caliberMm;
    }
    if ((r.caliberMm - 4.52).abs() < 0.01) return 4.5;
    if ((r.caliberMm - 5.52).abs() < 0.01) return 5.5;
    return r.caliberMm;
  }

  /// The Kalibre list name for [r] when its model names the cartridge
  /// (".308", "6.5 Creedmoor"…); null leaves the first name of its diameter.
  static String? cartridgeName(Rifle r) {
    final m = r.model.toLowerCase();
    const map = <(String, String)>[
      ('.338 lapua', '.338 Lapua Mag'),
      ('.338 win', '.338 Win Mag'),
      ('6.5 creedmoor', '6.5 Creedmoor'),
      ('6.5 prc', '6.5 PRC'),
      ('6.5x55', '6.5x55 Swedish'),
      ('.300 win', '.300 Win Mag'),
      ('.300 prc', '.300 PRC'),
      ('.300 blk', '.300 Blackout'),
      ('.300 blackout', '.300 Blackout'),
      ('7.62x51', '7.62x51 NATO'),
      ('7.62x39', '7.62x39'),
      ('7.62x54', '7.62x54R'),
      ('.30-06', '.30-06 Springfield'),
      ('.308', '.308 Win'),
      ('.243', '.243 Win'),
      ('5.56', '5.56x45 NATO'),
      ('.223', '.223 Rem'),
      ('.22-250', '.22-250 Rem'),
      ('.22 lr', '.22 LR'),
      ('.270 wsm', '.270 WSM'),
      ('.270', '.270 Win'),
      ('7mm rem', '7mm Rem Mag'),
      ('7mm prc', '7mm PRC'),
      ('7mm-08', '7mm-08 Rem'),
      ('.375', '.375 H&H Mag'),
      ('9.3x62', '9.3x62'),
      ('8x57', '8x57 JS'),
    ];
    if (r.platform != WeaponPlatform.firearm) return null;
    for (final (k, v) in map) {
      if (m.contains(k)) return v;
    }
    return null;
  }

  @override
  State<RiflePickerScreen> createState() => _RiflePickerScreenState();
}

class _RiflePickerScreenState extends State<RiflePickerScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Rifle> get _items {
    final q = _search.text.trim().toLowerCase();
    return [
      for (final r in CatalogRepository.rifles)
        if (r.platform == widget.platform &&
            !r.userEntered &&
            r.brand != 'Manuel' &&
            (q.isEmpty || '${r.brand} ${r.model}'.toLowerCase().contains(q)))
          r,
    ];
  }

  static String _mm(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final items = _items;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Tüfek listesi'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MenzilSpace.gutter,
              MenzilSpace.md,
              MenzilSpace.gutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('rifle-picker-search'),
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Ara: marka, model',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: MenzilSpace.xs),
                Text(
                  '${items.length} tüfek · bilgiler üreticilerin kendi '
                  'sayfalarından. Listede yoksa geri dönüp elle yazın.',
                  style: MenzilType.caption(c.ink2),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                MenzilSpace.gutter,
                MenzilSpace.sm,
                MenzilSpace.gutter,
                MenzilSpace.xl,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final r = items[i];
                final details = [
                  '${_mm(RiflePickerScreen.profileCaliber(r))} mm',
                  if (r.barrelLengthMm != null)
                    'namlu ${r.barrelLengthMm!.round()} mm',
                  if (r.magazineCapacity != null) '${r.magazineCapacity} atım',
                ].join(' · ');
                return MenzilCard(
                  margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    key: Key('rifle-picker-item-$i'),
                    title: Text(
                      '${r.brand} ${r.model}',
                      style: MenzilType.body(
                        c.ink,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(details, style: MenzilType.caption(c.ink2)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, r),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
