//
//  DropboxProvider.swift
//  Stash
//
//  Created by Yan Meng on 2026/5/10.
//

import AppKit
import SwiftyDropbox
import Carbon

extension Synchronizer {
    final class DropboxProvider: Provider {
        enum AuthError: Error {
            case cancelled
            case failed(String)
            case invalidURL
            case inProgress
        }
        
        var signedIn: Bool { DropboxClientsManager.authorizedClient != nil }
        
        func doSth() async throws {
            let client = DropboxClientsManager.authorizedClient
            
            let response = try await client!.files.createFolderV2(path: "/test/path/in/Dropbox/account").response()
            print(response)
        }
        
        private var continuation: CheckedContinuation<DropboxClient, Error>?
        
        func prepare() {
            // Register dropbox app
            DropboxClientsManager.setupWithAppKeyDesktop("y6ijm2p3vqr7kt8")
            
            // Handle
            NSAppleEventManager.shared().setEventHandler(self,
                                                         andSelector: #selector(handle),
                                                         forEventClass: AEEventClass(kInternetEventClass),
                                                         andEventID: AEEventID(kAEGetURL))
        }
        
        @discardableResult
        func authenticate(forceResignIn: Bool = false) async throws -> DropboxClient {
            if let client = DropboxClientsManager.authorizedClient, !forceResignIn {
                return client
            }
            
            return try await withCheckedThrowingContinuation { (c: CheckedContinuation<DropboxClient, Error>) in
                if let continuation = self.continuation {
                    continuation.resume(
                        throwing: AuthError.inProgress
                    )
                }
                self.continuation = c
                DispatchQueue.main.async {
                    DropboxClientsManager.authorizeFromControllerV2(
                        sharedApplication: NSApplication.shared,
                        controller: nil,
                        loadingStatusDelegate: nil,
                        openURL: { url in
                            DispatchQueue.main.async {
                                NSWorkspace.shared.open(url)
                            }
                        },
                        scopeRequest: ScopeRequest(scopeType: .user, scopes: [
                            "account_info.read",
                            "files.metadata.read",
                            "files.content.read",
                            "files.content.write"
                        ],
                                                   includeGrantedScopes: false)
                    )
                }
            }
        }
        
        @objc
        private func handle(
            _ event: NSAppleEventDescriptor?,
            replyEvent: NSAppleEventDescriptor?
        ) {
            
            guard
                let descriptor = event?.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)),
                let string = descriptor.stringValue,
                let url = URL(string: string)
            else {
                self.continuation?.resume(
                    throwing: AuthError.invalidURL
                )
                self.continuation = nil
                return
            }
            
            DropboxClientsManager.handleRedirectURL(
                url,
                includeBackgroundClient: false
            ) { result in
                
                guard let result else {
                    self.continuation?.resume(
                        throwing: AuthError.failed("Unknown auth result")
                    )
                    self.continuation = nil
                    return
                }
                
                switch result {
                    
                case .success:
                    guard let client =
                            DropboxClientsManager.authorizedClient
                    else {
                        self.continuation?.resume(
                            throwing: AuthError.failed("No client")
                        )
                        self.continuation = nil
                        return
                    }
                    
                    self.continuation?.resume(returning: client)
                    
                case .cancel:
                    self.continuation?.resume(
                        throwing: AuthError.cancelled
                    )
                    
                case .error(_, let description):
                    self.continuation?.resume(
                        throwing: AuthError.failed(
                            description ?? "Unknown error"
                        )
                    )
                }
                
                self.continuation = nil
                
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

