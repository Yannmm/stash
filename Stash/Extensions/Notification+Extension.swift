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
    static let onHoverRowView = NSNotification.Name("onHoverRowView")
    static let onCmdKeyChange = NSNotification.Name("onCmdKeyChange")
}
