# Temiz tasarım: Hedef, Hava Durumu, Pro Ayarlar + Hedef ekranının modüllere bölünmesi

Sahip kararı: 15.10.2026 10:07 (İstanbul), "görev aç". Onaylı tasarım: `design/clean-2026-10-15`
dalındaki `docs/design/clean-2026-10-15/` (README.md karar listesi, Hedef / HavaDurumu /
ProAyarlar görüntüleri). Tasarım dalı birleştirilmedi, yalnız örnek olarak kullanıldı.
Dal: `design/clean-hedef`, PR #317.

## Ne yapıldı

### 1. Modüllere bölme (davranış aynı)
- `ballistics_screen.dart` (6048 satır) bölündü. Sayfaların görünüm kodu aynen yeni dosyalara taşındı:
  - `hava_durumu_view.dart`: Hava Durumu sayfası (Hava, Basınç Ölçer, İrtifa, Rüzgâr, Hava özeti; profil yokken açılan Hava Durumu da).
  - `pro_ayarlar_view.dart`: Pro Ayarlar sayfası ve kutuları.
  - `hedef_view.dart`: Hedef sayfası (mesafe seçici, dürbün kartı, sonuç kartları).
  - `ballistics_shared_rows.dart`: Hava ve Pro'nun ortak satırları (Sıfırla, tarih | Sıfırla, kutu | düğme).
- `scope_dial_view.dart` (2141 satır) bölündü:
  - `scope_turrets.dart`: Kuleler (üst kule, yan kule, L-R, "Kuleleri kur" | "Kuleleri sıfırla").
  - `scope_reticle.dart`: Retikül.
  - `scope_results.dart`: Sonuç (Kule / Vuruş noktası okuması).
  - `scope_workings.dart`: Hesap dökümü.
- Durum, hesap, çözücü (solver), kayıt anahtarları, test anahtarları (ValueKey) ve gizli bayraklar
  ana dosyalarda kaldı ve değişmedi. Hiçbir şey silinmedi.
- Taşıma ayrı commit'lerde yapıldı ve o commit'lerde bütün testler (test/audit_*/ dahil) değişmeden geçti.

### 2. Tasarım
- **Hedef**
  - Sayfa başlığı "Hedef" ("Atış Çözümü" değil).
  - "Kuleleri kur" | "Kuleleri sıfırla" aynı satırda; yazı ikinci satıra kaymaz (sığmazsa küçülür).
    Diğer durum yazıları ("Çözüm kulelere kuruldu", "Kule sınırına kuruldu", "Çözüm: 0 klik",
    "Kuleler sıfırlandı") aynı kaldı.
  - Üst kule satırı: [boş 48][‹ 28][tambur][› 28][L-R 48], aralar 4 pt; tambur 78 pt yüksek ve
    retikülün dikey çizgisi üstünde ortalı. Başlık "← U   MOA   D →", değerler 2U · 0 · 2D; yönler aynı
    (‹ yukarı, › aşağı).
  - Yan (rüzgâr) kule: dikey, R yukarı / L aşağı, sıfırı retikülün yatay çizgisinde. Kutu uzun ve ince:
    390 pt telefonda yaklaşık 74 × 224 pt, retikül büyüdükçe/küçüldükçe oranla değişir. Yukarı/aşağı
    okları kutunun dışında (üstte ve altta), kutusuz ve zeminsiz; yalnız ok: beyaz, ince koyu kenarlı.
  - Korunanlar: Pro'dan mesafeyle gelince iki kule çözüme kurulu ve yan kule açık gelir; L-R yan kuleyi
    açar/kapar; "FFP · MOA · 31x" yazısı retikülün içinde.
  - "Hesap dökümü" açılır kapanır satır; sayfa açıldığında kapalı.
  - "DOPE kartını paylaş (PDF)" düğmesinde simge yok.
