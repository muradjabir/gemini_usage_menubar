import Foundation
import Combine
import ServiceManagement

@MainActor
public final class UsageStore: ObservableObject {
    @Published public var antigravitySnapshot: UsageSnapshot = .mockAntigravity
    @Published public var geminiSnapshot: UsageSnapshot = .mockGeminiApi
    @Published public var agyMetric: CircularGaugeMetric = .fiveHour
    @Published public var geminiMetric: CircularGaugeMetric = .fiveHour
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
                // Fallback check
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }
    
    public func refreshRealData() {
        Task.detached(priority: .background) {
            let realAgy = RealUsageProvider.fetchAntigravityUsage()
            await MainActor.run {
                self.antigravitySnapshot = realAgy
                self.lastUpdated = Date()
            }
        }
    }
    
    private func startLiveTimers() {
        // Ticking countdown timer every second
        secondTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.antigravitySnapshot.nextSlotResetSeconds > 0 {
                    self.antigravitySnapshot.nextSlotResetSeconds -= 1
                }
                if self.geminiSnapshot.nextSlotResetSeconds > 0 {
                    self.geminiSnapshot.nextSlotResetSeconds -= 1
                }
            }
        
        // Auto-refresh real usage every 30 seconds
        pollTimer = Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshRealData()
            }
    }
    
    public static func formatDuration(_ seconds: TimeInterval) -> String {
        let secs = Int(max(0, seconds))
        let hours = secs / 3600
        let minutes = (secs % 3600) / 60
        let s = secs % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(s)s"
        } else {
            return "\(s)s"
        }
    }
}
