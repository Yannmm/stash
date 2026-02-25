//
//  CsvParser.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/5.
//

import CodableCSV
import Foundation

class CsvParser {
    func parse(from csv: String) throws -> [AnyEntry] {
        let decoder = CSVDecoder {
            $0.headerStrategy = .firstLine
        }
        let rows = try decoder.decode([Row].self, from: csv)
        
        let anyEntries = rows.map({ row in
            var title = row.title
            if let tags = row.tags?.components(separatedBy: "|"), tags.count > 0 {
                title = title + " " + tags.map({ $0.hasPrefix("#") ? $0 : ("#" + $0) }).joined(separator: " ")
            }
            // TODO: add tags
            return AnyEntry(id: UUID(), name: title, type: .bookmark, url: row.url, hashtags: [], children: [])
        })
        
        return anyEntries
    }
}

fileprivate extension CsvParser {
    struct Row: Codable {
        let title: String
        let url: URL?
        let tags: String?
    }

}
