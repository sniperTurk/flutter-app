# HDF-1: Rüzgâr rehberi bağlantısı silindi

Dal: `fix/hdf1-ruzgar-rehberi-sil`. Taslak PR #357. Birleştirme yok, TestFlight yok.

İki çalışmada yapıldı. İlk çalışma (16.10.2026 sabah) #335 birleştikten sonra main'den dal açtı, silmeyi yaptı ve bu PR'ı açtı. O sırada #333 (denetim testleri) henüz main'de değildi. İkinci çalışma (16.10.2026, İstanbul 12:30 sonrası) #335 ve #328'in birleştiğini gördü, güncel main'i (#333, #355, #358 dahil) dala birleştirdi ve #333'ün denetim testlerini silinen bağlantıya göre güncelledi.

## Ne
- Hava Durumu sayfasında artık kullanılmayan "Rüzgâr tahmini nasıl yapılır?" bağlantısı koddan silindi.
- `WIND_GUIDE_LINK` bayrağı silindi. Bu bağlantıyı geri açmanın bir yolu artık yok.
- Rüzgâr başlığındaki ⓘ aynen duruyor. Dokununca "Rüzgârı gözle tahmin et" penceresi açılır: 6 satır ve Kapat düğmesi. Metin değişmedi.

## Nasıl
- `lib/features/ballistics/ballistics_screen.dart`: `_showWindGuideLink` (`bool.fromEnvironment('WIND_GUIDE_LINK')`) silindi. `WIND_OBSERVATION` açıklamasında "kartın altındaki bağlantı" diyen yorum "Rüzgâr ⓘ" olarak düzeltildi. Yalnız yorum değişti.
- `lib/features/ballistics/hava_durumu_view.dart`: Rüzgâr kartı ile "Pro Ayarlar'a geç" arasındaki gizli `WindGuideLink` satırı ve yorumu silindi. ⓘ'nin yanındaki yorum güncellendi.
- `lib/features/ballistics/wind_guide.dart`: yalnız bu bağlantı için olan `WindGuideLink` sınıfı (Key `wind-guide-link`) silindi.
  - `WindGuide` (başlık, satırlar, pencere) ve `WindGuideLines` duruyor, çünkü ⓘ bunları kullanıyor.
  - `linkLabel` metni ⓘ'nin ipucu ve VoiceOver etiketi olduğu için duruyor. Yorumu buna göre düzeltildi.
- Depo baştan sona tarandı (lib, test, tools, .github). Bayrağı açan bir derleme ya da iş akışı yok. Başka ekran ya da metin bu bağlantıya bağlı değil.

## Neden
- Sahibin kuralı (15.10.2026): kaldırılan ya da kullanılmayan özellik koddan silinir, bayrağın arkasına saklanmaz.
- Denetim bulgusu HDF-1 (= FLG-1, düşük): `docs/reports/denetim_testflight_2026_10_15b.md`, PR #333.

## Uç durumlar
- Kayıtlı kullanıcı verisine dokunulmadı. Bağlantı hiçbir şey kaydetmiyor, hiçbir kutuya değer yazmıyordu. Hiçbir sayı değişmez.
- TestFlight derlemesi bu bayrağı hiç açmıyordu. Görünen ekran aynı kalır.
- Rüzgâr ⓘ metrik (m/s) ve emperyal (mph) birimde aynı satırları gösterir.

## Bilerek yapılmayan
- Rüzgâr ⓘ'nin metni, başlığı ve görünüşü değişmedi.
- `WIND_OBSERVATION` (Rüzgâr gözlemi) bayrağı bu görevin kapsamında değil, dokunulmadı.
- Eski raporlar tarihî kayıt olduğu için değiştirilmedi: `ruzgar_rehber.md`, `temiz_tasarim_hedef.md`, `denetim_testflight_2026_10_15b.md`. Denetim raporundaki HDF-1 satırına "düzeldi" notu eklenmedi. Sahip isterse ayrı bir işte eklenebilir.
- CI'daki test tanısında görülen hatalar bu PR'dan gelmiyor ve bu PR'da düzeltilmedi. Ayrıntısı CI bölümünde.

