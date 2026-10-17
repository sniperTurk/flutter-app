# Üst çubuk logo + ince marka yazısı Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Profil sekmesindeki üst çubuk markası "Sniper Türk"ün soluna 44 pt logo eklemek ve marka yazısını w600 yapmak.

**Architecture:** `MenzilBrand` bir `Row` (logo 44×44, 4 pt boşluk, metin) olur; tamamı mevcut `FittedBox` içinde birlikte küçülür. `MenzilTopBar.titleSlotWidth` marka ölçümüne logo + boşluğu ekler.

**Tech Stack:** Flutter 3.47.2, flutter_test.

**Spec:** Owner onayı 2026-10-17 18:37 (görev metni): "logo 44 pt + Sniper Türk yazısı biraz ince".

## Global Constraints

- Logo 44 pt kare, metinle dikey ortalı, logo–metin arası 4 pt.
- Koyu tema `assets/branding/logo_line_dark.png`, açık tema `assets/branding/logo_line.png` (`Theme.of(context).brightness`).
- Logo dekoratif: semantikte yok; Semantics label 'Sniper Türk' kalır.
- Marka yazısı w600, 20 pt; `MenzilType.heading` global olarak değişmez.
- `titleSlotMaxFraction` ve FittedBox küçültme kalır; başka hiçbir şey değişmez ("Profiller" başlığı / "Profil ekle" dahil).

## Review Focus

1. 320 pt + yazı 1.25/1.3 → taşma yok, logo ve metin birlikte küçülür (top_bar_fixed_slot_test 320 döngüsü).
2. Profil kutusu her sekmede aynı x → slot genişliği logo dahil ölçülür (mevcut _expectSame).
3. Açık tema → doğru asset (yeni test, açık tema).
4. Metin ölçeği logoyu büyütmez; logo sabit 44 pt, ölçek sadece metne → titleSlotWidth testi `text*scale + 48`.
5. Ekran okuyucu: tek "Sniper Türk" etiketi, logo için ayrı düğüm yok (semantics testi).

---

### Task 1: Logo + w600 + slot ölçümü

**Files:**
- Modify: `lib/ui/menzil_widgets.dart` (`MenzilBrand`, `MenzilTopBar.titleSlotWidth`)
- Test: `test/top_bar_fixed_slot_test.dart`, `test/ust_cubuk_test.dart`

**Interfaces:**
- Produces: `MenzilBrand.logoSize = 44.0`, `MenzilBrand.logoGap = 4.0`, `MenzilBrand.logoAsset(Brightness) -> String`, `MenzilBrand.style(Color)` (w600), keys `top-bar-brand` (Text), `top-bar-brand-logo` (Image).

- [ ] Step 1: Testleri yaz: logo var, metnin solunda, 44×44, dikey ortalı, boşluk 4; asset koyu/açık; marka w600, 20 pt; sayfa başlığı w700 kalır; slot genişliği = max(başlıklar, marka metni + 48); semantics tek 'Sniper Türk'; Profil'de logo.left == slot.left.
- [ ] Step 2: Çalıştır, FAIL gör.
- [ ] Step 3: Uygula.
- [ ] Step 4: Testler PASS.
- [ ] Step 5: `tools/claude_flutter_verify.sh`, commit, push, draft PR, CI, sim-screens.
