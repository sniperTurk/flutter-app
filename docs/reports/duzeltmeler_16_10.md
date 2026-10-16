# Düzeltmeler 16.10.2026 — kod

Dal: `fix/duzeltmeler-16-10` · Taslak PR (birleştirilmedi, TestFlight yok).
Tasarım: PR #366, `design/duzeltmeler-16-10` dalı, `docs/design/duzeltmeler-2026-10-16/README.md` + `png/`.

## Sahibin kararı (İstanbul)
- 16.10.2026 20:06 tasarım PR #366 için: "onayladım". "Sonra" çizimleri ve README'nin "Dokunulacak kod" bölümleri uygulandı.
- 20:07, 5. madde değişti: "Profil seçici select diğer selectler gibi açılacak." #366'daki özel kart/gölge/sarı ✓ liste yapılmadı; uygulamadaki her açılır kutunun (MenzilSelect) listesi kullanıldı.
- Açık sorular: Hedef klik satırı kaydırıcının altında tek satır; Pro "N ayar açık" özeti girilen Mühimmat sıcaklığını sayar; liste köşesi diğer select'lerle aynı.

## Ne yapıldı
1. **Profil ekle:** sabit 148 pt genişlik kalktı (`SizedBox(width: _addButtonWidth)` silindi). Düğme yazısı kadar geniş, iki yanda 16 pt dolgu (`MenzilPrimaryButton(expand: false)`). Yükseklik, sarı renk ve yeri (Profiller satırının sağ ucu) aynı.
2+3. **Mühimmat sıcaklığı:** Hava Durumu'ndaki bölüm silindi (başlık, ⓘ, "isteğe bağlı", kart). Aynı kutu Pro Ayarlar > Tüfek düzeltmeleri içinde, Mermi uzunluğu'nun altında ve barut katsayısı yazısının üstünde: kutu satırın sol yarısında, "isteğe bağlı" sağ yarısında, kutunun ortasıyla aynı hizada. Yalnız ateşli silahta. Kutunun ⓘ'si artık Pro kutularının alttan açılan sayfasını açar; sayfada "Mühimmat sıcaklığı" satırı var (`ProInfoField`). Kutu kapalıyken "N ayar açık" özeti girilmiş bir değeri sayar.
4+6. **Hedef:** #330'un büyük "Üst kule / Yan kule" satırı kalktı. Yerine kaydırıcının hemen altında tek satır: `▌Üst kule 39 klik yukarı   ▌Yan kule 4 klik sağ`. Sayılar 15 pt yarı kalın (eşit genişlikte rakam), yazılar 12,5 pt gri, sarı ve mavi sol çizgi aynı. Satır hiç iki satıra inmez; dar ekranda yazı küçülür (`FittedBox`). Rüzgâr yoksa "Yan kule 0 klik rüzgâr yok". Üst boşluk 6 → 2 pt.
5. **Üst çubuk profil seçici:** düğmenin kendisi değişmedi. Dokununca açılan liste, uygulamadaki her MenzilSelect listesiyle aynı yoldan açılır: aynı açılış (`_MenzilMenuRoute`), aynı yerleşim (`_MenzilMenuLayout`: düğmenin 4 pt altında, düğme eninde), aynı yüzey rengi, çerçeve, köşe, satır yüksekliği, yazı ve açılış animasyonu. Seçili satır işareti yok (diğer select'lerde de yok). Her satırda profil adı ve kalibresi, Profil > Kalibre listesindeki gibi: ad, yanında 12 pt kalibre; sığmazsa ad alt satıra iner ve kalibre altına geçer, hiçbir şey "…" ile kesilmez.

## Nasıl
- `lib/ui/menzil_widgets.dart`: MenzilSelect'in liste açma kodu yeni, küçük ve herkese açık `MenzilSelectMenu<T>` sınıfına taşındı (`closeKeyboard`, `show`, `close`, `metricsChanged`). MenzilSelect bunu kullanıyor; davranışı aynı (klavye önce kapanır, yer yoksa sayfa yukarı kayar, dönme/pencere değişince liste kapanır). Rota, yerleşim ve liste çizimi (`_MenzilMenuRoute`, `_MenzilMenuLayout`, `_DropdownMenu`) özel kaldı ve tek yerde.
- `lib/features/home/home_screen.dart`: düğmeyi çizen `DropdownButtonFormField` aynen duruyor (düğme piksel piksel aynı kalsın diye), yalnız dokunuşu artık o almıyor (`AbsorbPointer`); üstteki dokunma `MenzilSelectMenu.show` ile listeyi açar. Seçim `_choose` ile, kayıt hatasında eskisi gibi önceki profile döner. VoiceOver: tek düğme, adı "Aktif tüfek profili", değeri "Ateşli 308 7,62 mm"; çift dokunuş aynı listeyi açar.
- `lib/features/profiles/profiles_screen.dart`: sabit genişlik silindi, `expand: false`. Çok büyük iOS yazı boyunda düğme en fazla eski 148 pt olur ve yazı tek satırda küçülür (aşağıda "Uç durumlar").
- `lib/features/ballistics/hava_durumu_view.dart`: bölüm silindi. `pro_ayarlar_view.dart`: satır, `ProInfoField`, özet sayımı eklendi. Kayıt anahtarı (`ammoTemp` / `ammoTempText`), denetleyici (`ammoTempCtl`), kutu anahtarı (`env-ammo-temp`), birim (°C; ABD birimlerinde °F, önceki gibi) ve hesap değişmedi.
- `lib/features/ballistics/scope_results.dart` (`TurretSolutionRow.build`) ve `hedef_view.dart` (üst boşluk). Anahtarlar (`hedef-turret-solution`, `hedef-solution-elevation`, `-windage`), sayılar (`requiredUp` / `requiredRight`) ve VoiceOver cümlesi ("Üst kule 39 klik, 3,9 MRAD yukarı") aynı. Dürbünün altındaki "Kule: … (… MRAD)" satırı duruyor.

## Neden
Sahibin TestFlight 110 incelemesindeki 6 madde ve onaylanan tasarım. Liste için sahibin 20:07 sözü: diğer select'lerle aynı açılsın.

## Uç durumlar
- **Kayıtlı Mühimmat sıcaklığı:** eski sürümde Hava Durumu'nda girilen değer aynı anahtardan Pro'daki kutuya yüklenir ve hesaba aynen girer (test: main'den okunan sayılarla birebir eşit).
- **PCP:** Mühimmat sıcaklığı hiçbir sayfada yok (önceki gibi).
- **Boş Mühimmat sıcaklığı:** hava sıcaklığı kullanılır (önceki gibi).
- **Profil ekle, çok büyük yazı:** düğme yazı kadar büyür ama en fazla eski 148 pt; ondan sonra yazı küçülür. Bu sınır olmadan iPhone 15 ve ×2 yazıda "Profiller" başlığı 5 pt taşıyordu (`menzil_layout_extremes_test`). Normal ve ×1,3 yazıda sınıra hiç ulaşılmaz (320 pt ×1,3'te düğme ≈ 132 pt).
- **Profil listesi, kısa aktif ad:** liste düğmeden geniş olamaz (CLAUDE.md), bu yüzden "bbbbb" aktifken liste dar olur; uzun adlar kesilmez, birkaç satıra iner (UST-1). Uzun liste kaydırılır.
- **Profil listesi, klavye açıkken:** önce klavye kapanır, sonra liste açılır (diğer select'ler gibi).
- **Hedef, 320 pt ve ×1,3:** klik satırı iki satıra inmez, taşmaz; yazı biraz küçülür.
- **Hedef, 0 klik:** yön yazılmaz ("Üst kule 0 klik"); rüzgâr girilmemişse "Yan kule 0 klik rüzgâr yok".

## Bilerek yapılmayan
- #366'daki 5. madde çizimi (kart, 16 pt köşe, gölge, sarı ✓, sarımsı satır): sahip 20:07'de değiştirdi.
- Hesap, formül, kayıt anahtarı, ⓘ metinleri değişmedi. Hava Durumu'nun diğer bölümleri, Hedef'te dürbün, kuleler, L-R, "Kuleleri kur/sıfırla", DOPE PDF değişmedi.
- `profile_editor_scope.dart` ve `profile_editor_ammo.dart`'a dokunulmadı (başka görevler).
- Üst çubuktaki düğmenin kendisi (genişlik, ad kısaltma, kalibre) değişmedi.
- Yeni bağımlılık yok.

## Testler
Yeni `test/duzeltmeler_16_10_test.dart` (Inter yazı tipiyle, iPhone güvenli alan boşluklarıyla):
- Profil ekle: 320 ve 390 pt, ×1,0 ve ×1,3: eni < 148, yazı tam boyutta ve tek satır, iki yanda 16 ± 0,5 pt, yükseklik 46–48, sağ uçta; ×2'de taşma yok.
- Mühimmat sıcaklığı: kayıtlı "35" ve "" Pro'daki kutuya yüklenir; 600 m üst kule `requiredUp` main'deki sayılarla **birebir** eşit (5,245725605337864 ve 5,529980691211749 MRAD; main e7b29bf üzerinde aynı adımlarla okundu); Pro'da yazınca da aynı.
- Hedef: 390×844'te kaydırma yok, klik satırı kaydırıcının ≤ 2,5 pt altında, 22 pt yüksek, dürbünün tamamı alt menünün üstünde; 34 pt sayı yok. 320 pt ×1,0 / ×1,3 satır tek satır, ekran içinde.
- Profil listesi: açılan listenin rotası `_MenzilMenuRoute` (MenzilSelect'inkiyle aynı), yüzey rengi, gölge, çerçeve/köşe, yazı boyu/ağırlığı/rengi ve satır yüksekliği açılmış bir MenzilSelect ile **eşit**; liste düğmenin 4 pt altında, solu düğmeyle aynı, eni ≤ düğme eni; satırlarda ad + "6,35 mm"; seçim aktif profili değiştirir. Uzun adlar (390, 320, 320 ×1,3): tam yazılır, "…" yok, satırlar üst üste binmez, alt satıra dokunmak o profili seçer. VoiceOver: tek düğme, ad + değer, çift dokunuş aynı listeyi açar.

Güncellenen testler (gevşetilmedi; yeni yerleşime göre):
- `muhimmat_sicakligi_bolum_test.dart`: Hava Durumu'nda yok; Pro Tüfek düzeltmeleri'nde yeri (Mermi uzunluğu ile barut yazısı arası, sol yarı / sağ yarı, aynı hiza), ⓘ sayfasında satır, PCP'de yok, özet sayımı, kayıtlı değer, 320/390 ×1,3 taşma yok.
- `ammo_temperature_test.dart`: aynı hesap testleri kutu Pro'da iken.
- `pro_tufek_ozet_sayim_test.dart`: Mühimmat sıcaklığı girilince "3 ayar açık", silinince "kapalı".
- `pro_info_popup_test.dart`: ateşli silahta Tüfek düzeltmeleri alanları listesine "Mühimmat sıcaklığı" eklendi (sıra ve vurgulama aynı kontrol).
- `hedef_sonuc_ustte_test.dart`: tek satır metni, VoiceOver cümlesi (aynı), renkler, 12,5 / 15 pt.
- `scope_dial_drag_test.dart`, `scope_dial_view_test.dart`: "klik sol / klik yukarı" artık iki yerde (klik satırı ve dürbün altı); ikisi ayrı ayrı aranıyor.
- `audit_2026_10_15b/hedef_split_audit_test.dart`: ok düğmelerinin 44 pt kontrolü dikdörtgen farkı yerine kutunun kendi boyutuyla yapılıyor (aşağıda kayan nokta 43,99999999999994 veriyordu; eşik aynı 44).
- `integration_test/chrono_screens_test.dart`: Mühimmat sıcaklığı adımı Pro'ya taşındı.
- `test/support/pro_sections.dart`: `env-ammo-temp` Tüfek düzeltmeleri kutusunda.

Yerel: `python3 tools/offline_dart_lint.py` → PASS (0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 atlandı).

## Ekran görüntüleri
SCREENSHOTS_PLACEHOLDER

## CI
CI_PLACEHOLDER

## Not
- Bu görev çalışırken bir başkasının bekleyen "Simulator screenshots" çalışması (38941387154) benim başlattığım çalışma yüzünden iptal oldu (iş akışı aynı anda yalnız bir bekleyen çalışmaya izin veriyor). Girdilerini göremediğim için yeniden başlatamadım; sahibi yeniden başlatmalı.
- Sayıları main'den okumak için açtığım geçici `probe/ammo-golden-16-10` dalı GitHub'da duruyor; bu ortamdan dal silme izni yok, silinebilir.

---
_Generated by [Claude Code](https://claude.ai/code)_
