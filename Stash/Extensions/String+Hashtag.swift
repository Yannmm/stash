//
//  String+Hashtag.swift
//  Stash
//
//  Created by Rayman on 2025/7/2.
//

import Foundation

extension String {
    enum RegexConstant {
        static let pattern1 = "#[^\\s]*"
        static let regex1 = try! NSRegularExpression(pattern: pattern1)
        
        static let pattern2 = "#[^\\s]+"
        static let regex2 = try! NSRegularExpression(pattern: pattern2)
        
        static let predefinedHashtags = String.Browser.allCases.map({ "#\($0.rawValue)" })
    }
}

extension String {
    var hashtags: [String] {
        return hashtagMatches.map { String(self[Range($0.range, in: self)!]) }
    }
    
    var hashtagMatches: [NSTextCheckingResult] {
        let nsrange = NSRange(self.startIndex..<self.endIndex, in: self)
        let matches = String.RegexConstant.regex2.matches(in: self, range: nsrange)
        return matches
    }
}
