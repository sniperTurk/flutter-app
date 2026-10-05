import 'dart:async';
// ignore: unnecessary_import
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/catalog_repository.dart';
import '../../models/domain.dart';
import '../../services/active_profile_store.dart';
import '../../services/profile_store.dart';
import '../../tools/domain/sight_height_geometry.dart';
import '../../tools/domain/sight_height_physical.dart';
import '../../tools/ports/camera_service.dart';
import '../../tools/ports/photo_picker.dart';
import '../../tools/ports/vision_assist.dart';
import '../../tools/tools_services.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'sight_height_diagrams.dart';
import 'tool_support.dart';

/// Sight Height (Menzil design "Sight Height" + "Noktaları işaretle").
///
/// TWO INDEPENDENT METHODS, neither required by the other:
///  * Physical: four caliper measurements taken at the scope's FRONT
///    (objective) end, the end nearest the muzzle:
///    bore radius + barrel top wall + front gap + objective OUTER radius.
///  * Photo (optional): mark three points on a landscape side photo taken
///    with the camera or chosen from the gallery. The result is an estimate.
///
/// Neither result is written to a profile before the user picks a profile
/// and confirms the old -> new change. Photos live only in memory on this
/// page: never stored, never uploaded. The optional visual-assist port
/// (Qwen Vision) is not connected in this version and nothing depends on it.
class SightHeightScreen extends StatefulWidget {
  /// Injected in tests; default to the persistent stores.
  final ProfileStore? profileStore;
  final ActiveProfileStore? activeProfileStore;
  const SightHeightScreen({
    super.key,
    this.profileStore,
    this.activeProfileStore,
  });

  @override
  State<SightHeightScreen> createState() => _SightHeightScreenState();
}

class _SightHeightScreenState extends State<SightHeightScreen> {
  late final ProfileStore _profiles =
      widget.profileStore ?? PersistentProfileStore();
  late final ActiveProfileStore _activeStore =
      widget.activeProfileStore ?? PersistentActiveProfileStore();

  final _bore = TextEditingController();
  final _wall = TextEditingController();
  final _gap = TextEditingController();
  final _objective = TextEditingController();

  RifleProfile? _active;
  String? _boreNote;
  String? _objectiveNote;

  SightHeightResult? _photoResult;
  Uint8List? _photo;
  String? _visionNote;

  @override
  void initState() {
    super.initState();
    unawaited(_loadActiveProfile());
  }

  @override
  void dispose() {
    _bore.dispose();
    _wall.dispose();
    _gap.dispose();
    _objective.dispose();
    super.dispose();
  }

  /// Prefills caliber and (when published) the objective OUTER diameter from
  /// the active profile. Everything stays editable; any failure just leaves
  /// the fields empty.
  Future<void> _loadActiveProfile() async {
    try {
      final id = await _activeStore.getActiveProfileId();
      if (id == null) return;
      final all = await _profiles.all();
      RifleProfile? profile;
      for (final p in all) {
        if (p.id == id) profile = p;
      }
      if (profile == null || !mounted) return;
      Rifle? rifle;
      for (final r in CatalogRepository.allRifles) {
        if (r.id == profile.rifleId) rifle = r;
      }
      ScopeOptic? scope;
      for (final s in CatalogRepository.allScopes) {
        if (s.id == profile.scopeId) scope = s;
      }
      if (!mounted) return;
      setState(() {
        _active = profile;
        if (rifle != null && _bore.text.isEmpty) {
          _bore.text = _plain(rifle.caliberMm);
          _boreNote =
              'Aktif profilden gelir: ${rifle.brand} ${rifle.model} · ${_plain(rifle.caliberMm)} mm.';
        }
        final outer = scope?.objectiveOuterDiameterMm;
        if (outer != null && _objective.text.isEmpty) {
          _objective.text = _plain(outer);
          _objectiveNote = 'Katalogdan gelir (${scope!.brand} ${scope.model}).';
        }
      });
    } catch (_) {
      // Fields simply stay empty.
    }
  }

  static String _plain(double v) => v.toString().replaceAll('.', ',');

  static double? _parse(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    return (v == null || !v.isFinite || v <= 0) ? null : v;
  }

