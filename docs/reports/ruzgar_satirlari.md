# Hedef: rüzgâr satırları Hesap dökümü'nün üstünde, tek satır

Sahip, 17.10.2026 11:56–12:23 (İstanbul), TestFlight 112, Hedef sayfası dürbün kartının altı:
"Yazı sanki hesap dökümü olarak algılanıyor; bunu okuyan kişi açılır menüye tıklamayabilir." ·
"İki yazıyı da tek satıra sığdır, toplam 2 satır olacak." · çizim onayı: "tamam böyle olsun", "aç".

## Ne değişti

Hedef sayfasında dürbün kartının sırası artık şöyle:

1. Kule satırı, **Vuruş noktası** satırı ve gri açıklama paragrafı (değişmedi)
2. `Rüzgâr 6,2 m/s: 24 klik sol · 9,3 m/s: 37 klik sol`
3. `Yana kayma: yakın %56 · orta %33 · uzak %11`
4. **Hesap dökümü** (açılır satır, kartın en altında, tek başına)

Eskiden bu iki yazı Hesap dökümü'nün altındaydı ve şöyleydi:
"Rüzgâr 6,2–9,3 m/s: yan düzeltme 24 klik L – 37 klik L." ve
"Rüzgâr etkisi: yakın %56 · orta %33 · uzak %11".

- Birinci satır: Hava Durumu'ndaki rüzgâr hızı ve o hızdaki yan kule klikleri, sonra En yüksek rüzgâr ve o hızdaki klikler. R/L yerine "sağ"/"sol" yazıyor. ABD biriminde mph (önceki gibi).
- İkinci satır: yalnız baş kelime değişti ("Rüzgâr etkisi" → "Yana kayma"); yüzdeler aynı.
- Her satır tek satırda kalır. Dar ekranda ya da büyük yazı boyutunda alt satıra geçmez; yazı biraz küçülür. Rakam kesilmez, "…" konmaz.

## Nasıl

- `lib/features/ballistics/ballistics_screen.dart`: iki satır `_extraShotNotes`'tan yeni `_windShotLines` metoduna taşındı. Hesap ve gösterme koşulları aynen kaldı (aynı `solve` çağrısı, aynı spin drift / sıfır ofseti düşümü, aynı `WindZoneShares`). Yalnız metin biçimi değişti. Her satır `Align` + `FittedBox(scaleDown)` + `Text(maxLines: 1, softWrap: false)` içinde.
- `lib/features/ballistics/scope_dial_view.dart`: `ScopeDialView`'a `aboveWorkings` parametresi eklendi. Satırlar okuma paragrafı ile Hesap dökümü arasına konuyor.
- Anahtarlar aynı: `shot-wind-bracket`, `shot-wind-zone-shares`.

## Neden

Sahip yazıların Hesap dökümü'ne ait sanıldığını, okuyanın açılır menüye dokunmayabileceğini söyledi. Bu yüzden satırlar Vuruş noktası'nın hemen altına alındı ve kısaltıldı.

## Uç durumlar

