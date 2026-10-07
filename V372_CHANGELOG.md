# V372 — Atış sekmesinde etkileşimli dürbün (kule + retikül)

Kaynak: V371. Menzil/Atış sayfasındaki dürbün artık statik bir resim değil:
yükseklik ve rüzgâr kuleleri çevrildikçe seçili mesafedeki vuruş noktası
retikül üzerinde canlı gösteriliyor (Strelok tarzı çalışma yapısı).

## Yeni
- `lib/core/scope_dial.dart` — saf hesap katmanı (`ScopeDialMath`):
  klik→açı, gereken düzeltmeye göre vuruş noktası ofseti, her retikül
  işaretinin vuracağı mesafe (holdover), açıdan doğrusal ofset (cm/in).
  Yakın-namlu (yükselen) kol yok sayılır, örnek aralığı dışına asla
  ekstrapolasyon yapılmaz.
- `lib/features/ballistics/scope_dial_view.dart` — `ScopeDialView`:
  - Üstte yükseklik kulesi (yatay tambur, sürükle veya ‹ › ile 1 klik),
    sağda rüzgâr kulesi (dikey tambur). Ana çizgiler 1 mrad / 1 MOA.
  - Retikül dürbünün kendi birimiyle çizilir: mrad için 1 mrad mil-dot,
    MOA için 2 MOA çentik; kalın kollar alanın %82'sinden sonra.
  - Sarı/amber vuruş noktası; alan dışındaysa kenarda yön oku.
  - Dikey işaretlerin yanında kırmızı mesafe etiketleri (o işareti hedefe
    tutunca vurulan mesafe); kule değiştikçe yeniden hesaplanır.
  - "Çözümü kuleye kur" (gereken kliki tek dokunuşla kurar) ve
    "Kuleleri sıfırla".
  - Kule hareketi katalogdaki toplam ayar aralığının yarısıyla sınırlı
    (`elevationRangeMrad` / `windageRangeMrad`; yoksa ±30 mrad).
  - Erişilebilirlik: kuleler `slider` semantiği ve artır/azalt eylemleri,
    vuruş noktası metni `liveRegion`.

## Değişen
- `ballistics_screen.dart`: statik `_SafeReticlePainter` kaldırıldı,
  yerine `_scopeDial(shot)`. Kule klikleri çalışma alanı durumunda tutulur
  (sekme değişiminde korunur; yeni profil sıfırdan başlar). Holdover eğrisi
  her doğrulanmış çözüm için bir kez (1 m adımla, 3000 m'ye kadar) önbelleğe
  alınır.

## Güvenlik sınırları (değişmedi)
- Rüzgâr hâlâ modellenmiyor: gereken rüzgâr düzeltmesi 0 kabul edilir,
  rüzgâr kulesi yalnızca nişan kaydırmasını gösterir; "Rüzgâr" kartı
  `KİLİTLİ` kalır. `windMrad` bu görünümde kullanılmaz.
- Yükseklik değerleri V354'teki gibi vakum düşüşünden gelir; mevcut tehlike
  uyarısı aynen duruyor. G1/G7 üretim kapısı KAPALI.
- Doğrulanmış çözüm yokken vuruş noktası ve mesafe etiketleri çizilmez,
  "Çözümü kuleye kur" devre dışıdır.
- Retikül aralıkları dürbünün kalibre edildiği büyütmede geçerlidir (FFP'de
  her büyütmede); SFP büyütme ölçeklemesi bu sürümde yok.

## Testler
- Yeni: `test/scope_dial_test.dart` (hesap katmanı),
  `test/scope_dial_view_test.dart` (kuleler, çözümü kurma, sıfırlama,
  rüzgâr kliki, tambur sürükleme),
  `tools/test_v372_interactive_scope_dial.py` (sözleşme).
- Güncellenen: `tools/test_v352_safe_shot_view.py` (statik retikül yerine
  etkileşimli görünüm).
- Bu ortamda: çevrimdışı Dart lint GEÇTİ (126 dosya, 0 sorun), Python
  regresyon paketi GEÇTİ (593 test). Flutter SDK indirilemediği için
  `flutter analyze`, `dart format`, `flutter test` ve iOS derlemesi
  ÇALIŞTIRILMADI — `tools/claude_flutter_verify.sh` / iOS CI ile doğrulanmalı.
