# Formül denetimi — inceleme raporu (PR #264)

Dal: `fix/formul-denetimi`. Ayrıntılı araştırma notu: `docs/research/formul_denetimi.md`.
Bu rapor, birleştirmeden önce mantığın anlaşılması için yazıldı.

Dal `main` ile güncellendi (merge, çakışma yok; main'deki Profil özeti başlık
boyutu, tahmini BC, turuncu hava düğmesi, dürbün filtreleri vb. aynen duruyor).

## Kısa özet

| # | Değişiklik | Ateşli tüfek (.308) | PCP slug | PCP pellet |
|---|---|---|---|---|
| 1 | Miller Sg ses altında ses hızındaki hız katsayısını kullanır | değişmez | Sg %4,3 yükselir, spin drift ~%3 artar | (2. madde yüzünden artık hesaplanmaz) |
| 2 | Diabolo pellet'te spin drift ve rüzgâr sıçraması yok | değişmez | değişmez | kapatıldı |
| 3 | Pro "Mermi uzunluğu" boşsa Profil > Mühimmat uzunluğu kullanılır | uzunluk profilde varsa Sg/spin drift artık çıkar | aynı | — |
| 4 | Hiç kullanılmayan 11 kod parçası silindi | davranış aynı | aynı | aynı |

---

## 1. Miller Sg — ses altı hız düzeltmesi

**NE:** `lib/core/stability.dart`, `Stability.millerSg` ve yeni
`Stability.speedOfSoundMps`.

**NASIL:** Miller formülü

Sg = 30·m / (t²·d³·l·(1+l²)) · (v/2800)^(1/3) · (T+460)/519 · 29,92/P

(m grain, d çap inç, t yiv oranı kalibre, l uzunluk kalibre, v fps, T °F,
P inHg). Değişiklik yalnız `v` için: mermi hızı yerel ses hızından düşükse
`v` yerine ses hızı konur.

- Ses hızı: kuru hava, ideal gaz, c = √(1,4 · 287,05 · (T°C + 273,15)).
  15 °C'de 340,29 m/s (ICAO Doc 7488/3 ile aynı).
- Koşul: `sound.isFinite && sound > velocityMps ? sound : velocityMps`.

**NEDEN:** Courtney & Miller, "A Stability Formula for Plastic-Tipped
Bullets: Part 1", Precision Shooting, Ocak 2012 (arXiv:1410.5340): "Bu
düzeltme katsayısı ses hızının altındaki bütün hızlarda ses hızındaki değeri
alır." Uygulama slug'ın kendi hızını kullanıyordu, Sg düşük çıkıyordu.

**ETKİ (sayılarla, ICAO 15 °C, 1013,25 hPa):**

.25 (6,35 mm) 50 gr slug, 985 fps (300 m/s), 10 mm, yiv 1:16:

| | Önce | Sonra |
|---|---|---|
| Sg | 3,019 | 3,148 (+%4,3) |
| Spin drift 100 m | 2,04 cm (0,204 mrad) | 2,10 cm (0,210 mrad) |
| Spin drift 200 m | 8,12 cm (0,406 mrad) | 8,37 cm (0,418 mrad) |
| Spin drift 300 m | 18,97 cm (0,632 mrad) | 19,55 cm (0,652 mrad) |
| Rüzgâr sıçraması, 10 mph yan rüzgâr | 0,170 mrad | 0,174 mrad |

(Yiv 1:17'de Sg 2,674 → 2,788; 300 m'de 17,4 → 17,9 cm.) Fark en çok
0,02 mrad, yani bir 0,1 mrad klikin beşte biri.

.308 168 gr, 2650 fps, 1:10, 31 mm: Sg 2,46 — **değişmez** (mermi ses
üstünde, koşul devreye girmez).

**KENAR DURUMLAR:**
- Mermi tam ses hızında: iki yol aynı değeri verir (test ediyor).
- Soğuk hava (−10 °C): ses hızı 325 m/s'ye düşer; 300 m/s slug yine
  ses altında, ses hızı kullanılır (test: Sg 2,4916).
- Ses hızı hesaplanamazsa (ör. −273 °C altı geçersiz giriş, NaN): eski
  davranış, mermi hızı kullanılır.

**BİLEREK DEĞİŞTİRİLMEYEN:**
- Yörünge hesabı nemli hava ses hızını kullanmaya devam ediyor
  (`Atmosphere.speedOfSoundMps`); yalnız Miller formülü kuru havaya göre
  tanımlandığı için kuru hava kullanır. Fark ihmal edilebilir (<0,3 %).
- Kararlılık uyarısı (Ö5) yalnız ateşli tüfekte gösterilmeye devam ediyor.

**TEST:** `test/formul_denetimi_2026_10_13_test.dart`, grup
"Miller Sg below the speed of sound": ICAO ses hızı, ses altı değer
(Python referansıyla 1e-5), soğuk hava, ses üstünde değişmezlik. Python
referansı: `tools/formul_denetimi_2026_10_13.py` (`miller_sg`) ve
`tools/test_formul_denetimi_2026_10_13.py`.

