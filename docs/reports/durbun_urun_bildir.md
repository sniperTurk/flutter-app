# Dürbün ürün bildirimi (feat/durbun-urun-bildir)

Sahip kararları, 17.10.2026 (İstanbul): 22:09 "daha önce yaptığımız (elle dürbün girişi) daha pro" · 22:11 PCP mühimmattaki gibi girilen bilgi Cloudflare kutumuza kaydedilsin · 22:12 "eklenen ürünü sadece kullanıcı görecek" · 22:15 "dürbünü aç".

## Ne yapıldı

- Kullanıcı elle girdiği dürbünle ("Aradığın dürbün listede yok mu?") bir profili **kaydettiğinde**, o dürbünün değerleri Cloudflare ürün kutusuna (`POST https://sniper-turk-urun-kutusu.sekerbirol76.workers.dev/urun`) **bir kez** gönderilir.
- Gönderilen gövde: `{"tur":"durbun","platform":"ios","uygulamaSurumu":"<sürüm+derleme>","kurulumKimligi":null,"alanlar":{…}}`. `alanlar` içinde yalnız kullanıcının girdiği değerler var: `marka`, `model`, `birim`, `odakDuzlemi`, `minBuyutme`, `maxBuyutme`, `mercekCapi`, `klikDegeri`, `ustKuleKlikSayisi`, `retikul`. Boş olanlar gönderilmez, sayılar sayı olarak gider (6, 0.1, 200).
- Profil adı, konum, tüfek/mühimmat, dürbün ayağı, cihaz kimliği ve kişisel veri **gönderilmez**.
- Kutunun döndürdüğü kayıt kimliği cihazda saklanır (`{id, tur, createdAt}` listesi). Bu liste şimdilik hiçbir yerde gösterilmiyor; "Ürününüz fabrika değerleriyle uygulamaya eklenmiştir" + "Profilime uygula" sonraki görevin işi.
- Elle dürbün girişi ekranı **hiç değişmedi** (aynı kutular, aynı bağlantı, aynı davranış). Katalog dürbünleri gönderilmez, ortak katalog değişmez, hesap değişmez.
- Gizlilik taslakları güncellendi: `docs/app-store/03-gizlilik-politikasi.md` (TR + EN) ve `02-gizlilik-etiketi.md`.

## Nasıl

- **Port / adaptör** (diğer araçlar gibi): `lib/tools/ports/product_report_service.dart` (`ProductReportService`, tür: `tufek | muhimmat | durbun`) ve `lib/tools/adapters/cloudflare_product_report_service.dart` (tek HTTPS POST, 10 sn zaman aşımı, tekrar deneme yok; kutunun sınırları — en çok 30 alan, anahtar `[A-Za-z0-9_]`, değer ≤ 200 karakter, gövde ≤ 8 KB — gönderilmeden önce kontrol edilir).
- **Defter**: `lib/services/product_report_ledger.dart`. Mevcut yerel depoda (SharedPreferences) profil başına son gönderilen değerlerin özetini (FNV-1a hash) ve dönen kimlikleri tutar. Değerler aynıysa gönderilmez; aynı anda iki kayıt basılırsa tek istek gider.
- **Bağlantı**: `ToolsServices.productReports`. Yalnız `ios-testflight.yml` derlemesi `--dart-define=SNIPER_TURK_APP_VERSION=<pubspec sürümü>+<derleme no>` verir; bu değer yoksa servis hiç kurulmaz. Bu yüzden testler, simülatör ve CI derlemeleri gerçek kutuya **asla** istek atmaz.
- **Kaydet**: `profile_editor.dart` `_save()` içinde kayıtlar yazıldıktan sonra, `Navigator.pop`'tan hemen önce `_reportTypedScope(id)` çağrılır (`unawaited`). Kayıt işlemi bu isteği beklemez, ona bağlı değildir.

## Neden

- Sahip, listede olmayan ürünleri görmek ve üretici verisiyle kataloğa eklemek istiyor (PCP mühimmattaki düzen). Kullanıcının girdiği dürbün yine yalnız kendi profilinde kalır.
- Zaman aşımı/hata kullanıcıya hiçbir şey göstermez; profil kaydı asla bundan etkilenmez.

## Uç durumlar

