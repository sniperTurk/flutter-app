# Saat Uygulaması Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Telefondaki Atış çözümünü (kule klikleri) Apple Watch ve Garmin'de göstermek; saatten mesafe isteği.

**Architecture:** Dart `WatchBridge` çözümü `sniper_turk/watch` kanalına yollar; iOS'ta `SniperTurkWatchBridge` (FlutterPlugin) bunu `WCSession.updateApplicationContext`'e verir. watchOS uygulaması (XcodeGen + `WatchCore` paketi) gösterir. Garmin Connect IQ uygulaması aynı mesaj şemasını kullanır (ayrı dal).

**Tech Stack:** Dart/Flutter 3.47.2, Swift/SwiftUI watchOS 10, WatchConnectivity, XcodeGen, Ruby xcodeproj, Monkey C.

**Spec:** `docs/superpowers/specs/2026-10-11-saat-uygulamasi-design.md`

## Global Constraints

- Hesap kodu (`lib/core/**`) değişmez.
- Yeni pub bağımlılığı yok; `pubspec.yaml`/`pubspec.lock` değişmez.
- `tools/bootstrap_ios_scaffold.sh`, `ios-ci.yml`, `ios-testflight.yml` değişmez.
- Metinler Türkçe, kalın yazı yok; "Sight height" İngilizce kalır.
- Mesaj şeması sürümü `v = 1`; alan adları spec'teki gibi.
- watchOS simülatör derlemesi en fazla 2 kez; yalnızca `watch-sim.yml` (workflow_dispatch).
- Garmin SDK indirilmez, lisans kabul edilmez.

## Review Focus

- Native kanal yok (Android, test, eski iskelet) → `publish` istisna atmaz, uygulama aynı çalışır. (Task 1 testi)
- Saatten 0, negatif, ondalık veya üst sınır üstü mesafe → yok sayılır/kırpılır. (Task 1 testi)
- Eksi sıfıra yuvarlanan açı ("-0.0") → "0.0". (Task 1 testi)
- Çözüm yokken saat eski sayıyı göstermez (`ok=false`). (Task 1 + Task 4 testi)
- 2 dakikadan eski veri → "Veri eski". (Task 4 testi)

---

### Task 1: Dart WatchSolution + WatchBridge

**Files:** Create `lib/services/watch/watch_solution.dart`, `lib/services/watch/watch_bridge.dart`; Test `test/watch_bridge_test.dart`.

**Interfaces — Produces:**
- `class WatchSolution { const WatchSolution({required bool ok, required String profile, required int range, required String rangeUnit, required int rangeStep, required int up, required int right, required double upAngle, required double rightAngle, required String unit, required double click, double? windSpeed, String? windUnit, int? windClock, required DateTime at}); factory WatchSolution.none({required String profile, required DateTime at}); Map<String, Object> toMessage(); }`
- `abstract interface class WatchTransport { Future<bool> send(Map<String, Object> message); Stream<Map<Object?, Object?>> get incoming; }`
- `class WatchBridge { WatchBridge({WatchTransport? transport, int maxRange = 100000}); static WatchBridge get instance; Future<void> publish(WatchSolution s); Stream<int> get rangeRequests; }`

- [ ] Testler: mesaj alanları; `ok=false` mesajında `up/right` yok; tekrar gönderilmez (zaman farklı olsa da); native yok → sessiz ve ikinci çağrı kanala gitmez; `setRange` süzgeci.
- [ ] Uygula, `python3 tools/offline_dart_lint.py` temiz, commit.

### Task 2: BallisticsScreen bağlantısı

**Files:** Modify `lib/features/ballistics/ballistics_screen.dart` (`initState`, `dispose`, `_scopeDial`).
- [ ] `_scopeDial` içinde `requiredUp/requiredRight` hesaplandıktan sonra `_publishWatch(...)` (post-frame). Yalnızca `view` `shot` veya `all`.
- [ ] `rangeRequests` → `_setShotDisplay`. Mevcut testler değişmeden geçmeli (test-diag).

### Task 3: iOS Runner köprüsü + configurator

**Files:** Create `watch/ios_runner/SniperTurkWatchBridge.swift`, `tools/configure_ios_watch_bridge.py`, `tools/configure_ios_watch_bridge.rb`, `tools/test_configure_ios_watch_bridge.py`.
- [ ] Python testi: implicit-engine şablonu ve klasik şablon; ikinci çalıştırma değişiklik yapmaz; `GeneratedPluginRegistrant` yoksa hata.

### Task 4: watchOS uygulaması

**Files:** `watch/WatchCore/Package.swift`, `Sources/WatchCore/*.swift`, `Tests/WatchCoreTests/*.swift`, `watch/SniperTurkWatch/project.yml`, `watch/SniperTurkWatch/Sources/*.swift`.
- [ ] `WatchCore` testleri: mesaj çözümü, `ok=false`, eskime (120 s), mesafe adımı ve sınır, Türkçe biçim ("↑ 47", "↓ 3", "→ 6", "← 2").

### Task 5: Elle tetiklenen derleme

**Files:** `.github/workflows/watch-sim.yml` (workflow_dispatch: `branch`).
- [ ] `swift test` (WatchCore) + XcodeGen + watchOS simülatör derlemesi + Runner köprüsüyle `flutter build ios --simulator --debug`. En fazla 2 tetikleme.

### Task 6: Garmin (feat/garmin dalı)

**Files:** `garmin/manifest.xml`, `garmin/monkey.jungle`, `garmin/source/*.mc`, `garmin/resources/**`, `garmin/README.md`.
- [ ] Derlenmez; README'de sahibinin adımları.

### Task 7: Doğrulama ve PR
- [ ] lint, unittest, test-diag, analyze-diag, format-diag; PR'lar REST ile; merge yok.
