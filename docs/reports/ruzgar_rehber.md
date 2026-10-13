# Rüzgâr rehberi (Hava Durumu) — rapor

Dal: `fix/ruzgar-rehber` · Sahibin kararı: 2026-10-13 19:43 · Taslak PR, birleştirme yok, TestFlight yok.

## Neden

"Rüzgâr gözlemi" seçimi (Beaufort sınıfı) seçilince Rüzgâr hızı kutusuna sınıfın orta değerini yazıyordu. Konumdan alınmış ya da ölçülmüş bir rüzgâr (ör. 2 m/s) sessizce siliniyor, yerine sınıf ortası geliyordu (Orta → 4,4). Bu yanlış veri riski yüksek olduğu için seçim gizlendi; yerine hiçbir kutuya yazmayan bir okuma rehberi kondu.

## Ne değişti

- `lib/features/ballistics/ballistics_screen.dart`
  - "Rüzgâr gözlemi" seçimi (`MenzilSelect`, Key öneki `wind-observation-`) artık `_showWindObservation = bool.fromEnvironment('WIND_OBSERVATION')` bayrağının arkasında. Varsayılan kapalı: görünmez, Rüzgâr hızına hiçbir şey yazmaz. Kod silinmedi ("gizle, silme"); `--dart-define=WIND_OBSERVATION=true` ile eski hâli geri gelir.
  - `_pickWindObservation` ve elle yazınca `_windObservation`'ı temizleyen kısım olduğu gibi kaldı (seçim görünmediği için zararsız).
  - Rüzgâr hızı, Rüzgâr yönü ve saat kadranı değişmedi.
  - Hava Durumu sayfasında (`BallisticsView.environment`) Rüzgâr kartının altına, "Pro Ayarlara Geç" düğmesinin üstüne `WindGuideBlock` eklendi (Key `wind-guide`). "Pro Ayarlara Geç" yerine "Hesapla" görünen durumda da aynı yerde durur.
- `lib/features/ballistics/wind_guide.dart` (yeni): `WindGuide` (başlık, satır üretimi, sayı biçimi) ve `WindGuideBlock` (görünüm).
- `lib/core/beaufort.dart`: `BeaufortClass`'a isteğe bağlı kısa tarif alanı `guide` ve `Beaufort.guideClasses` (kuvvet 0–5) eklendi. Uzun `land` metinleri değişmedi (gizli seçim onları kullanmaya devam eder).

## Rehber nasıl kuruluyor ve nereye yerleşiyor

Başlık: "Rüzgârı gözle tahmin et". Altında 6 madde:

- Duman dümdüz yükselir: 0–0,2 m/s
- Duman hafifçe yana kayar: 0,3–1,5 m/s
- Rüzgâr yüzde hissedilir, yapraklar hışırdar: 1,6–3,3 m/s
- Yapraklar ve ince dallar durmadan kıpırdar: 3,4–5,4 m/s
- Toz ve kâğıt kalkar, küçük dallar sallanır: 5,5–7,9 m/s
- Küçük ağaçlar sallanır: 8,0–10,7 m/s

Sayılar elle yazılmadı: her satır `Beaufort.classes` içindeki `minMps`/`maxMps` değerlerinden üretilir (tek kaynak). Kısa Türkçe tarifler sahibin onayladığı metinle birebir aynıdır ve `guide` alanında durur. Sayılar bir ondalıkla, Türkçe virgülle yazılır; tam sıfır "0" olarak kalır.

Görünüm: Inter, mevcut `MenzilType.body` stili (başlık kalın, maddeler ikincil mürekkep rengi, rakamlar sabit genişlik). Maddeler iki yana yaslanmaz. Satırlar sarılır; dar telefonda ve büyük yazıda taşmaz. Renkler `MenzilColors` üzerinden geldiği için koyu temada da doğru görünür.

