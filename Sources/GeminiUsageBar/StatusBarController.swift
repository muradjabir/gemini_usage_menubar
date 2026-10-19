import AppKit
import SwiftUI
import Combine

@MainActor
public final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var store: UsageStore
    private var cancellables = Set<AnyCancellable>()
    
    public init(store: UsageStore) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        
        super.init()
        
        setupPopover()
        setupStatusItem()
        bindStore()
    }
    
    private func setupPopover() {
        popover.contentSize = NSSize(width: 390, height: 400)
        popover.behavior = .transient
        popover.animates = true
        
        let contentView = PopoverContentView(store: store) { [weak self] in
            NSApplication.shared.terminate(self)
        }
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePopover(_:))
        updateStatusBarItem()
    }
    
    private func bindStore() {
        Publishers.CombineLatest(store.$antigravitySnapshot, store.$geminiSnapshot)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.updateStatusBarItem()
            }
            .store(in: &cancellables)
    }
    
    private func updateStatusBarItem() {
        guard let button = statusItem.button else { return }
        
        let agyPercent = store.antigravitySnapshot.fiveHourPercent
        let gemPercent = store.geminiSnapshot.fiveHourPercent
        
        // Render dynamic dual circular gauge image
        let gaugeImage = MenuBarGaugeRenderer.renderGaugeIcon(
            agyPercent: agyPercent,
            geminiPercent: gemPercent
        )
        
        button.image = gaugeImage
        button.imagePosition = .imageOnly
        button.title = ""
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
