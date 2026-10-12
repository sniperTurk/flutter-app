# Çevrimdışı denetim raporu — 2026-10-11

Soru: Sahada internet yokken SNIPER TÜRK nasıl davranıyor?

Kısa cevap: Balistik hesap, Profil, Hava Durumu (elle giriş), Pro ve Hedef
(tek atış + DOPE tablosu) tamamen cihaz üzerinde çalışıyor; hiçbiri ağa
çıkmıyor. Ağa çıkan üç yer var (hava servisi, yer arama, harita karoları).
Üç gerçek sorun bulundu ve bu dalda düzeltildi; iki konu sahibin kararına
bırakıldı.

## 1. Ağa çıkan kodun envanteri

`lib/` içinde `package:http`, `HttpClient`, `TileLayer`, `GoogleMap`,
`NetworkImage`, `url_launcher` arandı. Ağa çıkan yerlerin tamamı:

| # | Yer | Dosya | Ne zaman |
|---|-----|-------|----------|
| A | MET Norway hava servisi | `lib/tools/adapters/met_no_weather_provider.dart` | Yalnızca düğmeyle: Araçlar › Hava & Rüzgâr “Hava verisini getir”, Hava Durumu “Konumdan canlı hava verisi al” |
| B | Nominatim yer arama | `lib/tools/adapters/nominatim_place_search.dart` | Yalnızca harita ekranında “Ara” ile |
| C | Esri uydu karoları (flutter_map) | `lib/features/tools/map_distance_screen.dart` | Konum için mesafe ekranı açıkken |
| D | Google Maps (hybrid) | aynı dosya, `GOOGLE_MAPS_ENABLED` derlemesinde | Konum için mesafe ekranı açıkken |

Ağa çıkmayanlar (internetsiz çalışır):

- **Konum / rakım**: `geolocator` GPS kullanır; ağ servisi yok. Rakım GPS
  yüksekliğidir (dikey doğruluk ≤ 50 m ise), ayrı bir rakım API'si yok.
  `timeLimit: 15 sn`, tüm hatalar `LocationFailure('Konum alınamadı.')`.
- Pusula, eğim, kamera, galeri, DOPE PDF (`pdf`/`printing`), profil ve
  katalog depoları (`shared_preferences`, paketle gelen katalog).
- Uygulama açılışında hiçbir veri çekilmez (`autoWeather` varsayılan kapalı).

## 2. Her ağ çağrısı için kontrol listesi

| Kontrol | A Hava | B Yer arama | C Esri karoları | D Google Maps |
|---|---|---|---|---|
| Zaman aşımı | 12 sn ✔ | 12 sn ✔ | flutter_map/HTTP varsayılanı | SDK yönetir |
| Hata yakalanıyor mu | ✔ — **TLS hatası sızıyordu, düzeltildi** | ✔ — **TLS hatası aramayı kilitliyordu, düzeltildi** | Sessizce boş — **uyarı eklendi** | SDK boş harita gösterir (test edilemedi) |
| Türkçe mesaj | “İnternet bağlantısı yok. Bağlandığınızda tekrar deneyin.” | “İnternet bağlantısı yok.” | **Yeni:** “Harita yüklenemedi; internet yok olabilir. Mesafeyi elle de girebilirsiniz.” | yok |
| Donma / çökme | Yok (düğme “Tekrar dene”) | **Vardı** (Wi-Fi giriş sayfasında) — düzeltildi | Yok | Bilinmiyor (cihazda denenmedi) |
| Son başarılı veri | Yalnızca ekran açıkken bellekte; yaşıyla “Bayat veri / Güncel değil” gösterilir. Ekrandan çıkınca/uygulama kapanınca kaybolur | Oturum boyunca bellekte (aynı sorgu) | Görüntü önbelleği (bellek) | SDK önbelleği |
| Elle giriş | ✔ Hava Durumu alanları her zaman yazılabilir; hata durumunda “değerleri elle girin” | Haritayı kaydırıp dokunmak yeterli | ✔ GPS + dokunarak işaretleme çalışır; mesafe Hedef'teki mesafe kutusuna da yazılabilir | aynı |

Not (A): Derlemede `METNO_CONTACT` verilmezse hava servisi hiç çağrılmaz
(“yapılandırılmamış” mesajı); ios-ci derlemesi bunu sırdan verir.

## 3. Bulunan sorunlar ve düzeltmeler (ayrı commit'ler)

