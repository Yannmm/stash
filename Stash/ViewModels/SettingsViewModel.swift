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
    @Published var synchronizerApproach: Synchronizer.Approach
    
    private var cancellables = Set<AnyCancellable>()
    private let pieceSaver = PieceSaver()
    private let appHotKeyManager = HotKeyManager(action: .menu)
    private let searchHotKeyManager = HotKeyManager(action: .search)
    private let housekeeper: Housekeeper
    
    // TODO: add checking status in menu when is checking
//        self.approach = pieceSaver.value(for: PieceSaver.Key.synchronizerApproach) ?? .local
    
    
    var empty: Bool { housekeeper.storedEntries.isEmpty }
    
    private lazy var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // Ensures consistent formatting
        formatter.dateFormat = "yyyy-MM-dd'T'HH_mm_ssZ"
        return formatter
    }()
    
    func reset() throws {
        try housekeeper.removeAll()
    }
    
    
    func export() throws {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw SomeError.missingDownloadsUrl
        }
        exportDestinationDirectory = downloads
    }
    
    func `import`(_ filePath: URL, fileType: String.FileType, replace: Bool) throws {
        try housekeeper.import(from: filePath, fileType: fileType, replace: replace)
        self.importFromFile = filePath
    }
    
    init(housekeeper: Housekeeper) {
        self.housekeeper = housekeeper
        collapseHistory = pieceSaver.value(for: PieceSaver.Key.collapseHistory) ?? false
        launchOnLogin = RocketLauncher.shared.enabled
        showDockIcon = pieceSaver.value(for: PieceSaver.Key.showDockIcon) ?? false
        synchronizerApproach = pieceSaver.value(for: PieceSaver.Key.synchronizerApproach) ?? .local
        
        if let code = pieceSaver.value(for: PieceSaver.Key.appShortcut),
           let key = Key(carbonKeyCode: code),
           let modifiers = pieceSaver.value(for: PieceSaver.Key.appShortcutModifiers) {
            appShortcut = (key, NSEvent.ModifierFlags(rawValue: modifiers))
        }
        
        if let code = pieceSaver.value(for: PieceSaver.Key.searchShortcut),
           let key = Key(carbonKeyCode: code),
           let modifiers = pieceSaver.value(for: PieceSaver.Key.searchShortcutModifiers) {
            searchShortcut = (key, NSEvent.ModifierFlags(rawValue: modifiers))
        }
        
        self.setAppIdentifier()
        
        bind()
    }
    
    private func bind() {
        $collapseHistory
            .dropFirst()
            .sink { [weak self] in
                self?.pieceSaver.save(for: PieceSaver.Key.collapseHistory, value: $0)
            }
            .store(in: &cancellables)
        
        // Handle launch at login changes
        $launchOnLogin
            .dropFirst()
            .sink { [weak self] enabled in
                RocketLauncher.shared.enabled = enabled
                self?.pieceSaver.save(for: PieceSaver.Key.launchOnLogin, value: enabled)
            }
            .store(in: &cancellables)
        
        $showDockIcon
            .dropFirst()
            .sink { [weak self] in
                //                NSApp.setActivationPolicy($0 ? .regular : .accessory)
                self?.pieceSaver.save(for: PieceSaver.Key.showDockIcon, value: $0)
            }
            .store(in: &cancellables)
        
        $appShortcut
            .sink { [weak self] tuple2 in
                if let t2 = tuple2 {
                    self?.appHotKeyManager.register(shortcut: t2)
                } else {
                    self?.appHotKeyManager.unregister()
                }
                self?.pieceSaver.save(for: PieceSaver.Key.appShortcut, value: tuple2?.0.carbonKeyCode)
                self?.pieceSaver.save(for: PieceSaver.Key.appShortcutModifiers, value: tuple2?.1.rawValue)
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
                self?.pieceSaver.save(for: PieceSaver.Key.searchShortcut, value: tuple2?.0.carbonKeyCode)
                self?.pieceSaver.save(for: PieceSaver.Key.searchShortcutModifiers, value: tuple2?.1.rawValue)
            }
            .store(in: &cancellables)
        
        $exportDestinationDirectory
            .dropFirst()
            .compactMap({ $0 })
            .sink { [unowned self] in
                do {
                    self.exportToFile = try self.housekeeper.export(to: $0, suffix: "_\(self.timestampFormatter.string(from: Date.now))")
                } catch {
                    self.error = error
                }
            }
            .store(in: &cancellables)
        
//        updateChcker.$new
//            .sink { [unowned self] update in
//                if let v = update {
//                    self.checkedVersionDescription = "New Version Available: \(v.version)"
//                } else {
//                    self.checkedVersionDescription = "You're Up to Date"
//                }
//                self.newReleaseNotes = update?.releaseNotes
//            }
//            .store(in: &cancellables)
        
        $synchronizerApproach
            .dropFirst()
            .sink { [weak self] in
                self?.housekeeper.synchronizer.approach = $0
                // 如果 approach 切换失败，这里不应该保存，而是应该给用户提示,并退回之前的选择
                self?.pieceSaver.save(for: PieceSaver.Key.synchronizerApproach, value: $0)
            }
            .store(in: &cancellables)
        
        $error
            .compactMap({ $0 })
            .sink { ErrorTracker.shared.add($0)}
            .store(in: &cancellables)
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
        
        guard pieceSaver.value(for: PieceSaver.Key.appIdentifier) == nil else { return }
        pieceSaver.save(for: PieceSaver.Key.appIdentifier, value: UUID().uuidString)
    }
}

extension SettingsViewModel {
    enum SomeError: Error, LocalizedError {
        case missingDownloadsUrl
        case missingImportFileType
    }
}
