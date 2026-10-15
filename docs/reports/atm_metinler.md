# ATM-2 ve ATM-3: İrtifa / Basınç ⓘ metinleri

Sahip kararı: 2026-10-15 20:47 (İstanbul), "düzeltmek için görev aç".
Kaynak: `docs/reports/denetim_testflight_2026_10_14b.md`, bulgu ATM-2 ve ATM-3 (düşük).

## Ne yapıldı

- **ATM-2:** İrtifa kartı ⓘ'sine bir cümle eklendi: "İrtifa yalnız İstasyon basıncı boşken basınç tahmini için kullanılır."
- **ATM-2:** Basınç Ölçer kartı ⓘ'sine bir cümle eklendi: "Boşsa basınç İrtifa kartından tahmin edilir."
- **ATM-2:** Hiçbir yerde kullanılmayan `EnvironmentFieldInfo.altitude` metni silindi (CLAUDE.md: kullanılmayan kod silinir).
- **ATM-3:** `EnvironmentFieldInfo.pressure` (Araçlar → Doğrulama → Basınç ⓘ) artık olmayan "Basıncı telefondan al" düğmesinden söz etmiyor. Yeni metin sayfada olanı anlatıyor: kutu standart değerle başlar, atış anındaki basınç yazılır; Kestrel/barometreyle ölçülür ya da Araçlar > Hesaplayıcılar ile deniz seviyesinden istasyon basıncına çevrilir.

## Nasıl / neden

Yalnız `lib/features/ballistics/environment_field_info.dart` içindeki metinler değişti. Hesap, kutular ve düğmeler aynı; hiçbir mantık değişmedi. Metinler kısa, Türkçe, diğer ⓘ'lerle aynı biçimde ("Örnek: …" ile biter), sola yaslı (ⓘ bileşeni değişmedi).

## Uç durumlar

- Doğrulama sayfasında basınç kutusu metrikte 1013,25 hPa, inç-Hg'de 29,92 ile başlar; bu yüzden metin sayı vermeden "standart değerle başlar" diyor.
- Yerçekimi "Konumdan hesapla" de irtifayı kullanır; ama bu Pro'da ayrı bir düğmedir. Sahibin istediği cümle hesaptaki basınç kuralını anlatır.

## Bilerek yapılmayanlar (kapsam dışı)

- "Basıncı telefondan al" adı başka yerlerde de geçiyor: `tools/configure_ios_info_plist.py` (iOS izin metni), `tools/data_gen/generate_usage_guide.py`, bazı test yorumları. Görev yalnız ⓘ metin dosyası ve adı verilen testlerle sınırlı olduğu için bunlara dokunulmadı. Ayrı görev gerekirse sahip karar verir.

## Testler

- `test/phone_pressure_test.dart`: Basınç ⓘ'sinde eski düğme adı ve "düğme" sözü yok, "Hesaplayıcılar" ve "Örnek" var; İrtifa ve Basınç Ölçer ⓘ'leri kuralı içeriyor.
- `test/audit_2026_10_14b/atmosphere_altitude_audit_test.dart`: ATM-2 ve ATM-3 testlerinin `skip:`'i kaldırıldı (CLAUDE.md kuralı).
- `tools/test_denetim_2026_10_14b_atm.py`: ATM-2 ve ATM-3 testleri düzeltilmiş durumu doğruluyor (zayıflatılmadı): eski düğme adı yok, `altitude` sabiti yok, iki kartta kural cümlesi var. Eski metinle iki test düştü, yeni metinle geçti (yerelde denendi).
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (379 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 842 test OK.
- Bu ortamda Flutter SDK yok; Dart testleri yalnız CI'da çalışır.

## CI

CI_PLACEHOLDER

Taslak PR; birleştirme ve TestFlight yok.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
