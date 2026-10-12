import '../../models/domain.dart';

class ChecklistItem {
  final String id;
  final String title;

  /// ⓘ text: what to check, where, and why it matters.
  final String info;
  const ChecklistItem(this.id, this.title, this.info);
}

/// Ö11 Atış öncesi kontrol listesi: gross errors (wrong turn, wrong unit)
/// that no ballistic model can correct (Litz 2012; Gawande, The Checklist
/// Manifesto, 2009). The Su Terazisi screen itself is not part of this; the
/// list only reminds the shooter to check the level.
abstract final class PreShotChecklist {
  static List<ChecklistItem> items({
    String? profileName,
    AngularUnit? unit,
    bool? firstFocalPlane,
  }) {
    final unitText = unit?.label;
    return [
      ChecklistItem(
        'profile',
        profileName == null ? 'Doğru profil seçili' : 'Doğru profil: $profileName',
        'Hedef ekranındaki düzeltmeler aktif profile göre hesaplanır. Üstteki '
            'profil kutusunda tüfek, fişek ve dürbünün elinizdekiyle aynı '
            'olduğuna bakın. Örnek: 175 gr fişek atarken 168 gr profili yanlış '
            'düşüm verir.',
      ),
      ChecklistItem(
        'unit',
        unitText == null
            ? 'Kule birimi uygulamayla aynı'
            : 'Kule birimi $unitText, uygulamayla aynı',
        'Dürbün kulesinin üstünde birim yazar: MRAD veya MOA. Uygulamanın '
            'gösterdiği birimle aynı olmalı. MOA kuleye MRAD değeri çevirmek '
            'düzeltmeyi yaklaşık 3,4 kat yanlış yapar.',
      ),
      const ChecklistItem(
        'turret',
        'Kule doğru yönde ve doğru turda',
        'Yükseliş kulesini UP yönüne çevirin ve tur göstergesine bakın. '
            'Bir tur çoğu dürbünde 10 MRAD eder; yanlış turda 800 m’de yaklaşık '
            '8 m ıska olur. Yan kulede R ve L yönünü de kontrol edin.',
      ),
      const ChecklistItem(
        'parallax',
        'Paralaks hedef mesafesine ayarlı',
        'Paralaks düğmesini hedef mesafesine getirin. Gözünüzü dürbünün '
            'arkasında hafifçe oynatın: retikül hedef üzerinde kaymamalı. '
            'Kayıyorsa düğmeyi kayma bitene kadar çevirin.',
      ),
      const ChecklistItem(
        'level',
        'Su terazisi ortada, dürbün yatay',
        'Dürbün üstündeki veya raydaki su terazisinin kabarcığı ortada olmalı. '
            'Eğik tutulan tüfekte yükseliş düzeltmesi yana kaçırır; uzak '
            'mesafede birkaç derece eğim bile ıska ettirebilir.',
      ),
      if (firstFocalPlane != true)
        const ChecklistItem(
          'sfp',
          'Büyütme retikül tutuşuna uygun',
          'İkinci odak düzlemli dürbünde retikül ölçüleri yalnız bir '
              'büyütmede doğrudur, çoğunlukla en yüksek büyütmede. Retikülle '
              'tutuş yapacaksanız büyütmeyi o değere getirin; dürbünün '
              'kılavuzunda yazar. Kuleyle düzeltmede büyütme önemsizdir.',
        ),
    ];
  }
}
