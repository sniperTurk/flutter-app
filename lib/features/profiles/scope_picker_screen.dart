import 'package:flutter/material.dart';

import '../../data/catalog_repository.dart';
import '../../models/domain.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// "Listeden seç" for the scope (owner, 2026-10-10): the manufacturer-sourced
/// scopes of the catalog; magnification, objective, focal plane, turret unit,
/// travel and reticle fill the form.
class ScopePickerScreen extends StatefulWidget {
  const ScopePickerScreen({super.key});

  /// The model name without the designation the form builds itself
  /// ("6–24×50", "FFP"), e.g. "Sentinel (SCFF-57)".
  static String seriesName(ScopeOptic s) => s.model
      .replaceAll(
        RegExp(r'\s*\d+(?:[.,]\d+)?\s*[–-]\s*\d+(?:[.,]\d+)?\s*[×xX]\s*\d+\w*'),
        '',
      )
      .replaceAll(RegExp(r'\b(FFP|SFP)\b'), '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  @override
  State<ScopePickerScreen> createState() => _ScopePickerScreenState();
}

class _ScopePickerScreenState extends State<ScopePickerScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ScopeOptic> get _items {
    final q = _search.text.trim().toLowerCase();
    return [
      for (final s in CatalogRepository.scopes)
        if (!s.userEntered &&
            (q.isEmpty ||
                '${s.brand} ${s.model} ${s.reticle ?? ''}'
                    .toLowerCase()
                    .contains(q)))
          s,
    ];
  }

  static String _n(double v) =>
      (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString()).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final items = _items;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Dürbün listesi'),
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
                  key: const Key('scope-picker-search'),
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Ara: marka, model, retikül',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: MenzilSpace.xs),
                Text(
                  '${items.length} dürbün · bilgiler üreticilerin kendi '
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
                final s = items[i];
                final lo = s.minMagnification, hi = s.maxMagnification;
                final details = [
                  if (lo != null && hi != null)
                    '${_n(lo)}-${_n(hi)}×${_n(s.objectiveDiameterMm)}',
                  if (s.firstFocalPlane != null)
                    s.firstFocalPlane! ? 'FFP' : 'SFP',
                  '${_n(s.clickValue)} ${s.clickUnit.label}',
                  if (s.reticle != null) s.reticle!,
                ].join(' · ');
                return MenzilCard(
                  margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    key: Key('scope-picker-item-$i'),
                    title: Text(
                      '${s.brand} ${s.model}',
                      style: MenzilType.body(
                        c.ink,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      details,
                      style: MenzilType.caption(c.ink2),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, s),
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