- **En yüksek rüzgâr boş** (ya da rüzgâr hızından büyük değil): "Rüzgâr …" satırı görünmez, önceki gibi. "Yana kayma" satırı görünür (BC'li hesapta). Testle kontrol edildi.
- **BC yok (vakum modeli)**: iki satır da görünmez, önceki gibi.
- **Klik 0**: "0 klik" yazar, yön kelimesi yazmaz (önceki R/L kuralı ile aynı).
- **Dürbünün klik değeri katalogda yok**: dürbün yerine uyarı kartı çıkıyor. Satırlar önceki gibi açı birimiyle görünmeye devam ediyor (örn. "0,45 MRAD sağ"); artık uyarının hemen altında.
- **Diğer notlar** (spin drift, isabet olasılığı, hareketli hedef, uçuş uyarıları) yerinde kaldı: kartta Hesap dökümü'nün altında, eskisi gibi. Sahip bunlar için bir şey söylemedi. O notlar çıktığında Hesap dökümü kartın en son satırı olmuyor.

## Bilerek yapılmayan

- Hesap, sayı, Hesap dökümü içeriği ya da anahtar değişmedi. Başka metne dokunulmadı.
- Kullanım rehberi ve ⓘ metinleri değiştirilmedi. Eski satırı **harfi harfine** alıntılayan metin yok. Yalnız aralığı tarif eden yerler var:
  - `lib/features/ballistics/pro_section_info.dart:53–54`: örnek olarak "3–5 klik sağa" yazıyor (eski aralık biçimi).
  - `lib/features/guide/usage_guide_content.dart:102` ve `docs/kullanim-rehberi/REHBER.md:69`: "Rüzgâr: yan düzeltme, en yüksek rüzgâr girildiyse bir aralık olarak görünür".
  - `lib/features/ballistics/environment_field_info.dart:154`: "Hedef sayfası yan düzeltmeyi bu aralıkta gösterir".
  - "Rüzgâr etkisi" adı yalnız plan belgelerinde geçiyor (`docs/yeni-hesaplar-2026-10-11.md`, `docs/ruzgar-gozlem/plan.md`).
- `fix/hedef-klik-satiri` dalının dosyalarına (`hedef_view.dart`, `scope_results.dart`) dokunulmadı.

## Testler

- Yeni: `test/ruzgar_satirlari_test.dart`. Gerçek Hedef sayfası, sabit profil (PCP slug, G1 0,08), rüzgâr 6,2 m/s (saat 9), En yüksek rüzgâr 9,3 m/s.
  - 390 pt: metinler aynen `Rüzgâr 6,2 m/s: 24 klik sol · 9,3 m/s: 37 klik sol` ve `Yana kayma: yakın %56 · orta %33 · uzak %11`. Sayılar main'den alındı: 8cc3aab'de aynı girişlerle "… yan düzeltme 24 klik L – 37 klik L." ve "… %56 · %33 · %11" (geçici dal `tmp/ruzgar-satirlari-once`, probe testi). Alt uç = yan kulenin kendi kliği. Sıra: Vuruş noktası < Rüzgâr < Yana kayma < Hesap dökümü (dy). Her satır tek satır yüksekliğinde (±0,5 pt), satır taşmıyor, Vuruş noktası ile aynı sol hizada.
  - 320 pt + yazı ölçeği 1.3: taşma hatası yok, iki satır da tek satır, ekran içinde, sayılar aynı.
  - En yüksek rüzgâr boş: Rüzgâr satırı yok, Yana kayma aynı yüzdelerle var.
- Dar kapsamlı güncellenen eski testler (hiçbiri gevşetilmedi):
  - `test/core/hedef_golden_numbers_test.dart`: B alanında **aynı sayılar**, yeni okuma sırasıyla ("4,0 6,0 10 15" → "4,0 10 6,0 15", "3,0 5,0 10 17" → "3,0 10 5,0 17").
  - `test/audit_2026_10_14b/weather_wind_elevation_audit_test.dart`: klik okuyan regex yeni biçime uyarlandı (artık tüm satırı `^…$` ile eşliyor).
  - `test/shot_settings_test.dart`: "2,0–5,0 m/s" yerine "Rüzgâr 2,0 m/s: " ve " · 5,0 m/s: ".
  - `test/wind_observation_test.dart`: "Rüzgâr etkisi:" → "Yana kayma:".
  - `tools/test_v353_vacuum_angular_suppression.py`: "rüzgâr yalnız sürüklenme modunda" koruması yeni metot adını (`_windShotLines`) okuyor; koşul aynı.
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (420 dosya, 0 sorun). `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 atlanan, önceden de atlanıyordu).
- Bu ortamda Flutter SDK indirilemedi (storage.googleapis.com proxy'de engelli). Bu yüzden Dart testleri, analiz ve format yalnız CI'da çalıştı.

## Ekran görüntüsü (önce / sonra)

Simülatör (sim-screens, iPhone 16e, 390 pt ve 320 pt çerçeve), `integration_test/ruzgar_satirlari_screens_test.dart`:

EKRAN_GORUNTULERI

## CI

CI_LINKLERI

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01K1raKwYiHoidTCxUKmvLax
