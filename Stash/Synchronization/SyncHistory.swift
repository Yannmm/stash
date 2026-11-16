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
        private let queue = DispatchQueue(label: "com.stash.sync-history")
        private var _entries: [Entry] = []

        var entries: [Entry] { queue.sync { _entries } }

        init(fileURL: URL? = nil) {
            if let fileURL {
                self.fileURL = fileURL
            } else {
                let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                let dir = support.appendingPathComponent("Stash", isDirectory: true)
                if !FileManager.default.fileExists(atPath: dir.path) {
                    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                }
                self.fileURL = dir.appendingPathComponent("sync_history.json")
            }
            queue.sync { load() }
        }

        func log(action: String, sidecar: Sidecar) {
            queue.sync {
                let entry = Entry(timestamp: sidecar.timestamp, device: sidecar.device, action: action)
                _entries.append(entry)
                if _entries.count > cap {
                    _entries = Array(_entries.suffix(cap))
                }
                save()
            }
        }

        private func load() {
            guard let data = try? Data(contentsOf: fileURL) else { return }
            _entries = (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
        }

        private func save() {
            guard let data = try? JSONEncoder().encode(_entries) else { return }
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
