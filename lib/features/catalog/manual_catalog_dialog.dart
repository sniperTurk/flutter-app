// dart format off
import 'package:flutter/material.dart';

/// Add / edit dialog for the personal (manual) catalog, persisted through
/// `ManualCatalogStore` by the caller-supplied [onSave].
///
/// Lifecycle contract:
/// * every text controller is created in [State.initState] and disposed in
///   [State.dispose], i.e. only after the dialog route has fully finished its
///   exit animation (never while the fields can still paint);
/// * the record id is fixed once per dialog, and "Kaydet" is ignored while a
///   save is running, so repeated taps can never create duplicate records;
/// * a failed save keeps the dialog open with every typed value intact and
///   shows the error inside the dialog.
///
/// Pops `true` after a successful save, `null` on cancel.
class ManualCatalogDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final bool customAmmunition;
  final String defaultPlatform;
  final Future<void> Function(Map<String, dynamic> entry) onSave;

  const ManualCatalogDialog({
    super.key,
    this.existing,
    this.customAmmunition = false,
    required this.defaultPlatform,
    required this.onSave,
  });

  @override
  State<ManualCatalogDialog> createState() => _ManualCatalogDialogState();
}

class _ManualCatalogDialogState extends State<ManualCatalogDialog> {
  final form = GlobalKey<FormState>();
  late final Map<String, dynamic>? existing = widget.existing;
  late String kind = existing?['kind'] as String? ?? (widget.customAmmunition ? 'custom_ammunition' : 'rifle');
  late String selectedPlatform = existing?['platform'] as String? ?? widget.defaultPlatform;
  late String ammoType = existing?['ammoType'] as String? ?? (selectedPlatform == 'firearm' ? 'bullet' : 'pellet');
  late String focal = existing?['focal'] as String? ?? 'unknown';
  late String clickUnit = existing?['clickUnit'] as String? ?? 'mrad';

  /// Fixed for the lifetime of the dialog: a retry after a failed save, or a
  /// second tap, always targets the same record.
  late final String recordId = existing?['id'] as String? ?? 'manual_${DateTime.now().microsecondsSinceEpoch}';

  late final TextEditingController brand, model, caliber, grain, bc, objective, magnification, click,
      diameter, length, material, shape, lot, bcModel, notes, barrel;
  late final List<TextEditingController> _controllers;

  bool saving = false;
  String? saveError;

