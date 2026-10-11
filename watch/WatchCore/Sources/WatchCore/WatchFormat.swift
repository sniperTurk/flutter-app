import Foundation

/// Saatte görünen Türkçe metinler. Kalın yazı yok; yalnızca metin üretir.
public enum WatchFormat {
  /// Bu süreden eski veri sönük gösterilir ve uyarı verilir.
  public static let staleAfter: TimeInterval = 120

  public static func elevation(_ clicks: Int) -> String {
    "\(clicks < 0 ? "↓" : "↑") \(abs(clicks))"
  }

  public static func elevationLabel(_ clicks: Int) -> String {
    clicks < 0 ? "Aşağı" : "Yukarı"
  }

  public static func windage(_ clicks: Int) -> String {
    "\(clicks < 0 ? "←" : "→") \(abs(clicks))"
  }

  public static func windageLabel(_ clicks: Int) -> String {
    clicks < 0 ? "Sol" : "Sağ"
  }

  /// "4.7 MRAD": işaretsiz (yönü ok gösterir), en çok 2 ondalık, en az 1.
  public static func angle(_ value: Double, unit: String) -> String {
    "\(decimal(abs(value))) \(unit)"
  }

  public static func unitLine(unit: String, click: Double) -> String {
    "\(unit) · \(decimal(click))/klik"
  }

  public static func wind(speed: Double?, unit: String?, clock: Int?) -> String? {
    guard let speed, let unit, speed > 0 else { return nil }
    let base = "Rüzgâr \(String(format: "%.1f", speed)) \(unit)"
    guard let clock else { return base }
    return "\(base) · saat \(clock)"
  }

  public static func updated(_ at: Date, calendar: Calendar = .current) -> String {
    let c = calendar.dateComponents([.hour, .minute], from: at)
    return String(format: "Güncellendi %02d:%02d", c.hour ?? 0, c.minute ?? 0)
  }

  /// nil: veri taze. Aksi halde "Veri eski (9 dk)".
  public static func staleNotice(at: Date, now: Date) -> String? {
    let age = now.timeIntervalSince(at)
    guard age > staleAfter else { return nil }
    return "Veri eski (\(Int(age / 60)) dk)"
  }

  /// 4.70 → "4.7", 0.25 → "0.25", 0 → "0.0" (ondalık ayırıcı nokta,
  /// telefondaki gibi).
  static func decimal(_ value: Double) -> String {
    var s = String(format: "%.2f", value)
    while s.hasSuffix("0") && !s.hasSuffix(".0") { s.removeLast() }
    return s
  }
}

/// Saatten telefona mesafe isteği. Saat hesap yapmaz; yalnızca ister.
public enum RangeRequest {
  public static let maxRange = 9_999

  /// [value] + [delta] adım; en az bir adım, en çok [maxRange].
  public static func stepped(_ value: Int, by delta: Int, step: Int) -> Int {
    let s = max(1, step)
    return min(maxRange, max(s, value + delta * s))
  }

  public static func message(_ value: Int) -> [String: Any] {
    ["type": "setRange", "value": value]
  }
}
