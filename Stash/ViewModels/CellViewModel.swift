//
//  CellViewModel.swift
//  Stash
//
//  Created by Rayman on 2025/5/21.
//

import Combine

class CellViewModel: ObservableObject {
    @Published var entry: (any Entry)?
    @Published var title: String
    @Published var error: Error?
    
    let cabinet: OkamuraCabinet
    
    private var cancellables = Set<AnyCancellable>()
    
    var ableToUngroup: Bool {
        if let e = entry, e.unboxable, e.children(among: cabinet.storedEntries).count > 0 {
            return true
        }
        return false
    }
    
    init(entry: (any Entry)? = nil, cabinet: OkamuraCabinet) {
        self.cabinet = cabinet
        self.entry = entry
        self.title = entry?.name ?? ""
        
        bind()
    }
    
    private func bind() {
        $error
            .compactMap({ $0 })
            .sink { ErrorTracker.shared.add($0)}
            .store(in: &cancellables)
    }
    
    func update() throws {
        guard var e = entry else { return }
        guard e.name != title else { return }
        if title.trim().isEmpty { title = e.name }
        e.name = title
        try cabinet.update(entry: e)
        entry = e
    }
    
    func ungroup(_ entry: any Entry) throws {
        try cabinet.ungroup(entry: entry)
    }
}
