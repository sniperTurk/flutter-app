# Kule klik sesi

Sahip istekleri (2026-10-15, İstanbul): 23:30 "Dürbün kulelerini çevirme klik
sesi ekleyelim." ve 23:31 "Kuleyi kuleden çevirirken de klik sesi gelsin."

Dal: `feat/kule-klik-sesi` (#349 birleştikten sonra güncel main'den açıldı).
Taslak PR; birleştirmeyi sahibin ana oturumu yapar. TestFlight yok.

## Ne

Hedef sayfasındaki üst (yükseklik) ve yan (rüzgâr) kulede, kullanıcının
çevirdiği her klik adımı için bir kısa, metalik "tık" sesi çalar:

- Ok dokunuşu (‹ › ve ˄ ˅): 1 dokunuş = 1 klik = 1 ses.
- Tamburu sürükleme: değer her klik adımını geçtiğinde 1 ses (7 klik
  sürükleme = 7 ses, adımlarla aynı anda).
- Kule sınırına gelince kule durur, ses de durur.
- Başka hiçbir şey değişmedi: titreşim yok, ayar düğmesi yok, yeni ekran
  öğesi yok. Kule değerleri eskisiyle aynı hesaplanır.

## Nasıl

- Ses dosyası bizim: `tools/sounds/make_turret_click.py` (numpy + wave,
  internet yok, sabit tohum 20261015) `assets/sounds/turret_click.wav`
  dosyasını üretir. Mono, 44,1 kHz, 16 bit, 32 ms. İçeriği: hızlı sönen kısa
  bir gürültü patlaması (tırnağın oturması), kısa yüksek bir metal
  çınlaması (3150 Hz ve 5870 Hz) ve hafif bir gövde sesi (1180 Hz). Tepe
  seviyesi -6 dBFS; son 3 ms sessizliğe iner. İnternetten veya başka
  uygulamadan ses alınmadı.
- Ses kodu küçük bir servis: `lib/services/turret_click_sound.dart`.
  `TurretClickSound.instance` varsayılan olarak sessizdir; `main()` gerçek
  sesi (`AudioTurretClickSound`) kurar. Testler sahte servis takar, testte
  gerçek ses çalmaz.
- Gerçek ses: önceden yüklenmiş 4 oynatıcılık küçük havuz, sırayla
  kullanılır; her tık bir öncekinin bitmesini beklemez. Oynatıcılar ilk kule
  tamburu ekrana geldiğinde yüklenir (uygulama açılışında değil). Ses
  seviyesi 0,5 (orta).
- iOS ses oturumu: AVAudioSession kategorisi **ambient**. Sessiz/zil
  düğmesine uyar (sessizdeyken çalmaz) ve kullanıcının müziğini durdurmaz,
  onunla karışır.
- Kule tarafı (`scope_turrets.dart`, `_TurretDrumState._set`): ok, sürükleme
  ve VoiceOver ayarı zaten tek bir yerden (`_set`) geçiyordu. Ses tam orada,
  gerçekten çevrilen klik sayısı kadar istenir. Program hareketleri
  ("Kuleleri kur", "Kuleleri sıfırla", Pro → Hedef otomatik kurma, profil
  değişimi) kuleye yalnızca yeni değer olarak gelir, `_set`'ten geçmez;
  bu yüzden ses çıkarmaz.

## Neden

- Ses tek yerde (`_set`) olduğu için ok, tambur ve sınır davranışı tek
  kurala bağlı; ileride yeni bir çevirme yolu eklenirse de otomatik tıklar.
- Ambient kategori: sahip "müziği durdurmasın, sessiz düğmesine uysun"
  dedi; iOS'ta bunun karşılığı tam olarak budur. Yeni izin veya Info.plist
  anahtarı gerekmez (ses çalmak izin istemez; mikrofon kullanılmıyor).

## Seçimler ve uç durumlar

- **25 ms kuralı:** Ardışık iki tık arasında 25 ms'den az varsa ikincisi
  çalınmaz (sıraya alınmaz). Böylece çok hızlı sürüklemede ses tamburun
  gerisinde kalmaz; tamburun değeri yine tam sayıda klik değişir. Sayılan
  her adım servise bildirilir; seyreltme yalnız gerçek ses servisinde.
- **Bir karede birden çok adım:** Çok hızlı sürüklemede tek bir hareket
  birkaç klik geçebilir; servise o kadar tık istenir, 25 ms kuralı fazlasını
  düşürür.
- **Yeniden çizimden önce gelen ikinci sürükleme olayı:** Tambur, en son
  gönderdiği değeri hatırlar (`_sent`); böylece aynı adım için iki kez ses
  çıkmaz. Kule değeri eskisi gibi hesaplanır.
- **Kule sınırı:** Sınırda ok dokunuşu ve sürükleme değeri değiştirmez, ses
  de çıkmaz.
- **VoiceOver:** Kaydırıcının artır/azalt eylemi kullanıcının kendi adımı
  sayıldı; ok dokunuşu gibi bir kez tıklar.
- **Ses yüklenirken:** İlk yükleme bitmeden gelen tık düşürülür (bekletilmez).
- **Ses hatası:** Oynatıcı hata verirse sessizce yutulur; kule çalışmaya
  devam eder.
- **Kaydedilmiş veri:** Hiçbir kayıt biçimi değişmedi.

## Bilerek yapılmayan

- Titreşim (haptik), ses açma/kapama ayarı, ses seviyesi ayarı, yeni ekran
  öğesi: istenmedi, eklenmedi.
- Program hareketlerinde ses yok ("Kuleleri kur", "Kuleleri sıfırla",
  otomatik kurma, profil değişimi).
- Yeni izin / Info.plist anahtarı: gerekmedi, eklenmedi.

## Kullanılan paket

- `audioplayers` **6.4.0** (tam sürüm sabitlendi; iki haftadan eski).
  `pubspec.lock` repo'nun `lock-update.yml` iş akışıyla Flutter 3.47.2 ile
  üretildi; yalnız ekleme var (audioplayers ve platform paketleri:
  audioplayers_darwin 6.5.0, _platform_interface 7.2.0, _android 5.3.0,
  _web 5.3.0, _linux 4.3.0, _windows 4.4.1), mevcut sabitler değişmedi.
  `lockfile-provenance.txt` aynı iş akışıyla güncellendi.

## Testler

- `test/kule_klik_sesi_test.dart` (sahte ses servisi):
  - 4 okun her birine 1 dokunuş → her biri 1 ses, kule ±1 klik.
  - 5 hızlı dokunuş (üst ve yan) → 5 ses, kule 5 klik.
  - Üst ve yan tamburu tam N klik sürükleme (N = 1, 7) → N ses, her adımda
    anında; değer eskisi gibi 9 pt'de 1 klik.
  - 1 klikten az sürükleme → 0 ses, değer aynı.
  - Sınırın ötesine sürükleme → sınıra kadar ses, sonra yok; sınırda ok
    dokunuşu da sessiz.
  - "Kuleleri kur" / "Kuleleri sıfırla" / Pro → Hedef otomatik kurma → 0 ses.
- `tools/test_turret_click_sound.py`: betik bayt bayt aynı WAV'ı yeniden
  üretiyor; mono, 16 bit, 44,1 kHz, 25–40 ms (< 60 ms); tepe orta seviyede;
  pubspec'te varlık olarak kayıtlı; betikte ağ kodu yok.
- Yerel: `python3 tools/offline_dart_lint.py` geçti;
  `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (lockfile
  güncellemesinden sonra).
- Hiçbir mevcut test zayıflatılmadı, atlanmadı.

## CI

CI bağlantıları ve sonuçları PR açıklamasında güncel tutulur (bu dosyayı
güncellemek macOS işini yeniden başlatırdı).

**Gerçek cihazda ses CI'da doğrulanamaz:** Simülatör derlemesi uygulamanın
yeni eklentiyle açıldığını gösterir; sessiz düğmesi, müzikle karışma ve
gecikme yalnız gerçek iPhone'da denenebilir.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
