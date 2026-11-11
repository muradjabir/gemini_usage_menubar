import Foundation
import Combine
import ServiceManagement

@MainActor
public final class UsageStore: ObservableObject {
    @Published public var antigravitySnapshot: UsageSnapshot = .mockAntigravity
    @Published public var geminiArgonSnapshot: UsageSnapshot = .mockGeminiArgon
    @Published public var claudeOpusSnapshot: UsageSnapshot = .mockClaudeOpus
    @Published public var geminiFlashSnapshot: UsageSnapshot = .mockGeminiFlash
    
    @Published public var isRefreshing: Bool = false
    @Published public var lastUpdated: Date = Date()
    @Published public var launchAtLogin: Bool = false
    
    private var pollTimer: AnyCancellable?
    
    public init() {
        checkLaunchAtLoginStatus()
        refreshRealData()
        startLiveTimers()
    }
    
    public func refresh() {
        isRefreshing = true
        refreshRealData()
        checkLaunchAtLoginStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.isRefreshing = false
        }
    }
    
    public func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
    
    public func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    launchAtLogin = false
                } else {
                    try SMAppService.mainApp.register()
                    launchAtLogin = true
                }
            } catch {
                print("Failed to toggle launch at login:", error)
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }
    
    public func refreshRealData() {
        Task.detached(priority: .background) {
            let result = RealUsageProvider.fetchUsage()
            await MainActor.run {
                self.antigravitySnapshot = result.antigravity
                self.geminiArgonSnapshot = result.geminiArgon
                self.claudeOpusSnapshot = result.claudeOpus
                self.geminiFlashSnapshot = result.geminiFlash
                self.lastUpdated = Date()
            }
        }
    }
    
    private func startLiveTimers() {
        // Auto-refresh from transcript files every 30 seconds
        pollTimer = Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshRealData()
            }
    }
}
