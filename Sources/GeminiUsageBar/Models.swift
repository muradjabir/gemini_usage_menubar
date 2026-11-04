import Foundation

public enum UsageSource: String, CaseIterable, Identifiable {
    case antigravity = "Antigravity IDE"
    case geminiArgon = "Gemini Argon"
    case geminiFlash = "Gemini Flash"

    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .antigravity: return "sparkles"
        case .geminiArgon: return "bolt.shield.fill"
        case .geminiFlash: return "bolt.fill"
        }
    }
}

public struct DailyUsage: Identifiable {
    public let id = UUID()
    public let dayName: String
    public let count: Double
    public let maxCap: Double
    
    public var fraction: Double {
        guard maxCap > 0 else { return 0 }
        return min(max(count / maxCap, 0), 1.0)
    }
}

public struct UsageSnapshot {
    public var source: UsageSource
    public var fiveHourUsed: Double
    public var fiveHourLimit: Double
    public var nextSlotResetSeconds: TimeInterval
    public var fullResetSeconds: TimeInterval
    
    public var weeklyUsed: Double
    public var weeklyLimit: Double
    public var weeklyDays: [DailyUsage]
    
    public var fiveHourPercent: Double {
        guard fiveHourLimit > 0 else { return 0 }
        return (fiveHourUsed / fiveHourLimit) * 100
    }
    
    public var weeklyPercent: Double {
        guard weeklyLimit > 0 else { return 0 }
        return (weeklyUsed / weeklyLimit) * 100
    }
    
    public static var mockAntigravity: UsageSnapshot {
        UsageSnapshot(
            source: .antigravity,
            fiveHourUsed: 68,
            fiveHourLimit: 100,
            nextSlotResetSeconds: 42 * 60 + 15,
            fullResetSeconds: 2 * 3600 + 15 * 60,
            weeklyUsed: 331,
            weeklyLimit: 500,
            weeklyDays: []
        )
    }
    
    public static var mockGeminiArgon: UsageSnapshot {
        UsageSnapshot(
            source: .geminiArgon,
            fiveHourUsed: 45,
            fiveHourLimit: 100,
            nextSlotResetSeconds: 30 * 60,
            fullResetSeconds: 2 * 3600,
            weeklyUsed: 210,
            weeklyLimit: 500,
            weeklyDays: []
        )
    }
    
    public static var mockGeminiFlash: UsageSnapshot {
        UsageSnapshot(
            source: .geminiFlash,
            fiveHourUsed: 30,
            fiveHourLimit: 250,
            nextSlotResetSeconds: 15 * 60,
            fullResetSeconds: 1 * 3600,
            weeklyUsed: 150,
            weeklyLimit: 1000,
            weeklyDays: []
        )
    }
}
