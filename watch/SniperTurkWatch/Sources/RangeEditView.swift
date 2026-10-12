import SwiftUI
import WatchCore

/// Saatten mesafe değiştirme: Digital Crown ile seçilir, telefona istek
/// gider. Hesabı telefon yapar ve yeni çözümü geri gönderir.
struct RangeEditView: View {
  let solution: WatchSolution

  @EnvironmentObject private var store: WatchSessionStore
  @Environment(\.dismiss) private var dismiss
  @State private var value: Double = 0
  @State private var sending = false
  @State private var failed = false

  var body: some View {
    VStack(spacing: 6) {
      Text("Hedef mesafesi")
        .font(.system(size: 15, weight: .regular))
        .foregroundStyle(Palette.dim)
      Text("\(Int(value))")
        .font(.system(size: 48, weight: .regular))
        .foregroundStyle(Palette.cyan)
        .focusable()
        .digitalCrownRotation(
          $value,
          from: Double(solution.rangeStep),
          through: Double(RangeRequest.maxRange),
          by: Double(solution.rangeStep),
          sensitivity: .low,
          isContinuous: false,
          isHapticFeedbackEnabled: true)
      Text(solution.rangeUnit)
        .font(.system(size: 15, weight: .regular))
        .foregroundStyle(Palette.dim)
      if failed {
        Text("Telefona ulaşılamadı")
          .font(.system(size: 13, weight: .regular))
          .foregroundStyle(Palette.warn)
      }
      HStack {
        Button("Vazgeç") { dismiss() }
        Button("Gönder") {
          sending = true
          failed = false
          store.requestRange(Int(value)) { ok in
            sending = false
            if ok { dismiss() } else { failed = true }
          }
        }
        .foregroundStyle(Palette.amber)
        .disabled(sending)
      }
    }
    .onAppear { value = Double(solution.range) }
  }
}
