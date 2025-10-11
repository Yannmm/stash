//
//  Haha.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/2.
//

import Foundation
import Combine

final class DistributedNotificationPublisher: Publisher {
    typealias Output = Notification
    typealias Failure = Never

    private let name: Notification.Name
    private let object: String?

    init(name: Notification.Name, object: String? = nil) {
        self.name = name
        self.object = object
    }

    func receive<S>(subscriber: S) where S : Subscriber, DistributedNotificationPublisher.Failure == S.Failure, DistributedNotificationPublisher.Output == S.Input {
        let subscription = DistributedNotificationSubscription(subscriber: subscriber, name: name, object: object)
        subscriber.receive(subscription: subscription)
    }
}

private final class DistributedNotificationSubscription<S: Subscriber>: Subscription where S.Input == Notification, S.Failure == Never {
    private var subscriber: S?
    private var observer: NSObjectProtocol?

    init(subscriber: S, name: Notification.Name, object: String?) {
        self.subscriber = subscriber
        self.observer = DistributedNotificationCenter.default().addObserver(forName: name, object: object, queue: nil) { [weak self] notification in
            _ = self?.subscriber?.receive(notification)
        }
    }

    func request(_ demand: Subscribers.Demand) {
        // Demand handling is not necessary for NotificationCenter-style delivery
    }

    func cancel() {
        if let observer = observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        subscriber = nil
    }
}
