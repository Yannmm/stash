//
//  Notification+Extension.swift
//  Stash
//
//  Created by Rayman on 2025/4/9.
//

import Foundation

// passing data from uikit to swiftui https://www.swiftjectivec.com/events-from-swiftui-to-uikit-and-vice-versa/
extension NSNotification.Name {
    static let onDoubleTapRowView = NSNotification.Name("onDoubleTapRowView")
    static let onCmdKeyChange = NSNotification.Name("onCmdKeyChange")
    static let onShortcutKeyDown = NSNotification.Name("onShortcutKeyDown")
    static let onExpandOrCollapseItem = NSNotification.Name("onExpandOrCollapseItem")
}