### S1 — TLS/G/Ç hataları ham olarak sızıyordu (gerçek hata)
`package:http`'in `IOClient`'ı yalnızca `SocketException` ve `HttpException`'ı
`ClientException`'a sarar (`io_client.dart`). Wi-Fi giriş sayfası (otel,
atış alanı Wi-Fi'ı) veya bozuk sertifika `HandshakeException`/`TlsException`
üretir ve adaptörlerden ham çıkıyordu:

- Harita yer aramasında `_runSearch` yalnızca `PlaceSearchFailure`
  yakaladığından arama göstergesi sonsuza dek döndü, **Ara düğmesi kilitli
  kaldı** (yakalanmayan async hata).
- Hava & Rüzgâr “İnternet bağlantısı yok” yerine genel “Hava verisi
  alınamadı” gösterdi.

Düzeltme: her iki adaptör artık her `IOException`'ı “çevrimdışı” hatası
sayar. Commit: *hava ve yer arama TLS/G/Ç hatalarını 'İnternet bağlantısı yok' yapar*.

### S2 — Harita araması beklenmeyen hatada kilitleniyordu (savunma)
Bağlantı noktası sözleşmesi dışı bir hata da aramayı kilitlerdi. `_runSearch`
artık her hatada aramayı bitirir: “Yer aranamadı. Bağlantıyı kontrol edip
tekrar deneyin.” Commit: *harita yer araması beklenmeyen hatada dönmeye devam etmez*.

### S3 — İnternetsiz harita sessizce boş kalıyordu (görünür değişiklik)
Karolar inmeyince kullanıcı boş/gri bir harita görüyor, nedenini
bilmiyordu. Artık ilk karo hatasında alt panelde tek satırlık sarı uyarı
çıkar (`Key('map-offline')`). Kutu altı yardım yazısı değil, ekran durum
uyarısıdır (mevcut `MenzilNotice` bileşeni). Google Maps derlemesinde bu
uyarı yoktur (SDK karo hatası bildirmez). Commit: *harita görüntüsü inmezse kısa uyarı gösterilir*.

## 4. Sahibin kararına bırakılanlar (düzeltilmedi)

1. **Son hava verisi kalıcı değil.** Hava & Rüzgâr ekranındaki son veri
   yalnızca ekran açıkken tutulur; Hava Durumu sekmesindeki sıcaklık, nem,
   basınç, irtifa alanları da (`ShotSettingsStore` bunları saklamaz)
   uygulama yeniden açılınca gelmez. İnternetsiz sahada kullanıcı değerleri
   elle girmek zorunda. Öneri: son başarılı gözlemi zamanıyla birlikte
   `shared_preferences`'a yazıp “Bayat veri” etiketiyle göstermek.
   Gizlilik notu: konum saklanmamalı (bugünkü kural).
2. **Google Maps çevrimdışı davranışı** cihazda denenmedi; bulut ortamında
   iOS Simulator yok. TestFlight derlemesinde uçak modunda kontrol önerilir.

## 5. Kanıt: testler

- `test/offline_adapters_test.dart` — gerçek adaptörler, hata veren sahte
  HTTP istemcisi: `SocketException`, `HandshakeException`, `TlsException`,
  diğer `IOException` → hepsi “çevrimdışı”; asılı bağlantı → zaman aşımı.
- `test/offline_app_test.dart` — `HttpOverrides` ile tüm `HttpClient`
  oluşturma `SocketException` atar ve sayılır; hava/yer arama gerçek
  adaptörlerle, hata veren istemciyle:
  - Profil → Hava Durumu (canlı hava başarısız, mesaj, elle sıcaklık,
    hava yoğunluğu hesaplanır) → Pro Ayarlar (Coriolis hesaplanır) → Hedef
    (sürüklenme çözücüsü, klikler) → Tablo (DOPE). Ağ denemesi sayısı **0**.
  - Hava & Rüzgâr: internet yok / Wi-Fi giriş sayfası → Türkçe mesaj ve
    “Tekrar dene”.
  - Harita: yer arama çevrimdışı ve TLS hatasında kilitlenmez; karo
    hatasında uyarı çıkar, GPS + dokunma ile mesafe yine ölçülür.

Kırmızı→yeşil: testler önce düzeltmesiz dalda koşuldu (CI test-diag):
adaptör TLS testleri, Wi-Fi giriş sayfası testleri, beklenmeyen arama
hatası ve harita uyarısı testleri beklenen nedenle düştü; ana çevrimdışı
akış testi baştan geçti. Düzeltmelerden sonra hepsi geçti.

Yerelde Flutter SDK kurulamadı (bulut ortamı storage.googleapis.com'a
erişemiyor); doğrulama GitHub Actions tek seferlik iş akışlarıyla yapıldı.
