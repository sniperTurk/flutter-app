// SNIPER TÜRK — telefon tarafı saat köprüsü (iOS Runner).
//
// Dart `sniper_turk/watch` kanalı ile WatchConnectivity arasında aracı.
// Telefon → saat: `publish(map)` → WCSession.updateApplicationContext
// (yalnızca son durum tutulur). Saat → telefon: saatin sendMessage'ı →
// Dart'a `fromWatch(map)`.
//
// Saat eşlenmemişse, saat uygulaması kurulu değilse veya oturum henüz
// etkin değilse `publish` sessizce `false` döner; hiçbir şey atılmaz.
//
// Bu dosya iskelete yalnızca tools/configure_ios_watch_bridge.py ile eklenir
// (elle tetiklenen watch-sim.yml). TestFlight iskeleti bu dosyayı içermez.

import Flutter
import Foundation
import WatchConnectivity

final class SniperTurkWatchBridge: NSObject, FlutterPlugin, WCSessionDelegate {
  static let channelName = "sniper_turk/watch"

  private let channel: FlutterMethodChannel
  private var pendingContext: [String: Any]?

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: registrar.messenger())
    let instance = SniperTurkWatchBridge(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.activate()
  }

  private func activate() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "publish" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let context = call.arguments as? [String: Any] else {
      result(false)
      return
    }
    result(publish(context))
  }

  private func publish(_ context: [String: Any]) -> Bool {
    guard WCSession.isSupported() else { return false }
    let session = WCSession.default
    guard session.activationState == .activated else {
      // Etkinleşince gönderilir (yalnızca son durum).
      pendingContext = context
      return false
    }
    guard session.isPaired, session.isWatchAppInstalled else { return false }
    do {
      try session.updateApplicationContext(context)
      return true
    } catch {
      return false
    }
  }

  // MARK: - WCSessionDelegate

  func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    guard activationState == .activated, let pending = pendingContext else { return }
    DispatchQueue.main.async {
      self.pendingContext = nil
      _ = self.publish(pending)
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    // Kullanıcı başka bir saate geçti: yeni saat için yeniden etkinleştir.
    session.activate()
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    forward(message)
  }

  func session(
    _ session: WCSession, didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    forward(message)
    replyHandler(["ok": true])
  }

  private func forward(_ message: [String: Any]) {
    // WCSession geri çağrıları arka plan kuyruğunda gelir; kanal ana
    // iş parçacığında çağrılmalıdır.
    DispatchQueue.main.async {
      self.channel.invokeMethod("fromWatch", arguments: message)
    }
  }
}
