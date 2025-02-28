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
