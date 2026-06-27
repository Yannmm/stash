import Foundation

struct SidecarData: Codable, Equatable {
    let uid: String
    let timestamp: Date
    let device: String

    static func stamp() -> SidecarData {
        SidecarData(
            uid: UUID().uuidString,
            timestamp: Date(),
            device: Host.current().localizedName ?? "Unknown"
        )
    }
}