- **Hava Durumu**
  - Üst kart başlığı "Hava", özet kartının başlığı "Hava özeti" (kartın içindeki eski "Hava" yazısı kalktı).
  - Düğmelerde simge yok (Sıfırla, Basınç al, Haritadan, Telefondan, Konumdan canlı hava verisi al /
    Veriyi yenile). Yalnız "Hava verisi alındı" ✓ taşır.
  - Alınan düğmeler "… alındı" yazar ve sayfaya geri dönülünce de öyle kalır (mevcut davranış, testle bağlandı).
  - Rüzgâr başlığının ⓘ'si "Rüzgâr tahmini nasıl yapılır?" rehberini açar (aynı açılır pencere,
    altı satır, Kapat). Ayrı bağlantı `WIND_GUIDE_LINK` bayrağıyla gizlendi (varsayılan kapalı);
    metin ve bağlantı kodu silinmedi.
- **Pro Ayarlar**
  - "Düzeltme alındı" ve diğer veri düğmeleri ortak "alındı" stilini kullanır; simgeleri kaldırıldı
    (Düzeltme al, Haritadan ölç, Paralakstan, Konumdan al, Pusuladan al, Konumdan hesapla).
- **Renk**
  - "Alındı" düğmelerinin rengi `menzil_widgets.dart`'taki ortak stilden gelir. O dosya paralel görevin
    (`design/clean-profil`) olduğu için dokunulmadı; koyu mavi (#1F5F7A, çerçeve #2E7FA0, beyaz yazı)
    o görevle gelir. Hedef/Hava/Pro dosyalarında yerel bir "alındı" stili yok.
  - Turuncu #E8590C yalnız rüzgâr saatinde kalır; saat bunu kendi sabitinden (`WindClockPicker.orange`) okur.

## Nasıl
- Dart `part` dosyaları ve özel (private) uzantılar kullanıldı: kod aynı kütüphanede kaldığı için özel
  alanlara erişim ve davranış değişmedi. Uzantılar Flutter'ın korumalı `setState`'ini doğrudan
  çağıramadığı için `_update` adlı tek satırlık bir aktarıcı eklendi.
- Kaynak metnine bakan Python testleri artık kütüphanenin tamamını (ana dosya + part dosyaları) okur
  (`tools/dart_library_source.py`, paralel görevle birebir aynı dosya); böylece hiçbir test zayıflamadı,
  "yok" denetimleri taşınan kodu da kapsar.
- Ekran ölçüleri tasarım dosyasındaki değerlerden alındı (Hedef.dc.html).

## Neden
- 6000 satırlık tek dosyada değişiklik yapmak ve gözden geçirmek zordu; sayfa başına dosya, her görevin
  yalnız kendi sayfasına dokunmasını sağlar.
- Tasarım kararları sahibin 15.10.2026 onaylı listesinden.

## Uç durumlar
- Dar telefon (320 pt) ve 1,3 kat yazı boyutunda düğme yazıları tek satırda kalır, taşma yok (testli).
- Yan kule ölçüsü retikül boyutuyla oranlı; 390 pt ve 430 pt telefonda test edildi.
- Ok düğmeleri VoiceOver'a ayrı düğme olarak görünmez (28 pt ve 30 pt'lik dokunma alanları 44 pt kuralını
  bozmasın diye); VoiceOver kullanıcısı kuleyi tamburun kendi kaydırma eylemiyle (artır/azalt) çevirir.
- Hesap dökümü kapalıyken satırları ekranda yoktur; açınca aynı satırlar görünür.
- Hava özeti yalnız hava yoğunluğu hesaplandığında görünür (eskisi gibi).

## Yapılmayanlar
- `menzil_widgets.dart`, `lib/features/profiles/**`, `tools_screen.dart`'a dokunulmadı (paralel görev).
  "Alındı" düğmelerinin koyu mavisi o görevle gelecek.
