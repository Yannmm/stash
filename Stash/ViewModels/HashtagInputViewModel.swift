//
//  HashtagCollector.swift
//  Stash
//
//  Created by Yan Meng on 2025/6/26.
//

import Combine
import CombineExt
import AppKit

class HashtagInputViewModel: ObservableObject {
    let existentials: AnyPublisher<Set<String>, Never>
    @Published var title: String?
    @Published var hashtags: [String] = []
    @Published var query: String?
    @Published var keyboardAction: KeyboardAction?
    @Published var suggestionIndex: Int?
    private var cancellables = Set<AnyCancellable>()
    
    let _select = PassthroughSubject<String, Never>()
    
    func select(_ hashtag: String) { _select.send(hashtag) }
    
    var selected: AnyPublisher<String, Never> { _select.eraseToAnyPublisher() }
    
    init(existentials: AnyPublisher<Set<String>, Never>) {
        self.existentials = existentials
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
        
        let all =  existentials.map({ $0.union(String.RegexConstant.predefinedHashtags) })
        
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
        
        $keyboardAction.withLatestFrom($suggestionIndex, $hashtags, resultSelector: { ($0, $1.0, $1.1) })
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
            .withLatestFrom($suggestionIndex, $hashtags, resultSelector: { ($0, $1.0, $1.1) })
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
}
