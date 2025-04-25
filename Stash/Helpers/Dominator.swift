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
        // Create a URLRequest with headers that mimic a browser
        var request = URLRequest(url: url)
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.addValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        
        // Set a longer timeout for complex pages
        request.timeoutInterval = 30
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check if we got a redirect
        if let httpResponse = response as? HTTPURLResponse,
           (httpResponse.statusCode == 301 || httpResponse.statusCode == 302),
           let location = httpResponse.value(forHTTPHeaderField: "Location"),
           let redirectURL = URL(string: location) {
            // Follow the redirect
            return try await fetchWebPageTitle(from: redirectURL)
        }
        
        // Try to parse the HTML
        guard let htmlString = String(data: data, encoding: .utf8) else {
            // If UTF-8 fails, try other common encodings
            for encoding in [String.Encoding.isoLatin1, .windowsCP1252, .ascii] {
                if let html = String(data: data, encoding: encoding) {
                    return try extractTitle(from: html, fallbackURL: url)
                }
            }
            
            throw NSError(domain: "HTMLParsingError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to string"])
        }
        
        return try extractTitle(from: htmlString, fallbackURL: url)
    }
    
    private func extractTitle(from htmlString: String, fallbackURL: URL) throws -> String {
        // Check if the HTML string is empty or too short
        if htmlString.isEmpty || htmlString.count < 50 {
            // For Salesforce Trailhead specifically
            if fallbackURL.absoluteString.contains("trailhead.salesforce.com") {
                // Extract title from URL path components
                let pathComponents = fallbackURL.pathComponents
                if pathComponents.count > 4 && pathComponents[3] == "superbadges" {
                    return "Salesforce Superbadge: \(pathComponents[4].replacingOccurrences(of: "_", with: " ").capitalized)"
                }
                return "Salesforce Trailhead"
            }
            
            // For other sites with empty HTML
            return fallbackURL.host ?? fallbackURL.absoluteString
        }
        
        // Parse the HTML
        let doc = try SwiftSoup.parse(htmlString)
        
        // Try to get the title
        if let title = try? doc.title(), !title.isEmpty {
            return title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // If no title tag, try to find the first h1
        if let h1 = try? doc.select("h1").first(), let h1Text = try? h1.text(), !h1Text.isEmpty {
            return h1Text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // If no h1, try meta tags
        if let metaTitle = try? doc.select("meta[property=og:title]").first(),
           let content = try? metaTitle.attr("content"),
           !content.isEmpty {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Fallback to domain name
        return fallbackURL.host ?? fallbackURL.absoluteString
    }
}

extension Dominator {
    /// Browser bookmarks import
    // Tested: Safari, Chrome
    func decompose(_ html: String) throws -> Data  {
        guard isBookmarkFile(html) else {
            throw SomeError.Decompose.invalidDoctype
        }
        
        let document = try SwiftSoup.parse(html)
        let allElements: Elements = try document.select("body > dt")
        
        let json = try collect(allElements)
        let pretty = try JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .withoutEscapingSlashes])
        
        return pretty
    }
    
    private func decomposeDT(_ dt: Element) throws -> Any? {
        let h3s = try dt.select("> h3")
        
        var children = [Any]()
        if h3s.count > 0 {
            let header = try h3s.first()!.text()
            guard let dl = try dt.select("> dl").first() else { return nil }
            let dts = try dl.select("> dt")
            try dts.map({ try decomposeDT($0) })
                .compactMap({ $0 })
                .forEach { result in
                    children.append(result)
                }
            return [
                "name": header,
                "type": "directory",
                "children": children
            ] as [String : Any]
        } else {
            let a = try dt.select("> a")
            let name = try a.text()
            let url = try a.attr("href")
            return [
                "name": name,
                "type": "bookmark",
                "url": url,
            ]
        }
    }
    
    private func collect(_ dts: Elements) throws -> [Any] {
        var collector = [Any]()
        try dts.map({ try decomposeDT($0) })
            .compactMap({ $0 })
            .forEach({ result in
                collector.append(result)
            })
        return collector
    }
    
    private func isBookmarkFile(_ html: String) -> Bool {
        if let match = html.range(of: #"(?i)<!DOCTYPE\s+([^\s>]+)"#, options: .regularExpression) {
            let components = html[match].split(separator: " ")
            if components.count > 1 {
                let doctype = components[1].lowercased()
                return doctype == Constant.bookmarkDoctype
            }
        }
        return false
    }
    
    enum Constant {
        static let bookmarkDoctype = "netscape-bookmark-file-1"
    }
}

extension Dominator {
    func compose(_ json: Any) throws -> String {
        guard let j = json as? [[String: Any]] else {
            throw SomeError.Compose.invalidJSON
        }
        
        // Create elements
        let html = Document.init("")
        
        let head = Element(Tag("head"), "")
        let meta = try Element(Tag("meta"), "")
            .attr("http-equiv", "Content-Type")
            .attr("content", "text/html; charset=UTF-8")
        try head.appendChild(meta)
        let title = try Element(Tag("title"), "").text("Bookmarks")
        try head.appendChild(title)
        
        let body = Element(Tag("body"), "")
        
        try html.appendChild(head)
        try html.appendChild(body)
        
        try j.map({ try composeDT($0) })
            .compactMap({ $0 })
            .forEach({ try body.appendChild($0) })
        
        // Get HTML as string
        let htmlString =  try html.outerHtml()
        
        return htmlString
    }
    
    private func composeDT(_ json: [String: Any]) throws -> Element? {
        
        guard let type = json["type"] as? String else { return nil }
        
        switch type {
        case "bookmark":
            let dt = Element(Tag("dt"), "")
            let name = json["name"] as? String ?? ""
            let href = json["url"] as? String ?? ""
            let a = try Element(Tag("a"), "")
                .text(name)
                .attr("href", href)
            try dt.appendChild(a)
            return dt
        case "directory":
            let dt = Element(Tag("dt"), "")
            
            let name = json["name"] as? String ?? ""
            let a = try Element(Tag("h3"), "")
                .text(name)
            try dt.appendChild(a)
            
            let dl = Element(Tag("dl"), "")
            try dt.appendChild(dl)
            
            if let children = json["children"] as? [[String: Any]] {
                try children.map({ try composeDT($0) })
                    .compactMap({ $0 })
                    .forEach({ try dl.appendChild($0) })
            }
            
            return dt
        default:
            throw SomeError.Compose.unexpectedType(type)
        }
        
        
    }
    
}

extension Dominator {
    struct SomeError {
        enum Decompose: Error, LocalizedError {
            case invalidDoctype
        }
        
        enum Compose: Error, LocalizedError {
            case unexpectedType(String)
            case invalidJSON
        }
    }
}
