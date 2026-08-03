import Foundation

struct Network: Identifiable, Hashable {
  let id = UUID()
  var name = ""
  var isSecured = true
  var connectivity = 1.0
}

extension [Network] {
  static let mocks = [
    Network(
      name: "nachos",
      isSecured: true,
      connectivity: 0.5
    ),
    Network(
      name: "nachos 5G",
      isSecured: true,
      connectivity: 0.75
    ),
    Network(
      name: "Blob Jr's LAN PARTY",
      isSecured: true,
      connectivity: 0.2
    ),
    Network(
      name: "Blob's World",
      isSecured: false,
      connectivity: 1
    ),
  ]
}

let goofyWiFiNames = [
  "AirSpace1",
  "Living Room",
  "Courage",
  "Nacho WiFi",
  "FBI Surveillance Van",
  "Peacock-Swagger",
  "GingerGymnist",
  "Second Floor",
  "Evergreen",
  "__hidden_in_plain__sight__",
  "MarketingDropBox",
  "HamiltonVille",
  "404NotFound",
  "SNAGVille",
  "Overland101",
  "TheRoomWiFi",
  "PrivateSpace",
]
