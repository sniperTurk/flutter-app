# V379 — girilen her değerin yanında ⓘ açıklama

Kaynak: `main` @ `1b8c125`. Hesap, solver ve kapılar değişmedi.

- Sahip kuralı (2026-10-07): sayfalar düzenlenirken girilecek her değere
  bilgi eklenir. `CLAUDE.md`'ye kural olarak yazıldı.
- `MenzilInfoButton` ve `MenzilInput` / `MenzilSelect` için `info:`
  parametresi. Düğme 44 pt dokunma alanlı, VoiceOver'a açık ("Bilgi: …").
- Profil düzenleyicide tüm değer alanları açıklamalı (kalibre, namlu, yiv
  yönü/oranı, regülatör, mühimmat tipi, ağırlık, BC, BC modeli, odak
  düzlemi, büyütmeler, mercek çapı, dürbün birimi, klik, dürbün yüksekliği,
  çıkış hızı, sıfırlama, atış basıncı). Metinler
  `lib/features/profiles/profile_field_info.dart`.
- Test: tüm alanlarda ⓘ var; BC açıklaması açılıp kapanıyor.

## Ek: çıkış hızı fps (sahip isteği)
- Profil düzenleyicide namlu çıkış hızı **fps** olarak girilir (100–4900 fps;
  aralık dışı değer alan altında hata verir). Profil içeride m/s saklamaya
  devam eder (fps × 0,3048); hesaplar ve kayıt biçimi değişmedi. Yeni profil
  varsayılanı 820 fps.
- Profil listesi ve özeti hızı her iki birim sisteminde de fps gösterir.
- Test: düzenleyici kayıtlı 270 m/s'yi 885.8 fps gösterir; 6000 fps reddedilir.

## Ek 2 (sahip geri bildirimi, ekran görüntüsü 22:26)
- **Çıkış hızı**: yalnız etiket değil, değer de fps. Eski sürümde m/s
  kutusuna yazılan 950, 950 m/s olarak hesaba giriyordu; artık fps alınır ve
  çözücüye tam dönüşümle (× 0,3048) gider.
- **Atış basıncı alanı kaldırıldı**: PCP profil basıncı = regülatör basıncı
  (bar). Özetteki yinelenen "Atış basıncı" satırı kaldırıldı.
- **Varsayılan veri yok**: yeni profilde çıkış hızı (eski 250 m/s
  varsayılanı), sıfırlama (25 m) ve dürbün yüksekliği (65 mm) boş gelir.
- **Kaydet neden kapalı**: düğmenin üstünde bölüm bölüm eksik alanlar yazılır
  (ör. "Mühimmat: Marka, Model, Tip, Ağırlık, BC, BC modeli").

## Ek 3 (sahip, 23:18)
- Namlu uzunluğu **cm** olarak girilir ve özette cm gösterilir (mm saklanır).
- Mühimmat tipi: **Slug / Pellet** ("Diabolo" kaldırıldı).
- **Atış değerleri** (namlu çıkış hızı, sıfırlama) Tüfek kartının sonunda; ayrı bölüm yok.
- "Çıkış hızı" → **"Namlu çıkış hızı"**.
- (Atış basıncı → regülatör basıncı: Ek 2'de yapıldı.)
