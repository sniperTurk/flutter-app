# Formüller core'a taşındı (refactor/formuller-core)

Sahip kararı: 2026-10-15 10:46 (İstanbul), "yap". PR #317 ve #318 birleşene
kadar beklendi (ikisi de 16:35'te birleşmiş görüldü). Dal `main`'in o anki
`cb9ffee23900bdc4ff86dd0d9c4abd61f66c4805` commit'inden açıldı.

## Ne yapıldı

Ekran kodunda (lib/features/**, lib/ui/**) kalan hesap formülleri lib/core/
altına, belgeli ve saf (yan etkisiz) fonksiyonlar olarak taşındı. Ekranlar
artık bu fonksiyonları çağırıyor. Hiçbir sayı değişmedi: her fonksiyon,
eski satırdaki işlemi aynı sırayla yapıyor.

## Taşınan formüller (nereden → nereye)

| Formül | Nereden | Nereye |
|---|---|---|
| Spin drift (Litz): `1,25 · (Sg + 1,2) · t^1,83` inç, sonra mrad | `ballistics_screen.dart` `_spinDriftMrad` | `Stability.spinDriftInches`, `Stability.spinDriftMrad` (stability.dart) |
| Mermi boyu kalibre cinsinden: `boy/25,4 / (kalibre/25,4)` | `ballistics_screen.dart` `_stability` | `Stability.lengthCalibers` |
| Rüzgâr sıçraması (Litz): `0,01·Sg − 0,0024·l + 0,032` MOA/mph, sonra mrad | `ballistics_screen.dart` `_aeroJumpMrad` | `Stability.aeroJumpMoaPerMph`, `Stability.aeroJumpMrad` |
| Yan rüzgâr bileşeni: `−hız · sin(yön)` | `ballistics_screen.dart` `_aeroJumpMrad` | `WindClock.crosswindFromRight` (wind_clock.dart) |
| Uzunluk → mrad: `atan(m / mesafe) · 1000` | Hedef (sıfır ofseti, spin, öne nişan, hedef yarıçapı), Kule Doğrulama | `Units.linearToMrad` (units.dart) |
| mrad → uzunluk: `tan(mrad / 1000) · mesafe` | Hedef (spin/sıçrama cm yazısı, rüzgâr kayması, vuruş noktası yanal) | `Units.mradToLinear` |
| Hareketli hedef öne nişan: `hız · uçuş süresi`, sonra mrad | `ballistics_screen.dart` `_extraShotNotes` | `MovingTarget.leadM`, `MovingTarget.leadMrad` (yeni küçük dosya moving_target.dart; uygun mevcut dosya yoktu) |
| Hedef yarıçapı: `atan((çap/2) / mesafe) · 1000` | `ballistics_screen.dart` `_hitProbability` | `Wez.targetRadiusMrad` (wez.dart) |
| Sıfır ofseti (cm/inç → mrad, sınırlarıyla) | `ballistics_screen.dart` `_zeroOffsetMrad` ve `truing_screen.dart` `_zeroUpMrad` (aynı kural iki kez yazılıydı) | `ScopeDialMath.zeroOffsetMrad` (scope_dial.dart) |
| Eğim kosinüsü (yatay mesafe): `eğik · cos(açı)` | `scope_workings.dart` (dürbün hesap dökümü) | `ScopeDialMath.horizontalRange` |
| Su terazisi alçak geçiren filtre: `1 − e^(−dt/τ)` ve adım | `level_screen.dart` `_EasedAnglesState._tick` | `LowPass.factor`, `LowPass.step` (yeni küçük dosya low_pass.dart) |
| Kesit yoğunluğu: `grain / (7000 · d²)` ve tersi | `profile_editor_ammo.dart` (BC makul mü uyarısı, ağırlık aralığı) | `EstimatedBc.sectionalDensity`, `EstimatedBc.grainForSectionalDensity` (estimated_bc.dart) |
| cm/inç → m | Hedef (3 yer) ve Doğrulama | `Units.cmOrInchToMeters` |
| inç → m (`· 0,0254`) | Hedef spin, Hesaplayıcılar (mesafe) | `Units.inchesToMeters` |
| m → inç yazısı (`· 39,3700787`) | `scope_results.dart`, `scope_workings.dart` (2 yer) | `Units.metersToInchesDisplay` |
| mm → inç, m → ft, fps ↔ m/s | `profile_editor.dart` (3 yer), `calculators_screen.dart` (5 yer) | mevcut `UnitSystem` fonksiyonları (aynı işlem: `/ 25,4`, `/ 0,3048`, `· 0,3048`) |

## Neden

Formüller tek yerde, ekrandan bağımsız ve test edilebilir olsun. Sıfır ofseti
kuralı iki ekranda ayrı ayrı yazılıydı; artık tek fonksiyon.

## Sayıların değişmediğinin kanıtı

1. **Bit bit aynılık testi** (`test/core/formuller_core_test.dart`): her yeni
   fonksiyon, ekranda duran eski ifadeyle bir değer ızgarasında `==` ile
   (yaklaşık değil, tam eşitlik) karşılaştırılıyor. Sıfır ofseti için her iki
   eski kopya (Hedef ve Doğrulama) aynen testte yazılı.
2. **Hedef altın sayıları** (`test/core/hedef_golden_numbers_test.dart`):
   üç örnek profil (.308 sağ yiv 400 m, 10° eğim, soldan rüzgâr; 6,5 sol yiv
   G7 800 m, −15°; .223 sağ yiv 300 m rüzgârsız) için Hedef ekranındaki
   kule gereksinimi (tam double), hedef çapı, eğim, spin drift / sıçrama
   yazısı, öne nişan yazısı, rüzgâr aralığı, isabet olasılığı sayıları kayıt
   altına alındı. Değerler **önce `main` kodunda** (commit 49dbf5e = cb9ffee +
   yalnız bu test) kaydedildi ve orada yeşil koştu
   ([koşu 38745310264](https://github.com/sniperTurk/flutter-app/actions/runs/38745310264)).
   Taşımadan sonra aynı test değişmeden yeşil.
3. Elle hesaplanan referans değerler: `tools/formuller_core_reference.py`
   (yalnız ders kitabı formülleri; başka balistik uygulama değeri yok).

## Uç durumlar

- Sıfır mesafe ≤ 0, boş kutu veya ±100'den büyük sıfır ofseti: eskisi gibi 0.
- Mesafe 0'a bölme: eski satırlarda nasıl davranıyorsa aynı (fonksiyon ek
  kontrol eklemiyor; ekranlar zaten mesafeyi sınırlıyor).
- Rüzgâr yok / karşıdan rüzgâr: sıçrama 0 (testte var).
- Sol yiv: spin ve sıçrama ters işaretli (testte var).
- İnç yazısında yuvarlanmış 39,3700787 katsayısı bilerek korundu; tam
  1/0,0254'e geçmek son hanede farklı inç yazısı verebilirdi.

## Yapılmayanlar

- Çözücü (solver) koduna, kayıt anahtarlarına, test anahtarlarına ve gizli
  bayrak yollarına dokunulmadı. Başka hiçbir şey silinmedi.
- Saf ekran geometrisi UI'da kaldı: su terazisi kabarcığının piksel
  uzaklığı/kırpılması, pusula ve retikül çizim açıları, retikülde vuruş
  noktasının merkeze uzaklığı (`sqrt(yukarı² + sağ²)`, yalnız ok mu nokta mı
  çizileceğine karar veriyor), yerleşim ölçüleri.
- Görüntü biçimlendirmesi olan `m · 100` (cm yazısı) ve `· 100` (yüzde)
  çarpımları yerinde bırakıldı.
- `math.` kullanmayan küçük ekran hesapları taşınmadı (kapsam dışı, ayrı görev
  olabilir): rüzgâr aralığında rüzgâr bölgelerinin hamle oranıyla
  ölçeklenmesi (`min(bölge · oran, 60)`), WEZ rüzgâr belirsizliği
  (`(en yüksek − rüzgâr) / 2 / mpsPerMil`), BC hatası ölçeği
  (`1 − σ/100`), klik sayısı (`açı / klik / kule ölçeği`).
- TestFlight başlatılmadı.

## Testler

- Yeni: `test/core/formuller_core_test.dart` (her taşınan fonksiyon için elle
  hesap + bit bit aynılık), `test/core/hedef_golden_numbers_test.dart`.
- Güncellenen: `tools/test_formula_reference.py`
  `test_litz_spin_drift_and_jump` artık formül metnini stability.dart'ta,
  ekranın çağrısını ballistics_screen.dart'ta arıyor (miller testiyle aynı
  düzen; kontrol azaltılmadı, çağrı bağlantısı ayrıca kontrol ediliyor).
- Yerel: `python3 tools/offline_dart_lint.py` geçti (378 dosya, 0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (842 test).
  Flutter SDK bu ortamda indirilemedi (storage.googleapis.com engelli); Dart
  testleri yalnız CI'da koştu.
- test/audit_*/ dahil hiçbir test zayıflatılmadı veya atlanmadı.

## CI bağlantıları

- Biçimlendirme (format-fix):
  [38746191085](https://github.com/sniperTurk/flutter-app/actions/runs/38746191085)
  → commit 3fc555e çekildi.
- Tüm testler (test-diag, `test`), 3fc555e:
  [38746650821](https://github.com/sniperTurk/flutter-app/actions/runs/38746650821)
  — başarılı.
- Analiz (analyze-diag), 3fc555e:
  [38746655787](https://github.com/sniperTurk/flutter-app/actions/runs/38746655787)
  — başarısız: biçimlendiricinin böldüğü bir `if` satırı
  `curly_braces_in_flow_control_structures` bilgisi verdi; satır
  düzeltildi. Son baş commit'teki analiz, test ve iOS CI koşularının
  bağlantıları PR açıklamasında.

## Birleştirme sonucu

PR açıklamasında (birleştirme, baş commit'te `verify`, `dart-checks` ve
`wind-acceptance` başarılı ve çakışma yokken yapılır).