  PhysicalSightHeight? get _physical => SightHeightPhysical.compute(
    boreDiameterMm: _parse(_bore),
    barrelWallMm: _parse(_wall),
    gapMm: _parse(_gap),
    objectiveOuterDiameterMm: _parse(_objective),
  );

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ---------------------------------------------------------------- photo
  Future<void> _takePhoto() async {
    final photo = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute<Uint8List>(
        fullscreenDialog: true,
        builder: (_) => const _CapturePage(side: true),
      ),
    );
    if (photo != null && mounted) await _markPhoto(photo);
  }

  Future<void> _pickFromGallery() async {
    final picker = ToolsServicesScope.of(context).photoPicker;
    final Uint8List? photo;
    try {
      photo = await picker.pickPhoto();
    } on PhotoPickFailure catch (e) {
      if (mounted) _snack(e.message);
      return;
    } catch (_) {
      if (mounted) _snack('Galeri açılamadı.');
      return;
    }
    if (photo != null && mounted) await _markPhoto(photo);
  }

  Future<void> _markPhoto(Uint8List photo) async {
    final marks = await Navigator.push<List<PixelPoint>>(
      context,
      MaterialPageRoute<List<PixelPoint>>(
        builder: (_) => _MarkPage(photo: photo),
      ),
    );
    if (marks == null || !mounted) return;
    // The scale needs the objective OUTER diameter. The physical method is
    // NOT required for this: it is asked here when the field is empty.
    double? known = _parse(_objective);
    if (known == null) {
      final asked = await _askObjectiveDiameter();
      if (asked == null || !mounted) return;
      setState(() {
        _objective.text = _plain(asked);
        _objectiveNote = null;
      });
      known = asked;
    }
    final diameter = known;
    final result = SightHeightGeometry.measure(
      objectiveOuterDiameterMm: diameter,
      objectiveTop: marks[0],
      objectiveBottom: marks[1],
      boreCentre: marks[2],
    );
    if (result == null) {
      _snack(
        'İşaretlerden makul bir sonuç çıkmadı. Noktaları yeniden işaretleyin.',
      );
      return;
    }
    setState(() {
      _photo = photo;
      _photoResult = result;
    });
  }

  Future<double?> _askObjectiveDiameter() => showDialog<double>(
    context: context,
    builder: (_) => const _ObjectiveDiameterDialog(),
  );

  Future<void> _askVision() async {
    final photo = _photo;
    if (photo == null) return;
    final vision = ToolsServicesScope.of(context).vision;
    if (!vision.isConnected) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fotoğraf cihaz dışına gönderilecek'),
        content: const Text(
          'Görsel yardım için yan fotoğraf harici bir servise gönderilir. '
          'Göndermeden önce onayınız gerekir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await vision.analyze(photo);
    if (!mounted) return;
    setState(() {
      _visionNote = switch (res) {
        VisionSuggestion(:final description) =>
          'Yardımcı öneri (doğrulanmamıştır): $description',
        VisionUnavailable(:final reason) => reason,
      };
    });
  }

  // ---------------------------------------------------------------- apply
  /// Shared by both methods. Shows the profile choice and the old -> new
  /// value in a dialog; nothing is saved without that confirmation.
  Future<void> _apply(double newHeightMm) async {
    final List<RifleProfile> all;
    try {
      all = await _profiles.all();
    } catch (_) {
      if (mounted) _snack('Profiller okunamadı.');
      return;
    }
    if (!mounted) return;
    if (all.isEmpty) {
      _snack('Kayıtlı profil yok. Önce Profil sekmesinde oluşturun.');
      return;
    }
    final chosen = await showDialog<RifleProfile>(
      context: context,
      builder: (_) => _ApplyDialog(
        profiles: all,
        newHeightMm: newHeightMm,
        activeProfileId: _active?.id,
      ),
    );
    if (chosen == null || !mounted) return;
    final RifleProfile updated;
    try {
      updated = ToolProfileUpdate.apply(chosen, sightHeightMm: newHeightMm);
    } on FormatException catch (e) {
      _snack(e.message);
      return;
    }
    try {
      await _profiles.save(updated);
      if (mounted) _snack('Dürbün yüksekliği profile uygulandı.');
    } catch (_) {
      if (mounted) _snack('Profil kaydedilemedi. Mevcut değer korundu.');
    }
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final physical = _physical;
    final vision = ToolsServicesScope.of(context).vision;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Sight Height'),
      body: MenzilPage(
        children: [
          MenzilCard(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label:
                      'Yan görünüş: tüfek ve dürbün. Arka göz merceği solda, ön objektif sağda, namlu ağzı sağda. '
                      'Mavi kesikli çizgi dürbün ekseni, kırmızı kesikli çizgi namlu ekseni. Ölçüm noktası dürbünün ön '
                      'ucunun altında, namlu deliği merkezindedir. Dürbün yüksekliği dört parçanın toplamıdır.',
                  child: ExcludeSemantics(
                    child: AspectRatio(
                      aspectRatio:
                          sightSideViewSize.width / sightSideViewSize.height,
                      child: CustomPaint(
                        key: const Key('sight-side-view'),
                        painter: SightSideViewPainter(c),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: Text(
                    'Namlu deliğinin merkezinden dürbün merkezine, dik olarak ölçülen mesafedir.',
                    style: MenzilType.body(c.ink2).copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          _partsCard(c),
          const MenzilNotice(
            key: Key('sight-inclined-mount'),
            tone: MenzilNoticeTone.info,
            title: 'Ölçüm noktası',
            message:
                'Bütün ölçüleri dürbünün namlu ağzına en yakın ön objektif ucunda alın. Dürbün namluya göre '
                'eğimli monte edilmişse de doğru sonuç verir. Ölçüm yapmadan önce silahı boşaltın ve emniyette tutun.',
          ),
          const MenzilSectionHeader(
            'Ölçüler',
            padding: EdgeInsets.only(top: MenzilSpace.xs),
          ),
          _measureList(c, physical),
          _resultCard(c, physical),
          MenzilPrimaryButton(
            key: const Key('sight-apply'),
            label: 'Profile uygula',
            icon: Icons.save_alt,
            onPressed: physical == null
                ? null
                : () => _apply(physical.roundedMm),
          ),
          const MenzilNotice(
            tone: MenzilNoticeTone.info,
            message:
                'Profil seçimi ve eski/yeni değer uygulamadan önce bir pencerede gösterilir.',
          ),
          MenzilAccordion(
            key: const Key('sight-photo-section'),
            title: 'Fotoğrafla kontrol',
            initiallyExpanded: true,
            child: _photoSection(c, vision),
          ),
        ],
      ),
    );
  }

  Widget _partsCard(MenzilColors c) {
    Widget part(String n, String bold, String rest) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NumBadge(n),
          const SizedBox(width: MenzilSpace.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$bold ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: rest),
                ],
              ),
              style: MenzilType.body(
                c.ink,
              ).copyWith(fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
    return MenzilCard(
      key: const Key('sight-parts'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          part('1', 'Namlu iç yarıçapı:', 'namlu iç çapının (kalibre) yarısı.'),
          Divider(height: 1, color: c.surface2),
          part(
            '2',
            'Namlu üst et kalınlığı:',
            'namlu deliğinin üst kenarından namlunun üst dış yüzeyine.',
          ),
          Divider(height: 1, color: c.surface2),
          part(
            '3',
            'Boşluk:',
            'dürbünün namlu ağzı tarafındaki ön ucunda, dürbünün alt yüzeyinden namlunun üst yüzeyine. Kumpas ile ölçünüz.',
          ),
          Divider(height: 1, color: c.surface2),
          part(
            '4',
            'Dürbün yarıçapı:',
            'dürbünün aynı ön uçtaki (objektif) dış çapının yarısı.',
          ),
        ],
      ),
    );
  }

  Widget _measureList(MenzilColors c, PhysicalSightHeight? physical) {
    final bore = _parse(_bore), objective = _parse(_objective);
    final rows = <Widget>[
      _MeasureRow(
        number: '1',
        label: 'Namlu iç çapı (kalibre)',
        controller: _bore,
        fieldKey: const Key('sight-bore'),
        caption:
            '${_boreNote ?? 'Aktif profil yoksa kalibreyi girin.'}'
            '${bore == null ? '' : ' Hesapta yarısı (${PhysicalSightHeight.roundedText(bore / 2, 2)} mm) kullanılır.'}',
        onChanged: (_) => setState(() {}),
      ),
      _MeasureRow(
        number: '2',
        label: 'Namlu üst et kalınlığı',
        controller: _wall,
        fieldKey: const Key('sight-wall'),
        caption:
            'Bilmiyorsanız: (namlu dış çapı − iç çap) ÷ 2. Namlu dış çapını kumpas ile ölçünüz.',
        onChanged: (_) => setState(() {}),
      ),
      _MeasureRow(
        number: '3',
        label: 'Dürbün–namlu boşluğu (ön uç)',
        controller: _gap,
        fieldKey: const Key('sight-gap'),
        caption:
            'Dürbünün ön ucunda, alt yüzeyinden namlunun üstüne. Kumpas ile ölçünüz.',
        onChanged: (_) => setState(() {}),
      ),
      _MeasureRow(
        number: '4',
        label: 'Dürbün ön dış çapı (objektif)',
        controller: _objective,
        fieldKey: const Key('sight-objective'),
        caption:
            'Objektif gövdesinin en dış çapı; model adındaki cam çapı (ör. 56) değildir. '
            '${_objectiveNote ?? 'Katalogda yoksa kumpas ile ölçünüz.'}'
            '${objective == null ? '' : ' Hesapta yarısı (${PhysicalSightHeight.roundedText(objective / 2, 1)} mm) kullanılır.'}',
        onChanged: (_) => setState(() {}),
      ),
    ];
    return MenzilCard(
      key: const Key('sight-measures'),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.surface2),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _resultCard(MenzilColors c, PhysicalSightHeight? p) {
    String part(double? v) =>
        v == null ? '—' : '${PhysicalSightHeight.roundedText(v, 2)} mm';
    Widget line(String n, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _NumBadge(n),
          const SizedBox(width: MenzilSpace.md),
          Expanded(
            child: Text(
              label,
              style: MenzilType.body(c.ink).copyWith(fontSize: 14.5),
            ),
          ),
          Text(value, style: MenzilType.number(c.ink, size: 20)),
        ],
      ),
    );
    return MenzilCard(
      key: const Key('sight-result'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.amberSoft,
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dürbün yüksekliği',
                  style: MenzilType.body(
                    c.amberInk,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    p == null
                        ? '— mm'
                        : '${PhysicalSightHeight.roundedText(p.totalMm, 1)} mm',
                    key: const Key('sight-total'),
                    style: MenzilType.display(c.ink, size: 52),
                  ),
                ),
                if (p == null)
                  Text(
                    'Dört ölçüyü geçerli girin; sonuç burada görünür.',
                    style: MenzilType.caption(c.ink2),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line('1', 'Namlu iç yarıçapı', part(p?.boreRadiusMm)),
                Divider(height: 1, color: c.surface2),
                line('2', 'Namlu üst et kalınlığı', part(p?.barrelWallMm)),
                Divider(height: 1, color: c.surface2),
                line('3', 'Dürbün–namlu boşluğu', part(p?.gapMm)),
                Divider(height: 1, color: c.surface2),
                line(
                  '4',
                  'Dürbün yarıçapı (ön uç)',
                  part(p?.objectiveRadiusMm),
                ),
                Divider(height: 1, color: c.line),
                const SizedBox(height: MenzilSpace.sm),
                Text(
                  'Toplam',
                  style: MenzilType.body(
                    c.ink,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  p == null
                      ? '—'
                      : '${PhysicalSightHeight.roundedText(p.boreRadiusMm, 2)} + ${PhysicalSightHeight.roundedText(p.barrelWallMm, 2)} + '
                            '${PhysicalSightHeight.roundedText(p.gapMm, 2)} + ${PhysicalSightHeight.roundedText(p.objectiveRadiusMm, 2)} = '
                            '${PhysicalSightHeight.roundedText(p.totalMm, 2)} → ${PhysicalSightHeight.roundedText(p.totalMm, 1)} mm',
                  key: const Key('sight-sum'),
                  style: MenzilType.body(c.ink).copyWith(fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoSection(MenzilColors c, VisionAssist vision) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera_outlined, size: 20, color: c.cyanInk),
            const SizedBox(width: MenzilSpace.sm),
            Expanded(
              child: Text(
                'Yan fotoğrafla ölç (isteğe bağlı)',
                style: MenzilType.body(
                  c.cyanInk,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: MenzilSpace.sm),
        Text(
          'Kumpas yoksa yatay yan fotoğraf üzerinde işaretleyerek tahmin edebilirsiniz. Fiziksel ölçüm gerekmez; '
          'iki yöntem birbirinden bağımsızdır. Yan fotoğraf yatay (landscape) olmalıdır. Görsel yardım (Qwen Vision) '
          'bağlıysa bu akışta isteğe bağlı öneri verir.',
          style: MenzilType.body(c.ink).copyWith(fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: MenzilSpace.sm),
        const MenzilNotice(
          key: Key('sight-muzzle-warning'),
          tone: MenzilNoticeTone.danger,
          title: 'Namlu ağzı açık olmalı',
          message:
              'Namlu ağzında moderatör, susturucu veya alev gizleyen olmamalı. İşaretlenen nokta gerçek namlu '
              'deliğinin merkezi olmalıdır; takılı bir cihazın merkezi namlu ekseniyle aynı olmayabilir.',
        ),
        const SizedBox(height: MenzilSpace.sm),
        MenzilSecondaryButton(
          key: const Key('sight-capture-side'),
          label: 'Fotoğraf çek',
          icon: Icons.photo_camera_outlined,
          expand: true,
          onPressed: _takePhoto,
        ),
        const SizedBox(height: MenzilSpace.sm),
        MenzilSecondaryButton(
          key: const Key('sight-gallery'),
          label: 'Galeriden seç',
          icon: Icons.photo_library_outlined,
          expand: true,
          onPressed: _pickFromGallery,
        ),
        const SizedBox(height: MenzilSpace.md),
        _photoGuideCard(c),
        if (_photoResult != null) ...[
          const SizedBox(height: MenzilSpace.md),
          MenzilCard(
            key: const Key('sight-photo-result'),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fotoğraftan tahmin', style: MenzilType.caption(c.ink2)),
                const SizedBox(height: MenzilSpace.xxs),
                Text(
                  '${PhysicalSightHeight.roundedText(_photoResult!.heightMm, 1)} mm',
                  style: MenzilType.display(c.ink, size: 40),
                ),
                const SizedBox(height: MenzilSpace.xs),
                Text(
                  'Bu bir tahmindir: ölçek objektif ön ucundan alınır ve işaretleme hatası sonuca girer. '
                  'Profile yazmadan önce kumpas veya cetvelle doğrulayın. Fiziksel ölçüm sonucundan bağımsızdır.',
                  style: MenzilType.caption(c.ink2),
                ),
                const SizedBox(height: MenzilSpace.sm),
                MenzilSecondaryButton(
                  key: const Key('sight-photo-apply'),
                  label: 'Fotoğraf sonucunu profile uygula',
                  icon: Icons.save_alt,
                  expand: true,
                  onPressed: () => _apply(
                    double.parse(
                      PhysicalSightHeight.roundedText(
                        _photoResult!.heightMm,
                        1,
                      ).replaceAll(',', '.'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: MenzilSpace.sm),
        if (!vision.isConnected)
          const MenzilNotice(
            key: Key('sight-vision-off'),
            tone: MenzilNoticeTone.info,
            message:
                'Görsel yardım servisi bağlı değil. Fotoğraflar cihazdan çıkmaz ve yapay zekâ sonucu üretilmez.',
          )
        else ...[
          MenzilSecondaryButton(
            label: 'Görsel yardım iste',
            icon: Icons.auto_awesome_outlined,
            expand: true,
            onPressed: _photo == null ? null : _askVision,
          ),
          if (_visionNote != null)
            Padding(
              padding: const EdgeInsets.only(top: MenzilSpace.xs),
              child: Text(_visionNote!, style: MenzilType.caption(c.ink2)),
            ),
        ],
      ],
    );
  }

  Widget _photoGuideCard(MenzilColors c) => MenzilCard(
    key: const Key('sight-photo-guide'),
    margin: EdgeInsets.zero,
    background: c.cyanSoft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.adjust, size: 20, color: c.cyanInk),
            const SizedBox(width: MenzilSpace.sm),
            Expanded(
              child: Text(
                'Fotoğrafta işaretlenecek noktalar',
                style: MenzilType.body(
                  c.cyanInk,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: MenzilSpace.sm),
        Container(
          padding: const EdgeInsets.all(MenzilSpace.sm),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Semantics(
            label:
                'Fotoğrafta işaretlenecek üç nokta: objektif ön ucunun üst kenarı, alt kenarı ve namlu ağzında '
                'delik merkezi.',
            child: ExcludeSemantics(
              child: AspectRatio(
                aspectRatio:
                    sightPhotoGuideSize.width / sightPhotoGuideSize.height,
                child: CustomPaint(painter: SightPhotoGuidePainter(c)),
              ),
            ),
          ),
        ),
        const SizedBox(height: MenzilSpace.sm),
        Text(
          'Turuncu işaretleri fotoğrafta bu üç noktaya sürükleyin; seçili işareti ok tuşlarıyla ince ayarlayın.',
          style: MenzilType.caption(c.ink),
        ),
      ],
    ),
  );
}

class _NumBadge extends StatelessWidget {
  final String n;
  const _NumBadge(this.n);

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.cyanInk, shape: BoxShape.circle),
        child: Text(
          n,
          style: TextStyle(
            color: c.surface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// One numbered measurement row: label, 84 x 44 value box, unit and caption.
class _MeasureRow extends StatelessWidget {
  final String number, label, caption;
  final TextEditingController controller;
  final Key fieldKey;
  final ValueChanged<String> onChanged;
  const _MeasureRow({
    required this.number,
    required this.label,
    required this.caption,
    required this.controller,
    required this.fieldKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(MenzilRadius.input),
      borderSide: BorderSide(color: c.line),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumBadge(number),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: MenzilType.body(
                    c.ink,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 84,
                height: 44,
                child: Semantics(
                  label: '$label, milimetre',
                  textField: true,
                  child: TextField(
                    key: fieldKey,
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: onChanged,
                    style: MenzilType.body(
                      c.ink,
                    ).copyWith(fontWeight: FontWeight.w600, fontSize: 17),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: c.bg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border.copyWith(
                        borderSide: BorderSide(color: c.ink, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 26,
                child: Text('mm', style: MenzilType.caption(c.ink2)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 6),
            child: Text(caption, style: MenzilType.caption(c.ink2)),
          ),
        ],
      ),
    );
  }
}

/// Profile choice with an old -> new preview; nothing changes until "Uygula".
class _ApplyDialog extends StatefulWidget {
  final List<RifleProfile> profiles;
  final double newHeightMm;
  final String? activeProfileId;
  const _ApplyDialog({
    required this.profiles,
    required this.newHeightMm,
    required this.activeProfileId,
  });

  @override
  State<_ApplyDialog> createState() => _ApplyDialogState();
}

class _ApplyDialogState extends State<_ApplyDialog> {
  RifleProfile? _selected;

  @override
  void initState() {
    super.initState();
    for (final p in widget.profiles) {
      if (p.id == widget.activeProfileId) _selected = p;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.profiles]
      ..sort((a, b) {
        final pa = a.id == widget.activeProfileId ? 0 : 1;
        final pb = b.id == widget.activeProfileId ? 0 : 1;
        return pa.compareTo(pb);
      });
    final sel = _selected;
    return AlertDialog(
      title: const Text('Profile uygula'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioGroup<RifleProfile>(
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v),
              child: Column(
                children: [
                  for (final p in sorted)
                    RadioListTile<RifleProfile>(
                      value: p,
                      title: Text(p.name),
                      subtitle: Text(
                        p.id == widget.activeProfileId ? 'Aktif profil' : '',
                      ),
                    ),
                ],
              ),
            ),
            if (sel != null)
              Padding(
                key: const Key('sight-apply-preview'),
                padding: const EdgeInsets.only(top: MenzilSpace.sm),
                child: Text(
                  'Dürbün yüksekliği: ${ToolFormat.dec(sel.sightHeightMm, 1)} mm → '
                  '${ToolFormat.dec(widget.newHeightMm, 1)} mm',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: sel == null ? null : () => Navigator.pop(context, sel),
          child: const Text('Uygula'),
        ),
      ],
    );
  }
}

/// Full-screen landscape capture with an alignment template. The camera
/// session is opened here and ALWAYS disposed; orientation is restored.
class _CapturePage extends StatefulWidget {
  final bool side;
  const _CapturePage({required this.side});

  @override
  State<_CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<_CapturePage> {
  CameraSession? _session;
  CameraUnavailable? _failure;
  bool _busy = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    if (widget.side) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session == null && _failure == null && !_opening) {
      _opening = true;
      unawaited(_open());
    }
  }

  Future<void> _open() async {
    final camera = ToolsServicesScope.of(context).camera;
    try {
      final s = await camera.open();
      if (!mounted) {
        await s.dispose();
        return;
      }
      setState(() => _session = s);
    } on CameraUnavailable catch (e) {
      if (mounted) setState(() => _failure = e);
    } catch (_) {
      if (mounted) {
        setState(
          () => _failure = const CameraUnavailable(
            CameraUnavailableReason.error,
            'Kamera kullanılamıyor.',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    final s = _session;
    _session = null;
    if (s != null) unawaited(s.dispose());
    if (widget.side) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    super.dispose();
  }

  Future<void> _shoot() async {
    final s = _session;
    if (s == null || _busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await s.capture();
      if (mounted) Navigator.pop(context, bytes);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf alınamadı. Tekrar deneyin.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final title = widget.side ? 'Yan fotoğraf' : 'Ön fotoğraf';
    final failure = _failure;
    final Widget body;
    if (failure != null) {
      body = MenzilStateMessage(
        icon: Icons.no_photography_outlined,
        message: failure.message,
        action: failure.reason == CameraUnavailableReason.deniedPermanently
            ? MenzilSecondaryButton(
                label: 'Ayarları aç',
                icon: Icons.settings_outlined,
                onPressed: () =>
                    ToolsServicesScope.of(context).camera.openSettings(),
              )
            : null,
      );
    } else if (_session == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Stack(
        fit: StackFit.expand,
        children: [
          // Center loosens the tight Stack constraints so the preview keeps its
          // own aspect ratio instead of being stretched to the whole body.
          Center(child: _session!.buildPreview(context)),
          IgnorePointer(
            child: CustomPaint(
              key: Key(
                widget.side ? 'sight-template-side' : 'sight-template-front',
              ),
              painter: _TemplatePainter(side: widget.side, color: c.amber),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 8,
            child: MenzilNotice(
              tone: MenzilNoticeTone.info,
              message: widget.side
                  ? 'Telefonu yatay tutun. Objektif gövdesinin üst ve alt kenarı ile namlu şablondaki işaretlere denk gelsin; kamerayı namlu eksenine dik tutun.'
                  : 'Dürbünü tam karşıdan çekin; dürbün ekseni dikey çizgiyle namlu üzerinde ortalı olsun.',
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: MenzilSubPageBar(title: title),
      body: body,
      floatingActionButton: _session == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('sight-shutter'),
              onPressed: _busy ? null : _shoot,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Çek'),
            ),
    );
  }
}

class _TemplatePainter extends CustomPainter {
  final bool side;
  final Color color;
  const _TemplatePainter({required this.side, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final cx = size.width / 2, cy = size.height / 2;
    if (side) {
      // Horizontal barrel axis plus two guides for the objective edges.
      canvas.drawLine(
        Offset(size.width * 0.05, cy + size.height * 0.18),
        Offset(size.width * 0.95, cy + size.height * 0.18),
        p,
      );
      canvas.drawLine(
        Offset(size.width * 0.55, cy - size.height * 0.30),
        Offset(size.width * 0.95, cy - size.height * 0.30),
        p,
      );
      canvas.drawLine(
        Offset(size.width * 0.55, cy - size.height * 0.05),
        Offset(size.width * 0.95, cy - size.height * 0.05),
        p,
      );
    } else {
      canvas.drawLine(
        Offset(cx, size.height * 0.1),
        Offset(cx, size.height * 0.9),
        p,
      );
      canvas.drawLine(
        Offset(size.width * 0.2, cy),
        Offset(size.width * 0.8, cy),
        p,
      );
      canvas.drawCircle(Offset(cx, cy), size.shortestSide * 0.18, p);
    }
  }

  @override
  bool shouldRepaint(covariant _TemplatePainter old) =>
      old.side != side || old.color != color;
}

/// Marking page: three taps on the side photo (objective top edge,
/// objective bottom edge, bore centre). Taps are converted to image pixels
/// using the letterboxed display rectangle.
class _MarkPage extends StatefulWidget {
  final Uint8List photo;
  const _MarkPage({required this.photo});

  @override
  State<_MarkPage> createState() => _MarkPageState();
}

class _MarkPageState extends State<_MarkPage> {
  static const _prompts = [
    '1/3 · Objektifin ÖN ucunda (namlu ağzına en yakın) gövdenin ÜST kenarına dokunun.',
    '2/3 · Aynı ön uçta gövdenin ALT kenarına dokunun.',
    '3/3 · Namlu ağzının MERKEZİNE dokunun (moderatör/susturucu takılı olmamalı).',
  ];

  ui.Image? _image;
  bool _decodeFailed = false;

  /// The side photo must be landscape. The capture UI is forced to
  /// landscape, but the camera follows the PHYSICAL device orientation, so a
  /// phone held upright still produces a portrait image.
  bool _notLandscape = false;
  final List<Offset> _marks = []; // image pixel coordinates
  int? _selectedMark;
  String? _error;

  static const _markLabels = [
    'Objektif üst kenarı',
    'Objektif alt kenarı',
    'Namlu merkezi',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_decode());
  }

  Future<void> _decode() async {
    try {
      final img = await decodeImageFromList(widget.photo);
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() {
        _image = img;
        _notLandscape = img.width <= img.height;
      });
    } catch (_) {
      if (mounted) setState(() => _decodeFailed = true);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Rect _fitRect(Size box, ui.Image img) {
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final scale = (box.width / iw) < (box.height / ih)
        ? box.width / iw
        : box.height / ih;
    final w = iw * scale, h = ih * scale;
    return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
  }

  void _tap(Offset local, Size box) {
    final img = _image;
    if (img == null || _notLandscape || _marks.length >= 3) return;
    final r = _fitRect(box, img);
    if (!r.contains(local)) return;
    final px = Offset(
      (local.dx - r.left) / r.width * img.width,
      (local.dy - r.top) / r.height * img.height,
    );
    setState(() {
      _marks.add(px);
      _error = null;
    });
  }

  void _selectNearest(Offset local, Size box) {
    final img = _image;
    if (img == null || _marks.isEmpty) return;
    final r = _fitRect(box, img);
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < _marks.length; i++) {
      final m = _marks[i];
      final displayed = Offset(
        r.left + m.dx / img.width * r.width,
        r.top + m.dy / img.height * r.height,
      );
      final distance = (displayed - local).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    if (bestDistance <= 44) setState(() => _selectedMark = best);
  }

  void _nudgeSelected(double dx, double dy) {
    final img = _image;
    final index = _selectedMark;
    if (img == null || index == null || index >= _marks.length) return;
    final current = _marks[index];
    setState(() {
      _marks[index] = Offset(
        (current.dx + dx).clamp(0.0, img.width.toDouble()).toDouble(),
        (current.dy + dy).clamp(0.0, img.height.toDouble()).toDouble(),
      );
      _error = null;
    });
  }

  void _finish() {
    if (_marks.length != 3) return;
    Navigator.pop(context, [for (final m in _marks) PixelPoint(m.dx, m.dy)]);
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final img = _image;
    final Widget notice = Padding(
      padding: const EdgeInsets.all(MenzilSpace.md),
      child: MenzilNotice(
        key: const Key('sight-mark-prompt'),
        tone: _error == null ? MenzilNoticeTone.info : MenzilNoticeTone.warning,
        message:
            _error ??
            (_marks.length < 3
                ? _prompts[_marks.length]
                : 'Üç nokta işaretlendi. Sonucu hesaplayın veya sıfırlayın.'),
      ),
    );
    final Widget chips = Padding(
      padding: const EdgeInsets.symmetric(horizontal: MenzilSpace.md),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < 3; i++)
            Semantics(
              label:
                  '${i + 1}. nokta: ${_markLabels[i]}, ${i < _marks.length ? 'işaretlendi' : 'işaretlenmedi'}',
              excludeSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Container(
                  key: Key('sight-mark-chip-$i'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: i < _marks.length ? c.amberSoft : c.surface2,
                    border: Border.all(
                      color: i == _marks.length || i == _selectedMark
                          ? c.amber
                          : c.line,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(MenzilRadius.input),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        i < _marks.length
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: c.amberInk,
                      ),
                      const SizedBox(width: 6),
                      Text(_markLabels[i], style: MenzilType.caption(c.ink)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    final Widget photo = Expanded(
      child: _decodeFailed
          ? const MenzilStateMessage(
              icon: Icons.broken_image_outlined,
              message: 'Fotoğraf okunamadı. Yeniden çekin.',
            )
          : img == null
          ? const Center(child: CircularProgressIndicator())
          : _notLandscape
          ? const MenzilStateMessage(
              key: Key('sight-not-landscape'),
              icon: Icons.screen_rotation_outlined,
              message:
                  'Yan fotoğraf yatay değil. Telefonu yatay tutarak yeniden çekin; '
                  'dikey fotoğrafla ölçüm yapılmaz.',
            )
          : LayoutBuilder(
              builder: (context, box) {
                final size = Size(box.maxWidth, box.maxHeight);
                final r = _fitRect(size, img);
                return Semantics(
                  label:
                      'Fotoğraf işaretleme alanı. ${_marks.length} / 3 nokta işaretlendi.',
                  hint:
                      'Dokunarak işaretlenir. VoiceOver ile hassas işaretleme zordur; yüksekliği kumpasla ölçüp Profil ekranına elle girebilirsiniz.',
                  child: GestureDetector(
                    key: const Key('sight-mark-area'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      if (_marks.length < 3) {
                        _tap(d.localPosition, size);
                        if (_marks.isNotEmpty) {
                          setState(() => _selectedMark = _marks.length - 1);
                        }
                      } else {
                        _selectNearest(d.localPosition, size);
                      }
                    },
                    child: Stack(
                      children: [
                        Positioned.fromRect(
                          rect: r,
                          child: Image.memory(
                            widget.photo,
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MarkPainter(
                              marks: [
                                for (final m in _marks)
                                  Offset(
                                    r.left + m.dx / img.width * r.width,
                                    r.top + m.dy / img.height * r.height,
                                  ),
                              ],
                              color: c.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
    final Widget nudge = _marks.isEmpty
        ? const SizedBox.shrink()
        : Semantics(
            container: true,
            label: _selectedMark == null
                ? 'İşaret seçilmedi'
                : 'Seçili işaret: ${_markLabels[_selectedMark!]}',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MenzilSpace.md),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final entry in const [
                    (Icons.chevron_left, 'Sola', -2.0, 0.0),
                    (Icons.expand_less, 'Yukarı', 0.0, -2.0),
                    (Icons.expand_more, 'Aşağı', 0.0, 2.0),
                    (Icons.chevron_right, 'Sağa', 2.0, 0.0),
                  ])
                    IconButton(
                      tooltip: 'Seçili işareti ${entry.$2.toLowerCase()} taşı',
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: Icon(entry.$1),
                      onPressed: _selectedMark == null
                          ? null
                          : () => _nudgeSelected(entry.$3, entry.$4),
                    ),
                ],
              ),
            ),
          );
    final Widget actions = Padding(
      padding: const EdgeInsets.all(MenzilSpace.md),
      child: Row(
        children: [
          Expanded(
            child: MenzilSecondaryButton(
              key: const Key('sight-mark-reset'),
              label: 'Sıfırla',
              icon: Icons.restart_alt,
              expand: true,
              onPressed: _marks.isEmpty
                  ? null
                  : () => setState(() {
                      _marks.clear();
                      _selectedMark = null;
                    }),
            ),
          ),
          const SizedBox(width: MenzilSpace.sm),
          Expanded(
            child: MenzilPrimaryButton(
              key: const Key('sight-mark-compute'),
              label: 'Hesapla',
              icon: Icons.calculate_outlined,
              onPressed: _marks.length == 3 ? _finish : null,
            ),
          ),
        ],
      ),
    );
    // Short landscape (the camera flow returns here while still landscape):
    // image on the left, controls in a scrolling side panel, so the photo keeps
    // its height and nothing overflows. Portrait keeps the stacked layout.
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Noktaları işaretle'),
      body: SafeArea(
        top: false,
        child: landscape
            ? Row(
                children: [
                  photo,
                  SizedBox(
                    width: 320,
                    child: SingleChildScrollView(
                      child: Column(children: [notice, chips, nudge, actions]),
                    ),
                  ),
                ],
              )
            : Column(children: [notice, chips, photo, nudge, actions]),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final List<Offset> marks;
  final Color color;
  const _MarkPainter({required this.marks, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final m in marks) {
      canvas.drawCircle(m, 9, p);
      canvas.drawLine(Offset(m.dx - 14, m.dy), Offset(m.dx + 14, m.dy), p);
      canvas.drawLine(Offset(m.dx, m.dy - 14), Offset(m.dx, m.dy + 14), p);
    }
    if (marks.length >= 2) canvas.drawLine(marks[0], marks[1], p);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) =>
      old.marks.length != marks.length ||
      old.color != color ||
      !_sameMarks(old.marks, marks);

  static bool _sameMarks(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Asks for the objective OUTER diameter. The controller lives in this
/// dialog's own State so it is disposed only after the route is gone (an
/// early dispose while the close transition still shows the TextField would
/// assert in debug builds).
class _ObjectiveDiameterDialog extends StatefulWidget {
  const _ObjectiveDiameterDialog();

  @override
  State<_ObjectiveDiameterDialog> createState() =>
      _ObjectiveDiameterDialogState();
}

class _ObjectiveDiameterDialogState extends State<_ObjectiveDiameterDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Objektif dış çapı'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fotoğraftan ölçek almak için objektif gövdesinin en dış çapı gerekir; '
            'model adındaki cam çapı (ör. 56) değildir.',
          ),
          const SizedBox(height: MenzilSpace.sm),
          TextField(
            key: const Key('sight-ask-objective'),
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(suffixText: 'mm'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(
              _controller.text.trim().replaceAll(',', '.'),
            );
            if (v != null && v.isFinite && v > 0 && v <= 120) {
              Navigator.pop(context, v);
            }
          },
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}
