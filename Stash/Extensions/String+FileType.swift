//
//  String+FileType.swift
//  Stash
//
//  Created by Yan Meng on 2025/6/14.
//

extension String {
    func checkFileType() -> FileType {
        if isNetscapeBookmarkFile() {
            return .netscape
        } else {
            return .hungrymarks
        }
    }
    
    func isNetscapeBookmarkFile() -> Bool {
        if let range = range(of: #"(?i)<!DOCTYPE\s+NETSCAPE-Bookmark-file-1>"#, options: .regularExpression) {
            let doctype = self[range].lowercased()
            return doctype.caseInsensitiveCompare(Constant.bookmarkDoctype) == .orderedSame
        }
        return false
    }
}

extension String {
    enum FileType {
        case netscape
        case hungrymarks
        // TODO: add pocket
    }
    
    enum Constant {
        static let bookmarkDoctype = "<!DOCTYPE netscape-bookmark-file-1>"
    }
}
