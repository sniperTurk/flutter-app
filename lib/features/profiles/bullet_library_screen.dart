import 'package:flutter/material.dart';

import '../../data/bullet_library.dart';
import '../../models/domain.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// "Kütüphaneden seç" (owner, 2026-10-10): pick a bullet or pellet from the
/// manufacturers' published data; its weight, BC and drag law fill the form.
class BulletLibraryScreen extends StatefulWidget {
  final WeaponPlatform platform;

  /// The rifle's Kalibre (mm); null = every caliber.
  final double? caliberMm;

  const BulletLibraryScreen({
    super.key,
    required this.platform,
    this.caliberMm,
  });

  @override
  State<BulletLibraryScreen> createState() => _BulletLibraryScreenState();
}

class _BulletLibraryScreenState extends State<BulletLibraryScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _num(double v, [int d = 3]) =>
      v.toStringAsFixed(d).replaceAll('.', ',');

  /// The rifle type's records in the rifle's caliber (owner, 2026-10-10:
  /// no switch). A caliber with no record shows nothing, with a note.
  List<LibraryBullet> get _items {
    final q = _search.text.trim().toLowerCase();
    final cal = widget.caliberMm;
    final own = [
      for (final b in BulletLibrary.all)
        if (b.platform == widget.platform) b,
    ];
    final sameCaliber = cal == null
        ? own
        : [
            for (final b in own)
              if ((b.caliberMm - cal).abs() < 0.02) b,
          ];
    return [
      for (final b in sameCaliber)
        if (q.isEmpty || b.title.toLowerCase().contains(q)) b,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final items = _items;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Mermi kütüphanesi'),
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
                  key: const Key('library-search'),
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Ara: marka, model, ağırlık',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (items.isEmpty &&
                    _search.text.trim().isEmpty &&
                    widget.caliberMm != null)
                  Padding(
                    padding: const EdgeInsets.only(top: MenzilSpace.sm),
                    child: MenzilNotice(
                      key: const Key('library-no-caliber'),
                      tone: MenzilNoticeTone.info,
                      message:
                          'Bu kalibre '
                          '(${widget.caliberMm!.toStringAsFixed(2).replaceAll('.', ',')} mm) '
                          'için kütüphanede mermi yok. Değerleri kutusundan '
                          'veya üreticinin sitesinden elle girin.',
                    ),
                  ),
                Text(
                  '${items.length} kayıt · değerler üreticilerin kendi '
                  'sitelerinden; her kaydın kaynağı saklıdır.',
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
                final b = items[i];
                final bcs = [
                  if (b.g1 != null) 'G1 ${_num(b.g1!)}',
                  if (b.g7 != null) 'G7 ${_num(b.g7!)}',
                ].join(' · ');
                return MenzilCard(
                  margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    key: Key('library-item-$i'),
                    title: Text(
                      b.title,
                      style: MenzilType.body(
                        c.ink,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${_num(b.grain, b.grain % 1 == 0 ? 0 : 2)} gr · '
                      '${_num(b.diameterMm, 2)} mm · $bcs',
                      style: MenzilType.caption(c.ink2),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, b),
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
