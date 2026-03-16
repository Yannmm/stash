//
//  String+Range.swift
//  Stash
//
//  Created by Yan Meng on 2026/3/15.
//

import Foundation

extension String {
    func ranges(
        of search: String,
        options: String.CompareOptions = [],
        locale: Locale? = nil
    ) -> [Range<String.Index>] {
        var result: [Range<String.Index>] = []
        var startIndex = self.startIndex
        
        while let range = self.range(
            of: search,
            options: options,
            range: startIndex..<self.endIndex,
            locale: locale
        ) {
            result.append(range)
            startIndex = range.upperBound
        }
        
        return result
    }
}

extension String {
    func emphasize(_ text: String, baseStyle: (inout AttributedString) -> Void, highlightStyle: (inout AttributedString, Range<AttributedString.Index>) -> Void) -> AttributedString {
        var attr = AttributedString(self)
        baseStyle(&attr)
        
        let ranges = ranges(of: text, options: .caseInsensitive)
        guard ranges.count > 0 else { return attr }
        ranges.forEach { r in
            let rr = NSRange(r, in: self)
            if let range = Range(rr, in: attr) {
                highlightStyle(&attr, range)
            }
        }
        return attr
    }
}

extension String {
    
    func condense(
        matching search: String,
        leading: Int = 20,
        trailing: Int = 10,
        context: Int = 5
    ) -> String {
        
        guard !search.isEmpty else { return self }
        
        var segments: [Range<String.Index>] = []
        
        // Leading segment
        let leadEnd = index(startIndex, offsetBy: min(leading, count))
        segments.append(startIndex..<leadEnd)
        
        // Find matches
        var start = startIndex
        
        while let r = range(
            of: search,
            options: [.caseInsensitive],
            range: start..<endIndex
        ) {
            let lower = index(r.lowerBound, offsetBy: -context, limitedBy: startIndex) ?? startIndex
            let upper = index(r.upperBound, offsetBy: context, limitedBy: endIndex) ?? endIndex
            
            segments.append(lower..<upper)
            
            start = r.upperBound
        }
        
        // Trailing segment
        let trailStart = index(endIndex, offsetBy: -min(trailing, count), limitedBy: startIndex) ?? startIndex
        segments.append(trailStart..<endIndex)
        
        // Sort segments
        segments.sort { $0.lowerBound < $1.lowerBound }
        
        // Merge overlaps
        var merged: [Range<String.Index>] = []
        
        for seg in segments {
            if let last = merged.last, last.upperBound >= seg.lowerBound {
                merged[merged.count - 1] =
                    last.lowerBound..<max(last.upperBound, seg.upperBound)
            } else {
                merged.append(seg)
            }
        }
        
        // Build result
        var result = ""
        
        for (i, seg) in merged.enumerated() {
            if i > 0 {
                result += "..."
            }
            result += self[seg]
        }
        
        return result
    }
}
