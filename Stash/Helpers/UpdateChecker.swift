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
    enum Mode {
        case appStore
        case github
    }

    struct Release {
        let version: String
        let build: String?
        let releaseNotes: String?
        let url: URL
    }
}

final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    let mode: Mode

    private init(mode: Mode = .github) {
        self.mode = mode
    }

    @Published var new: Release?

    var currentVersion: String? {
        Bundle.main.version
    }

    var currentBuild: String? {
        Bundle.main.buildNumber
    }

    func check() async throws {
        let latest = try await fetchLatest()

        guard let cv = currentVersion else {
            self.new = latest
            return
        }

        let versionComparison = cv.compare(latest.version, options: .numeric)

        if versionComparison == .orderedAscending {
            self.new = latest
            return
        }

        if versionComparison == .orderedSame,
           let cb = currentBuild,
           let lb = latest.build,
           cb.compare(lb, options: .numeric) == .orderedAscending {
            self.new = latest
            return
        }
    }

    func go() {
        if let release = new {
            NSWorkspace.shared.open(release.url)
        } else {
            NSWorkspace.shared.open(Constant.defaultURL(for: mode))
        }
    }

    private func fetchLatest() async throws -> Release {
        switch mode {
        case .appStore:
            return try await fetchFromAppStore()
        case .github:
            return try await fetchFromGitHub()
        }
    }

    private func fetchFromAppStore() async throws -> Release {
        let (data, _) = try await URLSession.shared.data(from: Constant.appStoreInfo)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let stash = results.first,
              let version = stash["version"] as? String
        else { throw SomeError.missingDownloadsUrl }
        let notes = stash["releaseNotes"] as? String
        return Release(version: version, build: nil, releaseNotes: notes, url: Constant.appStoreInstall)
    }

    private func fetchFromGitHub() async throws -> Release {
        var request = URLRequest(url: Constant.githubLatestRelease)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String
        else { throw SomeError.missingDownloadsUrl }

        let notes = json["body"] as? String
        let htmlURL = (json["html_url"] as? String).flatMap(URL.init(string:)) ?? Constant.githubReleases

        let (version, build) = Self.parseTag(tagName)
        return Release(version: version, build: build, releaseNotes: notes, url: htmlURL)
    }

    // Parses tags like "v3.1.2", "3.1.2", "v3.1.2+45", "3.1.2(45)"
    static func parseTag(_ tag: String) -> (version: String, build: String?) {
        var s = tag
        if s.hasPrefix("v") || s.hasPrefix("V") {
            s = String(s.dropFirst())
        }

        // "3.1.2+45" or "3.1.2(45)"
        if let plusIdx = s.firstIndex(of: "+") {
            let version = String(s[s.startIndex..<plusIdx])
            let build = String(s[s.index(after: plusIdx)...])
            return (version, build.isEmpty ? nil : build)
        }

        if let openParen = s.firstIndex(of: "("),
           let closeParen = s.firstIndex(of: ")") {
            let version = String(s[s.startIndex..<openParen])
            let build = String(s[s.index(after: openParen)..<closeParen])
            return (version, build.isEmpty ? nil : build)
        }

        return (s, nil)
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
        alert.informativeText = "You're running the latest version of the app."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

fileprivate extension UpdateChecker {
    enum Constant {
        static let appStoreInfo = URL(string: "https://itunes.apple.com/lookup?id=6745811044")!
        static let appStoreInstall = URL(string: "https://apps.apple.com/cn/app/stashy/id6745811044?l=en-GB&mt=12")!
        static let githubLatestRelease = URL(string: "https://api.github.com/repos/Yannmm/stash/releases/latest")!
        static let githubReleases = URL(string: "https://github.com/Yannmm/stash/releases")!

        static func defaultURL(for mode: Mode) -> URL {
            switch mode {
            case .appStore: appStoreInstall
            case .github: githubReleases
            }
        }
    }
}
