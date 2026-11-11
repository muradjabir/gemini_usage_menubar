import AppKit
import SwiftUI
import Combine

@MainActor
public final class StatusBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var contextMenu: NSMenu
    private var store: UsageStore
    private var cancellables = Set<AnyCancellable>()
    
    public init(store: UsageStore) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        self.contextMenu = NSMenu()
        
        super.init()
        
        setupPopover()
        setupContextMenu()
        setupStatusItem()
        bindStore()
    }
    
    private func setupPopover() {
        popover.contentSize = NSSize(width: 380, height: 530)
        popover.behavior = .transient
        popover.animates = true
        
        let contentView = PopoverContentView(store: store)
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    private func setupContextMenu() {
        contextMenu.delegate = self
        
        // App title / header
        let titleItem = NSMenuItem(title: "AI Usage Monitor (v\(UpdateChecker.currentVersion))", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        contextMenu.addItem(titleItem)
        
        contextMenu.addItem(NSMenuItem.separator())
        
        // Refresh Now
        let refreshItem = NSMenuItem(title: "Refresh Usage Data", action: #selector(refreshClicked), keyEquivalent: "r")
        refreshItem.target = self
        contextMenu.addItem(refreshItem)
        
        // Check for Updates
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkUpdatesClicked), keyEquivalent: "u")
        updateItem.target = self
        contextMenu.addItem(updateItem)
        
        // About
        let aboutItem = NSMenuItem(title: "About AI Usage Bar...", action: #selector(aboutClicked), keyEquivalent: "")
        aboutItem.target = self
        contextMenu.addItem(aboutItem)
        
        contextMenu.addItem(NSMenuItem.separator())
        
        // Exit / Quit
        let exitItem = NSMenuItem(title: "Exit", action: #selector(exitClicked), keyEquivalent: "q")
        exitItem.target = self
        contextMenu.addItem(exitItem)
    }
    
    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateStatusBarItem()
    }
    
    private func bindStore() {
        Publishers.CombineLatest4(
            store.$antigravitySnapshot,
            store.$geminiArgonSnapshot,
            store.$claudeOpusSnapshot,
            store.$geminiFlashSnapshot
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            self?.updateStatusBarItem()
        }
        .store(in: &cancellables)
    }
    
    private func updateStatusBarItem() {
        guard let button = statusItem.button else { return }
        
        // Left Gauge: Antigravity Agent platform exhaustion
        let agyPercent = store.antigravitySnapshot.maxExhaustionPercent
        
        // Right Gauge: Highest exhausted model between Claude, Argon, and Flash
        let modelPercent = max(
            store.claudeOpusSnapshot.maxExhaustionPercent,
            store.geminiArgonSnapshot.maxExhaustionPercent,
            store.geminiFlashSnapshot.maxExhaustionPercent
        )
        
        let gaugeImage = MenuBarGaugeRenderer.renderGaugeIcon(
            agyPercent: agyPercent,
            geminiPercent: modelPercent
        )
        
        button.image = gaugeImage
        button.imagePosition = .imageOnly
        button.title = ""
    }
    
    @objc private func statusItemClicked(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent, let button = statusItem.button else { return }
        
        if event.type == .rightMouseUp {
            if popover.isShown {
                popover.performClose(sender)
            }
            statusItem.menu = contextMenu
            button.performClick(nil)
            statusItem.menu = nil
        } else {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    @objc private func refreshClicked() {
        store.refresh()
    }
    
    @objc private func checkUpdatesClicked() {
        Task {
            await UpdateChecker.shared.checkForUpdates(manual: true)
        }
    }
    
    @objc private func aboutClicked() {
        let alert = NSAlert()
        alert.messageText = "AI Usage Monitor"
        alert.informativeText = "Version \(UpdateChecker.currentVersion)\n\nA native macOS menu bar status monitor tracking daily and weekly usage quotas for Claude Opus, Gemini Argon, Gemini Flash, and Antigravity IDE.\n\nDeveloped by Murad Jabir."
        alert.alertStyle = .informational
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let icon = NSImage(contentsOfFile: iconPath) {
            alert.icon = icon
        }
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "GitHub Repository")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            if let url = URL(string: "https://github.com/muradjabir/gemini_usage_menubar") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    @objc private func exitClicked() {
        NSApplication.shared.terminate(self)
    }
}
