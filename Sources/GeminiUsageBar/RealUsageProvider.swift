import Foundation

public struct RealUsageResult {
    public let antigravity: UsageSnapshot
    public let geminiHydrogen: UsageSnapshot
    public let geminiArgon: UsageSnapshot
    public let geminiFlash: UsageSnapshot
    public let claudeOpus: UsageSnapshot
}

public struct RealUsageProvider {
    // Realistic plan quota baselines for Antigravity tiers:
    // Hydrogen (New flagship medium reasoning): ~25 daily / ~30 weekly
    // Argon (Pro reasoning): ~20 daily / ~25 weekly
    // Flash (High-throughput speed tier): ~100 daily / ~500 weekly
    // Claude Opus (Anthropic reasoning): ~20 daily / ~25 weekly
    // Total Antigravity agent capacity: ~100 daily / ~500 weekly
    public static let hydrogenDailyLimit: Double = 25.0
    public static let hydrogenWeeklyLimit: Double = 30.0
    
    public static let argonDailyLimit: Double = 20.0
    public static let argonWeeklyLimit: Double = 25.0
    
    public static let flashDailyLimit: Double = 100.0
    public static let flashWeeklyLimit: Double = 500.0
    
    public static let claudeDailyLimit: Double = 20.0
    public static let claudeWeeklyLimit: Double = 25.0
    
    public static let agyDailyLimit: Double = 100.0
    public static let agyWeeklyLimit: Double = 500.0

    public static func fetchUsage() -> RealUsageResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let geminiDir = home.appendingPathComponent(".gemini")
        
        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let sevenDaysAgo = now.addingTimeInterval(-7 * 86400)
        
        var agyDailyCount: Double = 0
        var agyWkCount: Double = 0
        var agyWkDays: [Int: Double] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
        
        var hydrogenDailyCount: Double = 0
        var hydrogenWkCount: Double = 0
        var hydrogenWkDays: [Int: Double] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
        
        var argonDailyCount: Double = 0
        var argonWkCount: Double = 0
        var argonWkDays: [Int: Double] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
        
        var flashDailyCount: Double = 0
        var flashWkCount: Double = 0
        var flashWkDays: [Int: Double] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
        
        var claudeDailyCount: Double = 0
        var claudeWkCount: Double = 0
        var claudeWkDays: [Int: Double] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackIsoFormatter = ISO8601DateFormatter()
        fallbackIsoFormatter.formatOptions = [.withInternetDateTime]
        
        let fileManager = FileManager.default
        if let subdirs = try? fileManager.contentsOfDirectory(at: geminiDir, includingPropertiesForKeys: nil) {
            for appDir in subdirs {
                let brainDir = appDir.appendingPathComponent("brain")
                guard fileManager.fileExists(atPath: brainDir.path) else { continue }
                guard let convDirs = try? fileManager.contentsOfDirectory(at: brainDir, includingPropertiesForKeys: nil) else { continue }
                
                for convDir in convDirs {
                    // Only read transcript.jsonl to avoid duplicates from transcript_full.jsonl
                    let transcriptPath = convDir
                        .appendingPathComponent(".system_generated")
                        .appendingPathComponent("logs")
                        .appendingPathComponent("transcript.jsonl")
                    
                    guard fileManager.fileExists(atPath: transcriptPath.path) else { continue }
                    guard let fileHandle = try? FileHandle(forReadingFrom: transcriptPath) else { continue }
                    defer { try? fileHandle.close() }
                    
                    let data = fileHandle.readDataToEndOfFile()
                    guard let text = String(data: data, encoding: .utf8) else { continue }
                    
                    var currentTier: String = "flash"
                    
                    for line in text.split(separator: "\n") {
                        if line.contains("USER_SETTINGS_CHANGE") || line.contains("Model Selection") {
                            let lower = line.lowercased()
                            if lower.contains("hydrogen") {
                                currentTier = "hydrogen"
                            } else if lower.contains("argon") {
                                currentTier = "argon"
                            } else if lower.contains("claude") {
                                currentTier = "claude"
                            } else if lower.contains("flash") {
                                currentTier = "flash"
                            } else if lower.contains("pro") {
                                currentTier = "argon"
                            }
                        }
                        
                        // Count user prompts (USER_INPUT)
                        if line.contains("\"type\":\"USER_INPUT\"") {
                            guard let lineData = line.data(using: .utf8),
                                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                                  let createdAtStr = json["created_at"] as? String else {
                                continue
                            }
                            
                            guard let date = isoFormatter.date(from: createdAtStr) ?? fallbackIsoFormatter.date(from: createdAtStr) else {
                                continue
                            }
                            
                            let rawWeekday = calendar.component(.weekday, from: date)
                            // Convert Sunday=1, Monday=2 -> Monday=0 .. Sunday=6
                            let monIndex = (rawWeekday + 5) % 7
                            
                            if date >= sevenDaysAgo {
                                agyWkCount += 1
                                agyWkDays[monIndex, default: 0] += 1
                                
                                switch currentTier {
                                case "hydrogen":
                                    hydrogenWkCount += 1
                                    hydrogenWkDays[monIndex, default: 0] += 1
                                case "argon":
                                    argonWkCount += 1
                                    argonWkDays[monIndex, default: 0] += 1
                                case "claude":
                                    claudeWkCount += 1
                                    claudeWkDays[monIndex, default: 0] += 1
                                case "flash":
                                    flashWkCount += 1
                                    flashWkDays[monIndex, default: 0] += 1
                                default:
                                    flashWkCount += 1
                                    flashWkDays[monIndex, default: 0] += 1
                                }
                            }
                            
                            if date >= todayStart {
                                agyDailyCount += 1
                                
                                switch currentTier {
                                case "hydrogen":
                                    hydrogenDailyCount += 1
                                case "argon":
                                    argonDailyCount += 1
                                case "claude":
                                    claudeDailyCount += 1
                                case "flash":
                                    flashDailyCount += 1
                                default:
                                    flashDailyCount += 1
                                }
                            }
                        }
                    }
                }
            }
        }
        
