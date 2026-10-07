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