- `lib/features/guide/usage_guide_content.dart` (Kullanım kılavuzu) hâlâ "Çözümü kulelere kur" yazıyor;
  dosya bu görevin listesinde olmadığı için değiştirilmedi. Ayrı bir görevle "Kuleleri kur" yapılabilir.
- Tek dokunuş: sayfa başlığı `lib/features/home/home_screen.dart`'ta tanımlı olduğu için "Hedef" başlığı
  için orada iki satır değişti (başka bir şey değişmedi).
- Sonuç kartlarının (Kule, Vuruş noktası, metrik ızgarası) görünümü değişmedi; yalnız dosyası ayrıldı.
- Hesap, alan, kayıt anahtarı değişikliği yok. TestFlight başlatılmadı.

## Testler
- Yeni: `test/temiz_tasarim_hedef_test.dart` — Hedef başlığı; "Kuleleri kur" | "Kuleleri sıfırla" tek satır
  (320 pt, 1,3x); üst kule satırı ölçüleri ve ortalama; yan kule ölçüsü (390 ve 430 pt), okların kutu
  dışında ve kutusuz olması, beyaz/koyu kenar; Pro'dan mesafeyle gelince otomatik kurma ve açık yan kule;
  retikül içindeki "FFP · MOA · 31x"; Hesap dökümü varsayılan kapalı / açılır / kapanır; PDF düğmesi
  simgesiz; Hava/Hava özeti başlıkları; düğmelerde simge yok, yalnız "Hava verisi alındı" ✓;
  "alındı" düğmelerinin ortak stil, yeniden açılınca korunması; rüzgâr saatinin #E8590C kalması;
  Rüzgâr ⓘ rehberi açar, ayrı bağlantı yok.
- Güncellenen (yeni karar yüzünden): başlık "Hedef" (menzil_shell, offline_app, pro_tab);
  "Kuleleri kur" yazısı (scope_dial_view); Hesap dökümünü açarak okuyan testler (scope_dial_view,
  yasla_sadece_hedef, ballistic_audit, incline_cant_ui); simge beklentileri (hava_sayfasi,
  hava_verisi_tazelik); rüzgâr rehberi ⓘ ile açılır (wind_guide); Python kaynak testleri kütüphanenin
  tamamını okur; `test_v352` başlığın "Hedef" olduğunu denetler. Hiçbir test atlanmadı (`skip:` yok),
  test/audit_*/ değişmedi.
- Yerel: `python3 tools/offline_dart_lint.py` geçti; `python3 -m unittest discover -s tools -p 'test_*.py'`
  748 test geçti. Bu ortamda Flutter SDK yok; Dart testleri ve analiz GitHub Actions'ta koştu.

## CI bağlantıları
- Taşıma commit'i (894451d), tüm testler: https://github.com/sniperTurk/flutter-app/actions/runs/38698075925 (başarılı)
- Taşıma 2 (6ef2400), analiz: https://github.com/sniperTurk/flutter-app/actions/runs/38698435610 (başarılı);
  tüm testler: https://github.com/sniperTurk/flutter-app/actions/runs/38698440894 (başarılı)
- Tasarım (5c0667a), analiz: https://github.com/sniperTurk/flutter-app/actions/runs/38699432730 (başarılı)
- Yeni testler (ee0d071), analiz: https://github.com/sniperTurk/flutter-app/actions/runs/38699783401 (başarılı);
  yeni test dosyası: https://github.com/sniperTurk/flutter-app/actions/runs/38699786388 (başarılı)
- Biçimlendirme (format-fix): https://github.com/sniperTurk/flutter-app/actions/runs/38700371229 (başarılı, da3d132)
- Son commit'in iOS CI (verify, dart-checks, wind-acceptance): https://github.com/sniperTurk/flutter-app/pull/317/checks

## Birleştirme sonucu
- Kural: son commit'te `verify`, `dart-checks` ve `wind-acceptance` başarılı ve çakışma yoksa PR hazır
  işaretlenip squash ile birleştirilir. Sonuç PR açıklamasının sonuna yazılır.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
