# Seçim kutuları tek satır, Sight height yarım genişlik

Dal: `fix/kalibre-tek-satir` · Draft PR · birleştirilmedi, TestFlight yok.

## Sahibin kararı (2026-10-17, İstanbul)

- 17:54–17:57 (TestFlight 113, Profil → Tüfek, Beretta BRX1): Kalibre kutusunda ".30-06 Springfield" iki satıra geçti, satır Namlu çıkış hızı'ndan uzun oldu; Sight height tek başına tam genişlikti. Sight height yarım genişlik olsun ("Tabiki A").
- 18:03–18:05 (TestFlight 113): Mühimmat → Model uzun adı tek satırda "…" ile kesiyor, Dürbün → Model ise iki satıra geçiyordu. Karar: "C: mühimmattaki gibi, sığdığı kadar görünür". Uygulamadaki her seçim kutusu için tek kural.

## Ne yapıldı

1. **Her kapalı seçim kutusu tek satır.** Seçilen değer normal yazı boyunda (15 pt) tek satırda görünür; sığmayan kısım "…" ile kesilir. Alt satıra geçmez, küçülmez. Kural `MenzilSelect`'in kendisinde olduğu için bütün seçim kutularında geçerli: Profil Tüfek/Dürbün/Mühimmat (Kalibre, Marka, Model, Retikül dahil), Hava Durumu, Pro, Araçlar. Üst çubuktaki profil seçici zaten tek satır ve "…" ile kesiliyordu; ona dokunulmadı.
2. **Kutu yüksekliği satırdaki yazılı kutuyla aynı.** Seçim kutusu, yanındaki yazılı kutudan (MenzilInput) 1 pt uzundu (50 / 49 pt). Kutunun dikey boşluğu ve satır yüksekliği ayarlandı; artık ikisi de normal yazıda 49 pt, ×1.3'te 55 pt. Yazı boyu değişmedi.
3. **Sight height yarım genişlik.** İki sütunlu satırın sol kutusu, Sıfırlama mesafesi ile aynı genişlikte; sağ sütun boş. Ateşli ve PCP. Birim (mm) kutunun içinde, ⓘ aynı.
4. **CLAUDE.md:** "select over typing" kuralındaki cümle "a long selected value stays on one line and is cut with "…" inside its box (owner, 2026-10-17 18:05)" oldu. Başka satıra dokunulmadı.
5. Önceki çalıştırmanın "sığmazsa küçülür" yaklaşımı (dalın ilk commit'i) kaldırıldı; yerine bu kural geldi.

## Nasıl

- `lib/ui/menzil_widgets.dart` → `MenzilSelect`:
  - Silindi: `wrapSelected` (uzun değeri iki satıra geçirip kutuyu uzatan yol, `menzil-select-wrapped` metni dahil), `fitSelected` (sığmazsa küçülten yol), `shortSelectedLabels` (sığmayınca kısa ad koyan yol). Bayrakla saklanmadı, kod silindi.
  - Kapalı kutu metni her zaman `maxLines: 1`, `softWrap: false`, `overflow: TextOverflow.ellipsis`.
  - Dikey boşluk 13 → 12,5 pt ve kapalı kutu metninin satır yüksekliği 20/13. Sebep: Flutter'ın sık (dense) liste düğmesi en az 24 pt yüksek; 13 pt boşlukla kutu 50 pt oluyordu, yazılı kutular 49 pt. Bu iki değer normal yazıda ve ×1.3'te eşitliği sağlıyor (ölçümle doğrulandı, aşağıda).
  - `MenzilFitText` artık yalnız kompakt etiketlerde kullanılıyor; kullanılmayan `short` ve `minScale` silindi (davranışı aynı).
  - Not: `_withWrapped` sarmalayıcısı kalkınca içerideki ağaç 2 boşluk sola kaydı; o yüzden dosyada satır farkı büyük görünüyor, mantık değişikliği yukarıdakiler kadar.
- `profile_editor_rifle.dart`: Marka, Model ve Kalibre'den `wrapSelected`/`fitSelected` kaldırıldı. Kalibre'nin kısa adı (".30-06", ".338-378 Wby Mag", "Listede yok") silindi; kutu **seçilen gerçek adı** gösterir, sığmazsa "…" ile keser. `_shortCartridge` artık kullanılmadığı için `profile_editor.dart`'tan silindi. Sight height `MenzilFullWidth` dışına alındı (dalın ilk commit'inden).
- `profile_editor_scope.dart`: Dürbün Model'den `wrapSelected` kaldırıldı.

## Neden

Sahip tek kural istedi: Mühimmat → Model'deki gibi tek satır ve "…". Kısa ad yerine gerçek ad gösterildi; çünkü sahip "sığdığı kadar görünür" dedi ve kısa ad seçilen öğeden farklı bir metin gösteriyordu (".30-06" ≠ ".30-06 Springfield").

