# V369 — release-candidate hazırlığı (V368 üzerinden)

Solver, `validation/acceptance.json`, katalog, G1/G7 kapısı (KAPALI), Atış/Tablo KİLİT davranışı değişmedi. Dart değişiklikleri derlenmedi (flutter yok).

- Profil deposu: bozuk birincil kayıt, yedekten onarılmadan veya üzerine yazılmadan ÖNCE `sniper_turk.rifle_profiles.v1.corrupt` anahtarına birebir kopyalanır (ilk kanıt korunur; kopya yazılamazsa işlem hata verir). Bozuk veri artık yok edilmiyor.
- CI: release derlemeleri `--dart-define=METNO_CONTACT` alır; `tools/validate_metno_contact.py` boş/placeholder/hatalı değeri reddeder (değer uydurulmaz, yankılanmaz). Eskiden CI'nın ürettiği release arşivi `CONTACT_REQUIRED` ile çıkar ve Hava sessizce kapalı olurdu.
- Testler: `test/profile_editor_fail_closed_test.dart`, `test/profile_store_test.dart` (3 quarantine testi) — YAZILDI, ÇALIŞTIRILMADI. Python: `test_v368_*` sözleşme/METNO testleri.
- Belgeler: `release/DEVICE_ACCEPTANCE_PLAN.md`, `release/PROFILE_RECOVERY_DESIGN.md`, `release/RELEASE_CHECKLIST.md`.
- V368 değişiklikleri (editör fail-closed, Home örnek çözümleme, `ResolutionPreset.high`) korunur.
