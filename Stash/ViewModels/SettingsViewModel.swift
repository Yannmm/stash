//
//  SettingsView.swift
//  Stash
//
//  Created by Yan Meng on 2025/4/27.
//

import AppKit
import Combine
import HotKey
import CombineExt
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var collapseHistory: Bool
    @Published var icloudSync: Bool
    @Published var launchOnLogin: Bool
    @Published var showDockIcon: Bool
    @Published var importFromFile: URL?
    @Published var exportDestinationDirectory: URL?
    @Published var exportToFile: URL?
    @Published var appShortcut: (Key, NSEvent.ModifierFlags)?
    @Published var searchShortcut: (Key, NSEvent.ModifierFlags)?
    @Published var isAppGlobalShortcutRecording = false
    @Published var isSearchGlobalShortcutRecording = false
    @Published var checkedVersionDescription: String = ""
    @Published var newReleaseNotes: String?
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let pieceSaver = PieceSaver()
    private let appHotKeyManager = HotKeyManager(action: .menu)
    private let searchHotKeyManager = HotKeyManager(action: .search)
    private let cabinet: OkamuraCabinet
    @ObservedObject var updateChcker: UpdateChecker
    
    var empty: Bool { cabinet.storedEntries.isEmpty }
    
    private lazy var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // Ensures consistent formatting
        formatter.dateFormat = "yyyy-MM-dd'T'HH_mm_ssZ"
        return formatter
    }()
    
    func reset() throws {
        try cabinet.removeAll()
    }
    
    
    func export() throws {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw SomeError.missingDownloadsUrl
        }
        exportDestinationDirectory = downloads
    }
    
    func `import`(_ filePath: URL, fileType: String.FileType, replace: Bool) throws {
        try cabinet.import(from: filePath, fileType: fileType, replace: replace)
        self.importFromFile = filePath
    }
    
    func goToAppStore() {
        updateChcker.go()
    }
    
    init(cabinet: OkamuraCabinet, updateChecker: UpdateChecker) {
        self.cabinet = cabinet
        self.updateChcker = updateChecker
        collapseHistory = pieceSaver.value(for: .collapseHistory) ?? false
        icloudSync = pieceSaver.value(for: .icloudSync) ?? true
        launchOnLogin = RocketLauncher.shared.enabled
        showDockIcon = pieceSaver.value(for: .showDockIcon) ?? false
        
        if let code: UInt32 = pieceSaver.value(for: .appShortcut),
           let key = Key(carbonKeyCode: code),
           let modifiers: UInt = pieceSaver.value(for: .appShortcutModifiers) {
            appShortcut = (key, NSEvent.ModifierFlags(rawValue: modifiers))
        }
        
        if let code: UInt32 = pieceSaver.value(for: .searchShortcut),
           let key = Key(carbonKeyCode: code),
           let modifiers: UInt = pieceSaver.value(for: .searchShortcutModifiers) {
            searchShortcut = (key, NSEvent.ModifierFlags(rawValue: modifiers))
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
                    self?.cabinet.monitorIcloud()
                } catch {
                    self?.error = error
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
        
        $appShortcut
            .sink { [weak self] tuple2 in
                if let t2 = tuple2 {
                    self?.appHotKeyManager.register(shortcut: t2)
                } else {
                    self?.appHotKeyManager.unregister()
                }
                self?.pieceSaver.save(for: .appShortcut, value: tuple2?.0.carbonKeyCode)
                self?.pieceSaver.save(for: .appShortcutModifiers, value: tuple2?.1.rawValue)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest($isAppGlobalShortcutRecording, $isSearchGlobalShortcutRecording)
            .map({ $0.0 || $0.1 })
            .withLatestFrom($appShortcut, $searchShortcut, resultSelector: { ($0, $1.0, $1.1) })
            .sink { [weak self] in
                if !$0.0 {
                    if let x = $0.1 {
                        self?.appHotKeyManager.register(shortcut: x)
                    }
                    if let x = $0.2 {
                        self?.searchHotKeyManager.register(shortcut: x)
                    }
                } else {
                    self?.appHotKeyManager.unregister()
                    self?.searchHotKeyManager.unregister()
                }
            }
            .store(in: &cancellables)
        
        $searchShortcut
            .sink { [weak self] tuple2 in
                if let t2 = tuple2 {
                    self?.searchHotKeyManager.register(shortcut: t2)
                } else {
                    self?.searchHotKeyManager.unregister()
                }
                self?.pieceSaver.save(for: .searchShortcut, value: tuple2?.0.carbonKeyCode)
                self?.pieceSaver.save(for: .searchShortcutModifiers, value: tuple2?.1.rawValue)
            }
            .store(in: &cancellables)
        
        $exportDestinationDirectory
            .dropFirst()
            .compactMap({ $0 })
            .sink { [unowned self] in
                do {
                    self.exportToFile = try self.cabinet.export(to: $0, suffix: "_\(self.timestampFormatter.string(from: Date.now))")
                } catch {
                    self.error = error
                }
            }
            .store(in: &cancellables)
        
        updateChcker.$new
            .sink { [unowned self] update in
                if let v = update {
                    self.checkedVersionDescription = "New Version Available: \(v.version)"
                } else {
                    self.checkedVersionDescription = "You're Up to Date"
                }
                self.newReleaseNotes = update?.releaseNotes
            }
            .store(in: &cancellables)
        
        $error
            .compactMap({ $0 })
            .sink { ErrorTracker.shared.add($0)}
            .store(in: &cancellables)
        
//        Task {
//            do {
//                let a = try await updateChcker.check()
//                newVersion = a?.releaseNotes
//            } catch {
//                self.error = error
//            }
//        }
    }
    
    var currentVersionDescription: String {
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
        pieceSaver.save(for: .appIdentifier, value: UUID().uuidString)
    }
}

extension SettingsViewModel {
    enum SomeError: Error, LocalizedError {
        case missingDownloadsUrl
        case missingImportFileType
    }
}
