//
//  UpdateChecker.swift
//  Stash
//
//  Created by Yan Meng on 2025/10/16.
//

import Foundation
import AppKit

extension UpdateChecker {
    enum SomeError: Error, LocalizedError {
        case missingDownloadsUrl
        case missingImportFileType
    }
}

extension UpdateChecker {
    struct AppStore {
        let version: String
        let releaseNotes: String?
    }
}

final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    private init() {}
    
    @Published var new: AppStore?
    
    var current: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    func check() async throws {
        let latest = try await _check()
        
        guard let c = current else {
            self.new = latest
            return
        }
        guard c.compare(latest.version, options: .numeric) == .orderedAscending else { return }
        self.new = latest
    }
    
    func go() {
        NSWorkspace.shared.open(Constant.appStoreStall)
    }
    
    private func _check() async throws -> AppStore {
        let (data, _) = try await URLSession.shared.data(from: Constant.appStoreInfo)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let results = json["results"] as? [[String: Any]],
        let stashy = results.first,
        let version = stashy["version"] as? String
        else { throw SomeError.missingDownloadsUrl }
        let notes = stashy["releaseNotes"] as? String
        return AppStore(version: version, releaseNotes: notes)
    }

    private func showUpdateAlert(latest: String, notes: String) {
        let alert = NSAlert()
        alert.messageText = "A new version (\(latest)) is available!"
        alert.informativeText = notes
        alert.addButton(withTitle: "Update Now")
        alert.addButton(withTitle: "Later")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(Constant.appStoreInfo)
        }
    }

    private func showNoUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "You're up to date!"
        alert.informativeText = "You’re running the latest version of the app."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

fileprivate extension UpdateChecker {
    enum Constant {
        static let appStoreInfo = URL(string: "https://itunes.apple.com/lookup?id=6745811044")!
        static let appStoreStall = URL(string: "https://apps.apple.com/cn/app/stashy/id6745811044?l=en-GB&mt=12")!
    }
}
