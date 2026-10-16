# Pro Ayarlar: açılan bölümlerdeki kutulardan ⓘ kaldırıldı

Dal: `fix/pro-kutu-info-kaldir` · PR: #373 (taslak)

Sahip, 16.10.2026 21:16–21:17 (İstanbul), TestFlight 110 ekran görüntüsü
(Pro Ayarlar, "Hareketli hedef" açık, her kutuda ⓘ): "Pro sayfası açılan
menü içindeki kutuların hepsinden infoları kaldır, zaten başlıklarda info
var."

## Ne yapıldı

- Pro Ayarlar'da açılan her bölümün kutularındaki ⓘ kaldırıldı:
  - Açı: Tüfek eğimi, Dürbün eğimi
  - Rüzgâr düzeltmesi: En çok rüzgâr, Yol ortası, Hedefte
  - Coriolis: Enlem, Atış yönü
  - Yerçekimi: Yerçekimi
  - Hareketli hedef: Hedef hızı, Yönü, Grup çapı, Hız farkı, Hedef çapı,
    Mesafe hatası, BC hatası, Atış sayısı
  - Tüfek düzeltmeleri: Gerçek / yazan, Yukarı + / aşağı −, Sağ + / sol −,
    Mermi uzunluğu, Kalan tüp basıncı (yalnız bayrak açıkken görünür)
- Bölüm başlıklarındaki ⓘ yerinde kaldı ("Hareketli hedef ⓘ" gibi).
  Başlığın alttan açılan sayfası, "Kutular" başlığı altında bölümdeki her
  kutunun açıklamasını kutunun eski ⓘ metniyle aynen gösteriyor. Bu
  metinler zaten sayfadaydı. Hiçbir açıklama kaybolmadı, metin
  değişmedi.
- CLAUDE.md'ye sahip istisnası eklendi ("UI rule: explain every entered
  value" altına).

## Nasıl

- `lib/features/ballistics/pro_ayarlar_view.dart`: bölüm içindeki
  `MenzilInput` / `MenzilSelect` kutularından `info:` ve Açı kutucuklarından
  `MenzilInfoButton` kaldırıldı. Kutu ⓘ'sını başlık sayfasına yönlendiren
  `MenzilInfoScope` sarmalayıcısı da kaldırıldı.
- Kullanılmayan kod silindi (CLAUDE.md, "kaldırılan özellik silinir"):
  - `lib/ui/menzil_widgets.dart`: `MenzilInfoScope` ve
    `MenzilInfoButton` içindeki yönlendirme.
  - `lib/features/ballistics/pro_info_sheet.dart`: dokunulan kutuyu
    vurgulama (`highlight`). Liste aynı yerde duruyor; boşluk aynı
    bırakıldı.
- Birimler kutunun içinde sağda kalıyor; ⓘ yokken birimden sonra 12 pt
  boşluk bırakılıyor. Bu, Hava Durumu'ndaki ⓘ'sız kutularda zaten var
  olan davranış.
- Değerler, kayıt anahtarları, satırda iki kutu düzeni, "Verileri sil" ve
  hesaplar değişmedi.

## Neden

Sahibin isteği: başlıkta zaten ⓘ var, kutulardaki ⓘ aynı sayfayı açıyordu.
Böylece her bölümde tek bilgi düğmesi kalıyor.

## Uç durumlar

- Coriolis / Yerçekimi kapalıyken kutular görünmüyor. Başlık sayfası da
  yalnız görünen kutuları listeliyor; bu davranış önceden de böyleydi.
