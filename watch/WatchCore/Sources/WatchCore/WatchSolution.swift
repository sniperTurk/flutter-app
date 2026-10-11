import Foundation

/// Mesaj şeması sürümü (telefon: lib/services/watch/watch_solution.dart).
public let watchSchemaVersion = 1

/// Telefonun Atış çözümü. Saat bunu yalnızca gösterir; hesap yapmaz.
public struct WatchSolution: Equatable {
  public let ok: Bool
  public let profile: String
  public let at: Date
  public let range: Int
  public let rangeUnit: String
  public let rangeStep: Int
  public let up: Int
  public let right: Int
  public let upAngle: Double
  public let rightAngle: Double
  public let unit: String
  public let click: Double
  public let windSpeed: Double?
  public let windUnit: String?
  public let windClock: Int?

  /// Telefonun mesajından çözer. Bilinmeyen sürüm veya eksik/yanlış türde
  /// alan varsa nil: saat yanlış sayı göstermektense hiç göstermez.
  public init?(message m: [String: Any]) {
    guard Self.int(m["v"]) == watchSchemaVersion,
      let ok = m["ok"] as? Bool,
      let profile = m["profile"] as? String,
      let atMs = Self.int(m["at"])
    else { return nil }
    self.ok = ok
    self.profile = profile
    self.at = Date(timeIntervalSince1970: Double(atMs) / 1000)
    guard ok else {
      self.range = 0
      self.rangeUnit = "m"
      self.rangeStep = 10
      self.up = 0
      self.right = 0
      self.upAngle = 0
      self.rightAngle = 0
      self.unit = "MRAD"
      self.click = 0
      self.windSpeed = nil
      self.windUnit = nil
      self.windClock = nil
      return
    }
    guard let range = Self.int(m["range"]),
      let rangeUnit = m["rangeUnit"] as? String,
      let rangeStep = Self.int(m["rangeStep"]), rangeStep > 0,
      let up = Self.int(m["up"]),
      let right = Self.int(m["right"]),
      let upAngle = Self.double(m["upAngle"]),
      let rightAngle = Self.double(m["rightAngle"]),
      let unit = m["unit"] as? String,
      let click = Self.double(m["click"])
    else { return nil }
    self.range = range
    self.rangeUnit = rangeUnit
    self.rangeStep = rangeStep
    self.up = up
    self.right = right
    self.upAngle = upAngle
    self.rightAngle = rightAngle
    self.unit = unit
    self.click = click
    self.windSpeed = Self.double(m["windSpeed"])
    self.windUnit = m["windUnit"] as? String
    self.windClock = Self.int(m["windClock"])
  }

  /// Tam sayı: Int veya tam değerli NSNumber. 4.5 gibi kesirli sayı nil.
  static func int(_ value: Any?) -> Int? {
    if let i = value as? Int { return i }
    guard let n = value as? NSNumber else { return nil }
    let d = n.doubleValue
    guard d.isFinite, d == d.rounded(), abs(d) < 9.0e15 else { return nil }
    return Int(d)
  }

  static func double(_ value: Any?) -> Double? {
    if let d = value as? Double { return d.isFinite ? d : nil }
    if let i = value as? Int { return Double(i) }
    guard let n = value as? NSNumber, n.doubleValue.isFinite else { return nil }
    return n.doubleValue
  }
}
