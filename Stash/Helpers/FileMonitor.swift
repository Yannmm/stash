//
//  LocalFileMonitor.swift
//  Stash
//
//  Created by Yan Meng on 2026/6/1.
//

import Foundation
import Combine

final class FileMonitor {
    
    private let _onChange = PassthroughSubject<URL, Never>()
    
    var onChange: AnyPublisher<URL, Never> {
        _onChange.eraseToAnyPublisher()
    }
    
    private let fileURL: URL
    private var fileDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    
    init(_ path: URL) {
        self.fileURL = path
    }
    
    deinit {
        stop()
    }
    
    func start() {
        guard source == nil else { return }
        
        fileDescriptor = open(fileURL.path, O_EVTONLY)
        
        guard fileDescriptor >= 0 else {
            print("Failed to open file: \(fileURL.path)")
            return
        }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: DispatchQueue.global()
        )
        
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            let flags = source.data
            
            if flags.contains(.delete) || flags.contains(.rename) {
                // File may have been replaced.
                self.restart()
            }
            
            self._onChange.send(fileURL) // TODO: subscribe to _onChange in caller
        }
        
        source.setCancelHandler { [fd = fileDescriptor] in
            close(fd)
        }
        
        self.source = source
        source.resume()
    }
    
    func stop() {
        source?.cancel()
        source = nil
        fileDescriptor = -1
    }
    
    private func restart() {
        stop()
        
        // Delay slightly to allow file recreation.
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.start()
        }
    }
}
