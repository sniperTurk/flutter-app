# Denetim düzeltmeleri F1, F2, F3, F5 (2026-10-14)

Kaynak: formül denetimi #292 (`docs/reports/formul_denetimi_2026_10_14.md`).
Dal: `fix/denetim-f1-f2-f3-f5` (main'den, #289/#290/#291 sonrası rebase).
Taslak PR; birleştirmeyi ana oturum yapar. TestFlight yok.

Özet: F1, F2, F3, F5 düzeltildi. F4 (SFP kalibrasyon büyütmesi) bu işte
yok, testi hâlâ `skip`. Gösterilen düzeltme klikleri değişmedi; değişen,
boş basınçta kullanılan basınç (F1), kule yolu sınırları/uyarıları (F2) ve
regülatörsüz PCP'nin sıfır hızı (F3).

## F1 — Basınç boşken irtifa kullanılıyor (Yüksek)

- **Ne değişti:**
  - `lib/features/ballistics/ballistics_screen.dart:1680` — Basınç kutusu
    boş ve İrtifa dolu ise basınç = `FieldCalc.stationPressureHpa(1013.25,
    irtifa)` (ISA istasyon basıncı). Yazılmış basınç her zaman öncelikli.
    İkisi de boşsa eskisi gibi 1013,25 hPa. Doğrulamaya `!pres.isFinite`
    eklendi (aşırı irtifada ISA formülü sayı vermezse hata mesajı çıkar).
  - `ballistics_screen.dart:4940` — Hedef (Atış) sayfasında, PCP regülatör
    notunun yanında kısa not: "Basınç irtifadan tahmin edildi." Yalnız son
    hesap basıncı irtifadan aldıysa görünür.
  - `lib/features/ballistics/environment_field_info.dart:47` — İrtifa ⓘ:
    "Basınç boşsa basınç irtifadan tahmin edilir (standart atmosfer). Basınç
    doluysa irtifa hesaba ayrıca girmez; ölçülen basınç irtifayı zaten
    içerir. Telefonda veya haritada yazar. Örnek: 1000 m."
  - #260 davranışı (İrtifa yazınca "Basınç alındı" durumu kalkar) aynı.
- **Neden:** Hava düğmesi basınç yazmıyor (#243); kullanıcı yalnız irtifa
  girince hesap deniz seviyesi havasıyla yapılıyor, mermi yüksek gidiyordu.
- **Önce / sonra** (denetim örneği, 15 °C, nem %0, 1500 m, Basınç boş;
  .308 168 gr G1 0,462, 2650 fps, sıfır 100 m):

  | | Önce | Sonra |
  |---|---|---|
  | Basınç | 1013,25 hPa | 845,56 hPa (ICAO) |
  | Hava yoğunluğu | 1,2250 kg/m³ | 1,0223 kg/m³ |
  | 300 m | 1,637 mrad | 1,556 mrad (2,4 cm fark) |
  | 500 m | 4,009 mrad | 3,729 mrad (14 cm, 3 klik) |
  | 800 m | 9,102 mrad | 8,102 mrad (80 cm, 10 klik) |

  PCP .22 G1 0,031, 280 m/s, sıfır 30 m, 1000 m: 50 m 0,997 → 0,921 mrad;
  100 m 5,737 → 5,378 mrad (~4 klik).
- **Kenar durumlar:**
  - Basınç yazılı (ör. 1013,25, irtifa 1500): yazılan kullanılır, not yok
    (test: yoğunluk 1,2250).
  - İkisi de boş: 1013,25 hPa, not yok.
  - İrtifa 0: ISA 1013,25 hPa verir, sonuç eskisiyle aynı; irtifa yazıldığı
    için not görünür (doğru: basınç irtifadan alındı).
  - Negatif irtifa (−400 m): 1062,2 hPa, yoğunluk 1,2842 kg/m³.
  - İmparatorluk birimi: irtifa ft → m çevrilip aynı formül.
  - Aşırı irtifa (>44 km): formül sayı vermez → "alanları kontrol edin".
  - Basınç uyarısı (`_pressureWarning`) yalnız yazılmış basınçta çalışır,
    değişmedi.

## F2 — Kule yolunda sıfırın kendi açısı (Orta)

- **Ne değişti:**
  - `lib/core/ballistic_engine.dart:61` `zeroAngleMrad(...)` ve
    `lib/core/aerodynamic_trajectory_solver.dart:189` `zeroAngleRad(...)`:
    çözücünün zaten bulduğu sıfır açısını (namlu − görüş hattı, sıfır
    mesafesinde, düz, sıfır günü hızı, ICAO sıfır havası) dışarı verir.
    Vakum yolu aynı kapalı formülü kullanır (yardımcıya taşındı; sonuç
    aynı). Hesap formülü değişmedi.
  - `ballistics_screen.dart:2579` `_zeroAngleClicks`: açıyı kulenin
    biriminde en yakın klike çevirir, profil hesabı başına bir kez.
  - `ballistics_screen.dart:2817`:
    `upClicks = max(0, min(halfUp + mount − zeroClicks, 2·halfUp))`,
    `downClicks = max(0, halfUp − mount + zeroClicks)`. İşaretler referans
    aracı `finding_turret_zero_angle` ile aynı (açı pozitif = namlu yukarı;
    sıfırlarken bu kadar YUKARI çevrilmiş).
  - `lib/features/ballistics/scope_dial_view.dart:69` yeni `zeroAngleClicks`;
    `:318` `mountBlocksZero` = `mount − zero > halfUp`; `:262` ayak önerisi
    en büyük ayağı `yarı yol + sıfır açısı` ile hesaplar. Kalan yolu yazan
    yerlerde "yaklaşık" yazıyor ("kulenin yukarı yolu yaklaşık … klik",
    "yukarı toplam yaklaşık … klik", "kuleyi yaklaşık … klik aşağı"), çünkü
    ray/namlu toleransı bilinmiyor.
  - Gösterilen gereken klik (`requiredUp/requiredRight`) **değişmedi**.
- **Neden:** 0 MOA ayakta sıfır kulenin ortasında değildir; sıfır açısı
  kadar yukarı çevrilmiştir. Eski hesap yukarı yolu fazla gösteriyor,
  "Kule yetmez" ve ayak önerisi bir kademe geç geliyordu.
- **Önce / sonra** (Gazi 6–36, 26 mrad yol):

  | Durum | Önce yukarı / aşağı | Sonra yukarı / aşağı |
  |---|---|---|
  | .308 800 m/s, 45 mm, sıfır 100 m, 0,1 mrad, 0 MOA (sıfır açısı 1,26 mrad = 13 klik) | 130 / 130 | **117** / 143 |
  | aynı, 20 MOA ayak (+58 klik) | 188 / 72 | 175 / 85 |
  | aynı, 30 MOA ayak (+87 klik) | 217 / 43 | 204 / 56 |
  | aynı, MOA kule ¼ MOA (yarı yol 178, sıfır 4,33 MOA = 17 klik), 0 MOA | 178 / 178 | 161 / 195 |
  | MOA kule, 20 MOA (+80) | 258 / 98 | 241 / 115 |
  | MOA kule, 30 MOA (+120) | 298 / 58 | 281 / 75 |
  | PCP saçma 280 m/s, 50 mm, sıfır 30 m (3,77 mrad), 15 mrad dürbün, 0,1 mrad | 75 / 75 | ~37 / ~113 |

  Not: MOA satırları formülden hesaplandı; uygulamada test edilen .308
  satırı (117) ve MRAD/MOA'nın aynı açıyı düştüğü ilişki.
- **Kenar durumlar:**
  - Ayak 0 / 20 / 30 MOA: yukarıdaki tablo; ayak klikleri kendisi aynı
    (0 / 58 / 87 klik, 0,1 mrad).
  - 60 MOA ayak, PCP 25 m sıfır (testteki profil, sıfır ~41 klik): eskiden
    "174 klik aşağı" diyordu, şimdi "yaklaşık 133 klik aşağı"; yarım yol 130
    olduğu için hâlâ "sıfırlanamaz". Sıfır açısı 44 klik olsaydı artık
    engellemezdi (testte var).
  - Kule yolu bilinmiyorsa (katalogda yok) hiçbir şey değişmez: sınır yok,
    uyarı yok.
  - Sıfır açısı hesaplanamazsa 0 kabul edilir (eski davranış).
  - Kule ölçek katsayısı (Pro) ayak kliki gibi sınıra uygulanmadı.

## F3 — Regülatörsüz PCP: sıfır ve atış aynı hızla (Düşük–orta)

- **Ne değişti:** `ballistics_screen.dart:1737` — regülatörsüz PCP'de
  "Basınca göre hız" tablosu Profil tüp basıncında (#284) bir hız veriyorsa
  sıfır da atış da o hızla çözülür (`vZero = null`). Regülatörlü PCP
  (regülatör devre dışı dahil) ve ateşli silah değişmedi. Gizli Pro "Kalan
  tüp basıncı" (`PRO_TUBE_PRESSURE` bayrağı) açıksa eski ayrım kalır.
- **Neden:** Tüp basıncı artık Profil'de sabit; profil kendi sıfır
  mesafesinde sıfırda olmalı.
- **Önce / sonra** (.22 G1 0,031, sıfır 30 m, profil 270 m/s, tablo 255 m/s):
  sıfır mesafesinde 0,26 mrad (0,8 cm) → 0; 50 m'de 1,3 cm ve 100 m'de
  2,6 cm fark artık yok (sıfır ve atış aynı hız). Sıfır 100 m'de (denetim
  testi): sıfır mesafesinde 1,0 mrad → < 0,05 mrad.
- **Kenar durumlar:** tablo hızı = profil hızı → eskisi gibi; tablo yoksa
  veya tüp basıncı boşsa profil hızı; regülatörlü ve tüp ≥ regülatör → profil
  hızı; regülatörlü ve tüp < regülatör → eskisi gibi (sıfır profil hızıyla,
  "Regülatör devre dışı" uyarısı).

## F5 — GA metin artığı (metin)

- `lib/features/tools/calculators_screen.dart:948`: "Diabolo saçmada GA,
  G1/G7'den daha uygundur" yerine "Saçma ve slug BC'leri G1'e göre
  yayımlanır." Hesap değişmedi.

## Bilerek yapılmayan

- **F4** (SFP kalibrasyon büyütmesi): bu görevde yok; testi `skip`.
- Pro "Kalan tüp basıncı" gizli kaldı; açılırsa F3'ün eski ayrımı geçerli.
- Kule ölçek katsayısı sıfır açısına uygulanmadı (ayak kliki gibi).
- Yeni form alanı yok.

## Testler

- `test/audit_2026_10_14/findings_audit_test.dart`: F1, F2, F3, F5 `skip`
  kaldırıldı, geçiyor; F4 `skip`.
- Yeni `test/denetim_f1_f2_f3_f5_test.dart`: iki boş, İrtifa 0, −400 m,
  yazılı basınç öncelikli, Hedef notu var/yok; MRAD ve MOA kulede aynı açı
  (.308: 13 klik, yukarı 117); vakum ve G1 sıfır açısı referansla
  (1,2161 / 1,2601 mrad); ayak sıfırı 41 klikte engeller, 44'te engellemez;
  ayak klikleri 0/20/30 MOA.
- Eski davranışı kodlayan ve güncellenen testler:
  - `test/scope_mount_cant_test.dart` "the shot tab uses the profile mount":
    sıfırlanamaz notunda "174 klik" yerine "yaklaşık (174 − sıfır) klik";
    sıfır açısı 35–43 klik; "yaklaşık 260 klik".
  - `tools/test_v372_interactive_scope_dial.py`: kule formülü metni
    (`halfUp+mountClicks-zeroClicks`, `halfUp-mountClicks+zeroClicks`).
- Basınç varsayılanını kodlayan başka test yoktu (İrtifa yazıp basıncı boş
  bırakan yoğunluk testi bulunmadı).
- Yerel: `python3 tools/offline_dart_lint.py` PASS (331 dosya, 0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` 740 test OK.
  Yerel Flutter SDK kurulamadı (proxy 403, Dart SDK indirilemedi) —
  Flutter testleri yalnız CI'da koştu.

## CI

Kod commit'i `85c87bf` (rebase sonrası; sonraki commit yalnız bu raporu
değiştirir):

| İş | Sonuç | Bağlantı |
|---|---|---|
| dart format (format-fix) | ✅ değişiklik yok | [#369](https://github.com/sniperTurk/flutter-app/actions/runs/38532131447) |
| `flutter test test` (tümü) | ✅ geçti | [#439](https://github.com/sniperTurk/flutter-app/actions/runs/38532134841) |
| `flutter analyze --fatal-infos --fatal-warnings` | ✅ geçti | [#296](https://github.com/sniperTurk/flutter-app/actions/runs/38532138583) |

Rebase öncesi (`ffcdebe`) de aynı üçlü yeşildi: format
[#366](https://github.com/sniperTurk/flutter-app/actions/runs/38530748572)
(biçim commit'i üretti), test
[#437](https://github.com/sniperTurk/flutter-app/actions/runs/38531131180),
analyze [#294](https://github.com/sniperTurk/flutter-app/actions/runs/38531134067).

iOS CI / verify, Simulator, TestFlight: bu işte **koşturulmadı**; geçti
denmez.

---
_Generated by [Claude Code](https://claude.ai/code)_
