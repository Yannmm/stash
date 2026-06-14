//
//  File+Extension.swift
//  Stash
//
//  Created by Yan Meng on 2026/6/3.
//

import Foundation

enum FileHelper {
    static func replaceFile(from source: URL, to destination: URL) async throws {
        try await Task.detached(priority: .utility) {
            let fm = FileManager.default

            if fm.fileExists(atPath: destination.path) {
                try fm.removeItem(at: destination)
            }

            try fm.copyItem(at: source, to: destination)
        }.value
    }
}
