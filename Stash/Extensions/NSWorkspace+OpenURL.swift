//
//  AppDelegate+OpenURL.swift
//  Stash
//
//  Created by Rayman on 2025/7/2.
//

import AppKit

extension NSWorkspace {
    func openURL(_ url: URL, withPreferredBrowser browser: String?) {
        if let b = browser {
            let path = "/Applications/\(b).app"
            if FileManager.default.fileExists(atPath: path) {
                // Browser is installed, open with it
                NSWorkspace.shared.open(
                    [url],
                    withApplicationAt: URL(fileURLWithPath: path),
                    configuration: NSWorkspace.OpenConfiguration(),
                    completionHandler: nil
                )
                return
            }
        }
        // Fallback to default browser
        NSWorkspace.shared.open(url)
    }
}
