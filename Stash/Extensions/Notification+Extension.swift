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
    static let onOutlineViewRowCount = NSNotification.Name("onOutlineViewRowCount")
    static let onShouldPresentBookmarkForm = NSNotification.Name("onShouldPresentBookmarkForm")
    static let onShouldOpenImportPanel = NSNotification.Name("onShouldOpenImportPanel")
    static let onRowViewSelectionChange = NSNotification.Name("onRowViewSelectionChange")
    static let onEditPopoverClose = NSNotification.Name("onEditPopoverClose")
    static let onToggleOutlineView = NSNotification.Name("onToggleOutlineView")
    static let onCellBecomeFirstResponder = NSNotification.Name("onBecomeFirstResponder")
    static let onCellResignFirstResponder = NSNotification.Name("onResignFirstResponder")
    static let onDragWindow = NSNotification.Name("onDragWindow")
}
