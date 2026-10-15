# TestFlight öncesi hesap denetimi — 15.10.2026 (b)

## Özet

- **Denetlenen sürüm:** main `4c51b77` (#324 birleşmiş hâli). Dal `audit/testflight-2026-10-15b` bu sha'dan açıldı.
- **Yüksek bulgu: 0.**
- **Karar: TestFlight başlayabilir** (bu denetim açısından; açık yüksek bulgu yok). Bu denetim TestFlight başlatmadı.
- Yeni bulgular: 1 orta (PRF-7, eski hata, #262'den beri var), 4 düşük (HDF-1, HDF-2, PRF-8, PRE-1).
- Taşıma PR'ları (#317, #318, #324) hiçbir sayıyı değiştirmedi. Eski profiller ve ayarlar yükleniyor. Depoda API anahtarı yok.

## Kapsam ve yöntem

- Tarih: 15.10.2026, İstanbul saati 19:55–20:50.
- #324: verify, dart-checks, wind-acceptance head `9a9d769` üzerinde başarılıydı. PR bu kontrolde zaten birleştirilmiş bulundu (`4c51b77`, 19:55); PR'a not yazıldı.
- Önceki TestFlight: main `d86dfff` (run 38692225761). Aradaki PR'lar: #317, #318, #319, #320, #321, #323, #324, #325.
- `lib/` değişmedi. Yalnız test, Python elle hesap ve bu rapor eklendi.
- Bağımsız kaynak: tanımlardan birim sabitleri (1 in = 25,4 mm, 1 gr = 0,06479891 g, 1 ft = 0,3048 m, MOA = π/10800 rad), Miller 2005 kararlılık formülü, ICAO standart atmosfer, `tools/formula_reference.py` (yayımlanmış G7 tablosu, CIPM hava, kendi çözücüsü). Hiçbir balistik uygulaması kullanılmadı.
- Bu ortamda Flutter SDK yok. Dart testleri yalnız CI'da çalıştı.

## PR başına tablo

| PR | Ne kontrol edildi | Bağımsız kaynak | Sonuç |
|---|---|---|---|
| #324 formüller `lib/core`'a | Taşınan her formül eski satır içi kodla tek tek karşılaştırıldı: birimler, yuvarlama, sınırlar, boş/sıfır durumları, çağıran yerler. Miller Sg, dönme kayması, aerodinamik sıçrama, sıfır ofseti (inç yolu), hareketli hedef, Profil BC penceresi, Hesaplayıcılar (Stadia, Enerji, İki hız, Hava lab), Su Terazisi yumuşatma, klik hesabı | Tanımlar, Miller 2005, elle hesap (Python) | Sayılar aynı. Örnek: Sg 1,71561429 (elle 1,71561428); Enerji 168 gr 2650 fps = 3551,15 J; hareketli hedef 2,25 mrad. Eski kopya kalmadı |
| #317 Hedef/Hava/Pro bölme + tasarım | Satır satır ve yöntem yöntem karşılaştırma; Hedef düzeltmesi, klikler, DOPE satırları, Doğrulama yolu, Pro→Hedef otomatik kule kurma, yan kule açılması, Hesap dökümü aç/kapa, "Hava verisi alındı" düğmesinin yeniden açılışta kalması, `WIND_GUIDE_LINK`, ⓘ metinleri | Python çözücü: 620 m → 5,8948 mrad yukarı, 1,6080 mrad sol; 59 U / 16 L klik | Sayılar aynı. Otomatik kurma ve yan kule çalışıyor. Düğme durumu aynı anahtarlarla kalıyor. Hesap dökümü kapalı başlıyor, hiçbir sayıyı değiştirmiyor. **HDF-1, HDF-2** |
| #318 Profil bölme + tasarım | Eski dosyanın her satırı yeni dosyalarda arandı; her metin kutusu kayıtta okunuyor mu; eski profil → dokunmadan Güncelle → çözücü girdisi; "Seçiniz" varsayılanları; Ek mühimmat kartı; açılır liste genişliği; inç/yard yolları; BC sınırları | Birim tanımları, elle hesap | Kod kaybı yok, her kutu kaydediliyor. Eski profil değişmeden kaydediliyor (yalnız gösterim yuvarlaması: hız ≤ 0,015 m/s). "Seçiniz" kayıtlı değerin üstüne yazmıyor. BC sınırları aynı. **PRF-7** (eski), **PRF-8** |
| #323 Tür zorunlu | Yalnız yeni profilde mi isteniyor; eski profil, tüfek kaydı olmayan profil, Kopyala | Kod + widget testi | Eski profil Tür yüzünden hiç engellenmiyor; Kopyala çalışıyor |
| #319 denetim testleri | Atlanan (`skip`) testler ve bulguların durumu | Önceki raporlar | Yüksek bulgular (ATM-1, PRF-2, PRF-6) düzelmiş, testleri `skip`'siz çalışıyor. Düzelmiş ama hâlâ atlanan test yok |
| #320, #321, #325 | Yalnız belge. #325'in tasarım belgesi; `lib/` içinde Claude/Anthropic bağlantısı var mı | Kod araması | `lib/` içinde anahtar ya da uç nokta yok |

### Gizli bayraklar

- d86dfff'te 15, şimdi 16 ortam okuması. Tek yenisi `WIND_GUIDE_LINK` (#317).
- Bütün `bool` bayraklar varsayılan kapalı (`defaultValue` yok).
- TestFlight derlemesi yalnız `METNO_CONTACT`, `GOOGLE_MAPS_ENABLED` ve `GOOGLE_MAPS_IOS_API_KEY` veriyor. Arayüz bayrağı açık değil; `WIND_GUIDE_LINK` kapalı.
- `WIND_GUIDE_LINK` açılırsa yalnız "Rüzgâr tahmini nasıl yapılır?" bağlantısı geri geliyor; sayı değişmiyor.

### API anahtarı

- İzlenen dosyalarda ve d86dfff sonrası bütün commit'lerde Google, Anthropic, OpenAI, GitHub anahtarı ya da özel anahtar yok. İmza dosyası (.p8, .p12, .mobileprovision) yok.
- Anahtarlar yalnız iş akışlarında `secrets.…` üzerinden geliyor.

## Bulgular

| Kimlik | Önem | Ne | Nerede |
|---|---|---|---|
| PRF-7 | Orta | Mesafe birimi "Seçiniz" iken Sıfırlama mesafesine 100 yazılıp sonra Yard seçilirse kutu 109,4 olur, 100,04 m kaydedilir; kullanıcı 100 yd (91,44 m) demek istemişti. Hata 300 yazınca 800 m'de yaklaşık 0,18 mrad (14 cm). Kutuda 109,4 göründüğü için yüksek değil. #262'den beri var, önceki TestFlight'ta da vardı | `lib/features/profiles/profile_editor_rifle.dart:576-589` (birim seçilmiş mi bakılmadan dönüştürülüyor) |
| HDF-1 (= FLG-1) | Düşük | Kaldırılan "Rüzgâr tahmini nasıl yapılır?" bağlantısı silinmemiş, `WIND_GUIDE_LINK` bayrağının arkasına saklanmış. 15.10 kuralına ("kaldırılan özellik silinir") aykırı. Sayı ve TestFlight etkilenmiyor | `ballistics_screen.dart:658-665`, `hava_durumu_view.dart:26-27` |
| HDF-2 | Düşük | Kule ok düğmeleri 44 pt en küçük dokunma boyutunun altında (üstte 28 pt, yanda 320 pt ekranda yaklaşık 23 pt). Önceden 44×44 idi. Onaylı tasarımla uyumlu; karar sahibin | `scope_turrets.dart:96-187` |
| PRF-8 | Düşük | Kalibre seçildikten sonra Tür seçilince kalibre aynı çaptaki ilk fişeğe döner (.300 Win Mag → .308 Win). Çap aynı, hesap aynı. #318/#323 ile bu yol sık kullanılır oldu | `profile_editor.dart:1558` |
| PRE-1 | Düşük | Grup merkezi "Sıfır ofsetine aktar" her zaman cm yazıyor; Pro/Hedef emperyal modda bu metni inç okur (2,54 kat). Bu derlemede emperyal mod açılamıyor (`SettingsStore.loadMetric()` hep `true`), bu yüzden şu an ulaşılamaz. #262'den kalma | `zero_group_screen.dart:117-163`, `pro_ayarlar_view.dart:261` |

Bulgu sayılmayan not: Hesap dökümünde eğim ve yatıklık açıklama satırları artık yalnız döküm açılınca görünüyor (istenen tasarım).

### Açık (önceki rapor)

Bu PR'lar bunları değiştirmedi ya da kötüleştirmedi:
- Orta: KUL-1, KUL-2, RUZ-1, RUZ-2, RUZ-3 (şüphe), MUH-1, MUH-2 (sahip kararı bekliyor), PRF-1, PRF-3, PRF-4.
- Düşük: KUL-3, ATM-2, ATM-3, MUH-3, MUH-4, MUH-5, PRF-5.
- 14 raporundan F4 testi hâlâ atlanıyor.

## Testler

`test/audit_2026_10_15b/`:
- `core_formulas_audit_test.dart`: 19 test. Her biri bir örnekte yeni formülü hem elle hesapla hem eski (d3fdf29) ifadeyle karşılaştırıyor. Atlanan yok.
- `hedef_split_audit_test.dart`: Pro 620 m → Hedef düzeltmesi, otomatik kurma 59 U / −16, yan kule; MOA profil; doğrudan açılan Hedef; DOPE 350/620 m; Hesap dökümü; düğme durumu yeniden açılışta; bayrak varsayılan kapalı. Atlanan: HDF-1, HDF-2.
- `profil_split_audit_test.dart`: iki eski profil dokunmadan kaydetme; tüfek kaydı olmayan eski profil; Kopyala → Güncelle; yeni profil (Ek mühimmat, yard, fps); PRF-8 koruma testi. Atlanan: PRF-7, PRF-8.

Python (`tools/`): `denetim_2026_10_15b_core.py`, `_hedef.py`, `_profil.py` (elle hesap) ve testleri `test_denetim_2026_10_15b_core.py`, `_hedef.py`, `_profil.py`, `_guvenlik.py` (anahtar ve bayrak taraması), `_pre.py` (PRE-1). Atlanan: HDF-1/FLG-1, PRE-1.

Not: Atlanan testlerin `skip` kaldırılınca gerçekten düştüğü bu denetimde CI'da ayrıca denenmedi.

Yerel:
- `python3 tools/offline_dart_lint.py` → 382 Dart dosyası, 0 sorun.
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 885 test başarılı, 3 atlandı.

## CI

| Ne | Sonuç | Bağlantı |
|---|---|---|
| #324 head `9a9d769`: verify, dart-checks, wind-acceptance | başarılı | https://github.com/sniperTurk/flutter-app/pull/324 |
| dart format (tek seferlik), ilk commit | başarılı; biçim commit'i geldi (`6ab4621`) | https://github.com/sniperTurk/flutter-app/actions/runs/38775532248 |
| `flutter test test`, ilk deneme | düştü: yalnız yeni Profil testi. Test, mağazanın kabul etmediği Tür'süz tüfek kaydı kullanıyordu (test hatası, uygulama hatası değil). Test gerçek durumla (tüfek kaydı yok) düzeltildi | https://github.com/sniperTurk/flutter-app/actions/runs/38775662683 |
| analyze, ilk deneme | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38775666619 |
| dart format (tek seferlik), son | başarılı; değişiklik yok | https://github.com/sniperTurk/flutter-app/actions/runs/38777320738 |
| `flutter test test` (bütün testler), son (`f065527`) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38777453446 |
| analyze, son (`f065527`) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38777457041 |

TestFlight, Simulator ve App Store çalıştırılmadı.

---
_Generated by [Claude Code](https://claude.ai/code)_
