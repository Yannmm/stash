//
//  Color+Theme.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/18.
//

import SwiftUICore

extension Color {
    static var theme: Color {
        return Color(hex: 0x7766E8)
    }
    
    static var text: Color {
        return Color(hex: 0x2B2D31)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
