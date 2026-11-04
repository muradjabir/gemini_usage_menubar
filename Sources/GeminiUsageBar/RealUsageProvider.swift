import Foundation

public struct RealUsageResult {
    public let antigravity: UsageSnapshot
    public let geminiArgon: UsageSnapshot
    public let geminiFlash: UsageSnapshot
}

public struct RealUsageProvider {
    // Fixed standard baseline quotas (so bars are stable and accurately reflect remaining allowance)
    public static let agy5hLimit: Double = 100.0     // Total prompts / interactions across all agents in 5h
    public static let agyWeeklyLimit: Double = 500.0
    
    public static let argon5hLimit: Double = 50.0     // Argon reasoning tier limit in 5h
    public static let argonWeeklyLimit: Double = 250.0
    
    public static let flash5hLimit: Double = 150.0    // Flash high-speed tier limit in 5h
    public static let flashWeeklyLimit: Double = 750.0

    public static func fetchUsage() -> RealUsageResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let geminiDir = home.appendingPathComponent(".gemini")
        
        let now = Date()
        let fiveHoursAgo = now.addingTimeInterval(-5 * 3600)
        let sevenDaysAgo = now.addingTimeInterval(-7 * 86400)
        
        var agy5hCount: Double = 0
        var agyWkCount: Double = 0
        var agy5hDates: [Date] = []
        var agyWkDays: [Int: Double] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
        
        var argon5hCount: Double = 0
        var argonWkCount: Double = 0
        var argon5hDates: [Date] = []
        var argonWkDays: [Int: Double] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
        
        var flash5hCount: Double = 0
        var flashWkCount: Double = 0
        var flash5hDates: [Date] = []
        var flashWkDays: [Int: Double] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
        
        let calendar = Calendar.current
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
                    // Only read transcript.jsonl (avoid counting transcript_full.jsonl duplicate)
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
                            if lower.contains("claude") {
                                currentTier = "other"
                            } else if lower.contains("argon") {
                                currentTier = "argon"
                            } else if lower.contains("flash") {
                                currentTier = "flash"
                            } else if lower.contains("pro") {
                                currentTier = "argon"
                            }
                        }
                        
                        // Count user prompts (USER_INPUT) - the true rate limit driver in Antigravity
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
                            let monIndex = (rawWeekday + 5) % 7
                            
                            if date >= sevenDaysAgo {
                                agyWkCount += 1
                                agyWkDays[monIndex, default: 0] += 1
                                
                                if currentTier == "argon" {
                                    argonWkCount += 1
                                    argonWkDays[monIndex, default: 0] += 1
                                } else if currentTier == "flash" {
                                    flashWkCount += 1
                                    flashWkDays[monIndex, default: 0] += 1
                                }
                            }
                            
                            if date >= fiveHoursAgo {
                                agy5hCount += 1
                                agy5hDates.append(date)
                                
                                if currentTier == "argon" {
                                    argon5hCount += 1
                                    argon5hDates.append(date)
                                } else if currentTier == "flash" {
                                    flash5hCount += 1
                                    flash5hDates.append(date)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        func computeSlotReset(for dates: inout [Date]) -> TimeInterval {
            dates.sort()
            guard let oldest = dates.first else { return 0 }
            let target = oldest.addingTimeInterval(5 * 3600)
            return max(0, target.timeIntervalSince(now))
        }
        
        let agyNextReset = computeSlotReset(for: &agy5hDates)
        let argonNextReset = computeSlotReset(for: &argon5hDates)
        let flashNextReset = computeSlotReset(for: &flash5hDates)
        
        let dayNames = ["M", "T", "W", "T", "F", "S", "S"]
        func makeDailyUsage(counts: [Int: Double], dailyCap: Double) -> [DailyUsage] {
            return (0..<7).map { i in
                DailyUsage(dayName: dayNames[i], count: counts[i] ?? 0, maxCap: dailyCap)
            }
        }
        
        let agySnap = UsageSnapshot(
            source: .antigravity,
            fiveHourUsed: agy5hCount,
            fiveHourLimit: agy5hLimit,
            nextSlotResetSeconds: agyNextReset,
            fullResetSeconds: max(0, 5 * 3600 - agyNextReset),
            weeklyUsed: agyWkCount,
            weeklyLimit: agyWeeklyLimit,
            weeklyDays: makeDailyUsage(counts: agyWkDays, dailyCap: max(20.0, (agyWkDays.values.max() ?? 20.0) * 1.2))
        )
        
        let argonSnap = UsageSnapshot(
            source: .geminiArgon,
            fiveHourUsed: argon5hCount,
            fiveHourLimit: argon5hLimit,
            nextSlotResetSeconds: argonNextReset,
            fullResetSeconds: max(0, 5 * 3600 - argonNextReset),
            weeklyUsed: argonWkCount,
            weeklyLimit: argonWeeklyLimit,
            weeklyDays: makeDailyUsage(counts: argonWkDays, dailyCap: max(15.0, (argonWkDays.values.max() ?? 15.0) * 1.2))
        )
        
        let flashSnap = UsageSnapshot(
            source: .geminiFlash,
            fiveHourUsed: flash5hCount,
            fiveHourLimit: flash5hLimit,
            nextSlotResetSeconds: flashNextReset,
            fullResetSeconds: max(0, 5 * 3600 - flashNextReset),
            weeklyUsed: flashWkCount,
            weeklyLimit: flashWeeklyLimit,
            weeklyDays: makeDailyUsage(counts: flashWkDays, dailyCap: max(25.0, (flashWkDays.values.max() ?? 25.0) * 1.2))
        )
        
        return RealUsageResult(
            antigravity: agySnap,
            geminiArgon: argonSnap,
            geminiFlash: flashSnap
        )
    }
}
