//
//  PathType.swift
//  Stash
//
//  Created by Rayman on 2025/3/26.
//

import Foundation

enum Path {
    case file(URL)
    case web(URL)
    case vnc(URL)
    case unknown
}

extension Path {
    init(_ string: String) {
        let lowercased = string.lowercased()
        switch lowercased {
        case let str where str.starts(with: "file://"):
            self = .file(URL(fileURLWithPath: lowercased))
        case let str where str.starts(with: "~"):
            self = .file(URL(fileURLWithPath: lowercased))
        case let str where str.starts(with: "/"):
            self = .file(URL(fileURLWithPath: lowercased))
        case let str where str.starts(with: "http"):
            fallthrough
        case let str where str.starts(with: "https"):
            self = .web(URL(string: str)!)
        case let str where str.starts(with: "vnc"):
            self = .vnc(URL(string: str)!)
        default:
            self = .web(URL(string: Helper.normalizeUrl(lowercased))!)
        }
    }
    
    private enum Helper {
        static func normalizeUrl(_ text: String) -> String {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if it already has a protocol
            if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                return trimmed
            }
            
            // Check if it's a localhost or IP address
            if trimmed.hasPrefix("localhost") ||
                trimmed.range(of: "^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}", options: .regularExpression) != nil {
                return "http://" + trimmed
            }
            
            // Default to https for all other URLs
            return "https://" + trimmed
        }
    }
}

extension Path: Equatable {
    
}