## Uç durumlar

- Çok uzun ad (ör. "Gold Medal Sierra MatchKing 168 gr Sierra MatchKing BTHP"): kutu boyu sabit, sonu "…". Açık listede ad tam görünür (liste değişmedi).
- Bir tüfek modelinde aynı fişeğin iki çeşidi varsa ayıran kısım (namlu boyu, yiv oranı) etiketin sonunda: yarım genişlikteki Kalibre kutusunda "…" arkasında kalabilir (ör. ".308 Win · 20 in namlu · 1:10"). Açık listede tam görünür. Bu, "sığdığı kadar görünür" kuralının doğal sonucu; kod incelemesinde not edildi.
- ×1.9 ve üstü çok büyük yazıda kompakt (44 pt) seçim kutuları (Hava Durumu, Pro Ayarlar ve Mühimmat kartındaki kompakt alanlar) yeni satır yüksekliği yüzünden biraz daha erken büyür (önce ~×2.4). ×1.3'e kadar değişiklik yok.
- Kısa ad sığıyorsa "…" yok (testte "kesildi mi" metnin gerçek genişliğine göre ölçülüyor).
- ×1.3 yazı boyunda kutu ve yanındaki yazılı kutu birlikte büyür (55 pt), satır yine eşit.
- 320 pt ×1.3'te form tek sütuna düşer; Sight height o zaman Sıfırlama mesafesi gibi tam genişlik (genişlikleri yine eşit).
- Kayıtlı veriler: hiçbir kayıt/alan değişmedi; eski profiller aynı açılır. Hesap koduna dokunulmadı.

## Bilerek yapılmayan

