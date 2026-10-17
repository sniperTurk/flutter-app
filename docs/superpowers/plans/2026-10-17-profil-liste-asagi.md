# Profil: liste kartların altında, buton en sonda — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Profil sekmesinde sıra Tüfek → Dürbün → Mühimmat → Profiller listesi → "Hava Durumu'na geç"; katalog notu silinir; kart arası ve Mühimmat → Profiller arası görünen boşluk 20 pt.

**Architecture:** `_ActiveProfileDetails` (profile_summary.dart) yalnızca üç kartı çizer (not ve buton çıkar). `ProfilesScreen._content` (profiles_screen.dart) sırayı kurar: kartlar, liste başlığı + satırlar (+ boş kart / gizli yedek düğmeleri), en sonda buton.

**Tech Stack:** Flutter 3.47.2, flutter_test.

**Spec:** Owner task 2026-10-17 19:14 ("20 pt olarak yap, iki düzeltmeyi de başlat"), quoted in the PR body.

## Global Constraints

- Görünen kart arası = `MenzilSpace.xl` (20). `MenzilMetricGrid` kendi altına `MenzilSpace.md` (10) iç boşluk koyar, bu yüzden araya `MenzilSpace.xl - MenzilSpace.md` girer.
- Satır arası 8 pt (`_ProfileRow` alt padding `sm`), başlık → ilk satır 8 pt: değişmez.
- Buton üstü `SizedBox(MenzilSpace.md)` korunur (son satırın 8 pt alt boşluğuyla görünen 18 pt).
- Başka bir şey değişmez (başlık boyu, "Profil ekle", satır gri yazısı diğer görevlerin).
- Kaldırılan not koddan silinir.

## Review Focus

- Aktif profil yok (activeProfileId null / listede yok) → kartlar ve buton yok, liste en üstte.
- Liste boş ama embedded değil → boş liste kartı ve Profil ekle görünür.
- Sıfır profil, embedded → WelcomePanel değişmez.
- embedded=false → buton yok.
- 320 pt × 1.25 metin → taşma yok.

---

### Task 1: Sıra, not ve boşluk

**Files:**
- Modify: `lib/features/profiles/profile_summary.dart` (`_ActiveProfileDetails`: `onContinue` + not + buton çıkar; kart arası `xl - md`)
- Modify: `lib/features/profiles/profiles_screen.dart` (`_content`)
- Test: `test/profil_liste_asagi_test.dart` (yeni); güncelle: `test/profiller_ustte_test.dart`, `test/profile_page_test.dart`, `test/profil_ozet_etiket_test.dart`

- [ ] Step 1: Yeni testler: sıra (rifle < scope < ammo < profiles-list-header < satırlar < profile-continue-weather), not yok, görünen kart arası 20, Mühimmat → başlık 20, satır arası 8, 320 pt × 1.25 taşma yok, boş liste ve sıfır profil.
- [ ] Step 2: Eski sırayı/notu/14 pt'yi doğrulayan testleri yeni kurala çevir.
- [ ] Step 3: Kodu değiştir.
- [ ] Step 4: `tools/claude_flutter_verify.sh` (yerelde SDK yoksa BLOCKED; CI zorunlu).
- [ ] Step 5: Commit, push, draft PR, CI, sim-screens.
