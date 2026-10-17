# Hava Durumu: rüzgâr tarihi solda, bölüm aralıkları

Sahip, 17.10.2026 (İstanbul): 19:23 "Tarihi ve saati sola al tüm sayfada solda" (B seçeneği) ·
20:02 "tüm önerileri uygula" · 20:03 "sağdaki görsel" onayı ve "rüzgâr yönü ve saat arasını değiştirme".

## Ne değişti

1. **Rüzgâr saati altındaki tarih solda.** Eskiden tek satırdı: solda "Saat 1 yönünde", sağda "17.10.2026 19:22". Şimdi iki satır, ikisi de kartın iç sol kenarında:
   - 1. satır: "Saat 1 yönünde" (koyu yazı rengi, aynı yazı)
   - 2. satır: tarih ve saat (gri, aynı yazı), hemen altında, 3 pt aralıkla
   Her satır tek satırda kalır; sığmazsa alt satıra geçmez, biraz küçülür (önceki gibi).
2. **Bölüm aralıkları** (Basınç Ölçer, İrtifa, Rüzgâr, Hava özeti):
   - Bir kartın alt kenarı → sonraki başlığın yazısı: **20 pt** (önce 28 pt yazı kutusundan; sizin ekranda ≈30)
   - Başlığın yazısı → kendi kartı: **8 pt** (önce ≈20 pt yazı kutusundan; sizin ekranda ≈25)
   - Hava özeti başlığı da aynı: düğmenin altından 20 pt, kartına 8 pt (önce düğmeden 14 pt).
   - Son kart (Rüzgâr) → "Pro Ayarlar'a geç": **10 pt, değişmedi** (sizin ekranda ≈12).
   - "Rüzgâr yönü" başlığı → saat kadranı: **değişmedi** (başlığın altı → saat 12 düğmesi 8 pt).
3. **Rüzgâr kartının içi:** "Rüzgâr hızı | Rüzgâr yönü" etiketlerinin üstündeki 14 pt boş kart dolgusu kaldırıldı. Kartın üst kenarı → "Rüzgâr hızı" yazısı **28,4 pt** oldu (önce 42,4 pt). **İstenen 14 pt'ye inmedi**, nedeni aşağıda ("Bilerek yapılmayan").

## Nasıl

- `lib/features/ballistics/wind_clock_picker.dart`: alttaki `Row` yerine iki satırlık sütun; ikisi de `AlignmentDirectional.centerStart`, arada `WindClockPicker.dateGap = 3`. Anahtarlar aynı (`wind-clock-label`, `wind-clock-date`). Kod yorumu yeni kurala göre yazıldı.
- `lib/ui/menzil_widgets.dart`: `MenzilSectionHeader`'a isteğe bağlı "tam aralık" kipi eklendi (`textGapAbove`, `textGapBelow`, `titleInfo`). Bu kipte başlık yazısı başlığın üst kenarından tam `textGapAbove`, alt kenarından tam `textGapBelow` uzakta durur. ⓘ'nin 44 × 44 pt dokunma alanı başlığın içine sığar; simge başlık yazısının ortasında kalır. Bu parametreleri vermeyen her başlık (Pro Ayarlar, Profil, Hedef, Balistik / DOPE) eskisi gibi çizilir.
- `lib/features/ballistics/hava_durumu_view.dart`: `_environmentInputs(sectionGaps: true)` yalnız Hava Durumu sayfalarında (profilli ve profilsiz). Başlıktan önceki kartların 10 pt dış boşluğu kalktı; boşluğu artık başlığın kendisi tutuyor (20 pt). Rüzgâr kartının üst iç dolgusu 0. Hava özeti `_atmosphereResult(gapAbove: 20)`; aradaki ekstra 10 pt kutusu silindi.
- `lib/features/ballistics/ballistics_shared_rows.dart`: `_headerWithInfo` isteğe bağlı `gapAbove` alıyor.

## Neden

Sahip başlıklar ile kartlar arasındaki boşluğu fazla buldu ve tarihin sağda değil, tüm sayfada olduğu gibi solda olmasını istedi; çizimin sağdaki hâlini onayladı.

Eski boşluğun kaynağı: başlıktaki ⓘ'nin 44 pt dokunma alanı başlık satırını 44 pt yapıyordu, 18 pt'lik yazı bu satırın ortasında duruyordu (üstte ve altta ~12 pt boş), üstüne 4 + 8 pt başlık dolgusu ve 10 pt kart dış boşluğu ekleniyordu.

## Uç durumlar

- **Basınç uyarısı görünürse** (İrtifa kartı ile Rüzgâr başlığı arasında): İrtifa kartı → uyarı 10 pt kaldı (önceki gibi). Uyarının kendi alt boşluğu 10 pt olduğu ve ⓘ'nin 44 pt alanı başlığın içine sığmak zorunda olduğu için uyarı → "Rüzgâr" yazısı 26,2 pt (önce ≈26). Rüzgâr yazısı → kart yine 8 pt. Testle kontrol edildi.
- **Rüzgâr yönü seçilmemişse:** 1. satır boş kalır (önceki gibi yer tutar), 2. satırda bugünün tarihi solda.
- **320 pt ve yazı boyutu ×1,3:** taşma yok; aralıklar aynı (20 / 8 pt). Başlık uzun gelirse alt satıra geçebilir, aralıklar yine aynı.
- **Profil yokken açılan Hava Durumu** aynı girdileri kullanır, aynı aralıkları alır.
- **Balistik / DOPE sayfası** aynı girdileri kullanıyor; orada hiçbir şey değişmedi (eski başlık ve kart boşlukları).
- **Kayıtlı veri:** hiçbir kayıt değişmedi; yalnız yerleşim.

