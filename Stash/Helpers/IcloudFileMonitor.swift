//
//  IcloudFileMonitor.swift
//  Stash
//
//  Created by Rayman on 2025/5/14.
//

import Foundation
import Combine

class IcloudFileMonitor {
    private let filename: String
    
    @Published var update: URL?
    
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var query: NSMetadataQuery = {
        let q = NSMetadataQuery()
        q.predicate = NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, filename)
        q.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        return q
    }()
    
    init(filename: String) {
        self.filename = filename
        setup()
    }
    
    private func setup() {
        
//        NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: nil, queue: nil, using: onUpdate)
        
        NotificationCenter.default
            .publisher(for: .NSMetadataQueryDidUpdate, object: query)
            .dropFirst()
            .sink(receiveValue: onUpdate)
            .store(in: &cancellables)
        
        query.start()
    }
    
    private func onUpdate(_ noti: Notification) {
        query.disableUpdates()
        
        for item in query.results {
            if let item = item as? NSMetadataItem,
               let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL {
                self.update = url
            }
        }
        
        query.enableUpdates()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        query.stop()
    }
}