- Mermi uzunluğu (spin drift açıkken) ve Kalan tüp basıncı
  (`PRO_TUBE_PRESSURE` açık PCP'de) görünüyorsa sayfada da yer alıyor.
- "Atış mesafesi" bölüm dışında (üst kart). Onun ⓘ'su kaldı, açılır
  pencere olarak açılıyor.
- Garmin saati satırının ⓘ'su bir başlık ⓘ'sı olduğu için kaldı.
- Diğer sayfalar (Hava Durumu, Profil, Hedef ve diğerleri) değişmedi.

## Bilerek yapılmayan

- Açık PR'larla çakışma olmasın diye başka dosyaya dokunulmadı.
  - fix/duzeltmeleri-16-10, Pro → Tüfek düzeltmeleri'ne "Mühimmat
    sıcaklığı" kutusu ekliyor. O PR birleşirse o kutu bu kurala göre ⓘ'sız
    olmalı ve metni Tüfek düzeltmeleri başlık sayfasına eklenmeli. Bu iş o
    PR'da veya birleştirmede yapılmalı.
  - #368, `MenzilInput`'u değiştiriyor. Bu PR `menzil_widgets.dart`'ta
    yalnız `MenzilInfoScope` bölümünü siliyor; #368'in değiştirdiği
    satırlarla çakışmıyor.
- Hiçbir açıklama metni değiştirilmedi.
- TestFlight başlatılmadı, birleştirme yapılmadı.

## Testler

- `test/pro_info_popup_test.dart` (PCP ve ateşli silah için):
  - Açılan her bölümde başlık ⓘ'su dışında `MenzilInfoButton` ve bilgi
    simgesi yok.
  - Başlık ⓘ'su duruyor.
  - Bölümdeki kutuların adları, başlık sayfasındaki "Kutular" listesiyle
    sırasıyla aynı. Her kutu sayfada bir kez geçiyor ve metni eski ⓘ
    metniyle aynı.
  - Dar ekranda (320 pt, yazı ×1,3) son kutu (Mermi uzunluğu) kaydırılarak
    görülebiliyor.
- `test/kutu_fikir4_test.dart`:
  - Pro bölüm kutularında birim kutunun içinde sağda, ⓘ yok.
  - Atış mesafesi kutusunda ⓘ hâlâ var.
  - Hava sayfasının kontrolleri değişmedi.
  - Atış sayısı listesi oku ile açılıyor.
- `test/pro_tab_test.dart`: Enlem ve Atış yönü kutularında ⓘ yok;
  Coriolis başlık sayfası ikisinin açıklamasını gösteriyor.
- `integration_test/wez_tour.dart`: Atış sayısı ekranı artık başlık
  ⓘ'sından açılıyor.
- Başka sayfaların kontrolleri gevşetilmedi.
- `tools/denetim_*.py` Pro'da ⓘ denetlemiyor; değişiklik gerekmedi.
- Yerel sonuçlar:
  - `python3 tools/offline_dart_lint.py`: GEÇTİ (407 dosya, 0 sorun).
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: GEÇTİ (915
    test, 1 atlanan; atlanan test bu PR'dan önce de atlanıyordu).
  - Flutter yerelde çalıştırılamadı: SDK indirmesi ağ politikasınca
    engellendi (storage.googleapis.com 403). Flutter testleri yalnız
    CI'da çalıştı.

## Ekran görüntüleri (önce / sonra, 390 pt)

`integration_test/sim_screens_pro_kutu_test.dart` gerçek Pro sayfasını
iOS Simülatöründe 390 pt genişlikte çiziyor:
- Hareketli hedef açık
- Hareketli hedef başlık ⓘ sayfası ve onun "Kutular" listesi
- Tüfek düzeltmeleri açık

"Önce" görüntüsü bu değişiklikten önceki commit'ten (yalnız tur
eklenmiş main), "sonra" görüntüsü bu daldan alındı.

| Ekran | Önce (86826816) | Sonra (dd722d8) |
|---|---|---|
| Hareketli hedef açık | <img src="https://github.com/sniperTurk/flutter-app/blob/7b861a34d53f6cfbcc595c57ec3ef35ab25469ed/latest/01_pro_target_acik.png?raw=true" width="240"> | <img src="https://github.com/sniperTurk/flutter-app/blob/cde39146e8cf7087dd717817a6c9b003ae7cb202/latest/01_pro_target_acik.png?raw=true" width="240"> |
| Tüfek düzeltmeleri açık | <img src="https://github.com/sniperTurk/flutter-app/blob/7b861a34d53f6cfbcc595c57ec3ef35ab25469ed/latest/04_pro_rifle_acik.png?raw=true" width="240"> | <img src="https://github.com/sniperTurk/flutter-app/blob/cde39146e8cf7087dd717817a6c9b003ae7cb202/latest/04_pro_rifle_acik.png?raw=true" width="240"> |
| Hareketli hedef başlık ⓘ sayfası | <img src="https://github.com/sniperTurk/flutter-app/blob/7b861a34d53f6cfbcc595c57ec3ef35ab25469ed/latest/02_pro_target_baslik_bilgi.png?raw=true" width="240"> | <img src="https://github.com/sniperTurk/flutter-app/blob/cde39146e8cf7087dd717817a6c9b003ae7cb202/latest/02_pro_target_baslik_bilgi.png?raw=true" width="240"> |
| Başlık sayfasında Kutular listesi | <img src="https://github.com/sniperTurk/flutter-app/blob/7b861a34d53f6cfbcc595c57ec3ef35ab25469ed/latest/03_pro_target_baslik_bilgi_kutular.png?raw=true" width="240"> | <img src="https://github.com/sniperTurk/flutter-app/blob/cde39146e8cf7087dd717817a6c9b003ae7cb202/latest/03_pro_target_baslik_bilgi_kutular.png?raw=true" width="240"> |

Simülatör çalıştırmaları: önce [run 38951402069](https://github.com/sniperTurk/flutter-app/actions/runs/38951402069), sonra [run 38956616073](https://github.com/sniperTurk/flutter-app/actions/runs/38956616073); ikisi de rc 0, 4 görüntü. Sonrada kutularda ⓘ yok, birimler kutu içinde sağda; başlık ⓘ'ları duruyor; başlık sayfası kutuları listeliyor.


## CI

- iOS CI (PR, dd722d8): [run 38948416171](https://github.com/sniperTurk/flutter-app/actions/runs/38948416171) — `verify` GEÇTİ, `dart-checks` GEÇTİ, `wind-acceptance` GEÇTİ (`ios-simulator` PR'da atlanıyor).
- Biçim (375209577): [run 38947738296](https://github.com/sniperTurk/flutter-app/actions/runs/38947738296) GEÇTİ; biçim commit'i b1d2c963 dala alındı.
- test-diag (`files=test`, b1d2c963): [run 38948074363](https://github.com/sniperTurk/flutter-app/actions/runs/38948074363) GEÇTİ. Sonraki iki commit yalnız yorum ve bir import; aynı testler `verify` içinde dd722d8'de de geçti.
- analyze-diag: ilk koşu [38948078228](https://github.com/sniperTurk/flutter-app/actions/runs/38948078228) ekran turundaki gereksiz import yüzünden KALDI; dd722d8 ile düzeltildi, [run 38948410375](https://github.com/sniperTurk/flutter-app/actions/runs/38948410375) GEÇTİ.
- Not: PR, bu rapor tamamlanmadan sahibin ana oturumunca main'e birleştirildi (f46ab8f, 19:37 UTC). Bu rapor dosyası bu yüzden yalnız `fix/pro-kutu-info-kaldir` dalında; main'e ayrıca alınması gerekirse ana oturum karar verir.


## Kod ve güvenlik incelemesi

- Code Review: ≥80 güvenli sorun yok. Eskimiş bir belge yorumu düzeltildi.
- Security review: sorun yok. Gizli anahtar, ağ ya da dosya erişimi
  eklenmedi; kayıtlı anahtarlar değişmedi, eski kayıtlar yükleniyor.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
