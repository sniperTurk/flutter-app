# V383 — kule ayar aralığı ve dürbün ayağı düzeltmeleri

Kaynak: `main` @ `4b44f09` (PR #29 dürbün ayağı).

- Profil → Dürbün: "Kule ayar aralığı (yükseklik)" ve "(rüzgâr)" alanları
  (dürbün biriminde, ⓘ açıklamalı, boş bırakılabilir; rüzgâr boşsa
  yükseklik aralığı kullanılır). Kişisel dürbün kaydına `elevationRangeMrad`
  / `windageRangeMrad` olarak yazılır; birim değişince açı korunarak
  çevrilir. Önceden profil kaydı aralığı hiç saklamıyordu.
- Aralık bilinmiyorsa tahmin yok: eski "her yöne 30 mrad" varsayımı
  kaldırıldı; "Kule yetmez" gösterilmez, kule davulu serbest döner.
- Yukarı yol toplam aralıkla sınırlı: min(yarı yol + ayak, toplam yol).
  Ayak yarı yoldan büyükse kırmızı uyarı: "Bu ayakla dürbün sıfırlanamaz".
- Ayak önerisi yalnız sıfırlamaya izin veren değerlerden; hiçbiri yetmezse
  "Hiçbir dürbün ayağı yetmez" yazar. Listedeki en küçük uygun ayak da
  gösterilir.