  @override
  void initState() {
    super.initState();
    TextEditingController text(String key) => TextEditingController(text: existing?[key]?.toString() ?? '');
    brand = text('brand');
    model = text('model');
    caliber = text('caliberMm');
    grain = text('grain');
    bc = text('bc');
    objective = text('objectiveMm');
    magnification = text('magnification');
    click = text('click');
    diameter = text('diameterMm');
    length = text('lengthMm');
    material = text('material');
    shape = text('shape');
    lot = text('lot');
    bcModel = text('bcModel');
    notes = text('notes');
    barrel = text('barrelLengthMm');
    _controllers = [brand, model, caliber, grain, bc, objective, magnification, click,
      diameter, length, material, shape, lot, bcModel, notes, barrel];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  double? _number(TextEditingController c) =>
      c.text.trim().isEmpty ? null : double.tryParse(c.text.trim().replaceAll(',', '.'));

  Map<String, dynamic> _entry() => <String, dynamic>{
    'id': recordId,
    'kind': kind, 'platform': selectedPlatform,
    'brand': brand.text.trim(), 'model': model.text.trim(),
    'caliberMm': kind == 'scope' ? null : _number(caliber),
    'barrelLengthMm': kind == 'rifle' ? _number(barrel) : null,
    // Twist is entered in the profile editor; editing the record here must
    // not silently drop it.
    'twistDirection': kind == 'rifle' ? (existing?['twistDirection']) : null,
    'twistRateIn': kind == 'rifle' ? (existing?['twistRateIn']) : null,
    'regulatorBar': kind == 'rifle' ? (existing?['regulatorBar']) : null,
    'minMag': kind == 'scope' ? (existing?['minMag']) : null,
    'maxMag': kind == 'scope' ? (existing?['maxMag']) : null,
    'elevationRangeMrad': kind == 'scope'
        ? (existing?['elevationRangeMrad'])
        : null,
    'windageRangeMrad': kind == 'scope' ? (existing?['windageRangeMrad']) : null,
    'grain': (kind == 'ammo' || kind == 'custom_ammunition') ? _number(grain) : null,
    'ammoType': (kind == 'ammo' || kind == 'custom_ammunition')
        ? (selectedPlatform == 'firearm' ? 'bullet' : (ammoType == 'bullet' ? 'pellet' : ammoType))
        : null,
    'bc': (kind == 'ammo' || kind == 'custom_ammunition') ? _number(bc) : null,
    'diameterMm': kind == 'custom_ammunition' ? _number(diameter) : null,
    'lengthMm': kind == 'custom_ammunition' ? _number(length) : null,
    'bcModel': kind == 'custom_ammunition' ? bcModel.text.trim() : null,
    'material': kind == 'custom_ammunition' ? material.text.trim() : null,
    'shape': kind == 'custom_ammunition' ? shape.text.trim() : null,
    'lot': kind == 'custom_ammunition' ? lot.text.trim() : null,
    'objectiveMm': kind == 'scope' ? _number(objective) : null,
    'magnification': kind == 'scope' ? magnification.text.trim() : null,
    'focal': kind == 'scope' ? focal : null,
    'click': kind == 'scope' ? _number(click) : null,
    'clickUnit': kind == 'scope' ? clickUnit : null,
    'notes': notes.text.trim(), 'sourceName': 'Kullanıcı girdisi',
  };

  Future<void> _save() async {
    if (saving) return; // re-entrancy guard: one write per tap sequence
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      saveError = null;
    });
    try {
      await widget.onSave(_entry());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      // Fields are untouched; the user can correct or simply retry.
      setState(() {
        saving = false;
        saveError = 'Kayıt başarısız: $error';
      });
    }
  }

  String? _optionalPositive(String? v, String message) =>
      v == null || v.trim().isEmpty || (double.tryParse(v.replaceAll(',', '.')) ?? 0) > 0 ? null : message;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: Text(kind == 'custom_ammunition' ? 'Özel Yapım Mermiler' : existing == null ? 'Manuel model ekle' : 'Manuel modeli düzenle'),
      content: SizedBox(width: 440, child: SingleChildScrollView(child: Form(key: form, child: AbsorbPointer(absorbing: saving, child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (kind != 'custom_ammunition') DropdownButtonFormField<String>(initialValue: kind, decoration: const InputDecoration(labelText: 'Kategori'), items: const [
          DropdownMenuItem(value: 'rifle', child: Text('Tüfek')),
          DropdownMenuItem(value: 'ammo', child: Text('Mühimmat')),
          DropdownMenuItem(value: 'scope', child: Text('Dürbün')),
        ], onChanged: existing != null ? null : (v) => setState(() => kind = v!)),
        if (kind != 'scope') DropdownButtonFormField<String>(initialValue: selectedPlatform, decoration: const InputDecoration(labelText: 'Platform'), items: const [
          DropdownMenuItem(value: 'pcp', child: Text('PCP')),
          DropdownMenuItem(value: 'firearm', child: Text('Ateşli')),
        ], onChanged: (v) => setState(() {
          selectedPlatform = v!;
          if (kind == 'ammo' || kind == 'custom_ammunition') {
            ammoType = selectedPlatform == 'firearm' ? 'bullet' : 'pellet';
          }
        })),
        TextFormField(controller: brand, decoration: const InputDecoration(labelText: 'Marka *'), validator: (v) => kind != 'custom_ammunition' && (v == null || v.trim().isEmpty) ? 'Marka gerekli' : null),
        TextFormField(controller: model, decoration: const InputDecoration(labelText: 'Model *'), validator: (v) => v == null || v.trim().isEmpty ? 'Model gerekli' : null),
        if (kind != 'scope') TextFormField(controller: caliber, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Kalibre (mm) *'), validator: (v) => kind == 'custom_ammunition' && (v == null || v.trim().isEmpty) ? null : (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) > 0 ? null : 'Pozitif kalibre girin'),
        if (kind == 'rifle') TextFormField(controller: barrel, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Namlu boyu (mm, isteğe bağlı)'), validator: (v) => _optionalPositive(v, 'Pozitif namlu boyu girin')),
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
            onChanged: (v) => setState(() => ammoType = v!),
          ),
          TextFormField(controller: grain, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Ağırlık (grain) *'), validator: (v) => kind == 'custom_ammunition' && (v == null || v.trim().isEmpty) ? null : (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) > 0 ? null : 'Pozitif ağırlık girin'),
          TextFormField(controller: bc, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'BC (isteğe bağlı)'), validator: (v) => _optionalPositive(v, 'Geçerli BC girin')),
        ],
        if (kind == 'custom_ammunition') ...[
          TextFormField(controller: diameter, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Gerçek çap (mm)'), validator: (v) => _optionalPositive(v, 'Pozitif çap girin')),
          TextFormField(controller: length, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Uzunluk (mm)'), validator: (v) => _optionalPositive(v, 'Pozitif uzunluk girin')),
          // A BC means nothing without its drag law, and G1 vs G7 values are not
          // interchangeable, so a BC requires an explicit G1/G7 choice.
          DropdownButtonFormField<String>(
            key: const ValueKey('bc-model'),
            initialValue: const ['G1', 'G7'].contains(bcModel.text.trim().toUpperCase()) ? bcModel.text.trim().toUpperCase() : null,
            decoration: const InputDecoration(labelText: 'BC sürtünme yasası (G1 / G7)', helperText: 'Üreticinin BC değerini hangi yasaya göre verdiğine bakın; emin değilseniz BC girmeyin.'),
            items: const [
              DropdownMenuItem(value: 'G1', child: Text('G1')),
              DropdownMenuItem(value: 'G7', child: Text('G7')),
            ],
            onChanged: (v) => setState(() => bcModel.text = v ?? ''),
            validator: (v) => bc.text.trim().isNotEmpty && v == null ? 'BC için G1 veya G7 seçin' : null,
          ),
          TextFormField(controller: material, decoration: const InputDecoration(labelText: 'Malzeme')),
          TextFormField(controller: shape, decoration: const InputDecoration(labelText: 'Çekirdek şekli / tipi')),
          TextFormField(controller: lot, decoration: const InputDecoration(labelText: 'Parti / lot numarası')),
          const Text('Profilde kullanmak için kalibre ve ağırlık gereklidir.'),
        ],
        if (kind == 'scope') ...[
          TextFormField(controller: magnification, decoration: const InputDecoration(labelText: 'Büyütme (ör. 5-25x)')),
          TextFormField(controller: objective, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Objektif (mm)'), validator: (v) => _optionalPositive(v, 'Geçerli çap girin')),
          DropdownButtonFormField<String>(initialValue: focal, decoration: const InputDecoration(labelText: 'Odak düzlemi'), items: const [
            DropdownMenuItem(value: 'unknown', child: Text('Bilinmiyor')),
            DropdownMenuItem(value: 'ffp', child: Text('FFP')),
            DropdownMenuItem(value: 'sfp', child: Text('SFP')),
          ], onChanged: (v) => setState(() => focal = v!)),
          TextFormField(controller: click, decoration: const InputDecoration(labelText: 'Klik değeri (isteğe bağlı)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => _optionalPositive(v, 'Geçerli klik girin')),
          DropdownButtonFormField<String>(initialValue: clickUnit, decoration: const InputDecoration(labelText: 'Klik birimi'), items: const [
            DropdownMenuItem(value: 'mrad', child: Text('MRAD')),
            DropdownMenuItem(value: 'moa', child: Text('MOA')),
          ], onChanged: (v) => setState(() => clickUnit = v!)),
          const Text('Profilde kullanmak için objektif ve klik değeri gereklidir.'),
        ],
        TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'Diğer bilgiler / notlar'), maxLines: 3),
        const SizedBox(height: 8), const Text('Bu kayıt kullanıcı girdisidir; üretici tarafından doğrulanmış değildir.'),
        if (saveError != null) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Semantics(liveRegion: true, child: Text(saveError!, key: const Key('manual-catalog-save-error'), style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ),
      ]))))),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(), child: const Text('İptal')),
        FilledButton(
          key: const Key('manual-catalog-save'),
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Kaydediliyor'))
              : const Text('Kaydet'),
        ),
      ],
    ),
  );
}