        let dayNames = ["M", "T", "W", "T", "F", "S", "S"]
        func makeDailyUsage(counts: [Int: Double], dailyCap: Double) -> [DailyUsage] {
            return (0..<7).map { i in
                DailyUsage(dayName: dayNames[i], count: counts[i] ?? 0, maxCap: dailyCap)
            }
        }
        
        let agySnap = UsageSnapshot(
            source: .antigravity,
            dailyUsed: agyDailyCount,
            dailyLimit: agyDailyLimit,
            weeklyUsed: agyWkCount,
            weeklyLimit: agyWeeklyLimit,
            weeklyDays: makeDailyUsage(counts: agyWkDays, dailyCap: max(20.0, (agyWkDays.values.max() ?? 20.0) * 1.2))
        )
        
        let hydrogenSnap = UsageSnapshot(
            source: .geminiHydrogen,
            dailyUsed: hydrogenDailyCount,
            dailyLimit: hydrogenDailyLimit,
            weeklyUsed: hydrogenWkCount,
            weeklyLimit: hydrogenWeeklyLimit,
            weeklyDays: makeDailyUsage(counts: hydrogenWkDays, dailyCap: max(10.0, (hydrogenWkDays.values.max() ?? 10.0) * 1.2))
        )
        
        let argonSnap = UsageSnapshot(
            source: .geminiArgon,
            dailyUsed: argonDailyCount,
            dailyLimit: argonDailyLimit,
            weeklyUsed: argonWkCount,
            weeklyLimit: argonWeeklyLimit,
            weeklyDays: makeDailyUsage(counts: argonWkDays, dailyCap: max(10.0, (argonWkDays.values.max() ?? 10.0) * 1.2))
        )
        
        let flashSnap = UsageSnapshot(
            source: .geminiFlash,
            dailyUsed: flashDailyCount,
            dailyLimit: flashDailyLimit,
            weeklyUsed: flashWkCount,
            weeklyLimit: flashWeeklyLimit,
            weeklyDays: makeDailyUsage(counts: flashWkDays, dailyCap: max(20.0, (flashWkDays.values.max() ?? 20.0) * 1.2))
        )
        
        let claudeSnap = UsageSnapshot(
            source: .claudeOpus,
            dailyUsed: claudeDailyCount,
            dailyLimit: claudeDailyLimit,
            weeklyUsed: claudeWkCount,
            weeklyLimit: claudeWeeklyLimit,
            weeklyDays: makeDailyUsage(counts: claudeWkDays, dailyCap: max(10.0, (claudeWkDays.values.max() ?? 10.0) * 1.2))
        )
        
        return RealUsageResult(
            antigravity: agySnap,
            geminiHydrogen: hydrogenSnap,
            geminiArgon: argonSnap,
            geminiFlash: flashSnap,
            claudeOpus: claudeSnap
        )
    }
}
