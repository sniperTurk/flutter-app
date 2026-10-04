# V368 — profil verisi bütünlüğü (fail-closed editör)

Solver, `validation/acceptance.json` (SHA 1d861282…7c67927d), katalog verisi, Atış/Tablo KİLİTLİ davranışı ve kapalı
G1/G7 kapısı değişmedi. Flutter/Dart yok: Dart değişiklikleri derlenmedi/çalıştırılmadı (NOT RUN).

- P1: Profil düzenleyici, kayıtlı tüfek/mühimmat/dürbün ID'si kataloğda çözülemezse veya mühimmat kalibresi uyumsuzsa
  sessizce "ilk katalog kaydını" seçip kaydediyordu. Artık düzenlemede alan boş bırakılır, uyarı gösterilir, Kaydet
  kullanıcı açıkça seçene kadar kapalıdır. Eksik basınç için uydurma '200' yazılmaz (yalnız yeni profilde varsayılan).
- P2: Ana ekran `_choose` aktif profili `saved` içindeki örnekle eşleştirir (RifleProfile'da ==/hashCode yok).
- Geri alma: V367'nin kanıtsız `ResolutionPreset.veryHigh` değişikliği `high`'a döndürüldü.
- Düzeltme: V367 raporundaki "camera dispose() initialize istisnasını yeniden fırlatır" varsayımı camera 0.12.1
  kaynağıyla doğrulanmadı; `_disposeQuietly` zararsız savunma olarak kaldı.
