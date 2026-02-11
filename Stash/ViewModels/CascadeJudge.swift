//
//  CascadeJudge.swift
//  Stash
//
//  Created by Rayman on 2026/2/11.
//

import Foundation

protocol LeveledIdentifiable: Identifiable where ID == UUID {
    var level: Int { get }
    
    var expanded: Bool { get }
}

protocol CascadeJudge {
    associatedtype Row: LeveledIdentifiable
    
    var rows: [Row] { get }
}

extension CascadeJudge {
    func cascade(from subjectId: UUID, to anchorId: UUID) -> Bool {
        guard let hostIndex = rows.firstIndex(where: { $0.id == anchorId }),
              let guestIndex = rows.firstIndex(where: { $0.id == subjectId }),
              hostIndex != guestIndex,
              rows[hostIndex].level != rows[guestIndex].level else {
            return false
        }
        
        if hostIndex < guestIndex {
            for row in rows[(hostIndex + 1)...guestIndex].reversed() {
                if row.level <= rows[hostIndex].level {
                    return false
                }
            }
        } else {
            for row in rows[(guestIndex + 1)...hostIndex].reversed() {
                if row.level <= rows[guestIndex].level {
                    return false
                }
            }
        }
        return true
    }
    
    func strideCount(_ id: UUID) -> Int {
        guard let index = rows.firstIndex(where: { $0.id == id }), rows[index].expanded else { return 0 }
        let level = rows[index].level
        var count = 0
        for row in rows[(index + 1)...] {
            guard level < row.level else { break }
            count += 1
        }
        
        return count
    }
}
