//
//  SyncError.swift
//  Stash
//
//  Created by Rayman Yan on 2026/10/19.
//

import Foundation

extension Synchronizer {
    // Errors other than auth related ones
    enum SyncError: Error, LocalizedError {
        case unexpected(String)
        
        case tokenExpired // for remote  provider only?
        case fileNotFound(String) // for remote provider only?
        case unauthenticated // for remote provider only?
        case api(Error) // for remote provider only?
        
        case malformatString(String)
        case corruptData(Data)
        
        
        var errorDescription: String? {
            switch self {
            case .api(let error):
                return error.localizedDescription
            default:
                return self.localizedDescription
            }
        }
    }
}
