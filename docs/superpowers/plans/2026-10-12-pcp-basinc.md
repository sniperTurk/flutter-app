# PCP tüp ve regülatör basıncı — uygulama planı

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (native; bu oturum). Steps use checkbox (`- [ ]`) syntax.

**Goal:** PCP profiline "Tüp basıncı | Regülatör basıncı" ve isteğe bağlı basınç–hız tablosu; Pro'da sahadaki kalan tüp basıncından hız.

**Architecture:** Saf hesap `lib/core/pcp_pressure.dart` (`PcpPressure.velocity`) — barut sıcaklığı (`PowderTemperature`) ile aynı desen: profil değerleri + saha değeri → bugünkü hız; sıfır, profil hızıyla çözülür (`zeroMuzzleVelocityMps`). Ateşli tüfekte hiç çağrılmaz.

**Tech Stack:** Flutter/Dart, flutter_test; CI: test-diag, analyze-diag, format.

**Spec:** Sahip kararı 2026-10-12 00:20 (görev metni). `docs/pcp-hiz` dalı/PR'ı yok → bu çerçeveyle tasarlandı.

## Global Constraints
- Yalnız PCP; ateşli tüfekte alan görünmez, hesap değişmez.
- Tüm yeni alanlar boşken PCP sonucu bugünküyle aynı.
- `pressureBar` = regülatör basıncı (V379'dan beri anlamı bu) — eski kayıtlar aynen okunur.
- Uydurma formül / varsayılan yok; < 2 nokta → tablo yok; aralık dışı → uç değer.
- ⓘ kısa Türkçe; yardım yazısı yok; etikette parantez yok; örnek değer (hint) yok; iki kutu yan yana; virgül kabul.
- Hız fps girilir (sahip kuralı), m/s saklanır. Basınç bar.

## Review Focus
1. Regülatörlü, tüp ≥ regülatör → profil hızı (tablo olsa bile).
2. Regülatörlü, tüp < regülatör, tabloda regülatör altında nokta yok → profil hızı + uyarı (uydurma yok).
3. Tabloda aynı basınç iki kez / yarım satır → kaydetme hatası.
4. Ateşli profilde eski/bozuk tablo verisi → profil tutarsız (integrity).
5. Hız Doğrulama (tool_support) yeni alanları silmemeli.

### Task 1: Hesap — `lib/core/pcp_pressure.dart`
- `class PressureVelocityPoint { final double bar, mps; }`
- `PcpPressure.velocity({required double profileMps, double? regulatorBar, double? tubeBar, List<PressureVelocityPoint> table}) → PcpVelocity {mps, regulatorBypassed, fromTable}`
- `PcpPressure.interpolate(List<PressureVelocityPoint>, double bar) → double?` (null < 2 nokta)
- Test: `test/pcp_pressure_test.dart` — boş → profil; regülatörlü üst/alt; regülatörsüz ara değer + uç sınır; 1 nokta → profil.

### Task 2: Model + doğrulama + kayıt
- `RifleProfile.tubePressureBar`, `RifleProfile.pressureVelocityTable` (const []).
- `ProfileInput.validate(tubePressureText, pressureTable: List<(String, String)>)` — PCP dışı yok sayılır; regülatör < tüp; satırda iki değer birlikte; aynı basınç yok; hız 100–4900 fps.
- Codec: `tubePressureBar`, `pressureVelocity: [{bar, mps}]`; yoksa boş, bozuksa FormatException.
- Integrity: ateşli + yeni alan → tutarsız.
- tool_support: alanları taşı.
- Test: `test/pcp_pressure_profile_test.dart`.

### Task 3: Profil arayüzü (PCP)
- Mühimmat kartında namlu çıkış hızından sonra `MenzilFullWidth` içinde iç `MenzilFieldGrid`: `profile-tube-pressure` | `profile-regulator-pressure`; "Basınca göre hız" başlığı + 4 satır `profile-pv-bar-i` | `profile-pv-fps-i`.
- ⓘ metinleri `profile_field_info.dart`.
- Widget test: PCP'de görünür, ateşlide yok; boş bırakınca kayıt eskisiyle aynı.

### Task 4: Pro + Hedef
- Pro > Tüfek düzeltmeleri (yalnız PCP): `pro-tube-pressure` (bar), açıklama, uyarı `pro-pcp-regulator`, `pro-pcp-velocity` satırı. ShotSettings `tubePressure` metni saklanır.
- `solve()`: `vToday = _pcpAdjusted(_powderAdjusted(v))`; değiştiyse `vZero = v`.
- Hedef: regülatör devre dışıysa uyarı `shot-pcp-regulator`.
- Test: ateşlide `pro-tube-pressure` yok; PCP boşken hız profil hızı.

### Task 5: Doğrulama
- `python3 tools/offline_dart_lint.py`, Python birim testleri, CI test-diag / analyze-diag / format, sim-screens 1 kez, PR (REST).
