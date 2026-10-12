import SwiftUI
import WatchCore

enum Palette {
  static let amber = Color(red: 0.914, green: 0.627, blue: 0.047)
  static let cyan = Color(red: 0.361, green: 0.765, blue: 0.902)
  static let dim = Color(red: 0.553, green: 0.627, blue: 0.682)
  static let warn = Color(red: 0.910, green: 0.349, blue: 0.047)
}

struct ContentView: View {
  @EnvironmentObject private var store: WatchSessionStore

  var body: some View {
    NavigationStack {
      TimelineView(.periodic(from: .now, by: 30)) { context in
        if let s = store.solution {
          SolutionView(
            solution: s, now: context.date,
            pending: WatchFormat.pendingNotice(requested: store.requestedRange, solution: s))
        } else {
          MessageView(title: "Telefon bekleniyor", detail: "Telefonda SNIPER TÜRK Atış sekmesini açın")
        }
      }
    }
  }
}

struct MessageView: View {
  let title: String
  let detail: String

  var body: some View {
    VStack(spacing: 8) {
      Text(title).font(.system(size: 18, weight: .regular))
      Text(detail)
        .font(.system(size: 14, weight: .regular))
        .foregroundStyle(Palette.dim)
        .multilineTextAlignment(.center)
    }
    .padding()
  }
}

struct SolutionView: View {
  let solution: WatchSolution
  let now: Date
  let pending: String?

  var body: some View {
    if !solution.ok {
      VStack(spacing: 6) {
        Text(solution.profile).font(.system(size: 16, weight: .regular))
        MessageView(title: "Çözüm yok", detail: "Telefonda hesaplayın")
      }
    } else {
      let stale = WatchFormat.staleNotice(at: solution.at, now: now)
      ScrollView {
        VStack(spacing: 4) {
          Text(solution.profile)
            .font(.system(size: 16, weight: .regular))
            .lineLimit(1)
          NavigationLink {
            RangeEditView(solution: solution)
          } label: {
            Text("\(solution.range) \(solution.rangeUnit)")
              .font(.system(size: 22, weight: .regular))
              .foregroundStyle(stale == nil ? Palette.cyan : Palette.dim)
          }
          .buttonStyle(.plain)
          TurretRow(
            label: WatchFormat.elevationLabel(solution.up),
            value: WatchFormat.elevation(solution.up),
            detail: WatchFormat.angle(solution.upAngle, unit: solution.unit),
            color: stale == nil ? Palette.amber : Palette.dim, size: 40)
          TurretRow(
            label: WatchFormat.windageLabel(solution.right),
            value: WatchFormat.windage(solution.right),
            detail: WatchFormat.angle(solution.rightAngle, unit: solution.unit),
            color: stale == nil ? .white : Palette.dim, size: 32)
          if let pending {
            Text(pending)
              .font(.system(size: 13, weight: .regular))
              .foregroundStyle(Palette.warn)
              .multilineTextAlignment(.center)
          }
          if let stale {
            VStack(spacing: 2) {
              Text(stale)
              Text("Telefonda çözümü açın")
            }
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(Palette.warn)
            .padding(6)
            .frame(maxWidth: .infinity)
            .background(Palette.warn.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
          }
          Group {
            if let wind = WatchFormat.wind(
              speed: solution.windSpeed, unit: solution.windUnit, clock: solution.windClock)
            {
              Text(wind)
            }
            Text(WatchFormat.unitLine(unit: solution.unit, click: solution.click))
            Text(WatchFormat.updated(solution.at))
          }
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(Palette.dim)
        }
      }
    }
  }
}

struct TurretRow: View {
  let label: String
  let value: String
  let detail: String
  let color: Color
  let size: CGFloat

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(label)
        .font(.system(size: 13, weight: .regular))
        .foregroundStyle(Palette.dim)
      Spacer()
      VStack(alignment: .trailing, spacing: 0) {
        Text(value)
          .font(.system(size: size, weight: .regular))
          .foregroundStyle(color)
        Text(detail)
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(Palette.dim)
      }
    }
  }
}
