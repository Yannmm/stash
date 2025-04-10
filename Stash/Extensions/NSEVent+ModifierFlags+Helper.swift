//
//  NSEVent+ModifierFlags+Helper.swift
//  Stash
//
//  Created by Rayman on 2025/4/10.
//

import AppKit

extension NSEvent.ModifierFlags {
    func containsOnly(_ flags: NSEvent.ModifierFlags) -> Bool {
        return self.intersection(.deviceIndependentFlagsMask) == flags
    }
}