---

## 2. Diabolo pellet'te spin drift ve rüzgâr sıçraması yok

**NE:** `lib/features/ballistics/ballistics_screen.dart`, `_stability()`.
Bu metot hem `_spinDriftMrad` (spin drift) hem `_aeroJumpMrad` (rüzgâr
sıçraması) tarafından kullanılıyor.

**NASIL:** Yeni koşul:
`if (ammunition?.type == AmmunitionType.pellet) return null;`
`null` dönünce ikisi de hesaplanmaz, Atış ekranında spin drift satırı
görünmez. Slug (`AmmunitionType.slug`) ve mermi (`bullet`) aynen hesaplanır.

**NEDEN:** Diabolo pellet dönüşle değil, eteğinin sürüklenmesiyle (basınç
merkezi ağırlık merkezinin arkasında) düz uçar. Miller kuralı ve Litz'in
spin drift (1,25·(Sg+1,2)·TOF^1,83) ve rüzgâr sıçraması formülleri dönüşle
kararlı mermiler için çıkarılmıştır (Litz, Applied Ballistics for
Long-Range Shooting). Uygulamanın kendi PCP notu da "slug ile anlamlıdır"
diyordu; ama Pro'da uzunluk yazılırsa pellet'e de uygulanıyordu.

**ETKİ:** .22 18 gr pellet, 100 m: önce ~2,5 cm yanlış yan düzeltme ve
10 mph yan rüzgârda ~1,4 cm yanlış dikey düzeltme ekleniyordu; artık 0.
Slug ve .308'de sayı değişmez.

**KENAR DURUMLAR:**
- Profilde mühimmat yoksa (`ammunition == null`) koşul tutmaz; eskisi gibi
  diğer kontroller (yiv, uzunluk) karar verir.
- Pellet'e Pro'da uzunluk yazılsa da hesap yapılmaz (test ediyor).

**BİLEREK DEĞİŞTİRİLMEYEN:** Ateşli tüfeklerdeki kararlılık/transonik
uyarıları (`_flightWarnings`) zaten yalnız ateşli tüfekte; dokunulmadı.

**METİN:** PCP notuna (`ProSectionInfo.spinDriftPcpNote`) "Diabolo pellet
için hesaplanmaz." eklendi.

**TEST:** `test/formul_denetimi_2026_10_13_test.dart`,
"pellet: no spin drift even with a typed length".

---

## 3. Profil > Mühimmat uzunluğu Sg için kullanılır

**NE:** `ballistics_screen.dart`, yeni getter `_bulletLengthMm`;
`_muzzleSg()` ve `_stability()` artık bunu kullanıyor.

**NASIL:**
- Pro'daki "Mermi uzunluğu" kutusu doluysa o değer;
- boşsa profildeki mühimmatın `lengthMm` değeri;
- değer 0'dan büyük ve en fazla 100 mm değilse `null` (Sg ve spin drift
  hesaplanmaz). Pro kutusuna geçersiz bir sayı (ör. 150) yazılırsa
  profil değerine düşülmez; kullanıcının yazdığı geçerli sayılmaz ve
  hesap yapılmaz (eski davranışla aynı).

**NEDEN:** Profil > Mühimmat'taki "Uzunluk" kaydediliyordu ama hiçbir
hesapta kullanılmıyordu; kullanıcı aynı değeri Pro'ya tekrar yazmak
zorundaydı.

**ETKİ:** Profilinde uzunluk olan kullanıcıda spin drift açıksa artık
Pro'ya yazmadan da gösterilir. Örnek: .25 50 gr slug, 10 mm, 1:16 →
300 m'de 19,6 cm sağa. Pro kutusu doluysa sonuç eskisiyle aynı.

**KENAR DURUMLAR:** iki kaynak da boş → eskisi gibi hesap yok; ikisi
dolu → Pro kutusu geçerli.

**METİN:** "Mermi uzunluğu" ⓘ (`EnvironmentFieldInfo.bulletLength`) ve
Spin drift açıklamasına (`ProSectionInfo.spinDrift`) "Boşsa Profil >
Mühimmat'taki uzunluk kullanılır" eklendi.

**TEST:** "slug: the Profil length gives spin drift with no Pro box".

---

## 4. Ölü kod temizliği

Hepsi `lib/`, `test/`, `integration_test/` ve `tools/` içinde tekrar
arandı (grep); hiçbirine referans yok (yalnız eski denetim notu
`docs/guvenlik-denetimi-2026-10-11.md` adlarını anıyor).