- **Değişmeden tekrar kayıt**: gönderilmez. **Bir dürbün değeri değişirse**: yeniden gönderilir.
- **Ağ hatası / zaman aşımı**: hiçbir şey saklanmaz, kullanıcı bir şey görmez; o profil bir sonraki kaydedilişte tekrar dener. Sunucu kaydı aldı ama yanıt 10 sn içinde gelmediyse aynı dürbün sunucuya iki kez düşebilir (zararsız).
- **Bu sürümden önce kaydedilmiş elle dürbünlü profiller**: ilk "Güncelle"de bir kez gönderilir (önceden gönderilmedikleri için).
- **Aynı dürbün iki profilde**: her profil için bir kez gider (özet profil başına tutulur).
- **Birim SMOA**: elle girişte SMOA da seçilebildiği için `"birim":"SMOA"` olarak gider (istenen listede yalnız MOA|MRAD vardı; değer olduğu gibi gönderiliyor).
- **Tüp çapı**: elle dürbün girişinde Tüp kutusu yok, bu yüzden `tup` hiç gönderilmez.
- **Profil silinirse**: o profilin özeti cihazda kalır (birkaç bayt); kimlik listesi silinmez.
- **Profil deposuna yazma sonradan başarısız olursa**: dürbün kaydı yapılmış ve istek gitmiş olabilir; profil kaydedilmemiş görünür. Elle dürbün kaydı zaten yazıldığı için bu kabul edilebilir.

## Bilerek yapılmayan

- Dürbün sayfasında hiçbir arayüz değişikliği yok (kutu, açılır pencere, metin yok).
- Katalog dürbünleri, tüfek, mühimmat, hesap ve diğer sayfalar değişmedi.
- Worker ve `sniperTurk/kullanici-urunleri` deposu değiştirilmedi.
- Kimlik listesini gösteren ekran (sonraki görev).
- Yeni paket eklenmedi (`package_info_plus` doğrudan bağımlılık olsaydı `pubspec.lock` kayardı); sürüm TestFlight derleme bayrağıyla geliyor.
- **Mühimmat görevi ile birleştirme**: `feat/diger-marka-urun-bildir` bu dal açılırken main'e girmemişti (origin'de dal da yoktu), bu yüzden port/adaptör burada açıldı. Port tür bağımsız (`ProductReportKind.muhimmat` hazır); **iki görevin port/adaptörü tek bir tanede birleştirilmelidir** — hangisi sonra birleşirse diğerininkini kullanmalı.

## Ayrıca değişen

- `.github/workflows/ios-testflight.yml`: derlemeye `SNIPER_TURK_APP_VERSION` eklendi (pubspec sürümü + `GITHUB_RUN_NUMBER`).
- `tools/test_m1_tools_scope_contract.py`: `http` kullanan adaptörler listesine yeni adaptör eklendi (Google irtifa adaptöründe yapıldığı gibi).
- `tools/test_denetim_2026_10_15b_guvenlik.py`: sürüm derlemesinde izin verilen `dart-define` listesine `SNIPER_TURK_APP_VERSION` eklendi. Bu bir arayüz bayrağı değil, bir metin; varsayılanının boş olduğunu aynı dosyadaki test hâlâ denetliyor.
- `test/support/tool_fakes.dart`: `testServices()` isteğe bağlı `productReports` alır.
- Hiçbir test silinmedi ya da gevşetilmedi.

## Testler

`test/durbun_urun_bildir_test.dart` (gerçek ağ yok: adaptör `MockClient` ile, ekran sahte servisle):

- Elle dürbünle kaydet → **tam bir istek**, alanlar birebir; sayılar sayı; kimlik `kayit-1` saklandı.
- Değişmeden "Güncelle" → istek yok. Model `X2` yapılınca → ikinci istek, yeni değerle; sonra yine değişmeden → istek yok.
- Retikül ve Üst kule klik sayısı boşken → bu iki alan gönderilmez.
- Katalog dürbünü (Element Optics Titan) → istek yok, kimlik yok.
- Ağ hatası → profil kaydedildi, ekranda hiçbir şey yok, özet/kimlik saklanmadı; sonraki kayıt tekrar dener.
- Hiç yanıt gelmeyen istek → kayıt beklemeden kapanır.
- Uygulamada kutu yoksa (testler/CI) → hiçbir şey gönderilmez; `ToolsServices.production().productReports` testte `null`.
- Adaptör: gövde birebir JSON, adres, `Content-Type`; 400/500/bozuk yanıt/çevrimdışı/zaman aşımı → hata; varsayılan zaman aşımı 10 sn; sınır dışı alanlar istek atılmadan reddedilir.
- Defter: özet anahtar sırasından bağımsız; profil başına bir kez; `createdAt` saklanır; aynı anda iki çağrı tek istek; hiçbir zaman hata fırlatmaz.

Hesap ve arayüz: hesap koduna dokunulmadı; dürbün sayfasının widget'ları ve mevcut dürbün testleri (`den17b_1_kule_klik_test.dart`, `durbun_girisi_tasarim_test.dart` vb.) değişmedi. Arayüz değişmediği için simülatör görüntüsü alınmadı.

Yerel: `python3 tools/offline_dart_lint.py` → PASS (0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 atlanan, önceden de atlanıyordu). Bu ortamda Flutter SDK indirilemediği için (`storage.googleapis.com` engelli) `flutter test` yerelde çalışmadı; testler CI'da çalıştı.

## CI bağlantıları

CI_LINKS

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
