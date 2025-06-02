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
    @Published var importFromFile: (Bool, URL)?
    @Published var exportToDirectory: URL?
    @Published var shortcut: (Key, NSEvent.ModifierFlags)?
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
            ErrorTracker.shared.add(error)
        }
    }
    
    func importHungrymarks(_ filePath: URL) {
        do {
            try cabinet.importHungrymarks(from: filePath)
        } catch {
            self.error = error
            ErrorTracker.shared.add(error)
        }
    }
    
    init(hotKeyManager: HotKeyManager, cabinet: OkamuraCabinet) {
        self.hotKeyManager = hotKeyManager
        self.cabinet = cabinet
        collapseHistory = pieceSaver.value(for: .collapseHistory) ?? false
        icloudSync = pieceSaver.value(for: .icloudSync) ?? true
        launchOnLogin = RocketLauncher.shared.enabled
        showDockIcon = pieceSaver.value(for: .showDockIcon) ?? false
        
        if let code: UInt32 = pieceSaver.value(for: .hotkey),
           let key = Key(carbonKeyCode: code),
           let modifiers: UInt = pieceSaver.value(for: .hokeyModifiers) {
            shortcut = (key, NSEvent.ModifierFlags(rawValue: modifiers))
        }
        
        self.setAppIdentifier()
        
        bind()
    }
    
    private func bind() {
        $collapseHistory
            .dropFirst()
            .sink { [weak self] in
                self?.pieceSaver.save(for: .collapseHistory, value: $0)
            }
            .store(in: &cancellables)
        $icloudSync
            .dropFirst()
            .sink { [weak self] in
                self?.pieceSaver.save(for: .icloudSync, value: $0)
                do {
                    try self?.cabinet.save()
                } catch {
                    self?.error = error
                    ErrorTracker.shared.add(error)
                }
            }
            .store(in: &cancellables)
        
        // Handle launch at login changes
        $launchOnLogin
            .dropFirst()
            .sink { [weak self] enabled in
                RocketLauncher.shared.enabled = enabled
                self?.pieceSaver.save(for: .launchOnLogin, value: enabled)
            }
            .store(in: &cancellables)
        $showDockIcon
            .dropFirst()
            .sink { [weak self] in
                //                NSApp.setActivationPolicy($0 ? .regular : .accessory)
                self?.pieceSaver.save(for: .showDockIcon, value: $0)
            }
            .store(in: &cancellables)
        $shortcut
            .dropFirst()
            .sink { [weak self] tuple2 in
                if let t2 = tuple2 {
                    self?.hotKeyManager.register(shortcut: t2)
                } else {
                    self?.hotKeyManager.unregister()
                }
                self?.pieceSaver.save(for: .hotkey, value: tuple2?.0.carbonKeyCode)
                self?.pieceSaver.save(for: .hokeyModifiers, value: tuple2?.1.rawValue)
            }
            .store(in: &cancellables)
        
        $shortcut
            .compactMap({ $0 })
            .sink { [weak self] in
                self?.hotKeyManager.register(shortcut: $0)
            }
            .store(in: &cancellables)
        
        $importFromFile
            .compactMap({ $0 })
            .sink { [weak self] in
                do {
                    if $0.0 {
                        try self?.cabinet.import(from: $0.1)
                    } else {
                        try self?.cabinet.importHungrymarks(from: $0.1)
                    }
                } catch {
                    self?.error = error
                    ErrorTracker.shared.add(error)
                }
            }
            .store(in: &cancellables)
        $exportToDirectory
            .dropFirst()
            .compactMap({ $0 })
            .sink { [weak self] in
                do {
                    try self?.cabinet.export(to: $0)
                } catch {
                    self?.error = error
                    ErrorTracker.shared.add(error)
                }
            }
            .store(in: &cancellables)
    }
    
    var versionDescription: String {
        var result = " ("
        
        if let version = Bundle.main.version {
            result += "v\(version)"
        }
        if let build = Bundle.main.buildNumber {
            result += "·b\(build)"
        }
        return result + ")"
    }
    
    private func setAppIdentifier() {
        guard let id: UUID? = pieceSaver.value(for: .appIdentifier), id == nil else { return }
        pieceSaver.save(for: .appIdentifier, value: UUID())
    }
}
