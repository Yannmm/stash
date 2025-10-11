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
            return AnyEntry(id: UUID(), name: title, type: .bookmark, url: row.url, children: [])
        })
        
        return anyEntries
        
        
//        let rows = csv.split(separator: "\n")
//        guard rows.count > 0 else { return [] }
//        let header = rows.first!.split(separator: ",", omittingEmptySubsequences: false).map({ String($0) })
//        let entries = rows
//            .dropFirst()
//            .map { string in
//                var map = [String: String]()
//                string
//                    .split(separator: ",", omittingEmptySubsequences: false)
//                    .map({ String($0) })
//                    .enumerated().forEach({ map[header[$0]] = $1 })
//                return map
//            }.map { (map: [String: String]) -> AnyEntry? in
//                guard var title = map[Constant.title],
//                      let urlString = map[Constant.url],
//                      let url = URL(string: urlString) else {
//                    return nil
//                }
//                
//                if let tags = map[Constant.tags]?.components(separatedBy: "|"),
//                   tags.count > 0 {
//                    title = title + " " + tags.map({ "#" + $0 }).joined(separator: " ")
//                }
//                
//                return AnyEntry(id: UUID(), name: title, type: .bookmark, url: url, children: [])
//            }
//            .compactMap({ $0 })
//        
//        return entries
    }
}

fileprivate extension CsvParser {
    struct Row: Codable {
        let title: String
        let url: URL?
        let tags: String?
    }

}
