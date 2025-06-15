//
//  String+FileType.swift
//  Stash
//
//  Created by Yan Meng on 2025/6/14.
//

import UniformTypeIdentifiers

extension String {
//    func checkFileType() -> FileType {
//        if isNetscapeBookmarkFile() {
//            return .netscape
//        } else {
//            // TODO: check pocket file
//            return .hungrymarks
//        }
//    }
    
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
        case pocket
        
        var contentTypes: [UTType] {
            switch self {
            case .netscape:
                return [.html]
            case .hungrymarks:
                return [UTType(filenameExtension: "txt")!]
            case .pocket:
                return [UTType(filenameExtension: "csv")!]
            }
        }
    }
    
    enum Constant {
        static let bookmarkDoctype = "<!DOCTYPE netscape-bookmark-file-1>"
    }
}
