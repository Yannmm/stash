//
//  StashApp.swift
//  stash
//
//  Created by Yan Meng on 2025/1/26.
//

import SwiftUI

@main
struct StashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