## Bilerek yapılmayan

- **Rüzgâr kartında 14 pt yapılamadı (28,4 pt oldu).** "Rüzgâr hızı" ve "Rüzgâr yönü" etiketlerinin üstündeki boşluk boş bir başlık/satır değil; o iki alanın ⓘ'sinin 44 × 44 pt dokunma alanı. Kurallar: ⓘ dokunma alanı en az 44 pt (Apple), ⓘ kutunun üstünde ve kutunun dışında (testler `kutu_fikir4_test`, `info_etiket_satiri_test` bunu kontrol ediyor). Etiket kartın üstünden 14 pt aşağıda olursa kutunun üstü kartın üstünden 34,6 pt aşağıda olur; 44 pt'lik ⓘ kutuya değmeden oraya sığmaz (9,4 pt kartın dışına taşar ve oraya dokunulamaz). Bu yüzden yalnız kartın 14 pt boş iç dolgusu kaldırıldı. 14 pt istenirse seçenekler (sahibin kararı):
  1. Rüzgâr hızı / Rüzgâr yönü ⓘ'leri kutunun sağ üst köşesine 9,4 pt binsin (iki testteki "ⓘ kutunun dışında" kuralı bu iki alan için değişir).
  2. Bu iki ⓘ'nin dokunma alanı 44 pt'den küçük olsun (önerilmez).
- Üstteki Hava kartında (Sıcaklık | Bağıl nem) aynı ⓘ satırı var ve üstte ≈42 pt boşluk duruyor; sahip "diğer kartların iç dolgusunu değiştirme" dediği için dokunulmadı.
- Diğer tarihler (hava verisi, basınç, irtifa) zaten soldaydı; değişmedi.
- Pro Ayarlar, Profil, Hedef, alt menü adı ("Hava Durumu"), etiketler ve metinler değişmedi. Yeni alan yok.
- Ölçüler yazı kutusunun kenarından alınmıştır (testlerdeki gibi). Ekranda harflerin mürekkebi yazı kutusunu tam doldurmadığı için gözle ölçülen boşluk birkaç pt daha büyük görünebilir (aşağıda ekran görüntülerindeki ölçümler).

## Testler

- Yeni: `test/hava_aralik_tarih_test.dart` (390 pt, 320 pt, 320 pt ×1,3):
  - "Saat 1 yönünde" üstte, tarih altta, aralık 3 pt; ikisinin sol kenarı = kartın iç sol kenarı (±0,5 pt); tek satır, renkler aynı.
  - Basınç Ölçer, İrtifa, Rüzgâr, Hava özeti: kart → başlık yazısı 20 pt, yazı → kart 8 pt (±0,5); ⓘ 44 × 44 pt, başlığın içinde, simge yazının ortasında.
  - Rüzgâr kartı: ⓘ satırı kartın üst kenarında başlıyor; üst Hava kartının 14 pt iç dolgusu aynı.
  - "Rüzgâr yönü" başlığı → saat 12: 8 pt (main ile aynı); Rüzgâr kartı → "Pro Ayarlar'a geç" 10 pt (main ile aynı).
  - Basınç uyarısı görünürken üst üste binme yok.
  - Taşma yok (`takeException` boş).
- Önce kırmızı: düzeltme olmadan bu dosya düştü (tarih satırı yan yanaydı: −14,5 pt; başlık aralığı 28 pt) — [test-diag #769](https://github.com/sniperTurk/flutter-app/actions/runs/39052902929).
- Mevcut testlerin hiçbiri değiştirilmedi ve hiçbiri gevşetilmedi.
- Yerel: `python3 tools/offline_dart_lint.py` → 435 Dart dosyası, 0 sorun; `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test, OK (1 atlandı).
- Bu ortamda Flutter SDK indirilemedi (ağ engeli), Flutter testleri CI'da koştu.

## Ekran görüntüleri

(sim-screens.yml, ref=fix/hava-aralik-tarih — eklenecek)

## CI bağlantıları

- dart format: [format-fix #541](https://github.com/sniperTurk/flutter-app/actions/runs/39053017702) (biçim commit'i branch'e eklendi)
- analyze: [analyze-diag #497](https://github.com/sniperTurk/flutter-app/actions/runs/39053400371) — başarılı
- Tüm testler (`test`): [test-diag #771](https://github.com/sniperTurk/flutter-app/actions/runs/39053402579) — başarılı
- iOS CI (verify, dart-checks, wind-acceptance): PR açıldıktan sonra eklenecek

Taslak PR; birleştirme yok, TestFlight yok.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
