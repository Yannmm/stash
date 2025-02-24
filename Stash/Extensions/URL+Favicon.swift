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
        static let template = "https://favicone.com/%@"
    }
}

