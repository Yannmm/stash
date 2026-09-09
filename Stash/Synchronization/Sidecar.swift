import Foundation

struct Sidecar: Codable, Equatable {
    let uid: UUID
    let timestamp: Date
    let prettyTimestamp: String?
    let device: String

    static func stamp() -> Sidecar {
        let timestamp = Date()

        return Sidecar(
            uid: UUID(),
            timestamp: timestamp,
            prettyTimestamp: timestamp.formatted(
                date: .numeric,
                time: .standard
            ),
            device: Host.current().localizedName ?? "Unknown"
        )
    }
}
