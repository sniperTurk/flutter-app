import 'package:flutter/material.dart';
import '../../models/domain.dart';
import '../../services/user_catalog_store.dart';

class ManualCatalogDialog extends StatefulWidget {
  final WeaponPlatform platform;
  final Map<String, dynamic>? initial;
  const ManualCatalogDialog({super.key, required this.platform, this.initial});
  @override
  State<ManualCatalogDialog> createState() => _ManualCatalogDialogState();
}

class _ManualCatalogDialogState extends State<ManualCatalogDialog> {
  late String kind = widget.initial?['kind'] as String? ?? 'rifle';
  late String platform = widget.initial?['platform'] as String? ?? widget.platform.name;
  late String type = widget.initial?['type'] as String? ??
      (platform == 'firearm' ? 'bullet' : 'pellet');
  late String clickUnit = widget.initial?['clickUnit'] as String? ?? 'mrad';
  final fields = <String, TextEditingController>{};
  String? error;
  TextEditingController controller(String key) => fields.putIfAbsent(key,
      () => TextEditingController(text: widget.initial?[key]?.toString() ?? ''));

  @override
  void dispose() {
    for (final c in fields.values) { c.dispose(); }
    super.dispose();
  }

  Widget field(String key, String label, {bool number = false, bool required = false}) =>
      TextField(controller: controller(key),
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: '$label${required ? ' *' : ''}'));

  void save() {
    final entry = <String, dynamic>{
      'id': widget.initial?['id'] ?? 'user-${DateTime.now().microsecondsSinceEpoch}',
      'kind': kind, 'platform': platform, 'brand': controller('brand').text.trim(),
      'model': controller('model').text.trim(),
    };
    double? numeric(String key) {
      final text = controller(key).text.trim().replaceAll(',', '.');
      if (text.isEmpty) return null;
      final value = double.tryParse(text);
      if (value == null || !value.isFinite || value <= 0) {
        throw FormatException('$key: pozitif sayı girin');
      }
      return value;
    }
    try {
      if (kind == 'rifle' || kind == 'ammunition') entry['caliberMm'] = numeric('caliberMm');
      if (kind == 'rifle') {
        entry['barrelLengthMm'] = numeric('barrelLengthMm');
        if (platform == 'pcp') entry['airCapacityCc'] = numeric('airCapacityCc');
      }
      if (kind == 'ammunition') { entry['grain'] = numeric('grain'); entry['type'] = platform == 'firearm' ? 'bullet' : type; }
      if (kind == 'scope') {
        entry['objectiveDiameterMm'] = numeric('objectiveDiameterMm');
        entry['clickValue'] = numeric('clickValue');
        entry['clickUnit'] = clickUnit;
      }
      UserCatalogStore.validate(entry);
      Navigator.pop(context, entry);
    } on FormatException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Manuel model ekle' : 'Kişisel modeli düzenle'),
    content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: kind,
          decoration: const InputDecoration(labelText: 'Kayıt türü'),
          items: const [DropdownMenuItem(value:'rifle',child:Text('Tüfek')),
            DropdownMenuItem(value:'ammunition',child:Text('Mühimmat')),
            DropdownMenuItem(value:'scope',child:Text('Dürbün'))],
          onChanged: widget.initial != null ? null : (v) => setState(() => kind = v!)),
        if (kind != 'scope') DropdownButtonFormField<String>(initialValue: platform,
          decoration: const InputDecoration(labelText: 'Platform'),
          items: const [DropdownMenuItem(value:'pcp',child:Text('PCP')),
            DropdownMenuItem(value:'firearm',child:Text('Ateşli'))],
          onChanged: (v) => setState(() {platform = v!; type = platform == 'pcp' ? 'pellet' : 'bullet';})),
        field('brand', 'Marka', required: true), field('model', 'Model', required: true),
        if (kind != 'scope') field('caliberMm', 'Kalibre (mm)', number:true, required:true),
        if (kind == 'rifle') ...[
          field('barrelLengthMm', 'Namlu uzunluğu (mm)', number:true),
          if (platform == 'pcp') field('airCapacityCc', 'Hava hacmi (cc)', number:true),
        ],
        if (kind == 'ammunition') ...[
          field('grain', 'Ağırlık (grain)', number:true, required:true),
          DropdownButtonFormField<String>(
            key: ValueKey('legacy-ammo-type-$platform'),
            initialValue: platform == 'firearm' ? 'bullet' : type,
            decoration: const InputDecoration(labelText:'Mühimmat tipi'),
            items: (platform == 'firearm' ? ['bullet'] : ['pellet','slug'])
              .map((v) => DropdownMenuItem(value:v,child:Text(v))).toList(),
            onChanged:(v)=>setState(()=>type=v!)),
        ],
        if (kind == 'scope') ...[
          field('objectiveDiameterMm','Objektif çapı (mm)',number:true,required:true),
          field('clickValue','Klik değeri',number:true,required:true),
          DropdownButtonFormField<String>(initialValue:clickUnit,
            items: const [DropdownMenuItem(value:'mrad',child:Text('MRAD')),
              DropdownMenuItem(value:'moa',child:Text('MOA'))],
            onChanged:(v)=>setState(()=>clickUnit=v!)),
        ],
        const SizedBox(height:12),
        const Text('Kişisel kayıt; üretici tarafından doğrulanmış değildir.'),
        if (error != null) Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
      ]))),
    actions: [TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Vazgeç')),
      FilledButton(onPressed:save,child:const Text('Kaydet'))],
  );
}
