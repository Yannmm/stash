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
    @Published var hashtags: [String] = []
    @Published var filter: String = ""
    private var cancellables = Set<AnyCancellable>()
    private let regex = try! NSRegularExpression(pattern: "#[\\p{L}\\p{N}_]+")
    
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
        let all =  cabinet.$storedEntries
            .map {
                $0
                    .map({ $0.name })
                    .map({ [unowned self] text in
                        let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
                        let matches = self.regex.matches(in: text, range: nsrange)
                        return matches.map { String(text[Range($0.range, in: text)!]) }
                    })
                    .flatMap({ $0 })
            }
            .map({ Set($0) })
            .map({ Array($0).sorted(by: { $0 < $1 }) })
        
        Publishers.CombineLatest(all, $filter)
            .map { all, filter in
                all.filter({ $0.contains(filter) })
            }
            .sink { [unowned self] result in
                self.hashtags = result
            }
            .store(in: &cancellables)
    }
}

extension HashtagViewModel {
    enum Keyboard {
        case up
        case down
        case enter
    }
}
