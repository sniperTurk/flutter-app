# Apple Watch prototipi

- `WatchCore/`: Swift Package. Telefonun mesajını çözer, Türkçe metinleri
  üretir. Balistik hesap yok. Test: `swift test --package-path watch/WatchCore`
  (macOS).
- `SniperTurkWatch/`: SwiftUI watchOS uygulaması (XcodeGen `project.yml`).
  `xcodegen generate` ile proje üretilir, `.xcodeproj` repo'ya girmez.
- `ios_runner/SniperTurkWatchBridge.swift`: iPhone tarafındaki köprü
  (`sniper_turk/watch` kanalı ↔ WatchConnectivity). İskelete yalnızca
  `tools/configure_ios_watch_bridge.py` + `.rb` ile, elle tetiklenen
  `.github/workflows/watch-sim.yml` içinde eklenir.

Mesaj şeması (v1) telefon tarafında `lib/services/watch/watch_solution.dart`.
Ayrıntılar: `docs/saat-uygulamasi/`.
