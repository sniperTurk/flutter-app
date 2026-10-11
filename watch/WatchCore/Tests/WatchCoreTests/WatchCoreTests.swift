import Foundation
import XCTest

@testable import WatchCore

final class WatchSolutionTests: XCTestCase {
  // The phone's message (same shape as test/watch_bridge_test.dart).
  private func message(_ overrides: [String: Any] = [:]) -> [String: Any] {
    var m: [String: Any] = [
      "v": 1,
      "ok": true,
      "profile": "Tikka T3x .308",
      "at": 1_760_193_120_000,
      "range": 600,
      "rangeUnit": "m",
      "rangeStep": 10,
      "up": 47,
      "right": 6,
      "upAngle": 4.7,
      "rightAngle": 0.6,
      "unit": "MRAD",
      "click": 0.1,
      "windSpeed": 3.0,
      "windUnit": "m/s",
      "windClock": 3,
    ]
    for (k, v) in overrides { m[k] = v }
    return m
  }

  func testDecodesEveryField() throws {
    let s = try XCTUnwrap(WatchSolution(message: message()))
    XCTAssertTrue(s.ok)
    XCTAssertEqual(s.profile, "Tikka T3x .308")
    XCTAssertEqual(s.range, 600)
    XCTAssertEqual(s.rangeUnit, "m")
    XCTAssertEqual(s.rangeStep, 10)
    XCTAssertEqual(s.up, 47)
    XCTAssertEqual(s.right, 6)
    XCTAssertEqual(s.unit, "MRAD")
    XCTAssertEqual(s.click, 0.1, accuracy: 1e-9)
    XCTAssertEqual(s.windClock, 3)
    XCTAssertEqual(s.at, Date(timeIntervalSince1970: 1_760_193_120))
  }

  func testNumbersArriveAsNSNumber() throws {
    // WatchConnectivity delivers property-list numbers as NSNumber.
    let s = try XCTUnwrap(
      WatchSolution(message: message([
        "range": NSNumber(value: 650), "up": NSNumber(value: -3),
        "upAngle": NSNumber(value: 0.25), "at": NSNumber(value: Int64(1_760_193_120_000)),
      ])))
    XCTAssertEqual(s.range, 650)
    XCTAssertEqual(s.up, -3)
    XCTAssertEqual(s.upAngle, 0.25, accuracy: 1e-9)
  }

  func testRejectsUnknownSchemaOrMissingFields() {
    XCTAssertNil(WatchSolution(message: message(["v": 2])))
    var noUp = message()
    noUp.removeValue(forKey: "up")
    XCTAssertNil(WatchSolution(message: noUp))
    XCTAssertNil(WatchSolution(message: message(["up": 4.5])))
  }

  func testNoSolutionNeedsNoClicks() throws {
    let s = try XCTUnwrap(
      WatchSolution(message: ["v": 1, "ok": false, "profile": "P", "at": 0]))
    XCTAssertFalse(s.ok)
  }
}

final class WatchFormatTests: XCTestCase {
  func testElevationAndWindageArrows() {
    XCTAssertEqual(WatchFormat.elevation(47), "↑ 47")
    XCTAssertEqual(WatchFormat.elevation(-3), "↓ 3")
    XCTAssertEqual(WatchFormat.elevationLabel(-3), "Aşağı")
    XCTAssertEqual(WatchFormat.elevationLabel(0), "Yukarı")
    XCTAssertEqual(WatchFormat.windage(6), "→ 6")
    XCTAssertEqual(WatchFormat.windage(-2), "← 2")
    XCTAssertEqual(WatchFormat.windageLabel(-2), "Sol")
    XCTAssertEqual(WatchFormat.windageLabel(6), "Sağ")
  }

  func testAngleTextDropsSignAndTrailingZeros() {
    XCTAssertEqual(WatchFormat.angle(4.70, unit: "MRAD"), "4.7 MRAD")
    XCTAssertEqual(WatchFormat.angle(-0.25, unit: "MOA"), "0.25 MOA")
    XCTAssertEqual(WatchFormat.angle(0, unit: "MRAD"), "0.0 MRAD")
  }

  func testUnitWindAndTime() throws {
    XCTAssertEqual(WatchFormat.unitLine(unit: "MOA", click: 0.25), "MOA · 0.25/klik")
    XCTAssertEqual(WatchFormat.wind(speed: 3.0, unit: "m/s", clock: 3), "Rüzgâr 3.0 m/s · saat 3")
    XCTAssertEqual(WatchFormat.wind(speed: 5.0, unit: "mph", clock: nil), "Rüzgâr 5.0 mph")
    XCTAssertNil(WatchFormat.wind(speed: nil, unit: nil, clock: nil))
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Istanbul"))
    let at = Date(timeIntervalSince1970: 1_760_193_120)  // 2025-10-11 17:32 +03
    XCTAssertEqual(WatchFormat.updated(at, calendar: cal), "Güncellendi 17:32")
  }

  func testPendingRangeUntilThePhoneAnswers() throws {
    let s = try XCTUnwrap(
      WatchSolution(message: [
        "v": 1, "ok": true, "profile": "P", "at": 0, "range": 600, "rangeUnit": "m",
        "rangeStep": 10, "up": 1, "right": 0, "upAngle": 0.1, "rightAngle": 0.0,
        "unit": "MRAD", "click": 0.1,
      ]))
    XCTAssertNil(WatchFormat.pendingNotice(requested: nil, solution: s))
    XCTAssertNil(WatchFormat.pendingNotice(requested: 600, solution: s))
    XCTAssertEqual(
      WatchFormat.pendingNotice(requested: 650, solution: s),
      "İstenen 650 m bekleniyor. Telefonda Atış açık olmalı.")
  }

  func testStaleAfterTwoMinutes() {
    let at = Date(timeIntervalSince1970: 1000)
    XCTAssertNil(WatchFormat.staleNotice(at: at, now: at.addingTimeInterval(120)))
    XCTAssertEqual(
      WatchFormat.staleNotice(at: at, now: at.addingTimeInterval(9 * 60 + 5)), "Veri eski (9 dk)")
  }
}

final class RangeRequestTests: XCTestCase {
  func testStepsStayPositiveAndBounded() {
    XCTAssertEqual(RangeRequest.stepped(600, by: 1, step: 10), 610)
    XCTAssertEqual(RangeRequest.stepped(10, by: -1, step: 10), 10)
    XCTAssertEqual(RangeRequest.stepped(5, by: -3, step: 5), 5)
    XCTAssertEqual(RangeRequest.stepped(9_995, by: 1, step: 10), RangeRequest.maxRange)
  }

  func testMessageShape() {
    let m = RangeRequest.message(650)
    XCTAssertEqual(m["type"] as? String, "setRange")
    XCTAssertEqual(m["value"] as? Int, 650)
  }
}
