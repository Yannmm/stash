//
//  Publisher+Extension.swift
//  Stash
//
//  Created by Yan Meng on 2025/8/24.
//

import Combine
import Foundation

extension Publisher {
    func withLatestFrom<P>(
        _ other: P
    ) -> AnyPublisher<(Self.Output, P.Output), Failure> where P: Publisher, Self.Failure == P.Failure {
        let other = other
        // Note: Do not use `.map(Optional.some)` and `.prepend(nil)`.
        // There is a bug in iOS versions prior 14.5 in `.combineLatest`. If P.Output itself is Optional.
        // In this case prepended `Optional.some(nil)` will become just `nil` after `combineLatest`.
            .map { (value: $0, ()) }
            .prepend((value: nil, ()))
        
        return map { (value: $0, token: UUID()) }
            .combineLatest(other)
            .removeDuplicates(by: { (old, new) in
                let lhs = old.0, rhs = new.0
                return lhs.token == rhs.token
            })
            .map { ($0.value, $1.value) }
            .compactMap { (left, right) in
                right.map { (left, $0) }
            }
            .eraseToAnyPublisher()
    }
    
    
    func withLatestFrom2<P1, P2>(
        _ p1: P1,
        _ p2: P2
    ) -> AnyPublisher<(Self.Output, P1.Output, P2.Output), Failure>
    where P1: Publisher, P2: Publisher,
          Self.Failure == P1.Failure,
          Self.Failure == P2.Failure
    {
        // Workaround to avoid iOS <14.5 Optional combineLatest bug
        let latestP1 = p1
            .map { (value: $0, ()) }
            .prepend((value: nil, ()))
        
        let latestP2 = p2
            .map { (value: $0, ()) }
            .prepend((value: nil, ()))
        
        // Combine p1 and p2 first
        let combinedLatest = latestP1.combineLatest(latestP2)
        
        return self
            .map { (value: $0, token: UUID()) }
            .combineLatest(combinedLatest)
            .removeDuplicates(by: { $0.0.token == $1.0.token })
            .map { (left, right) in
                (left.value, right.0.value, right.1.value)
            }
            .compactMap { trigger, l1, l2 in
                if let l1 = l1, let l2 = l2 {
                    return (trigger, l1, l2)
                } else {
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
}
