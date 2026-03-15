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
