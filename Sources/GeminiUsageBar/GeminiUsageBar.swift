import AppKit
import SwiftUI

@main
struct GeminiUsageBarApp {
    static func main() {
        // Enforce single instance using bundle identifier check
        let bundleID = Bundle.main.bundleIdentifier ?? "com.muradjabir.GeminiUsageBar"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if runningApps.count > 1 {
            // Already running another instance; terminate this duplicate immediately
            exit(0)
        }
        
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // Hides from Dock, keeps purely in MenuBar
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private let store = UsageStore()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(store: store)
    }
}
