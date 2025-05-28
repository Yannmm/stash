//
//  HungrymarkParser.swift
//  Stash
//
//  Created by Rayman on 2025/5/27.
//

import Foundation

class HungrymarkParser {
    private func _px(_ line: String) -> (Int, Dummy)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let parts = trimmed
            .split(separator: trimmed.hasPrefix("*") ? " " : "\t")
            .map({ String($0).trimmingColons() })
        guard parts.count >= 2 else { return nil }
        if parts[0] == "*" {
            return (line.countPrefixCharacter("\t"), Dummy(name: parts[1], url: nil, type: .directory))
        } else {
            return (line.countPrefixCharacter("\t"), Dummy(name: parts[1], url: URL(string: parts[0]), type: .bookmark))
        }
    }
    
    private func recursive(_ children: [Dummy], _ level: Int) -> Dummy {
        for e in children.reversed() {
            if e.type == .directory {
                if level == 0 {
                    return e
                } else {
                    return recursive(e.children, level - 1)
                }
                
            }
        }
        return children.first!
    }
    
    private func insert(_ root: inout [Dummy], _ level: Int, _ element: Dummy) {
        if level == 0 {
            root.append(element)
        } else {
            let k = recursive(root, level - 1)
            k.children.append(element)
        }
    }
    
    func parse(text: String) -> [any Entry] {
        let lines = text.components(separatedBy: .newlines)
        
        var root = [Dummy]()

        for line in lines {
            guard let r = _px(line) else { continue }
           insert(&root, r.0, r.1)
        }

        return root.map({ $0.asAnyEntry() }).asEntries
    }
}

extension HungrymarkParser {
    class Dummy {
        let name: String
        let url: URL?
        let type: EntryType
        var children = [Dummy]()
        
        init(name: String, url: URL?, type: EntryType) {
            self.name = name
            self.url = url
            self.type = type
        }
        
        func asAnyEntry() -> AnyEntry {
            AnyEntry(id: nil, name: name, type: type, url: url, children: children.map({ $0.asAnyEntry() }))
        }
    }
}

fileprivate extension String {
    func trimmingColons() -> String {
        self.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
    
    func countPrefixCharacter(_ character: Character) -> Int {
        self.prefix(while: { $0 == character }).count
    }
}
