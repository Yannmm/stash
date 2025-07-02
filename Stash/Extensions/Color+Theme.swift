//
//  Color+Theme.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/18.
//

import SwiftUICore
import AppKit

extension Color {
//    static var primary: Color {
//        return Color(hex: 0x7766E8)
//    }
    
    static var accent: Color {
        return Color(hex: 0xD3D3D3)
    }
    
    static var text: Color {
        return Color(hex: 0x2B2D31)
    }
    
    static var primary: Color {
        return Color(NSColor(name: nil) { appearance in
            if appearance.name == .darkAqua || appearance.name == .vibrantDark {
                return NSColor(Color(hex: 0xB0A8FF)) // Dark background
            } else {
                return NSColor(Color(hex: 0x7766E8)) // Light background
            }
        })
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
