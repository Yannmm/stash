//
//  String+Favicon.swift
//  Stash
//
//  Created by Rayman on 2025/2/21.
//

import Foundation

extension URL {
    var faviconUrl: URL? {
        guard let host = self.host(),
              let iconUrl = URL(string: String(format: Constant.template, host)) else {
            return nil;
        }
        return iconUrl
    }
    
    private struct Constant {
//                static let template = "https://twenty-icons.com/%@"
        static let template = "https://favicone.com/%@?s=128"
//        static let template = "https://favicon.yandex.net/favicon/%@"
    }
}

extension URL {
    var isVnc: Bool {
        self.scheme?.lowercased() == "vnc"
    }
}

extension URL {
    var firstDomainLetter: String {
        var text = "?"
        if let comps = path.split(separator: "/").first?.lowercased() {
            text = (comps.hasPrefix("www.") ? String(comps.dropFirst(4).first ?? "?") : String(comps.first ?? "?")).uppercased()
        }
        return text
    }
}
