import Foundation

public enum UsageSource: String, CaseIterable, Identifiable {
    case antigravity = "Antigravity IDE"
    case geminiArgon = "Gemini Argon"
    case claudeOpus = "Claude Opus"
    case geminiFlash = "Gemini Flash"

    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .antigravity: return "sparkles"
        case .geminiArgon: return "bolt.shield.fill"
        case .claudeOpus: return "brain.head.profile"
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
    public var dailyUsed: Double
    public var dailyLimit: Double
    
    public var weeklyUsed: Double
    public var weeklyLimit: Double
    public var weeklyDays: [DailyUsage]
    
    public var dailyPercent: Double {
        guard dailyLimit > 0 else { return 0 }
        return (dailyUsed / dailyLimit) * 100
    }
    
    public var weeklyPercent: Double {
        guard weeklyLimit > 0 else { return 0 }
        return (weeklyUsed / weeklyLimit) * 100
    }
    
    // Primary gauge percentage for menu bar or quick status:
    // Takes the higher exhaustion level between daily and weekly
    public var maxExhaustionPercent: Double {
        max(dailyPercent, weeklyPercent)
    }
    
    public static var mockAntigravity: UsageSnapshot {
        UsageSnapshot(
            source: .antigravity,
            dailyUsed: 12,
            dailyLimit: 50,
            weeklyUsed: 115,
            weeklyLimit: 250,
            weeklyDays: []
        )
    }
    
    public static var mockGeminiArgon: UsageSnapshot {
        UsageSnapshot(
            source: .geminiArgon,
            dailyUsed: 15,
            dailyLimit: 20,
            weeklyUsed: 22,
            weeklyLimit: 25,
            weeklyDays: []
        )
    }
    
    public static var mockClaudeOpus: UsageSnapshot {
        UsageSnapshot(
            source: .claudeOpus,
            dailyUsed: 18,
            dailyLimit: 20,
            weeklyUsed: 22,
            weeklyLimit: 25,
            weeklyDays: []
        )
    }
    
    public static var mockGeminiFlash: UsageSnapshot {
        UsageSnapshot(
            source: .geminiFlash,
            dailyUsed: 4,
            dailyLimit: 100,
            weeklyUsed: 70,
            weeklyLimit: 500,
            weeklyDays: []
        )
    }
}
