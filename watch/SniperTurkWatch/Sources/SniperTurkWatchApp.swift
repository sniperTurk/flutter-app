import SwiftUI

/// SNIPER TÜRK saat uygulaması: telefondaki Atış çözümünü gösterir.
/// Balistik hesap telefonda yapılır (tek doğru kaynak).
@main
struct SniperTurkWatchApp: App {
  @StateObject private var store = WatchSessionStore()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(store)
    }
  }
}
