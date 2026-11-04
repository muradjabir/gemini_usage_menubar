import Foundation
import Combine
import ServiceManagement

@MainActor
public final class UsageStore: ObservableObject {
    @Published public var antigravitySnapshot: UsageSnapshot = .mockAntigravity
    @Published public var geminiArgonSnapshot: UsageSnapshot = .mockGeminiArgon
    @Published public var geminiFlashSnapshot: UsageSnapshot = .mockGeminiFlash
    
    // Fallback combined snapshot for menu bar icons or general usage
    public var combinedGeminiSnapshot: UsageSnapshot {
        geminiArgonSnapshot
    }
    
    @Published public var agyMetric: UsageWindowMetric = .fiveHour
    @Published public var argonMetric: UsageWindowMetric = .fiveHour
    @Published public var flashMetric: UsageWindowMetric = .fiveHour
    
    @Published public var isRefreshing: Bool = false
    @Published public var lastUpdated: Date = Date()
    @Published public var launchAtLogin: Bool = false
    
    private var secondTimer: AnyCancellable?
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
                self.geminiFlashSnapshot = result.geminiFlash
                self.lastUpdated = Date()
            }
        }
    }
    
    private func startLiveTimers() {
        // Decrement reset seconds each second
        secondTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                func decrementSnap(_ snap: inout UsageSnapshot) {
                    if snap.nextSlotResetSeconds > 0 {
                        snap.nextSlotResetSeconds = max(0, snap.nextSlotResetSeconds - 1)
                    }
                    if snap.fullResetSeconds > 0 {
                        snap.fullResetSeconds = max(0, snap.fullResetSeconds - 1)
                    }
                }
                
                decrementSnap(&self.antigravitySnapshot)
                decrementSnap(&self.geminiArgonSnapshot)
                decrementSnap(&self.geminiFlashSnapshot)
            }
        
        // Auto-refresh from transcript files every 30 seconds
        pollTimer = Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshRealData()
            }
    }
}
