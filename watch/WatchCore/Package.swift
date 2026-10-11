// swift-tools-version:5.9
// Saat uygulamasının test edilebilir çekirdeği: mesaj çözümü ve Türkçe
// biçimlendirme. Balistik hesap YOK; hesap telefonda yapılır.
import PackageDescription

let package = Package(
  name: "WatchCore",
  platforms: [.watchOS(.v10), .macOS(.v13)],
  products: [.library(name: "WatchCore", targets: ["WatchCore"])],
  targets: [
    .target(name: "WatchCore"),
    .testTarget(name: "WatchCoreTests", dependencies: ["WatchCore"]),
  ]
)
