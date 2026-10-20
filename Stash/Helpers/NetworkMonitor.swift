//
//  NetworkMonitor.swift
//  Stash
//
//  Created by Rayman Yan on 2026/10/19.
//

import Network
import Combine

final class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(
        label: "com.rendezvousauoaradis.stash.network-monitor"
    )

    private var previousStatus: NWPath.Status?
    private var previousInterfaces: Set<String> = []
    
    var onChange: AnyPublisher<Void, Never> { _onChange.eraseToAnyPublisher() }
    
    private let _onChange = PassthroughSubject<Void, Never>()

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            let interfaces = Set(
                [
                    NWInterface.InterfaceType.wifi,
                    .wiredEthernet,
                    .cellular,
                    .other,
                    .loopback
                ]
                .filter { path.usesInterfaceType($0) }
                .map { String(describing: $0) }
            )

            let changed =
                previousStatus != nil &&
                (
                    previousStatus != path.status ||
                    previousInterfaces != interfaces
                )

            previousStatus = path.status
            previousInterfaces = interfaces

            if changed {
                _onChange.send(())
            }
        }

        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
