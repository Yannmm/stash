import Foundation

struct Sidecar: Codable, Equatable {
    let uid: UUID
    let timestamp: Date
    let device: String

    static func stamp() -> Sidecar {
        Sidecar(
            uid: UUID(),
            timestamp: Date(),
            device: Host.current().localizedName ?? "Unknown"
        )
    }
}
