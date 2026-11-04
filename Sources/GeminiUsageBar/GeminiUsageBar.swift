import AppKit
import SwiftUI

@main
struct GeminiUsageBarApp {
    private static var lockFileDescriptor: Int32 = -1
    
    static func main() {
        // Enforce true OS-level single instance via BSD file lock
        let lockPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("com.muradjabir.GeminiUsageBar.lock")
        lockFileDescriptor = open(lockPath, O_CREAT | O_RDWR, 0o666)
        if lockFileDescriptor < 0 || flock(lockFileDescriptor, LOCK_EX | LOCK_NB) != 0 {
            // Another instance already holds the lock; exit immediately
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
