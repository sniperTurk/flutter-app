# Tüfek sırası ve yazılı dürbünde Retikül listesi

Dal: `fix/tufek-sirasi` (güncel main'den, #309 birleştikten sonra). Taslak PR; birleştirme ve TestFlight yok.

## Ne yapıldı

### Bölüm A — Tüfek kutularının sırası (sahip, 14.10.2026 18:56–18:58)

Profil Oluştur ve Profili Düzenle → Tüfek kartı.

| Satır | Önce | Sonra |
|---|---|---|
| 1 | Marka (tam satır) | Marka (tam satır) |
| 2 | Model (tam satır) | Model (tam satır) |
| — | "Aradığın tüfek listede yok mu?" | "Aradığın tüfek listede yok mu?" (yeri aynı) |
| 3 | Namlu çıkış hızı \| Kalibre | **Kalibre (tam satır, tek başına)** |
| (koşullu) | Mermi çapı | Mermi çapı (Kalibre'nin hemen altında, tam satır) |
| 4 | Namlu yiv yönü \| Yiv oranı | **Yiv oranı \| Namlu yiv yönü** |
| 5 | Sight height \| Mesafe birimi | Sight height \| Mesafe birimi |
| 6 | Sıfırlama mesafesi (tek) | **Sıfırlama mesafesi \| Namlu çıkış hızı** |

- **Sahibin istisnası:** "Her satırda iki kutu" kuralına sahip bu sayfada yalnız Marka, Model ve Kalibre için istisna verdi; bu üçü kendi satırında tek ve tam genişlikte. Diğer satırlar iki kutulu.
- Uzun Marka / Model / Kalibre seçimi küçülmüyor; normal yazı boyutunda alt satıra geçiyor, kutu büyüyor (#308'deki Model kutusu gibi, `wrapSelected`). Kalibre artık yarım kutu olmadığı için yazıyı küçülten eski yöntem yerine bu kullanıldı.
- Yazılı tüfek ("listede yok") aynı sırayı izliyor; "Listeden seç" bağlantısı yine Marka / Model'in altında. Üretim yerinde duruyor.
- "Kaydetmek için eksik" satırı Tüfek adlarını yeni görsel sırayla yazıyor: Marka, Model, Kalibre, Yiv oranı, Yiv yönü, Sight height, Mesafe birimi, Sıfırlama mesafesi, Namlu çıkış hızı.

**Nasıl:** Yalnız var olan kutuların yeri ve eşleşmesi değişti. "Namlu çıkış hızı | Kalibre" satırını kuran yöntem ikiye ayrıldı (Kalibre kutusu ve Namlu çıkış hızı kutusu); her kutunun denetleyicisi, doğrulaması, ⓘ metni, liste içeriği, kayıt anahtarı, varsayılanı ve hesabı aynı kaldı. Gizli bayraklar (RIFLE_LISTEDE_YOK vb.) değişmedi.

**Neden:** Sahibin 18:56–18:58 kararı (2026-10-13 tarihli "Namlu çıkış hızı | Kalibre aynı satırda" kararının yerine geçer).

### Bölüm B — Yazılı dürbünde Retikül listesi (sahip, 14.10.2026 18:30–18:33)

**Sorun:** "Aradığın dürbün listede yok mu?" ile açılan dürbünde Dürbün birimi "Seçiniz" iken Profil Oluştur 4 retikül (Christmas tree (MIL), MIL çizgili, Mil-Dot, Duplex), Profili Düzenle 2 retikül (MOA çizgili, Duplex) gösteriyordu.

**Sebep:** Liste, kutuda görünmeyen gizli birim değerine göre süzülüyordu (yeni profilde MRAD, düzenlemede kayıtlı birim, örn. MOA). Birim seçilmemiş olsa da süzme yapılıyordu.

**Düzeltme:** Yazılı dürbünde Dürbün birimi seçilmemişken Retikül listesi beş düz retikülün hepsini gösteriyor (her iki sayfada). Birim seçilince bugünkü süzme sürüyor: MRAD → MIL desenleri + Duplex (4), MOA / SMOA → MOA çizgili + Duplex (2). Seçilmiş ya da kayıtlı bir retikül listede kalıyor ve seçili duruyor; uymayan bir birim seçmek onu sessizce silmiyor. Katalog dürbünlerinin retikül listesi değişmedi. (#309'da bu işi yapan bir commit yoktu; yeni yazıldı.)

## Uç durumlar

- Dar ekranda (320 pt) ya da büyük yazıda kart tek sütuna düşer; o zaman iki kutulu satırlar alt alta, aynı sırayla gelir (bugünkü ızgara davranışı; Yiv oranı ve Sight height satırları zaten böyleydi). Daha önce her genişlikte yan yana zorlanan tek satır "Namlu çıkış hızı | Kalibre" idi; Kalibre artık tam satır olduğu için bu zorlama gerekmiyor.
- Yazılı tüfeğe geçmek Kalibre seçimini bugünkü gibi sıfırlar; "Fişeğim listede yok" yeniden seçilince Mermi çapı yine Kalibre'nin hemen altında çıkar.
- "Yiv yönünü seçin" uyarısı Yiv oranı | Namlu yiv yönü satırının hemen altında kalır.
- Eski / yazılı profiller, katalog tüfeği düzenleme ve Kopyala aynı sırayla açılır (#308'in eşleme kuralları değişmedi).

## Yapılmayanlar

- Mühimmat, diğer sayfalar, hesap ve veri değişmedi.
- **Hiçbir şey silinmedi.** Kalibre'nin kısa etiket listesi (`shortSelectedLabels`) de yerinde bırakıldı (alt satıra geçen kutuda kullanılmıyor).

## Testler

- `test/profil_duzen_koruma_test.dart`
  - Tüfek sırası sabitlendi: yeni profil, katalog tüfeği düzenleme (Gazi/Hercules), 13 Ekim öncesi eski profil, yazılı tüfek, Kopyala ve Güncelle → yeniden aç.
  - Marka / Model / Kalibre her biri tek satırda, aynı sol kenar, tam genişlik; 4–6. satırlardaki çiftler aynı satırda.
  - "Fişeğim listede yok" → Mermi çapı Kalibre'nin hemen altında (liste ve yazılı tüfek).
  - Kaydet → yeniden aç: değerler aynı.
  - Eksik satırı Tüfek adlarını yeni sırayla yazıyor.
  - Uzun Marka ("Accuracy International") ve Kalibre (".338-378 Weatherby Mag") normal boyutta alt satıra geçiyor.
  - Retikül: yeni profil yazılı dürbün, birim Seçiniz → 5; düzenlemede gizli birim MOA, kutu Seçiniz → 5; MRAD → 4; MOA ve SMOA → 2; seçilmiş retikül birim değişince silinmiyor; kayıtlı MOA çizgili korunuyor; katalog dürbün listesi değişmedi.
  - Her iki bölüm için 320 pt, yazı ×1.0 ve ×1.3: taşma yok.
- `test/velocity_caliber_row_test.dart`: "Namlu çıkış hızı | Kalibre aynı satırda" varsayımı sahibin 18:58 kararıyla geçersiz kaldı. Dosya yeni düzene göre güncellendi: Kalibre tam satır, Sıfırlama mesafesi | Namlu çıkış hızı; PCP ve Ateşli, 430 / 375 / 320 pt, ×1.0 / ×1.3.
- `test/profile_lists_test.dart`: aynı eski varsayımı içeren iki kontrol yeni düzene göre güncellendi.
- Yerel: `python3 tools/offline_dart_lint.py` → 0 sorun; `python3 -m unittest discover -s tools -p 'test_*.py'` → 743 test geçti. (Bu ortamda Flutter SDK indirilemedi; Flutter testleri yalnız CI'da koştu.)

## CI

- Biçim (dart format): başarılı, değişiklik gerekmedi — https://github.com/sniperTurk/flutter-app/actions/runs/38602112684 (ilk biçim düzeltmesi commit'i: https://github.com/sniperTurk/flutter-app/actions/runs/38600715794)
- Testler (`test` klasörünün tamamı): başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38602209184
- Analiz: başarılı (`--fatal-infos --fatal-warnings`) — https://github.com/sniperTurk/flutter-app/actions/runs/38602214591

iOS CI, Simulator, TestFlight ve App Store çalıştırılmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01Di1qdgc1e5N6BtHxAGZhQY
