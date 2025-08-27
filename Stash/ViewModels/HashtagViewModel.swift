//
//  HashtagCollector.swift
//  Stash
//
//  Created by Yan Meng on 2025/6/26.
//

import Combine
import AppKit

class HashtagViewModel: ObservableObject {
    let cabinet: OkamuraCabinet
    @Published var title: String?
    @Published var hashtags: [String] = []
    @Published var query: String?
    @Published var keyboardAction: KeyboardAction?
    @Published var suggestionIndex: Int?
    private var cancellables = Set<AnyCancellable>()
    
    let _select = PassthroughSubject<String, Never>()
    
    func select(_ hashtag: String) { _select.send(hashtag) }
    
    var selected: AnyPublisher<String, Never> { _select.eraseToAnyPublisher() }
    
    init(cabinet: OkamuraCabinet) {
        self.cabinet = cabinet
        bind()
    }
    
    private func bind() {
        func _extract(_ source: some Publisher<[String], Never>) -> some Publisher<Set<String>, Never> {
            source
                .map {
                    $0
                        .map({ text in
                            let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
                            let matches = String.RegexConstant.regex2.matches(in: text, range: nsrange)
                            return matches.map { String(text[Range($0.range, in: text)!]) }
                        })
                        .flatMap({ $0 })
                }
                .map({ Set($0) })
        }
        
        let existings = _extract($title.map({ $0.map({ o in [o] }) ?? [] }))
        
        let all =  _extract(cabinet.$storedEntries.map({ $0.map({ $0.name }) })).map({ $0.union(String.RegexConstant.predefinedHashtags) })
        
        let rest = Publishers.CombineLatest(existings, all).map { a, b in
            b.subtracting(a)
        }
        .map({ Array($0).sorted(by: { $0 < $1 }) })
        
        Publishers.CombineLatest(rest, $query.map({ $0?.lowercased() }))
            .map { rest, filter in
                rest.filter({
                    if let f = filter {
                        return $0.lowercased().contains(f)
                    } else {
                        return true
                    }
                })
            }
            .sink { [unowned self] result in
                self.hashtags = result
            }
            .store(in: &cancellables)
        
        $keyboardAction.withLatestFrom2($suggestionIndex, $hashtags)
            .map({ t3 in
                guard let index = t3.1 else { return nil }
                switch t3.0 {
                case .down: // ↓ Down arrow
                    return (index + 1) % t3.2.count
                case .up: // ↑ Up arrow
                    return (index - 1 + t3.2.count) % t3.2.count
                default: return nil
                }
            })
            .compactMap({ $0 })
            .sink { [weak self] in
                self?.suggestionIndex = $0
            }
            .store(in: &cancellables)
        
        $keyboardAction.filter({ $0 == .enter })
            .withLatestFrom2($suggestionIndex, $hashtags)
            .map({ $0.1 == nil ? nil : $0.2[$0.1!] })
            .compactMap({ $0 })
            .sink { [weak self] in
                self?.select($0)
            }
            .store(in: &cancellables)
        
        $hashtags.map({ $0.count })
            .removeDuplicates()
            .map({ $0 > 0 ? 0 : nil })
            .sink { [weak self] in
                self?.suggestionIndex = $0
            }
            .store(in: &cancellables)
    }
    
    @discardableResult
    func findCursoredRange(text: String, cursorLocation: Int) -> NSRange? {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = String.RegexConstant.regex1.matches(in: text, range: range)
        if let cursored = matches.filter({ (cursorLocation >= $0.range.location)
            && (cursorLocation <= $0.range.location + $0.range.length) }).first {
            return cursored.range
        } else {
            return nil
        }
    }
    
    func insert(text: String, hashtag: String, cursorLocation: Int) -> (String, NSRange)? {
        if let cursored = findCursoredRange(text: text, cursorLocation: cursorLocation),
           let range = Range(cursored, in: text) {
            let updated = text.replacingCharacters(in: range, with: hashtag)
            let cursorRange = NSRange(updated.range(of: hashtag)!, in: updated)
            let cursorRange1 = NSRange(location: cursorRange.location + cursorRange.length, length: 0)
            return (updated, cursorRange1)
        } else {
            return nil
        }
    }
}


