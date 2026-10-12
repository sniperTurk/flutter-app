# GA sürüklenme tablosu — saha doğrulama protokolü (iki kronograf)

Rapor Ö13 (a), `docs/yeni-hesaplar-2026-10-11.md`. Amaç: kodda
"UNVERIFIED" işaretli GA tablosunun (`lib/core/standard_drag_tables.dart`)
diabolo saçmanın gerçek sürüklenme biçimine uyup uymadığını sahada ölçmek.

## Fikir

Bir sürüklenme tablosu saçmanın Cd–Mach biçimine uyuyorsa, iki kronografla
farklı hız aralıklarında ölçülen BC aynı çıkar. Biçim uymuyorsa BC hızla
sistematik olarak kayar (Courtney & Courtney, "The Truth About Ballistic
Coefficients", arXiv:0705.0389; diabolo saçmada sürüklenmenin hıza güçlü
bağlılığı: UCL Discovery 10072258). Hesap uygulamada hazır:
Araçlar > Hesaplayıcılar > "İki hız ölçümünden BC", model GA ve G1.

## Gereken

- İki kronograf (veya bir kronograf iki konumda, aynı saçma partisiyle).
  İkisi önce yan yana aynı atışları ölçerek karşılaştırılır; ortalama fark
  %0,5'ten büyükse düzeltme farkı not edilir.
- Telemetre veya şerit metre (konum hatası ±5 cm).
- Termometre, telefon barometresi ("Basıncı telefondan al").
- Rüzgârsız (< 1 m/s) bir gün; aynı tüfek, aynı dolum basıncı aralığı.

## Adımlar

1. Kronograf A namlu ağzından 1 m'ye, kronograf B sırayla 10 m, 25 m ve
   50 m'ye konur (B'nin her konumu ayrı seri). Aradaki mesafe ölçülür.
2. Her konumda en az 10 atış; her atışın V1 ve V2'si birlikte yazılır.
   Atışlar arasında dolum basıncı regülatör aralığında kalmalı.
3. Sıcaklık, istasyon basıncı ve nem her seri başında yazılır.
4. Her atış için Hesaplayıcılar'da V1, V2, aradaki mesafe ve hava girilir;
   GA ve G1 için BC okunur. Seri ortalaması ve standart sapması alınır.
5. İki farklı dolum basıncıyla (ör. regülatör üst ve alt ayar) tekrarlanır:
   bu, aynı mesafede farklı hız aralığı verir.

## Değerlendirme

| Gözlem | Anlam |
|---|---|
| GA BC'si konumlar ve hızlar arasında ±%3 içinde sabit; G1 BC'si belirgin kayıyor | GA tablosu bu saçmaya uyuyor. |
| GA BC'si de hız düştükçe aynı yönde > %3 kayıyor | GA tablosunun biçimi bu saçmaya uymuyor; özel sürüklenme eğrisi (Hız Doğrulama > Sürüklenme eğrisi veya Doppler verisi) gerekir. |
| Seri içi SD, seriler arası farktan büyük | Ölçüm yetersiz; atış sayısını artırın, kronograf hizasını kontrol edin. |

Kabul ölçütü: en az iki farklı saçma (diabolo 16–18 gr ve 21–25 gr) için
GA BC'sinin tüm konum/hız serilerinde ±%3 içinde kalması. O zaman koddaki
"UNVERIFIED" notu kaynak olarak bu ölçüm kaydıyla değiştirilebilir.

## Kayıt biçimi

Her seri için bir satır: tarih, saçma (marka, model, gr), tüfek, dolum
basıncı, sıcaklık, basınç, nem, B konumu (m), n, V1 ort., V2 ort., BC GA
ort./SD, BC G1 ort./SD. Kayıtlar `validation/` altına CSV olarak eklenir;
uygulamaya giren her değişiklik bu kayda dayanmalı.
