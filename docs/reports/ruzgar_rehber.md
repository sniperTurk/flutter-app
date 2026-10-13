# Rüzgâr rehberi (Hava Durumu) — rapor

Dal: `fix/ruzgar-rehber` · Sahibin kararı: 2026-10-13 19:43 · Taslak PR, birleştirme yok, TestFlight yok.

## Neden

"Rüzgâr gözlemi" seçimi (Beaufort sınıfı) seçilince Rüzgâr hızı kutusuna sınıfın orta değerini yazıyordu. Konumdan alınmış ya da ölçülmüş bir rüzgâr (ör. 2 m/s) sessizce siliniyor, yerine sınıf ortası geliyordu (Orta → 4,4). Bu yanlış veri riski yüksek olduğu için seçim gizlendi; yerine hiçbir kutuya yazmayan bir okuma rehberi kondu.

## Ne değişti

- `lib/features/ballistics/ballistics_screen.dart`
  - "Rüzgâr gözlemi" seçimi (`MenzilSelect`, Key öneki `wind-observation-`) artık `_showWindObservation = bool.fromEnvironment('WIND_OBSERVATION')` bayrağının arkasında. Varsayılan kapalı: görünmez, Rüzgâr hızına hiçbir şey yazmaz. Kod silinmedi ("gizle, silme"); `--dart-define=WIND_OBSERVATION=true` ile eski hâli geri gelir.
  - `_pickWindObservation` ve elle yazınca `_windObservation`'ı temizleyen kısım olduğu gibi kaldı (seçim görünmediği için zararsız).
  - Rüzgâr hızı, Rüzgâr yönü ve saat kadranı değişmedi.
  - Hava Durumu sayfasında (`BallisticsView.environment`) Rüzgâr kartının altına, "Pro Ayarlara Geç" düğmesinin üstüne rehber eklendi. "Pro Ayarlara Geç" yerine "Hesapla" görünen durumda da aynı yerde durur. (İlk sürümde sayfada açık bir bloktu; takipte bağlantı + popup oldu, aşağıdaki "Takip: popup" bölümüne bakın.)
- `lib/features/ballistics/wind_guide.dart` (yeni): `WindGuide` (başlık, satır üretimi, sayı biçimi, popup), `WindGuideLines` (6 madde) ve `WindGuideLink` (sayfadaki bağlantı).
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
  - Rüzgâr gözlemi varsayılan olarak görünmüyor; bağlantı Rüzgâr kartının altında, "Pro Ayarlara Geç"in üstünde (dikdörtgen konumlarıyla sıra kontrolü); bağlantı popup'ı açıyor (başlık + 6 satır), Kapat kapatıyor;
  - mph popup'ı mph gösteriyor, m/s göstermiyor;
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

## Takip: popup

Sahibin kararı: 2026-10-13 19:49. Aynı dalda (`fix/ruzgar-rehber`, taslak PR #272) devam edildi; yeni dal açılmadı.

**Ne değişti**

- Rehber artık sayfada açık bir blok değil. Rüzgâr kartı ile "Pro Ayarlara Geç" düğmesi arasında yalnızca bağlantı görünümlü bir düğme var: **"Rüzgâr tahmini nasıl yapılır?"** (`WindGuideLink`, Key `wind-guide-link`; dokunma alanı en az 44 pt; "Aradığın dürbün listede yok mu?" bağlantısıyla aynı `TextButton` biçimi).
- Dokununca bir popup açılır (`WindGuide.show`). Başlık **"Rüzgârı gözle tahmin et"**, altında aynı 6 madde (Beaufort'tan, m/s ya da mph), sola hizalı, rakamlar sabit genişlik. Tek eylem: **Kapat** (Key `wind-guide-close`).
- Popup, alan ⓘ açıklamalarıyla aynı mekanizmayı kullanır (`MenzilInfoButton`'daki gibi `showDialog` + `AlertDialog`, kaydırılabilir içerik). `fix/pro-aciklama-popup` dalı main'e henüz birleşmediği için main'de ortak bir alt sayfa (bottom sheet) yardımcısı yok; o yüzden ⓘ diyaloğu örnek alındı. O PR birleşirse bu popup tek satırla ortak yardımcıya taşınabilir.
- `WindGuideBlock` kaldırıldı (yerini `WindGuideLines` + popup aldı). Rüzgâr gözlemi seçimi `WIND_OBSERVATION` bayrağının arkasında gizli kalmaya devam ediyor. Araçlar'a sayfa eklenmedi.
- Rehber hâlâ yalnızca gösterir: bağlantı, popup, madde ya da Kapat hiçbir kutuya yazmaz.
- main bu dala yeniden birleştirilmek istendi; dal zaten güncel main'i (`e08c1e3`: üst çubuk, liste genişliği, dürbün formu) içeriyordu, çakışma yoktu.

**Uç durumlar**

- mph: popup'taki aralıklar mph'ye çevrilmiş, bir ondalık ve Türkçe virgülle gösterilir.
- Dar telefon (320 pt), yazı ölçeği 1,3, koyu tema: sayfada ve açık popup'ta taşma yok; maddeler ekran içinde sarılır.
- Kayıtlı profiller: değişiklik yok (gözlem seçimi hiç kaydedilmiyordu).

**Testler** (`test/wind_guide_test.dart`, güncellendi)

- Sayfada satır ya da başlık yok, yalnızca bağlantı var; bağlantı Rüzgâr kartının altında ve "Pro Ayarlara Geç"in üstünde (dikdörtgenlerle).
- Bağlantıya dokununca popup açılıyor; başlık ve 6 satır sırayla, sola hizalı; Kapat popup'ı kapatıyor.
- mph popup'ı mph gösteriyor.
- Elle yazılan rüzgâr (2) ve konumdan alınan rüzgâr (2,0), popup açılıp bir maddeye dokunulup kapatıldıktan sonra da aynı kalıyor.
- 320 pt, yazı ölçeği 1,3, koyu tema: popup açıkken ve kapandıktan sonra taşma yok.

**Doğrulama** (commit `241874d`)

- Yerel: `python3 tools/offline_dart_lint.py` → PASS (315 Dart dosyası, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 724 test, OK.
- CI biçimlendirme (format-fix): başarılı, değişiklik yok (317 dosya, 0 değişti) — https://github.com/sniperTurk/flutter-app/actions/runs/38442989677
- CI `flutter analyze --fatal-infos --fatal-warnings`: başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38443337447
- CI `flutter test test`: başarılı (tüm test klasörü) — https://github.com/sniperTurk/flutter-app/actions/runs/38443332503
- Bu rapor `241874d`'ten sonra ayrı bir commit olarak eklendi (yalnızca bu Markdown dosyası).
- iOS CI / Simulator / cihaz / TestFlight bu takipte çalıştırılmadı ve geçti sayılmamalıdır. PR taslak; birleştirme yok.

---
_Generated by [Claude Code](https://claude.ai/code)_
