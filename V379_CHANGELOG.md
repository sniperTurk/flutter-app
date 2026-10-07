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
