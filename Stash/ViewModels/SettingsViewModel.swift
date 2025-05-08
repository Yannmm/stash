//
//  SettingsView.swift
//  Stash
//
//  Created by Yan Meng on 2025/4/27.
//

import AppKit
import Combine
import HotKey

class SettingsViewModel: ObservableObject {
    @Published var collapseHistory: Bool
    @Published var icloudSync: Bool
    @Published var launchOnLogin: Bool
    @Published var showDockIcon: Bool
    @Published var importFromFile: URL?
    @Published var exportToDirectory: URL?
    @Published var shortcut: (Key, NSEvent.ModifierFlags)
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let pieceSaver = PieceSaver()
    private let hotKeyManager: HotKeyManager
    private let cabinet: OkamuraCabinet
    
    func reset() {
        do {
            try cabinet.removeAll()
        } catch {
            self.error = error
        }
    }
    
    init(hotKeyManager: HotKeyManager, cabinet: OkamuraCabinet) {
        self.hotKeyManager = hotKeyManager
        self.cabinet = cabinet
        collapseHistory = pieceSaver.value(for: .collapseHistory) ?? false
        icloudSync = pieceSaver.value(for: .icloudSync) ?? false
        launchOnLogin = pieceSaver.value(for: .launchOnLogin) ?? false
        showDockIcon = pieceSaver.value(for: .showDockIcon) ?? false
        
        var key: Key?
        if let saved: UInt32 = pieceSaver.value(for: .hotkey) {
            key = Key(carbonKeyCode: saved)
        }
        if key == nil {
            key = Key(string: "s")
        }
        
        var modifiers: NSEvent.ModifierFlags?
        if let saved: UInt = pieceSaver.value(for: .hokeyModifiers) {
            modifiers = NSEvent.ModifierFlags(rawValue: saved)
        }
        if modifiers == nil {
            modifiers = NSEvent.ModifierFlags([.shift, .command])
        }
        shortcut = (key!, modifiers!)
        
        $collapseHistory
            .sink { [weak self] in
                self?.pieceSaver.save(for: .collapseHistory, value: $0)
            }
            .store(in: &cancellables)
        $icloudSync
            .sink { [weak self] in
                self?.pieceSaver.save(for: .icloudSync, value: $0)
            }
            .store(in: &cancellables)
        $launchOnLogin
            .sink { [weak self] in
                self?.pieceSaver.save(for: .launchOnLogin, value: $0)
            }
            .store(in: &cancellables)
        $showDockIcon
            .sink { [weak self] in
//                NSApp.setActivationPolicy($0 ? .regular : .accessory)
                self?.pieceSaver.save(for: .showDockIcon, value: $0)
            }
            .store(in: &cancellables)
        $shortcut
            .sink { [weak self] in
                hotKeyManager.register(shortcut: $0)
                self?.pieceSaver.save(for: .hotkey, value: $0.0.carbonKeyCode)
                self?.pieceSaver.save(for: .hokeyModifiers, value: $0.1.rawValue)
            }
            .store(in: &cancellables)
        $importFromFile
            .compactMap({ $0 })
            .sink { [weak self] in
                do {
                    try self?.cabinet.import(from: $0)
                } catch {
                    self?.error = error
                }
            }
            .store(in: &cancellables)
        $exportToDirectory
            .compactMap({ $0 })
            .sink { [weak self] in
                do {
                    try self?.cabinet.export(to: $0)
                } catch {
                    self?.error = error
                }
            }
            .store(in: &cancellables)
    }
}
