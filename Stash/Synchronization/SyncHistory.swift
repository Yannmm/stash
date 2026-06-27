import Foundation

extension Synchronizer {
    final class History {
        struct Entry: Codable {
            let timestamp: Date
            let device: String
            let action: String
        }

        private let fileURL: URL
        private let cap = 100
        private(set) var entries: [Entry] = []

        init() {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = support.appendingPathComponent("Stash", isDirectory: true)
            if !FileManager.default.fileExists(atPath: dir.path) {
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            fileURL = dir.appendingPathComponent("sync_history.json")
            load()
        }

        func log(action: String, sidecar: SidecarData) {
            let entry = Entry(timestamp: sidecar.timestamp, device: sidecar.device, action: action)
            entries.append(entry)
            if entries.count > cap {
                entries = Array(entries.suffix(cap))
            }
            save()
        }

        private func load() {
            guard let data = try? Data(contentsOf: fileURL) else { return }
            entries = (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
        }

        private func save() {
            guard let data = try? JSONEncoder().encode(entries) else { return }
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
