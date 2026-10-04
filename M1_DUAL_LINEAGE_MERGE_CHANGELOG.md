# M1 Dual-Lineage Merge — 2026-10-03

Ana taban: M1 teslim hattı (MET Norway + camera/http + lib/tools port/adapter mimarisi).
Karşılaştırılan ikinci hat: saha araçları hattı (Open-Meteo + image_picker + lib/services/field).

## Seçici olarak taşınan geliştirme
- Sight Height fotoğraf işaretleme ekranına erişilebilir hassas konumlama davranışı eklendi.
- İşaret seçimi ve 2 kaynak-piksel adımlı sol/yukarı/aşağı/sağ ince ayar eklendi.
- İnce ayar düğmeleri en az 44x44 dokunma alanına sahip.
- Seçili işaret VoiceOver/Semantics etiketiyle açıklanıyor.
- Mark painter artık yalnız işaret sayısını değil koordinat değişimini de repaint nedeni sayıyor; bu, ince ayar sonrası görselin güncellenmemesi riskini gideriyor.

## Bilerek taşınmayanlar
- Open-Meteo weather hattı (M1 MET Norway kararı korunuyor).
- image_picker (M1 camera paketi korunuyor).
- Uygulama içine Qwen API anahtarı/endpoint gömme yaklaşımı.
- lib/services/field paralel servis mimarisi; tek port/adapter mimarisi korunuyor.

## Doğrulama
- tools/test_m1_dual_lineage_merge.py: 2/2 PASS.
- M1 test keşfi (`test_m1*.py`): 17/17 PASS.
- Offline Dart lint: 97 Dart dosyası, 0 sorun.
- Python compileall: PASS.
- Flutter analyze/test, iOS build, Simulator ve fiziksel iPhone: NOT RUN.
- Production G1/G7 gate: CLOSED; değiştirilmedi.
