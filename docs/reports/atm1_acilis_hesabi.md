# ATM-1 düzeltmesi: kayıtlı Hava Durumu açılışta hesaba giriyor

Dal: `fix/atm1-acilis-hesabi` (main 2ff9267'den). Taslak PR; birleştirme yok, TestFlight yok.
Bulgu: PR #310, `docs/reports/denetim_testflight_2026_10_14b.md`, ATM-1 (yüksek).

## Neden oluyordu

- Hedef'in ilk otomatik hesabı, ekran açıldıktan hemen sonra (ilk kare sonrası) çalışıyor.
- Kayıtlı ayarlar (sıcaklık, nem, basınç, İrtifa…) diskten biraz sonra geliyor.
- Gelince kutulara yazılıyor ve önbellek siliniyordu, ama yeniden hesap yapılmıyordu. Hedef, boş kutularla (deniz seviyesi havası) yapılmış eski sonucu gösteriyordu.
- Uygulama Profil'de açılıp Hedef'e geçilince görünüm değişmediği için ("shot → shot") orada da hesap yapılmıyordu.

## Ne değişti

- `lib/features/ballistics/ballistics_screen.dart`, `_loadShotSettings`: kayıt kutulara yazıldıktan sonra, bir düzenlemeden sonra çalışan aynı sessiz hesap (`_quietSolve()`) bir kez çağrılıyor.
- Yalnız kayıt gerçekten varsa çalışıyor. Hiç kayıt yoksa ek hesap yok; ilk hesap aynen kalıyor.
- Ekran kapanmışsa hiçbir şey yapmıyor (var olan `if (!mounted) return;` denetiminden sonra; arada bekleme yok).
- Profil yoksa `_quietSolve` zaten hiçbir şey yapmıyor.
- Hesap formülü, arayüz, ağ isteği değişmedi. Yeni zamanlayıcı yok.
- Hesap üst üste eklenmiyor: hesap her seferinde kutulardan baştan yapılıyor. İlk otomatik hesap `_basis` boşsa çalıştığı için, kayıt ondan önce gelirse ikinci kez çalışmıyor.
- Aynı yol Kronograf → SD gibi başka sayfanın yazdığı ayarlar yeniden okununca da hesaplıyor; bu da artık yeni değerle hesaplanıyor.

## Tekrar örneği: önce / sonra

Hava Durumu 15 °C, nem %0, Telefondan irtifa 1500 m, Basınç boş → uygulamayı kapat/aç → Hedef.

| | Önce | Sonra | Bağımsız referans |
|---|---|---|---|
| Hava yoğunluğu (kg/m³) | 1,2211 (deniz seviyesi) | 1,0223 | 1,0223 (ISA 845,56 hPa, ρ = P/(R·T)) |
| "Basınç irtifadan tahmin edildi." notu | yok | var | — |
| Kayıtlı basınç 900 hPa (15 °C, %0) | 1,2211 | 1,0881 | 1,0881 |

"Önce" sütunu, düzeltme olmadan CI'da ölçüldü (aşağıdaki kırmızı tur). "Sonra" sütunu düzeltmeden sonraki testlerden.

## Kenar durumlar

- Kayıtta yalnız basınç (İrtifa yok): 900 hPa kullanılıyor, not yok.
- Basınç ve İrtifa birlikte kayıtlı: yazılı basınç kazanıyor, İrtifa ikinci kez uygulanmıyor (1,0881).
- Hiç kayıt yok: deniz seviyesi, öncekiyle aynı (1,2211), not yok.
- Kapatmadan önce İrtifa Sıfırla: açılışta İrtifa boş, 1,2250 (1013,25 hPa, 15 °C, %0), not yok.
- Uygulama Hedef'te açılınca, Profil'de açılıp Hedef'e geçince, Hava Durumu → Hedef geçişinde not görünüyor.
- Ayarlar gelmeden ekran kapanırsa: hata yok, bekleyen zamanlayıcı yok.

## Testler

- `test/audit_2026_10_14b/atm1_restart_solve_test.dart` (yeni):
  - Denetim dalından kopyalanan iki ATM-1 testi, `skip` kaldırılmış: "Hava yoğunluğu after a restart matches the restored boxes", "Hedef opened directly shows the F1 note for the restored İrtifa".
  - Eklenenler: Profil → Hedef (shot → shot); Hava Durumu → Hedef; yalnız basınç kayıtlı; basınç + İrtifa kayıtlı; kayıt yok; Sıfırla sonra yeniden açılış; ayarlar gelmeden kapanma; açılıp kapanınca bekleyen zamanlayıcı yok.
- `tools/test_atm1_acilis_hesabi.py` (yeni): denetimdeki `test_atm1_saved_weather_is_solved_after_it_is_restored` (`expectedFailure` olmadan) ve kaynak korumaları (hesap geri yazmadan ve `mounted` denetiminden sonra; yalnız kayıt varsa; ağ/zamanlayıcı çağrısı yok; Dart testlerinde `skip` yok).
- Not: PR #310 henüz main'de değil. Bu testler ayrı dosyada; #310 birleşince oradaki iki ATM-1 testindeki `skip: true` ve Python'daki `@unittest.expectedFailure` kaldırılmalı (ya da bu PR'dan sonra birleşirse bu dosyalarla çakışma yok, yalnız o iki satır).

Yerel:
- `python3 tools/offline_dart_lint.py`: PASS, 346 Dart dosyası, 0 sorun.
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 748 test, OK.
- Flutter SDK bu ortama kurulamadı (storage.googleapis.com proxy'de 403); Dart testleri yalnız CI'da çalıştı.

## CI

| İş | Commit | Sonuç | Bağlantı |
|---|---|---|---|
| ATM-1 testleri, düzeltme olmadan (kırmızı kanıt) | baafe30 | beklendiği gibi başarısız: 1,2211 ölçüldü, not yok | https://github.com/sniperTurk/flutter-app/actions/runs/38603852389 |
| Dart format düzeltme | 122b864 | başarılı, değişiklik commit'i yok | https://github.com/sniperTurk/flutter-app/actions/runs/38604069316 |
| ATM-1 testleri, düzeltmeyle | 122b864 | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38604199480 |
| Bütün test takımı (`files=test`) | 122b864 | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38604190475 |
| analyze | 122b864 | başarısız: testte kullanılmayan `_type` | https://github.com/sniperTurk/flutter-app/actions/runs/38604195310 |
| analyze | 28608af | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38604402794 |
| Dart format düzeltme | 28608af | başarılı, değişiklik commit'i yok | https://github.com/sniperTurk/flutter-app/actions/runs/38604931095 |
| Bütün test takımı (`files=test`) | 28608af | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38604935842 |

- iOS CI (`iOS CI / verify`), Simulator ve TestFlight çalıştırılmadı; geçti denmiyor.

## Yapılmayanlar

- Birleştirme ve TestFlight yok.
- ATM-2, ATM-3 ve diğer denetim bulgularına dokunulmadı.
- PR #310'daki atlanmış ATM-1 testleri bu dalda değiştirilmedi (o dosyalar main'de yok).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
