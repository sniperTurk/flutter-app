# V345 changelog

- Vacuum/gravity baseline sonuç tablosundan doğrudan `Klik`/tambur talimatı kaldırıldı.
- G1/G7 harici referans kabul kapısı geçmeden kullanıcıya vakum düzeltmesinden türetilmiş dial komutu gösterilmiyor.
- MRAD/MOA vakum düzeltmesi, rüzgârın 0.00 güvenlik gösterimi, namlu enerjisi ve TOF tanısal/uyarı etiketleriyle korunuyor.
- `tools/test_v345_vacuum_click_suppression.py` bu fail-closed UI sözleşmesini kilitliyor.
- G1/G7 production gate CLOSED kalır; bu sürüm drag DOPE'u açmaz.
