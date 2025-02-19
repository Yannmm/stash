//
//  CustomMenuItem.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/11.
//

import AppKit

class CustomMenuItem: NSMenuItem {
    
    let object: (any Entry)?
    
    init(title string: String, action selector: Selector?, keyEquivalent charCode: String, with object: (any Entry)?) {
        self.object = object
        super.init(title: string, action: selector, keyEquivalent: charCode)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
