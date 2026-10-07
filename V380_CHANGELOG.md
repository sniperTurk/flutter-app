# V380 — Ayarlar kaldırıldı (tek anahtarla toplu birim değişimi yok)

Kaynak: `main` @ `1509aa4`. Hesap, solver ve kapılar değişmedi.

## Neden
Sahip kararı (2026-10-07/08): bütün birimleri tek "metrik/emperyal" anahtarıyla
gruplamak hatalıydı ve karışıklığa yol açtı (Ayarlar emperyalken Profil hızı
m/s alıyordu). Birimler alanın kendisinde belirlenir: namlu çıkış hızı fps,
namlu cm, regülatör bar; dürbün için MRAD/MOA/Yard seçeneği ayrıca gelecek.

## Değişiklikler
- Ayarlar ekranı, Araçlar'daki Ayarlar kutucuğu ve üst çubuktaki birim düğmesi
  kaldırıldı (`MenzilTopBar.unitLabel` artık isteğe bağlı).
- `SettingsStore.loadMetric()` her zaman metrik döner: daha önce emperyal
  seçmiş bir cihaz da güncellemeden sonra tutarlı çalışır.
- Testler ve sözleşmeler (v271, iOS smoke) güncellendi.