- Etiket, ⓘ metni, sıra, değer, hesap değişmedi.
- Açık listeler değişmedi (uzun ad listede satır kaydırabilir, eskisi gibi).
- Üst çubuk profil seçicisi zaten kurala uyuyordu; dokunulmadı.
- Başka açık dallarla çakışma (`git merge-tree` ile denendi): `fix/diger-kalibre-sil`, `feat/pcp-ortalama-hiz`, `fix/mermi-uzunlugu-100`, `data/arken-sfp` ile metin çakışması yok. Ama `fix/diger-kalibre-sil` Kalibre öğelerinde `short:` ve `_shortCartridge` kullanıyor; bu PR ikisini sildiği için iki dal birlikte main'e girince o dalın `short:` satırları ve `_savedOffModelCaliber`'daki `short` alanı da silinmeli, yoksa derlenmez. İki değişiklik de korunur; kısa ad artık gösterilmiyor.
- Geçici dallar `tmp/kalibre-tek-satir-format` ve `tmp/kalibre-diag` (biçimlendirme ve yükseklik ölçümü için) silinemedi: proxy dal silmeye izin vermiyor. Elle silinebilir; kod içermiyorlar (format dalı bu PR ile aynı commit'te).

## Testler

Yeni: `test/kalibre_tek_satir_test.dart` ve ortak yardımcı `test/support/select_one_line.dart`. Her biri 390 pt, 320 pt, 320 pt + yazı ×1.3'te:

- Kalibre ".30-06 Springfield" (BRX1 yolundan, yarım genişlik), elle tüfekte ".338-378 Weatherby Mag" ve "Fişeğim listede yok", PCP "11.43 mm (.45)".
- Dürbün Model "SH-4J GENII 6–24×50 FFP VPR (MRAD)" (katalog yolu) ve seçilen Retikül.
- Mühimmat Model "Gold Medal Sierra MatchKing 168 gr Sierra MatchKing BTHP" (katalogdaki gerçek ad, Federal, .30-06).
- Kütüphanedeki en uzun retikül adı ("Ballistic Plex E1 FFP (…)") yarım kutuda, yanında yazılı kutu.

Her kutu için: tek satır (paragraf yüksekliği tek satır ±0,5 pt), 15 pt (küçülmemiş, FittedBox yok), `ellipsis`, sığmıyorsa gerçekten kesilmiş, metin kutunun içinde, kutu standart yükseklikte (±0,5 pt) ve satır komşusuyla eşit; taşma yok. Sight height genişliği == Sıfırlama mesafesi genişliği (±0,5 pt), sağ sütun boş, mm kutunun içinde.

İki satır bekleyen ve dar kapsamlı güncellenen testler:

- `test/profil_duzen_koruma_test.dart`: `_wrapsAtNormalSize` → `_oneLineAtNormalSize` (Dürbün Model, Tüfek Model, kısa Model, uzun Marka "Accuracy International", 320 pt Marka); `_caliberOneLine` artık "…" kuralını ölçüyor; Sight height genişliği Sıfırlama mesafesi ile karşılaştırılıyor. Grup adı "Model boxes: one line, cut with "…"".
- `test/velocity_caliber_row_test.dart`: `_expectWraps` → `_expectOneLine` (aynı ortak yardımcı).
- `test/pcp_muhimmat_tasarim_test.dart`: Sight height yarım genişlik (dalın ilk commit'inden).

Başka test gevşetilmedi; silinen test yok.

## Ölçüm (yükseklik)

Geçici bir test CI'da kutu yüksekliklerini yazdırdı (değişiklikten önce): normal yazıda seçim kutusu 50 pt, yazılı kutu 49 pt; ×1.3'te 55,25 / 55 pt. Değişiklikten sonra tüm testler ±0,5 pt eşitliği geçti.

## Yerel kontroller

- `python3 tools/offline_dart_lint.py`: PASS, 436 Dart dosyası, 0 sorun.
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 915 test, OK (1 atlandı).
- Bu ortamda Flutter SDK indirilemedi (proxy 403); biçimlendirme `format-fix` iş akışıyla CI'da yapıldı ve aynı commit'e alındı.

## Ekran görüntüleri (simülatör, 390 pt)

Simülatör: iPhone 16e (390 pt), iOS 26.2. Koşu: https://github.com/sniperTurk/flutter-app/actions/runs/39056745969 · flutter test çıkış kodu 0, 8 görüntü. Görüntüler `ci/sim-screens` dalında `5220bbf3f7c7599a16b57eb7b6d669ad354a9497` commit'inde (README "@ 2101b3f" yazıyor; iş akışı main'den başlatılır, çekilen dal `fix/kalibre-tek-satir`).

| Sayfa | Görülen |
|---|---|
| [Tüfek BRX1 üst](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/01_tufek_brx1_390.png) · [alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/02_tufek_brx1_390_alt.png) | Kalibre ".30-06 Sprin…" tek satır; Kalibre ile Namlu çıkış hızı aynı boyda; Sight height yarım genişlik, sağı boş, mm kutunun içinde |
| [Mühimmat üst](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/03_muhimmat_gold_medal_390.png) · [alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/04_muhimmat_gold_medal_390_alt.png) | Model "Gold Medal Sierra MatchKing 168 gr …" tek satır |
| [Dürbün üst](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/05_durbun_sh4j_390.png) · [alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/06_durbun_sh4j_390_alt.png) | Model "SH-4J GENII 6–24×50 FFP VPR (MRA…" tek satır (önce iki satırdı) |
| [PCP Tüfek üst](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/07_pcp_tufek_390.png) · [alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/08_pcp_tufek_390_alt.png) | Kalibre "11.43 mm (.45)" sığıyor, "…" yok; Sight height yarım genişlik |

![Tüfek BRX1](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/02_tufek_brx1_390_alt.png)
![Mühimmat](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/03_muhimmat_gold_medal_390.png)
![Dürbün](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/05_durbun_sh4j_390.png)
![PCP Tüfek](https://raw.githubusercontent.com/sniperTurk/flutter-app/5220bbf3f7c7599a16b57eb7b6d669ad354a9497/latest/08_pcp_tufek_390_alt.png)

Kendi gözümle kontrol ettim; sahibin istediğinden farklı bir şey görmedim. Not: 320 pt simülatör görüntüsü istenmedi; 320 pt ve ×1.3 widget testleriyle ölçüldü.

## CI

Kod commit'i `20e3c44` (PR başı, rapordan önce):

- iOS CI (pull_request): https://github.com/sniperTurk/flutter-app/actions/runs/39046901382 — `verify` success, `dart-checks` success, `wind-acceptance` success (`ios-simulator` atlandı, isteğe bağlı iş).
- Tüm testler (`test-diag`, files=test): https://github.com/sniperTurk/flutter-app/actions/runs/39046722738 — success.
- Analyzer (`analyze-diag`): https://github.com/sniperTurk/flutter-app/actions/runs/39046724210 — success.
- Biçim (`format-fix`, değişiklik çıkmadı): https://github.com/sniperTurk/flutter-app/actions/runs/39046721031 — success. Not: görevde verilen `gh workflow run 375209577` numarası iOS CI değil, bu biçim düzeltme iş akışı; iOS CI PR açılınca kendiliğinden çalıştı.
- Simülatör: https://github.com/sniperTurk/flutter-app/actions/runs/39056745969 — success.
- Kod incelemesi: https://github.com/sniperTurk/flutter-app/pull/395#issuecomment-6236136430 (sorun yok). Güvenlik incelemesi: https://github.com/sniperTurk/flutter-app/pull/395#issuecomment-6236145188 (bulgu yok).

Bu rapor commit'i yalnız dokümandır; PR başı değişince iOS CI yeniden çalışır, sonucu PR'da görünür.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_016AFaqdk8s6iQW62zHvfeU4
