//
//  Dominator.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/25.
//

import Foundation
import SwiftSoup

class Dominator {
    func fetchWebPageTitle(from url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "HTMLParsingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to string"])
        }
        
        let doc = try SwiftSoup.parse(htmlString)
        if let title = try? doc.title() {
            return title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return url.host ?? url.absoluteString
    }
}
