//
//  DropboxProvider.swift
//  Stash
//
//  Created by Yan Meng on 2026/5/8.
//

import AppKit
import SwiftyDropbox
import Carbon

extension Synchronizer {
    final class DropboxProvider: Provider1 {
        func prepare() {
            DropboxClientsManager.setupWithAppKeyDesktop("y6ijm2p3vqr7kt8")
            
            _listen()
        }
        
        func authenticate() {
            DropboxClientsManager.authorizeFromControllerV2(
                sharedApplication: NSApplication.shared,
                controller: nil,
                loadingStatusDelegate: nil,
                openURL: { url in
                    NSWorkspace.shared.open(url)
                },
                scopeRequest: ScopeRequest(scopeType: .user, scopes: ["account_info.read"], includeGrantedScopes: false)
            )
        }
        
        var isSignedIn: Bool {
            let client = DropboxClientsManager.authorizedClient
            return client != nil
        }
        
        func doSth() {
            let client = DropboxClientsManager.authorizedClient
            
            Task {
                let response = try await client!.files.createFolderV2(path: "/test/path/in/Dropbox/account").response()
                print(response)
            }
        }
        
        private func _listen() {
            NSAppleEventManager.shared().setEventHandler(self,
                                                         andSelector: #selector(handleGetURLEvent1),
                                                         forEventClass: AEEventClass(kInternetEventClass),
                                                         andEventID: AEEventID(kAEGetURL))
        }
        
        @objc private func handleGetURLEvent1(_ event: NSAppleEventDescriptor?, replyEvent: NSAppleEventDescriptor?) {
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
                    
                    doSth()
                }
            }
        }
    }
}


extension Synchronizer {
    protocol Provider1 {
        func prepare()
        func authenticate()
        func doSth()
        var isSignedIn: Bool { get }
    }
}

