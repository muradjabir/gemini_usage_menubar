import AppKit
import SwiftUI

@main
struct GeminiUsageBarApp {
    static func main() {
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
