# Profil Oluştur: kutulara ölçü birimi (fix/kutu-birimleri)

Sahip kararı (2026-10-15 22:56, İstanbul, Profil Oluştur sayfası):
"Ölçü birimi girilecek kutu içleri: Sight height … mm, Sıfırlama mesafesi …
m, Namlu çıkış hızı … fps, Ağırlık … gr. Hıza göre BC kutularına da ölçü
birimi gir."

## Ne yapıldı

Profil Oluştur / Profili Düzenle'de şu kutular artık birimini gösteriyor:

| Bölüm | Kutu | Birim |
|---|---|---|
| Tüfek | Sight height | mm |
| Tüfek | Sıfırlama mesafesi | Mesafe birimi Metre ya da seçilmemişse **m**, Yard ise **yd** |
| Tüfek | Namlu çıkış hızı | fps |
| Mühimmat | Ağırlık (yazılan kutu, PCP) | gr |
| Ek mühimmat bilgileri → Hıza göre BC | 1. eşik hızı, 2. eşik hızı | fps |

- Sıfırlama mesafesinin birimi Mesafe birimi değişince hemen değişiyor
  (Yard seçilince "yd", Metre seçilince "m").
- Ateşli tüfekte listeden seçilen **Ağırlık** maddeleri zaten
  "168 gr (10,9 g)" biçiminde "gr" gösteriyordu; "Listede yok" ile açılan
  "Kutudaki ağırlık" kutusu da zaten "gr = … g" gösteriyordu. Bunlara
  dokunulmadı.
- **Eşik altı BC** birimsiz kaldı: BC'nin birimi yok; temiz tasarım kararı
  da "Eşik altı BC birimsiz" (docs/reports/temiz_tasarim_profil.md) ve bunu
  koruyan test (`test/temiz_tasarim_profil_test.dart`) değişmedi.

## Nasıl

Yalnız var olan `MenzilInput` kutusunun `unit:` parametresi verildi (5 kutu,
3 dosya, 7 satır). Sıfırlama mesafesinde birim, kayıtlı Mesafe birimi
değerinden (`distanceUnit.symbol`: "m" / "yd") geliyor; o değer seçim
yapılmamışken Metre'dir. Etiketler, ⓘ metinleri, doğrulama, kaydedilen
değerler ve yerleşim değişmedi.

**Dikkat (sahibin kararı gerekebilir):** Profil sayfasında `unit:` birimi,
Hız ölçüm sıcaklığı "°C" ve PCP "1. hız" "fps" kutularında olduğu gibi,
kutunun kendi etiket satırının sağ ucunda, yazı alanının hemen üstünde
gösteriyor. Yazı alanının içinde (rakamın sağında) gösterme yalnız Hava
Durumu / Pro Ayarlar'ın kısa kutu düzeninde (MenzilCompactFields) var.
Görev "aynı yolla, yalnız `unit:` ile" dediği için ortak kutu bileşeni
değiştirilmedi. Birim rakamın yanında, yazı alanının içinde istenirse bu,
Profil sayfasındaki bütün birimli kutuları (°C, bar, fps, mm) etkileyen ayrı
bir görev olur.

## Neden

Birimi görünmeyen kutuya yanlış birimle değer yazılabiliyordu (ör. metre
yerine yard, grain yerine gram). Yard seçiliyken "m" göstermek yanlış
olacağı için Sıfırlama mesafesi birimi Mesafe birimini izliyor.

## Uç durumlar

- Mesafe birimi seçilmemiş (yeni profil): "m"; kayıtlı değer zaten metre
  sayılıyor.
- Metre → Yard → Metre: kutudaki sayı eskisi gibi çevriliyor (100 m →
  109.4 yd), birim de birlikte değişiyor.
- Dar ekran ve büyük yazı: 320 ve 390 pt genişlikte, yazı ölçeği 1.0 ve
  1.3'te etiket "…" ile kesilmiyor, birim kesilmiyor, yazılan değer kutuya
  sığıyor, taşma hatası yok.
- Kayıtlı veriler: hiçbir kayıt alanı değişmedi; eski profiller aynen
  açılıyor.

## Bilerek yapılmayan

- Ortak `MenzilInput` bileşeni değiştirilmedi (birimi yazı alanının içine
  taşımak yok; yukarıdaki "Dikkat" notu).
- Eşik altı BC'ye birim eklenmedi (BC birimsiz).
- Ağırlık listesinin maddeleri ve değerleri değiştirilmedi (zaten "gr").
- Etiket, ⓘ metni, doğrulama, kayıt biçimi, yerleşim değişmedi. TestFlight
  başlatılmadı, birleştirme yapılmadı.

## Testler

- Yeni: `test/kutu_birimleri_test.dart`
  - Sight height "mm", Sıfırlama mesafesi "m", Namlu çıkış hızı "fps";
    etiketler aynı.
  - Sıfırlama mesafesi: seçim yokken "m", Yard seçilince "yd" (100 → 109.4),
    Metre seçilince yine "m".
  - PCP Ağırlık "gr".
  - Ateşli Ağırlık listesinin her maddesi "<değer> gr (" ile başlıyor.
  - 1. ve 2. eşik hızı "fps"; Eşik altı BC birimsiz.
  - 320 / 390 pt × yazı ölçeği 1.0 / 1.3 (Ateşli ve PCP ayrı): birim kutunun
    üstünde, kutu genişliği içinde; etiket tam (maxLines aşılmıyor, "…"
    yok), etiket birimin solunda; yazılan değer yazı alanına sığıyor; taşma
    istisnası yok. Ölçüm için uygulamanın sistem yazı tipi yerine paketteki
    Inter yazı tipi kullanılıyor (test/ekran_boyutu_test.dart ile aynı yol).
- Var olan testler değiştirilmedi, zayıflatılmadı.
- Yerel: `python3 tools/offline_dart_lint.py` → 0 sorun;
  `python3 -m unittest discover -s tools -p 'test_*.py'` → 842 test, OK.
  Bu ortamda Flutter SDK indirilemediği için `flutter test` yerelde
  koşmadı; Flutter testleri CI'da koştu.

## CI

CI_SONUCLARI_BURAYA

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01CNP4NPXCqoyGfPYMQ4yXir
