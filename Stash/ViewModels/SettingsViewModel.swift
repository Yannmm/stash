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
    @Published var synchronizerApproach: Synchronizer.Option
    @Published var availability: Synchronizer.Availability?

    var onCheckAvailability: ((Synchronizer.Option) async -> Synchronizer.Availability)?

    func refreshAvailability() {
        guard let check = onCheckAvailability else { return }
        let current = synchronizerApproach
        Task { @MainActor in
            self.availability = await check(current)
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private let appHotKeyManager = HotKeyManager(action: .menu)
    private let searchHotKeyManager = HotKeyManager(action: .search)
    
    private let onReset: () throws -> Void
    private let onImport: (URL, String.FileType, Bool) throws -> Void
    private let onExport: (URL, String?) throws -> URL
    private let onChangeApproach: (Synchronizer.Option) -> Void
    
    // TODO: add checking status in menu when is checking
    //        self.approach = Pref.value(for: PieceSaver.Key.synchronizerApproach) ?? .local
    
    
    var empty: Bool { false }
    
    private lazy var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // Ensures consistent formatting
        formatter.dateFormat = "yyyy-MM-dd'T'HH_mm_ssZ"
        return formatter
    }()
    
    func reset() throws {
        try self.onReset()
    }
    
    
    func export() throws {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw SomeError.missingDownloadsUrl
        }
        exportDestinationDirectory = downloads
    }
    
    func `import`(_ filePath: URL, fileType: String.FileType, replace: Bool) throws {
        try self.onImport(filePath, fileType, replace)
        self.importFromFile = filePath
    }
    
    init(
        provider: Synchronizer.Option,
        onReset: @escaping () throws -> Void,
        onImport: @escaping (URL, String.FileType, Bool) throws -> Void,
        onExport: @escaping (URL, String?) throws -> URL,
        onChangeApproach: @escaping (Synchronizer.Option) -> Void
    ) {
        self.onReset = onReset
        self.onImport = onImport
        self.onExport = onExport
        self.onChangeApproach = onChangeApproach
        
        collapseHistory = Pref.value(for: Pref.Key.collapseHistory) ?? false
        launchOnLogin = RocketLauncher.shared.enabled
        showDockIcon = Pref.value(for: Pref.Key.showDockIcon) ?? false
        synchronizerApproach = provider
        
        if let code = Pref.value(for: Pref.Key.appShortcut),
           let key = Key(carbonKeyCode: code),
           let modifiers = Pref.value(for: Pref.Key.appShortcutModifiers) {
            appShortcut = (key, NSEvent.ModifierFlags(rawValue: modifiers))
        }
        
        if let code = Pref.value(for: Pref.Key.searchShortcut),
           let key = Key(carbonKeyCode: code),
           let modifiers = Pref.value(for: Pref.Key.searchShortcutModifiers) {
            searchShortcut = (key, NSEvent.ModifierFlags(rawValue: modifiers))
        }

        bind()
    }
    
    private func bind() {
        $collapseHistory
            .dropFirst()
            .sink { [weak self] in
                Pref.save(for: Pref.Key.collapseHistory, value: $0)
            }
            .store(in: &cancellables)
        
        // Handle launch at login changes
        $launchOnLogin
            .dropFirst()
            .sink { [weak self] enabled in
                RocketLauncher.shared.enabled = enabled
                Pref.save(for: Pref.Key.launchOnLogin, value: enabled)
            }
            .store(in: &cancellables)
        
        $showDockIcon
            .dropFirst()
            .sink { [weak self] in
                //                NSApp.setActivationPolicy($0 ? .regular : .accessory)
                Pref.save(for: Pref.Key.showDockIcon, value: $0)
            }
            .store(in: &cancellables)
        
        $appShortcut
            .sink { [weak self] tuple2 in
                if let t2 = tuple2 {
                    self?.appHotKeyManager.register(shortcut: t2)
                } else {
                    self?.appHotKeyManager.unregister()
                }
                Pref.save(for: Pref.Key.appShortcut, value: tuple2?.0.carbonKeyCode)
                Pref.save(for: Pref.Key.appShortcutModifiers, value: tuple2?.1.rawValue)
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
                Pref.save(for: Pref.Key.searchShortcut, value: tuple2?.0.carbonKeyCode)
                Pref.save(for: Pref.Key.searchShortcutModifiers, value: tuple2?.1.rawValue)
            }
            .store(in: &cancellables)
        
        $exportDestinationDirectory
            .dropFirst()
            .compactMap({ $0 })
            .sink { [unowned self] in
                do {
                    self.exportToFile = try self.onExport($0, "_\(self.timestampFormatter.string(from: Date.now))")
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
                self?.onChangeApproach($0)
                Pref.save(for: Pref.Key.synchronizerApproach, value: $0)
                self?.refreshAvailability()
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
}

extension SettingsViewModel {
    enum SomeError: Error, LocalizedError {
        case missingDownloadsUrl
        case missingImportFileType
    }
}