Rehber yalnızca gösterir: dokunulunca hiçbir kutuya yazmaz. Kullanıcı isterse hızı kendisi yazar.

## Uç durumlar

- **İngiliz birimleri (mph):** Birim sistemi mph olduğunda aynı aralıklar mph'ye çevrilip bir ondalıkla, Türkçe virgülle gösterilir: 0–0,4 · 0,7–3,4 · 3,6–7,4 · 7,6–12,1 · 12,3–17,7 · 17,9–23,9 mph. (Not: uygulama şu an yalnızca metrik çalışıyor, `SettingsStore.loadMetric()` hep `true`; mph görünümü bileşen düzeyinde test edildi.)
- **Daha önce gözlem seçilmiş kayıtlı profiller:** Gözlem seçimi hiç kaydedilmiyordu; kaydedilen yalnızca o anda yazılmış Rüzgâr hızı sayısıydı. Bu sayı profilde olduğu gibi kalır ve normal bir rüzgâr değeri gibi geri yüklenir. Göç (migration) gerekmez.
- **Dar telefon:** 320 pt genişlikte satırlar sarılır, ekrandan taşmaz.
- **Büyük yazı:** Yazı ölçeği 1,3'te taşma (overflow) hatası yok.

## Bilerek yapılmayanlar

- Gözlem seçimi ve ⓘ metni (`EnvironmentFieldInfo.windObservation`) silinmedi, yalnızca gizlendi.
- Beaufort 6–7 rehbere eklenmedi (sahibin listesi 0–5).
- Rehber Rüzgâr hızı / En yüksek rüzgâr kutularına hiçbir şey yazmaz; "dokununca doldur" eklenmedi.
- 10 m yükseklik düzeltmesi yapılmadı (önceki kararla aynı).
- Profil, üst çubuk ve diğer bölümlere dokunulmadı.

## Testler

- `test/wind_guide_test.dart` (yeni):
  - satırlar `Beaufort.classes`'tan (kuvvet 0–5) ve sahibin metniyle birebir (m/s);
  - mph satırları (Türkçe virgül, bir ondalık);
  - Rüzgâr gözlemi varsayılan olarak görünmüyor; başlık ve 6 satır Rüzgâr kartının altında, "Pro Ayarlara Geç"in üstünde (dikdörtgen konumlarıyla sıra kontrolü);
  - `WindGuideBlock(metric: false)` mph gösteriyor, m/s göstermiyor;
  - elle yazılan rüzgâr (2) değişmiyor, rehbere dokunmak bir şey yazmıyor;
  - konumdan alınan rüzgâr (2,0) alındığı gibi kalıyor;
  - 320 pt genişlik, yazı ölçeği 1,3, koyu tema: taşma yok.
- `test/wind_observation_test.dart` güncellendi: seçimi kullanan testler kaldırıldı; yerine "varsayılan olarak gizli" testi geldi. Hedef'teki yakın/orta/uzak rüzgâr payı testi artık rüzgârı elle (4,4) yazıyor.
- `integration_test/` içinde gözlem seçimini kullanan test yok (arandı).

## Doğrulama

Yerel (bu ortamda Flutter SDK yok):

- `python3 tools/offline_dart_lint.py` → PASS (311 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 724 test, OK

CI (commit `08ac02f`, dal `fix/ruzgar-rehber`):

- Biçimlendirme (format-fix): başarılı, biçim commit'i `08ac02f` dala itildi ve alındı — https://github.com/sniperTurk/flutter-app/actions/runs/38433452694
- `flutter analyze --fatal-infos --fatal-warnings`: başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38433637222
- `flutter test test` (tüm test klasörü): başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38433633189

Bu rapor `08ac02f`'ten sonra ayrı bir commit olarak eklendi (yalnızca bu Markdown dosyası). iOS CI / Simulator / cihaz / TestFlight çalıştırılmadı ve geçti sayılmamalıdır.

---
_Generated by [Claude Code](https://claude.ai/code)_
