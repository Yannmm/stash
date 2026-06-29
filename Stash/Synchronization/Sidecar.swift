import Foundation

struct Sidecar: Codable, Equatable {
    let uid: String
    let timestamp: Date
    let device: String

    static func stamp() -> Sidecar {
        Sidecar(
            uid: UUID().uuidString,
            timestamp: Date(),
            device: Host.current().localizedName ?? "Unknown"
        )
    }
}
