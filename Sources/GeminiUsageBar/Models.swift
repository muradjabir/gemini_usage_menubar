import Foundation

public enum UsageSource: String, CaseIterable, Identifiable {
    case antigravity = "Antigravity IDE"
    case geminiApi = "Gemini API"

    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .antigravity: return "sparkles"
        case .geminiApi: return "bolt.fill"
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
        let days = [
            DailyUsage(dayName: "M", count: 45, maxCap: 100),
            DailyUsage(dayName: "T", count: 78, maxCap: 100),
            DailyUsage(dayName: "W", count: 92, maxCap: 100),
            DailyUsage(dayName: "T", count: 64, maxCap: 100),
            DailyUsage(dayName: "F", count: 35, maxCap: 100),
            DailyUsage(dayName: "S", count: 12, maxCap: 100),
            DailyUsage(dayName: "S", count: 5, maxCap: 100)
        ]
        return UsageSnapshot(
            source: .antigravity,
            fiveHourUsed: 68,
            fiveHourLimit: 100,
            nextSlotResetSeconds: 42 * 60 + 15,
            fullResetSeconds: 2 * 3600 + 15 * 60,
            weeklyUsed: 331,
            weeklyLimit: 500,
            weeklyDays: days
        )
    }
    
    public static var mockGeminiApi: UsageSnapshot {
        let days = [
            DailyUsage(dayName: "M", count: 1.2, maxCap: 5.0),
            DailyUsage(dayName: "T", count: 2.8, maxCap: 5.0),
            DailyUsage(dayName: "W", count: 3.4, maxCap: 5.0),
            DailyUsage(dayName: "T", count: 2.1, maxCap: 5.0),
            DailyUsage(dayName: "F", count: 1.8, maxCap: 5.0),
            DailyUsage(dayName: "S", count: 0.6, maxCap: 5.0),
            DailyUsage(dayName: "S", count: 0.4, maxCap: 5.0)
        ]
        return UsageSnapshot(
            source: .geminiApi,
            fiveHourUsed: 220,
            fiveHourLimit: 1000,
            nextSlotResetSeconds: 15 * 60 + 40,
            fullResetSeconds: 1 * 3600 + 45 * 60,
            weeklyUsed: 12.3,
            weeklyLimit: 25.0,
            weeklyDays: days
        )
    }
}