## Testler
- `test/wind_guide_test.dart`: "imperial popup shows mph" testi eskiden silinen `WindGuideLink` ile pencereyi açıyordu. Şimdi pencereyi doğrudan `WindGuide.show(metric: false)` ile açıyor ve aynı 6 mph satırını ve m/s olmadığını denetliyor. Test zayıflatılmadı. Bağlantının görünmediğini, ⓘ'nin Rüzgâr başlığında durduğunu ve pencereyi açtığını denetleyen testler aynen kaldı. Yalnız yorumları güncellendi.
- `test/audit_2026_10_15b/hedef_split_audit_test.dart` (#333'ten), `WIND_GUIDE_LINK` grubu:
  - Silinen sınıfı kullanan ve bayrağın var olmasını bekleyen iki test kaldırıldı.
  - Yerine yeni bir widget testi geldi. Hava Durumu'nda bağlantı yok. ⓘ'nin ipucu `WindGuide.linkLabel`. ⓘ'ye dokununca pencere açılıyor, başlık "Rüzgârı gözle tahmin et" ve 6 rehber satırı `WindGuide.lines` ile birebir aynı.
  - HDF-1 testi ("removed link is deleted, not kept behind a flag") **artık atlanmıyor**. `ballistics_screen` kütüphanesinde ve `wind_guide.dart` içinde bayrak, `_showWindGuideLink`, `WindGuideLink` ve `wind-guide-link` anahtarı yok. `lib/` altındaki hiçbir `.dart` dosyasında da yok.
- `tools/test_denetim_2026_10_15b_hedef.py`:
  - Bayrağın varsayılan kapalı olduğunu denetleyen `test_wind_guide_flag_defaults_off` kaldırıldı, çünkü bayrak artık yok.
  - HDF-1 testi `test_removed_wind_guide_link_is_deleted` **atlanmadan çalışıyor**. Kapsamı genişletildi: `wind_guide.dart`, `_showWindGuideLink` ve anahtar da denetleniyor.
- `tools/test_denetim_2026_10_15b_guvenlik.py`: FLG-1 testi `test_no_new_flag_after_delete_not_hide_rule` **atlanmadan çalışıyor** ve geçiyor.
- `tools/test_hdf1_ruzgar_rehberi_sil.py` (ilk çalışmada eklendi, 5 test):
  - `lib/` altında `WIND_GUIDE_LINK`, `WindGuideLink`, `'wind-guide-link'` ve `_showWindGuideLink` yok.
  - `.github` ve `tools` betikleri bayrağı açmıyor.
  - Rüzgâr ⓘ hâlâ `WindGuide.linkLabel` ipucuyla `WindGuide.show`'u açıyor.
  - Rehber metni duruyor.
- `test/temiz_tasarim_hedef_test.dart`: değişmedi. Bağlantının olmadığını ve ⓘ'nin rehberi açtığını zaten denetliyor.
- Yerel sonuçlar:
  - `python3 tools/offline_dart_lint.py`: PASS, 406 dosya, 0 sorun.
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: 915 test OK, 1 atlandı. Atlanan PRE-1, açık bulgu ve bu işle ilgisi yok. Main'de 3 test atlanıyordu; HDF-1 ve FLG-1 artık çalışıyor.
  - Bu ortamda Flutter yok. Flutter testleri yalnız CI'da çalıştı.

## CI bağlantıları
Commit `1eca540` (main birleştirildikten sonra). Bundan sonraki commit yalnız bu raporu değiştirir:

- Format (One-off dart format fix): https://github.com/sniperTurk/flutter-app/actions/runs/38881531170 → success. Düzeltme commit'i gerekmedi.
- Analyze (One-off analyze diagnostic): https://github.com/sniperTurk/flutter-app/actions/runs/38881536950 → success.
- Test (One-off test diagnostic, files=test): https://github.com/sniperTurk/flutter-app/actions/runs/38881534120 → iş "success" bitti, ama şu dosyalarda hata bildirdi:
  - `truing_shared_record_test.dart`
  - `scope_mount_cant_test.dart`
  - KESIK (kesik metin) denetimi: Profil formu (yeni/düzenle) ve Pro "kapalı"
  
  Rüzgâr ve rehber testlerinde, ayrıca `audit_2026_10_15b` testlerinde hata yok. Karşılaştırma için aynı tanı main'de de çalıştırıldı: https://github.com/sniperTurk/flutter-app/actions/runs/38883882578 → aynı 10 hata satırı birebir aynı. Yani bu hatalar main'de zaten var.
- PR denetimleri (iOS CI run https://github.com/sniperTurk/flutter-app/actions/runs/38881537644):
  - `wind-acceptance`: success, https://github.com/sniperTurk/flutter-app/actions/runs/38881537644/job/116909182909
  - `dart-checks`: success, https://github.com/sniperTurk/flutter-app/actions/runs/38881537644/job/116909182571
  - `verify`: success, https://github.com/sniperTurk/flutter-app/actions/runs/38881537644/job/116913869292
  - `ios-simulator`: atlandı (isteğe bağlı iş).
- Simulator, cihaz ve TestFlight çalıştırılmadı.

## İnceleme
- Code Review (CLAUDE.md uyumu, hata taraması, git geçmişi, eski PR yorumları, kod yorumları): kodda sorun bulunmadı. Bulunan tek şey bu raporun ilk sürümünün eskimiş olmasıydı ("#333 henüz main'de değil"). Bu sürümde düzeltildi.
- Security review: güvenlik sorunu yok. Değişiklik yalnız silme. Ağ çağrısı, gizli anahtar, kayıtlı veri ya da iş akışı değişikliği yok. Python testleri yalnız depo içindeki dosyaları okuyor.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_015tDqvXyrwgaqQPsyXYmgJp
