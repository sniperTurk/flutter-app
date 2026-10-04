// dart format off
import 'package:flutter/material.dart';
import '../../core/catalog_search.dart';
import '../../data/catalog_repository.dart';
import '../../models/domain.dart';
import '../../services/manual_catalog_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// Production catalog view. Platform selection is explicit: PCP users never see
/// firearm rifles/ammunition mixed into their working catalog (and vice versa).
/// Optics remain global because the same optic can be used by either platform.
class CatalogScreen extends StatefulWidget {
  final WeaponPlatform initialPlatform;
  const CatalogScreen({super.key, this.initialPlatform = WeaponPlatform.pcp});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late WeaponPlatform platform = widget.initialPlatform;
  final TextEditingController _searchController = TextEditingController();
  String query = '';
  final _manualStore = ManualCatalogStore();
  List<Map<String, dynamic>> _manual = [];

  @override
  void initState() {
    super.initState();
    _refreshManual();
  }

  Future<void> _refreshManual() async {
    try {
      final items = await _manualStore.all();
      if (mounted) setState(() => _manual = items);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kullanıcı kataloğu okunamadı: $e')));
    }
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(String value) => CatalogSearch.matches(value, query);

  @override
  Widget build(BuildContext context) {
    const repo = CatalogRepository();
    final rifles = repo
        .riflesFor(platform)
        .where((x) => _matches('${x.brand} ${x.model} ${x.caliberMm}'))
        .toList(growable: false);
    final ammunition = repo
        .ammunitionFor(platform)
        .where((x) => _matches('${x.brand} ${x.model} ${x.caliberMm} ${x.type.name}'))
        .toList(growable: false);
    final scopes = CatalogRepository.scopes
        .where((x) => _matches('${x.brand} ${x.model} ${x.objectiveDiameterMm}'))
        .toList(growable: false);

    return Scaffold(
      appBar: MenzilSubPageBar(title: 'Katalog', actions: [IconButton(key: const Key('manual-catalog-add'), tooltip: 'Manuel model ekle', icon: const Icon(Icons.add), onPressed: () => _editManual())]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(MenzilSpace.gutter, MenzilSpace.md, MenzilSpace.gutter, MenzilSpace.xl),
        children: [
          SegmentedButton<WeaponPlatform>(
            segments: const [
              ButtonSegment(
                value: WeaponPlatform.pcp,
                label: Text('PCP Tüfekler'),
                icon: Icon(Icons.air),
              ),
              ButtonSegment(
                value: WeaponPlatform.firearm,
                label: Text('Ateşli Tüfekler'),
                icon: Icon(Icons.local_fire_department_outlined),
              ),
            ],
            selected: {platform},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => platform = selection.single),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('catalog-search'),
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Katalogda ara',
              hintText: 'Marka, model veya kalibre',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayı temizle',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => query = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (value) => setState(() => query = value.trim()),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: () => _editManual(), icon: const Icon(Icons.add), label: const Text('Listede yok mu? Manuel ekle')),
          ..._manual.where((e) => e['kind'] != 'custom_ammunition' && (e['kind'] == 'scope' || e['platform'] == platform.name) && _matches('${e['brand']} ${e['model']} ${e['caliberMm'] ?? ''}')).map((e) => ListTile(
            key: Key('manual-${e['id']}'),
            title: Text('${e['brand']} ${e['model']}'),
            subtitle: Text('Kullanıcı girdisi • ${e['kind'] == 'scope' ? 'Dürbün' : e['kind'] == 'rifle' ? 'Tüfek' : 'Mühimmat'}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: 'Düzenle', icon: const Icon(Icons.edit), onPressed: () => _editManual(existing: e)),
              IconButton(tooltip: 'Sil', icon: const Icon(Icons.delete_outline), onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try { await _manualStore.remove(e['id'] as String); await _refreshManual(); }
                catch (error) { if (mounted) messenger.showSnackBar(SnackBar(content: Text('$error'))); }
              }),
            ]),
          )),
          const SizedBox(height: 20),
          Text(
            '${platform == WeaponPlatform.pcp ? 'PCP' : 'Ateşli'} Tüfekler (${rifles.length})',
            style: MenzilType.heading(MenzilColors.of(context).ink, size: 22),
          ),
          if (rifles.isEmpty)
            const ListTile(title: Text('Aramaya uygun tüfek kaydı yok.')),
          ...rifles.map(
            (x) => ListTile(
              key: Key('catalog-rifle-${x.id}'),
              title: Text(x.displayName),
              subtitle: Text(_rifleSummary(x)),
              isThreeLine: x.sourceName != null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDetails(
                context,
                title: x.displayName,
                rows: _rifleDetails(x),
                sourceName: x.sourceName,
                sourceDocument: x.sourceDocument,
              ),
            ),
          ),
          const Divider(),
          Text(
            '${platform == WeaponPlatform.pcp ? 'PCP' : 'Ateşli'} Mühimmat (${ammunition.length})',
            style: MenzilType.heading(MenzilColors.of(context).ink, size: 22),
          ),
          if (ammunition.isEmpty)
            const ListTile(title: Text('Aramaya uygun mühimmat kaydı yok.')),
          ...ammunition.map(
            (x) => ListTile(
              key: Key('catalog-ammunition-${x.id}'),
              title: Text(x.displayName),
              subtitle: Text(_ammunitionSummary(x)),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDetails(
                context,
                title: x.displayName,
                rows: _ammunitionDetails(x),
                sourceName: x.sourceName,
                sourceDocument: x.sourceDocument,
              ),
            ),
          ),
          const Divider(),
          Text('Özel Yapım Mermiler', style: MenzilType.heading(MenzilColors.of(context).ink, size: 22)),
          const Text('Tüm bilgiler kullanıcı tarafından girilir; üretici verisi olarak gösterilmez.'),
          OutlinedButton.icon(key: const Key('custom-ammunition-add'),
            onPressed: () => _editManual(customAmmunition: true),
            icon: const Icon(Icons.add), label: const Text('Özel yapım mermi ekle')),
          ..._manual.where((e) => e['kind'] == 'custom_ammunition' && e['platform'] == platform.name &&
              _matches('${e['brand']} ${e['model']} ${e['caliberMm'] ?? ''}')).map((e) => ListTile(
            key: Key('custom-ammunition-${e['id']}'),
            title: Text('${e['model']}'),
            subtitle: Text('Kullanıcı girdisi • ${e['caliberMm'] ?? 'Kalibre belirtilmedi'} mm • ${e['grain'] ?? 'Ağırlık belirtilmedi'} grain'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: 'Düzenle', icon: const Icon(Icons.edit), onPressed: () => _editManual(existing: e)),
              IconButton(tooltip: 'Sil', icon: const Icon(Icons.delete_outline), onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try { await _manualStore.remove(e['id'] as String); await _refreshManual(); }
                catch (error) { if (mounted) messenger.showSnackBar(SnackBar(content: Text('$error'))); }
              }),
            ]),
            onTap:() => _showDetails(context, title: '${e['model']}', rows: [
              for (final key in ['brand','ammoType','caliberMm','grain','diameterMm','lengthMm','bc','bcModel','material','shape','lot','notes'])
                if (e[key] != null && e[key].toString().trim().isNotEmpty)
                  MapEntry(key, e[key].toString()),
            ], sourceName: 'Kullanıcı girdisi', sourceDocument: 'Özel yapım mühimmat; doğrulanmamış kişisel kayıt'),
          )),
          const Divider(),
          Text(
            'Dürbünler (${scopes.length})',
            style: MenzilType.heading(MenzilColors.of(context).ink, size: 22),
          ),
          const Text('Dürbün kataloğu her iki platform için ortaktır.'),
          if (scopes.isEmpty)
            const ListTile(title: Text('Aramaya uygun dürbün kaydı yok.')),
          ...scopes.map(
            (x) => ListTile(
              key: Key('catalog-scope-${x.id}'),
              title: Text(x.displayName),
              subtitle: Text(_scopeSummary(x)),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDetails(
                context,
                title: x.displayName,
                rows: _scopeDetails(x),
                sourceName: x.sourceName,
                sourceDocument: x.sourceDocument,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _editManual({Map<String, dynamic>? existing, bool customAmmunition = false}) async {
    String kind = existing?['kind'] as String? ?? (customAmmunition ? 'custom_ammunition' : 'rifle');
    String selectedPlatform = existing?['platform'] as String? ?? platform.name;
    String ammoType = existing?['ammoType'] as String? ?? 'pellet';
    String focal = existing?['focal'] as String? ?? 'unknown';
    final brand = TextEditingController(text: existing?['brand'] as String? ?? '');
    final model = TextEditingController(text: existing?['model'] as String? ?? '');
    final caliber = TextEditingController(text: existing?['caliberMm']?.toString() ?? '');
    final grain = TextEditingController(text: existing?['grain']?.toString() ?? '');
    final bc = TextEditingController(text: existing?['bc']?.toString() ?? '');
    final objective = TextEditingController(text: existing?['objectiveMm']?.toString() ?? '');
    final magnification = TextEditingController(text: existing?['magnification'] as String? ?? '');
    final click = TextEditingController(text: existing?['click']?.toString() ?? '');
    final diameter = TextEditingController(text: existing?['diameterMm']?.toString() ?? '');
    final length = TextEditingController(text: existing?['lengthMm']?.toString() ?? '');
    final material = TextEditingController(text: existing?['material'] as String? ?? '');
    final shape = TextEditingController(text: existing?['shape'] as String? ?? '');
    final lot = TextEditingController(text: existing?['lot'] as String? ?? '');
    final bcModel = TextEditingController(text: existing?['bcModel'] as String? ?? '');
    final notes = TextEditingController(text: existing?['notes'] as String? ?? '');
    final form = GlobalKey<FormState>();
    try {
      await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, update) => AlertDialog(
        title: Text(kind == 'custom_ammunition' ? 'Özel Yapım Mermiler' : existing == null ? 'Manuel model ekle' : 'Manuel modeli düzenle'),
        content: SizedBox(width: 440, child: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (kind != 'custom_ammunition') DropdownButtonFormField<String>(initialValue: kind, decoration: const InputDecoration(labelText: 'Kategori'), items: const [
            DropdownMenuItem(value: 'rifle', child: Text('Tüfek')),
            DropdownMenuItem(value: 'ammo', child: Text('Mühimmat')),
            DropdownMenuItem(value: 'scope', child: Text('Dürbün')),
          ], onChanged: (v) => update(() => kind = v!)),
          if (kind != 'scope') DropdownButtonFormField<String>(initialValue: selectedPlatform, decoration: const InputDecoration(labelText: 'Platform'), items: const [
            DropdownMenuItem(value: 'pcp', child: Text('PCP')),
            DropdownMenuItem(value: 'firearm', child: Text('Ateşli')),
          ], onChanged: (v) => update(() {
            selectedPlatform = v!;
            if (kind == 'ammo' || kind == 'custom_ammunition') {
              ammoType = selectedPlatform == 'firearm' ? 'bullet' : 'pellet';
            }
          })),
          TextFormField(controller: brand, decoration: const InputDecoration(labelText: 'Marka *'), validator: (v) => kind != 'custom_ammunition' && (v == null || v.trim().isEmpty) ? 'Marka gerekli' : null),
          TextFormField(controller: model, decoration: const InputDecoration(labelText: 'Model *'), validator: (v) => v == null || v.trim().isEmpty ? 'Model gerekli' : null),
          if (kind != 'scope') TextFormField(controller: caliber, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Kalibre (mm) *'), validator: (v) => kind == 'custom_ammunition' && (v == null || v.trim().isEmpty) ? null : (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) > 0 ? null : 'Pozitif kalibre girin'),
          if (kind == 'ammo' || kind == 'custom_ammunition') ...[
            DropdownButtonFormField<String>(
              // initialValue is only read when the field state is created; the key
              // rebuilds the field when the platform (and its item list) changes.
              key: ValueKey('ammo-type-$selectedPlatform'),
              initialValue: selectedPlatform == 'firearm' ? 'bullet' : (ammoType == 'bullet' ? 'pellet' : ammoType),
              decoration: const InputDecoration(labelText: 'Mühimmat tipi'),
              items: (selectedPlatform == 'firearm' ? const ['bullet'] : const ['pellet', 'slug'])
                  .map((value) => DropdownMenuItem(value: value, child: Text(value == 'bullet' ? 'Bullet' : value == 'slug' ? 'Slug' : 'Pellet')))
                  .toList(growable: false),
              onChanged: (v) => update(() => ammoType = v!),
            ),
            TextFormField(controller: grain, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Ağırlık (grain) *'), validator: (v) => kind == 'custom_ammunition' && (v == null || v.trim().isEmpty) ? null : (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) > 0 ? null : 'Pozitif ağırlık girin'),
            TextFormField(controller: bc, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'BC (isteğe bağlı)'), validator: (v) => v == null || v.trim().isEmpty || (double.tryParse(v.replaceAll(',', '.')) ?? 0) > 0 ? null : 'Geçerli BC girin'),
          ],
          if (kind == 'custom_ammunition') ...[
            TextFormField(controller: diameter, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Gerçek çap (mm)'), validator: (v) => v == null || v.trim().isEmpty || (double.tryParse(v.replaceAll(',', '.')) ?? 0) > 0 ? null : 'Pozitif çap girin'),
            TextFormField(controller: length, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Uzunluk (mm)'), validator: (v) => v == null || v.trim().isEmpty || (double.tryParse(v.replaceAll(',', '.')) ?? 0) > 0 ? null : 'Pozitif uzunluk girin'),
            TextFormField(controller: bcModel, decoration: const InputDecoration(labelText: 'BC modeli (G1 / G7 / diğer)')),
            TextFormField(controller: material, decoration: const InputDecoration(labelText: 'Malzeme')),
            TextFormField(controller: shape, decoration: const InputDecoration(labelText: 'Çekirdek şekli / tipi')),
            TextFormField(controller: lot, decoration: const InputDecoration(labelText: 'Parti / lot numarası')),
          ],
          if (kind == 'scope') ...[
            TextFormField(controller: magnification, decoration: const InputDecoration(labelText: 'Büyütme (ör. 5-25x)')),
            TextFormField(controller: objective, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Objektif (mm)'), validator: (v) => v == null || v.trim().isEmpty || (double.tryParse(v.replaceAll(',', '.')) ?? 0) > 0 ? null : 'Geçerli çap girin'),
            DropdownButtonFormField<String>(initialValue: focal, decoration: const InputDecoration(labelText: 'Odak düzlemi'), items: const [
              DropdownMenuItem(value: 'unknown', child: Text('Bilinmiyor')),
              DropdownMenuItem(value: 'ffp', child: Text('FFP')),
              DropdownMenuItem(value: 'sfp', child: Text('SFP')),
            ], onChanged: (v) => update(() => focal = v!)),
            TextFormField(controller: click, decoration: const InputDecoration(labelText: 'Klik değeri (isteğe bağlı)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v == null || v.trim().isEmpty || (double.tryParse(v.replaceAll(',', '.')) ?? 0) > 0 ? null : 'Geçerli klik girin'),
          ],
          TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'Diğer bilgiler / notlar'), maxLines: 3),
          const SizedBox(height: 8), const Text('Bu kayıt kullanıcı girdisidir; üretici tarafından doğrulanmış değildir.'),
        ])))),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
          FilledButton(onPressed: () async {
            if (!form.currentState!.validate()) return;
            double? number(TextEditingController c) => c.text.trim().isEmpty ? null : double.tryParse(c.text.trim().replaceAll(',', '.'));
            final entry = <String, dynamic>{
              'id': existing?['id'] ?? 'manual_${DateTime.now().microsecondsSinceEpoch}',
              'kind': kind, 'platform': selectedPlatform,
              'brand': brand.text.trim(), 'model': model.text.trim(),
              'caliberMm': kind == 'scope' ? null : number(caliber),
              'grain': (kind == 'ammo' || kind == 'custom_ammunition') ? number(grain) : null,
              'ammoType': (kind == 'ammo' || kind == 'custom_ammunition')
                  ? (selectedPlatform == 'firearm' ? 'bullet' : (ammoType == 'bullet' ? 'pellet' : ammoType))
                  : null,
              'bc': (kind == 'ammo' || kind == 'custom_ammunition') ? number(bc) : null,
              'diameterMm': kind == 'custom_ammunition' ? number(diameter) : null,
              'lengthMm': kind == 'custom_ammunition' ? number(length) : null,
              'bcModel': kind == 'custom_ammunition' ? bcModel.text.trim() : null,
              'material': kind == 'custom_ammunition' ? material.text.trim() : null,
              'shape': kind == 'custom_ammunition' ? shape.text.trim() : null,
              'lot': kind == 'custom_ammunition' ? lot.text.trim() : null,
              'objectiveMm': kind == 'scope' ? number(objective) : null,
              'magnification': kind == 'scope' ? magnification.text.trim() : null,
              'focal': kind == 'scope' ? focal : null,
              'click': kind == 'scope' ? number(click) : null,
              'notes': notes.text.trim(), 'sourceName': 'Kullanıcı girdisi',
            };
            try {
              await _manualStore.upsert(entry);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _refreshManual();
            } catch (error) {
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Kayıt başarısız: $error')));
            }
          }, child: const Text('Kaydet'))],
      )));
    } finally {
      // Text fields belong to this dialog's lifetime; controllers are disposed
      // after the route is fully dismissed.
      brand.dispose(); model.dispose(); caliber.dispose(); grain.dispose(); bc.dispose();
      diameter.dispose(); length.dispose(); material.dispose(); shape.dispose(); lot.dispose(); bcModel.dispose();
      objective.dispose(); magnification.dispose(); click.dispose(); notes.dispose();
    }
  }

  List<MapEntry<String, String>> _rifleDetails(Rifle rifle) => [
        MapEntry('Platform', rifle.platform == WeaponPlatform.pcp ? 'PCP' : 'Ateşli'),
        MapEntry('Kalibre', '${rifle.caliberMm} mm'),
        if (rifle.magazineCapacity != null) MapEntry('Şarjör', '${rifle.magazineCapacity} atış'),
        if (rifle.barrelLengthMm != null) MapEntry('Namlu', '${rifle.barrelLengthMm!.toStringAsFixed(0)} mm'),
        if (rifle.airCapacityCc != null) MapEntry('Hava kapasitesi', '${rifle.airCapacityCc!.toStringAsFixed(0)} cc'),
        if (rifle.plenumCc != null) MapEntry('Plenum', '${rifle.plenumCc!.toStringAsFixed(0)} cc'),
        if (rifle.overallLengthMm != null) MapEntry('Toplam uzunluk', '${rifle.overallLengthMm!.toStringAsFixed(0)} mm'),
        if (rifle.weightKg != null) MapEntry('Ağırlık', '${rifle.weightKg} kg'),
        if (rifle.barrelType != null) MapEntry('Namlu tipi', rifle.barrelType!),
        if (rifle.rail != null) MapEntry('Ray', rifle.rail!),
        if (rifle.moderatorThread != null) MapEntry('Moderatör dişi', rifle.moderatorThread!),
      ];

  List<MapEntry<String, String>> _ammunitionDetails(Ammunition ammunition) => [
        MapEntry('Platform', ammunition.platform == WeaponPlatform.pcp ? 'PCP' : 'Ateşli'),
        MapEntry('Kalibre', '${ammunition.caliberMm} mm'),
        MapEntry('Ağırlık', '${ammunition.grain} gr'),
        MapEntry('Tip', ammunition.type.name),
        if (ammunition.ballisticCoefficient != null) MapEntry('BC', '${ammunition.ballisticCoefficient}'),
        if (ammunition.ballisticModel != null) MapEntry('Balistik model', ammunition.ballisticModel!.name.toUpperCase()),
      ];

  List<MapEntry<String, String>> _scopeDetails(ScopeOptic scope) => [
        MapEntry('Objektif', '${scope.objectiveDiameterMm.toInt()} mm'),
        if (scope.objectiveOuterDiameterMm != null) MapEntry('Dış objektif çapı', '${scope.objectiveOuterDiameterMm} mm'),
        if (scope.tubeDiameterMm != null) MapEntry('Tüp', '${scope.tubeDiameterMm} mm'),
        if (scope.minMagnification != null && scope.maxMagnification != null) MapEntry('Büyütme', '${scope.minMagnification}–${scope.maxMagnification}×'),
        MapEntry('Klik', '${scope.clickValue} ${scope.clickUnit.name.toUpperCase()}'),
        if (scope.elevationRangeMrad != null) MapEntry('Elevasyon', '${scope.elevationRangeIsLowerBound ? '>' : ''}${scope.elevationRangeMrad} MRAD'),
        if (scope.windageRangeMrad != null) MapEntry('Windage', '${scope.windageRangeIsLowerBound ? '>' : ''}${scope.windageRangeMrad} MRAD'),
        if (scope.firstFocalPlane != null) MapEntry('Odak düzlemi', scope.firstFocalPlane! ? 'FFP' : 'SFP'),
        if (scope.zeroStop != null) MapEntry('Zero Stop', scope.zeroStop! ? 'Var' : 'Yok'),
        if (scope.reticle != null) MapEntry('Retikül', scope.reticle!),
        if (scope.lengthMm != null) MapEntry('Uzunluk', '${scope.lengthMm} mm'),
        if (scope.weightG != null) MapEntry('Ağırlık', '${scope.weightG} g'),
      ];

  void _showDetails(
    BuildContext context, {
    required String title,
    required List<MapEntry<String, String>> rows,
    required String? sourceName,
    required String? sourceDocument,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MenzilType.heading(MenzilColors.of(context).ink, size: 22)),
              const SizedBox(height: 12),
              ...rows.map((row) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 130, child: Text(row.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Expanded(child: Text(row.value)),
                      ],
                    ),
                  )),
              const Divider(height: 28),
              Text('Veri kaynağı', style: MenzilType.heading(MenzilColors.of(context).ink, size: 18)),
              const SizedBox(height: 6),
              Text(sourceName ?? 'Kaynak doğrulanmadı'),
              if (sourceDocument != null) ...[
                const SizedBox(height: 4),
                SelectableText(sourceDocument),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _ammunitionSummary(Ammunition ammunition) {
    final provenance = ammunition.sourceName == null
        ? 'Kaynak doğrulanmadı'
        : ammunition.sourceName == 'Kullanıcı girdisi'
            ? 'Doğrulama: kullanıcı girdisi'
            : 'Kaynak: ${ammunition.sourceName}';
    return '${ammunition.caliberMm} mm • ${ammunition.grain} gr • '
        '${ammunition.type.name} • $provenance';
  }

  String _scopeSummary(ScopeOptic scope) {
    final provenance = scope.sourceName == null
        ? 'Kaynak doğrulanmadı'
        : 'Kaynak: ${scope.sourceName}';
    return '${scope.objectiveDiameterMm.toInt()} mm • '
        '${scope.clickValue} ${scope.clickUnit.name}/click • $provenance';
  }

  String _rifleSummary(Rifle rifle) {
    final details = <String>[
      if (rifle.magazineCapacity != null) '${rifle.magazineCapacity} atış',
      if (rifle.barrelLengthMm != null)
        'Namlu ${rifle.barrelLengthMm!.toStringAsFixed(0)} mm',
      if (rifle.airCapacityCc != null)
        '${rifle.airCapacityCc!.toStringAsFixed(0)} cc',
      if (rifle.weightKg != null)
        '${rifle.weightKg!.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')} kg',
      if (rifle.sourceName != null) 'Kaynak: ${rifle.sourceName}',
    ];
    // An entry with no manufacturer/source metadata is intentionally kept
    // usable as a catalog/manual template, but it must never be presented as
    // verified. This wording is part of the production provenance contract.
    return details.isEmpty
        ? 'Kaynak doğrulanmadı • Ayrıntılı teknik veri henüz yok.'
        : details.join(' • ');
  }
}
