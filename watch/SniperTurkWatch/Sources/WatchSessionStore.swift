import Foundation
import WatchConnectivity
import WatchCore

/// Telefonla WatchConnectivity bağlantısı. Telefonun son çözümü
/// application context olarak gelir; mesafe isteği sendMessage ile gider.
final class WatchSessionStore: NSObject, ObservableObject, WCSessionDelegate {
  @Published private(set) var solution: WatchSolution?

  override init() {
    super.init()
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  /// Telefona yeni mesafe isteği. Telefona ulaşılamazsa false.
  func requestRange(_ value: Int, completion: @escaping (Bool) -> Void) {
    let session = WCSession.default
    guard session.activationState == .activated, session.isReachable else {
      completion(false)
      return
    }
    session.sendMessage(
      RangeRequest.message(value),
      replyHandler: { _ in DispatchQueue.main.async { completion(true) } },
      errorHandler: { _ in DispatchQueue.main.async { completion(false) } })
  }

  private func apply(_ context: [String: Any]) {
    guard let s = WatchSolution(message: context) else { return }
    DispatchQueue.main.async { self.solution = s }
  }

  // MARK: - WCSessionDelegate

  func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    let context = session.receivedApplicationContext
    if !context.isEmpty { apply(context) }
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    apply(applicationContext)
  }
}
