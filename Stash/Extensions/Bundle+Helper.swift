//
//  Bundle+Helper.swift
//  Stash
//
//  Created by Yan Meng on 2025/5/11.
//

import Foundation

extension Bundle {
    var version: String? { infoDictionary?["CFBundleShortVersionString"] as? String }
    
    var buildNumber: String? { infoDictionary?["CFBundleVersion"] as? String }
    
    var builDate: Date?
    {
//        let bundleName = infoDictionary!["CFBundleName"] as? String ?? "Info.plist"
//        if let infoPath = path(forResource: bundleName, ofType: nil),
//           let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
//           let infoDate = infoAttr[FileAttributeKey.creationDate] as? Date
//        {
//            return infoDate
//        } else {
//            return nil
//        }
        
        let bundleName = infoDictionary!["CFBundleName"] as? String ?? "Info.plist"
        if let infoPath = path(forResource: "Info", ofType: "plist"),
            let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
            let infoDate = infoAttr[.modificationDate] as? Date {
            return infoDate
        }
        return nil
    }
}
