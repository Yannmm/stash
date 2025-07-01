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
    @Published var filter: String?
    private var cancellables = Set<AnyCancellable>()
    private let regex = try! NSRegularExpression(pattern: "#[\\p{L}\\p{N}_]+")
    private let regex2 = try! NSRegularExpression(pattern: "#[\\p{L}\\p{N}_]*")
    
    let _keyboard = PassthroughSubject<Keyboard?, Never>()
    var keyboard: AnyPublisher<Keyboard?, Never> { _keyboard.eraseToAnyPublisher() }
    func setKeyboard(_ value: Keyboard?) {
        _keyboard.send(value)
    }
    
    init(cabinet: OkamuraCabinet) {
        self.cabinet = cabinet
        bind()
    }
    
    private func bind() {
        func _extract(_ source: some Publisher<[String], Never>) -> some Publisher<Set<String>, Never> {
            source
                .map {
                    $0
                        .map({ [unowned self] text in
                            let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
                            let matches = self.regex.matches(in: text, range: nsrange)
                            return matches.map { String(text[Range($0.range, in: text)!]) }
                        })
                        .flatMap({ $0 })
                }
                .map({ Set($0) })
        }
        
        let existings = _extract($title.map({ $0.map({ o in [o] }) ?? [] }))
        
        let all =  _extract(cabinet.$storedEntries.map({ $0.map({ $0.name }) }))
        
        let rest = Publishers.CombineLatest(existings, all).map { a, b in
            b.subtracting(a)
        }
        .map({ Array($0).sorted(by: { $0 < $1 }) })
        
        Publishers.CombineLatest(rest, $filter)
            .map { rest, filter in
                rest.filter({
                    if let f = filter {
                        return $0.contains(f)
                    } else {
                        return true
                    }
                })
            }
            .sink { [unowned self] result in
                self.hashtags = result
            }
            .store(in: &cancellables)
    }
    
    func insert(text: String, hashtag: String, cursorLocation: Int) -> (String, NSRange)? {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = self.regex2.matches(in: text, range: range)
        if let cursored = matches.filter({ (cursorLocation >= $0.range.location)
            && (cursorLocation <= $0.range.location + $0.range.length) }).first,
           let range = Range(cursored.range, in: text) {
            let updated = text.replacingCharacters(in: range, with: hashtag)
            let cursorRange = NSRange(updated.range(of: hashtag)!, in: updated)
            let cursorRange1 = NSRange(location: cursorRange.location + cursorRange.length, length: 0)
            return (updated, cursorRange1)
        } else {
            return nil
        }
    }
}

extension HashtagViewModel {
    enum Keyboard {
        case up
        case down
        case enter
    }
}
