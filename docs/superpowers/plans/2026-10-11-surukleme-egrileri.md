# Ölçülmüş sürüklenme eğrileri — uygulama planı

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (sahibi yöntemi belirledi).

**Goal:** Kütüphane mermisinin yayımlanmış ölçülmüş Cd–Mach eğrisi varsa çözücüde onu, yoksa G1/G7'yi kullanmak.
**Architecture:** `data/drag-curves/measured/*.json` → `generate_measured_drag_curves.py` (lisans, kapsam, birebir kütüphane eşleşmesi denetimi) → `lib/data/measured_drag_curves.dart`; `MeasuredDragLookup.forBullet` profilde `_applyBullet` içinde mevcut özel eğri yoluna bağlanır.
**Spec:** görev metni (2026-10-11) ve `docs/surukleme-egrileri/RAPOR.md`.

## Global Constraints
- Yasak kaynaklar: Applied Ballistics/CDM, ChairGun, Strelok, QuickLOAD/QuickTARGET, GRT, JBM, Hornady 4DOF, forum/blog/bayi.
- Lisans belirsizse ekleme yok. Eğri eklemek G1/G7 sonuçlarını değiştirmez.
- UI: kalın yok, kutu altı yardım yok, etikette parantez yok.

## Review Focus
- Eğri kapsamı eksik (ör. yalnız ses üstü) → uygulamaya alınmaz (generator testi).
- Benzer adlı başka mermi (grain farkı) → eğri bağlanmaz (lookup testi).
- Eğrisi olan mermiden G7'ye elle dönüş → BC dolu kalır (`_applyBullet`).

## Tasks
1. Veri biçimi + M855 başvuru kaydı + RAPOR (data dalı). ✔
2. Generator + Python testleri (`tools/test_generate_measured_drag_curves.py`). ✔
3. `MeasuredDragLookup` + `_applyBullet` + Dart testleri (`test/measured_drag_curve_test.dart`). ✔
4. Doğrulama: offline lint, Python suite, CI test/analyze/format diag.
