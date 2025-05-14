import Foundation
import ServiceManagement

class RocketLauncher {
    static let shared = RocketLauncher()
    
    private let service = SMAppService.mainApp
    
    var enabled: Bool {
        get {
            service.status == .enabled
        }
        set {
            do {
                if newValue {
                    if service.status == .enabled {
                        try service.unregister()
                    }
                    try service.register()
                } else {
                    try service.unregister()
                }
            } catch {
                ErrorTracker.shared.add(error, ["desc": "❌ Failed to \(newValue ? "enable" : "disable") launch at login: \(error)"])
            }
        }
    }
}
