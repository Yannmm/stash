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
            let tags = row.tags?.components(separatedBy: "|") ?? []
            return AnyEntry(id: UUID(), name: row.title, type: .bookmark, url: row.url, hashtags: tags, children: [])
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
