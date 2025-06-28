//
//  Geometry.swift
//  Stash
//
//  Created by Yan Meng on 2025/6/27.
//

import Foundation

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