| Silinen | Dosya |
|---|---|
| `EnvironmentFieldInfo.spinDrift` (yerine `ProSectionInfo.spinDrift` kullanılıyor) | `environment_field_info.dart` |
| `ProfileFieldInfo.caliberOther` | `profile_field_info.dart` |
| `ToolFormat.velocity` | `tool_support.dart` |
| `UserCatalogStore.rifle / ammunition / scope` (+ kullanılmayan import) | `user_catalog_store.dart` |
| `ColdBoreSummary.correctionRightMrad` | `cold_bore.dart` |
| `GravityFilter.isAdaptive` | `tilt_math.dart` |
| `LevelController.setAutoMode / cancelCalibrationCapture / clearAllCalibration` | `level_controller.dart` |
| `MenzilRadius.hold` | `menzil_theme.dart` |

**BİLEREK SİLİNMEYEN:** gizli bayraklar `SHOT_TABLE_SWITCH`,
`WELCOME_RESTORE`, `PCP_AMMO_BRAND`, `GOOGLE_MAPS_ENABLED` yerinde
(`SCOPE_LISTEDE_YOK` depoda yok). Eski "Kütüphaneden seç" ekranı ve
kalın DejaVu yazı tipi de silinmedi; karar sahibin.

---

## 5. Yörünge çözücüsü (değişiklik yok, doğrulama)

Çözücü bağımsız bir Python nokta-kütle referansıyla karşılaştırıldı
(.308 168 gr G1, 6.5 CM 140 gr G7, 6,35 mm 50 gr slug, .22 18 gr pellet);
fark 0,005 mrad toleransın içinde (klik 0,1 mrad). Test: aynı dosyada
"solver vs independent point-mass reference".

---

## 6. Kontroller

Yerel:
- `python3 tools/offline_dart_lint.py` → PASS (310 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 732 test OK

CI:

Hepsi `fix/formul-denetimi` dalının `856c36f` commit'inde (main ile birleşmiş
hâli + bilgi metinleri) çalıştı:

| İş | Çalışma | Sonuç |
|---|---|---|
| Dart format (`format-fix.yml`, 375209577) | [#304](https://github.com/sniperTurk/flutter-app/actions/runs/38422105467) | ✅ başarılı; biçim değişikliği gerekmedi, commit itilmedi |
| `flutter analyze` (`analyze-diag.yml`) | [#230](https://github.com/sniperTurk/flutter-app/actions/runs/38422109442) | ✅ başarılı |
| `flutter test test` (`test-diag.yml`) | [#354](https://github.com/sniperTurk/flutter-app/actions/runs/38422114695) | ✅ başarılı (çıkış kodu 0; tüm testler geçti) |

Not: test işinin günlüğündeki "KESIK|…" ve yığın izi satırları, iş akışının
`grep` ile her zaman yüzeye çıkardığı bilgi çıktılarıdır (metin kesilme
taraması ve beklenen hata testleri); iş başarıyla bitti.
Sonraki commit (`06d6b28`) yalnız bu rapor dosyasını ekler (Dart kodu değişmez).

Sonraki tur (`8ce8b2d`: main'in yeni hâli #268 birleştirildi, yalnız
`docs/research`; PR #267'deki entegrasyon testi düzeltmesi alındı):

| İş | Çalışma | Sonuç |
|---|---|---|
| Dart format | [#309](https://github.com/sniperTurk/flutter-app/actions/runs/38429149796) | ✅ başarılı, değişiklik yok |
| `flutter analyze` | [#234](https://github.com/sniperTurk/flutter-app/actions/runs/38429154559) | ✅ başarılı |
| iOS CI `dart-checks` (format, analyze, testler) | [run 38429149488](https://github.com/sniperTurk/flutter-app/actions/runs/38429149488) | ✅ başarılı |
| iOS CI `wind-acceptance` | aynı çalışma | ✅ başarılı |
| iOS CI `verify` (macOS, Simulator) | aynı çalışma, deneme 1 ve 2 | ⛔ **ENGELLİ** — iki denemede de 15 dk macOS sırada bekleyip makine almadan iptal edildi; hiç çalışmadı |

**iOS CI `verify` geçti DENMEZ.** İlk denemede (`06d6b28`,
[run 38422927319](https://github.com/sniperTurk/flutter-app/actions/runs/38422927319))
Simulator duman testi `integration_test/app_launch_test.dart:129`'da
düştü: test PCP'de gizli olan `ammo-brand-select` kutusunu arıyordu
(`PCP_AMMO_BRAND` bayrağı). Bu hata bu PR'ın değil, main'de de var;
düzeltmesi PR #267'de (orada Simulator testi geçti,
[run 38425348799](https://github.com/sniperTurk/flutter-app/actions/runs/38425348799)).
Aynı değişiklik bu dala alındı (`7e13d5a`); #267 birleşince etkisiz kalır.
Sonraki `verify` denemeleri macOS makinesi bulunamadığı için çalışmadı.
Bir sonraki `verify` çalışmasının yeşil olması gerekiyor.

Çalışmayanlar (geçti denmez): iOS Simulator duman testi (son hâl), cihaz,
imza, TestFlight. Birleştirme yapılmadı; PR taslak olarak duruyor.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
