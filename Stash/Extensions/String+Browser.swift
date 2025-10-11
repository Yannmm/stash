//
//  String+Browsers.swift
//  Stash
//
//  Created by Rayman on 2025/7/2.
//

extension String {
    enum Browser: String, CaseIterable {
        case safari
        case chrome
        case firefox
        case edge
        
        var name: String {
            switch self {
            case .safari: return "Safari"
            case .chrome: return "Google Chrome"
            case .edge: return "Microsoft Edge"
            case .firefox: return "Firefox"
            }
        }
    }
}
