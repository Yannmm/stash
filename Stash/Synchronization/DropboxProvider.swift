//
//  DropboxProvider.swift
//  Stash
//
//  Created by Yan Meng on 2026/5/10.
//

import Foundation
import Combine
import SwiftyDropbox
import AppKit
import SwiftUI

extension Synchronizer {
    final class DropboxProvider: Provider {
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }
        
        var availability: AnyPublisher<Availability, Never> { _availability.eraseToAnyPublisher() }
        private let _availability = CurrentValueSubject<Availability, Never>(.pending(InitialPendingState(name: "Dropbox")))
        
        private var _sdkInitialized = false
        
        init() {}
        
        @discardableResult
        func checkAvailability() async -> Availability {
            let a: Availability = .pending(Authentication.anonymous({ [weak self] in
                self?.authenticate()
            }))
            defer { _availability.send(a) }
            return a
        }
        
        func sidecar() async throws -> Sidecar {
            throw ProviderError.notImplemented
        }
        
        func document() async throws -> Data {
            throw ProviderError.notImplemented
        }
        
        func send(document: Data, sidecar: Sidecar) async throws {
            throw ProviderError.notImplemented
        }
        
        func prepare() async throws {
            guard !_sdkInitialized else { return }
            _sdkInitialized = true
            // Set up dropbox sdk
            DropboxClientsManager.setupWithAppKeyDesktop("y6ijm2p3vqr7kt8")
            
            // Register authenticate callback
            NSAppleEventManager.shared().setEventHandler(self,
                                                             andSelector: #selector(handleGetURLEvent),
                                                             forEventClass: AEEventClass(kInternetEventClass),
                                                             andEventID: AEEventID(kAEGetURL))
        }
        
        @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor?, replyEvent: NSAppleEventDescriptor?) {
            if let aeEventDescriptor = event?.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) {
                if let urlStr = aeEventDescriptor.stringValue {
                    let url = URL(string: urlStr)!
                    let oauthCompletion: DropboxOAuthCompletion = {
                        if let authResult = $0 {
                            switch authResult {
                            case .success:
                                print("Success! User is logged into Dropbox.")
                            case .cancel:
                                print("Authorization flow was manually canceled by user!")
                            case .error(_, let description):
                                print("Error: \(String(describing: description))")
                            }
                        }
                    }
                    DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false, completion: oauthCompletion)
                    // this brings your application back the foreground on redirect
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
        
        // Functional methods
        
        var signedIn: Bool {
            DropboxClientsManager.authorizedClient != nil
        }
        
        var account: String? {
            if let client = DropboxClientsManager.authorizedClient {
                return client.selectUser
//                client.users.getCurrentAccount().response { account, error in
//                    if let account {
//
//                    } else {
//                        print("Token is invalid or expired: \(String(describing: error))")
//                    }
//                }
            }
            return nil
        }
        
        func authenticate() {
            let scope = ScopeRequest(scopeType: .user, scopes: ["account_info.read"], includeGrantedScopes: false)
            DropboxClientsManager.authorizeFromControllerV2(
                sharedApplication: NSApplication.shared,
                controller: nil,
                loadingStatusDelegate: nil,
                openURL: {(url: URL) -> Void in NSWorkspace.shared.open(url)},
                scopeRequest: scope
            )
        }
    }
}

extension Synchronizer.DropboxProvider {
    enum ProviderError: Error, LocalizedError {
        case notImplemented
        
        var errorDescription: String? {
            switch self {
            case .notImplemented:
                return "Dropbox sync is not yet implemented"
            }
        }
    }
}

extension Synchronizer.DropboxProvider {
    enum Authentication {
        case anonymous(() -> Void)
        case ready
    }
}

extension Synchronizer.DropboxProvider.Authentication: Synchronizer.PendingDescriptor {
    func describe() -> AttributedString {
        switch self {
        case .anonymous:
            var attr = AttributedString("Please sign in Dropbox.")
            attr.foregroundColor = .secondary
            if let range = attr.range(of: "sign in") {
                attr[range].foregroundColor = Color.theme
                attr[range].link = URL(string: "action://abc")
            }
            return attr
        case .ready:
            var attr = AttributedString("Dropbox is good to go (Here should be acount inf )")
            return attr
        }
    }
    
    var action: (() -> Void)? {
        switch self {
        case .anonymous(let action):
            return action
        case .ready:
            return nil
        }
    }
}
