import Foundation

public struct RealUsageResult {
    public let antigravity: UsageSnapshot
    public let geminiArgon: UsageSnapshot
    public let geminiFlash: UsageSnapshot
}

public struct RealUsageProvider {
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
                    let transcriptPath = convDir
                        .appendingPathComponent(".system_generated")
                        .appendingPathComponent("logs")
                        .appendingPathComponent("transcript.jsonl")
                    
                    guard fileManager.fileExists(atPath: transcriptPath.path) else { continue }
                    guard let fileHandle = try? FileHandle(forReadingFrom: transcriptPath) else { continue }
                    defer { try? fileHandle.close() }
                    
                    let data = fileHandle.readDataToEndOfFile()
                    guard let text = String(data: data, encoding: .utf8) else { continue }
                    
                    // Track model tier: "argon", "flash", or "other" (e.g. claude)
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
                                currentTier = "argon" // 3.1 Pro -> mapped to reasoning/Argon tier
                            }
                        }
                        
                        if line.contains("\"type\":\"PLANNER_RESPONSE\"") || line.contains("\"type\":\"USER_INPUT\"") {
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
        func makeDailyUsage(counts: [Int: Double]) -> [DailyUsage] {
            let maxVal = max(100.0, (counts.values.max() ?? 100.0) * 1.1)
            return (0..<7).map { i in
                DailyUsage(dayName: dayNames[i], count: counts[i] ?? 0, maxCap: maxVal)
            }
        }
        
        let agySnap = UsageSnapshot(
            source: .antigravity,
            fiveHourUsed: agy5hCount,
            fiveHourLimit: max(1000.0, agy5hCount * 1.1),
            nextSlotResetSeconds: agyNextReset,
            fullResetSeconds: max(0, 5 * 3600 - agyNextReset),
            weeklyUsed: agyWkCount,
            weeklyLimit: max(3000.0, agyWkCount * 1.1),
            weeklyDays: makeDailyUsage(counts: agyWkDays)
        )
        
        let argonSnap = UsageSnapshot(
            source: .geminiArgon,
            fiveHourUsed: argon5hCount,
            fiveHourLimit: max(1000.0, argon5hCount * 1.1),
            nextSlotResetSeconds: argonNextReset,
            fullResetSeconds: max(0, 5 * 3600 - argonNextReset),
            weeklyUsed: argonWkCount,
            weeklyLimit: max(3000.0, argonWkCount * 1.1),
            weeklyDays: makeDailyUsage(counts: argonWkDays)
        )
        
        let flashSnap = UsageSnapshot(
            source: .geminiFlash,
            fiveHourUsed: flash5hCount,
            fiveHourLimit: max(1000.0, flash5hCount * 1.1),
            nextSlotResetSeconds: flashNextReset,
            fullResetSeconds: max(0, 5 * 3600 - flashNextReset),
            weeklyUsed: flashWkCount,
            weeklyLimit: max(3000.0, flashWkCount * 1.1),
            weeklyDays: makeDailyUsage(counts: flashWkDays)
        )
        
        return RealUsageResult(
            antigravity: agySnap,
            geminiArgon: argonSnap,
            geminiFlash: flashSnap
        )
    }
}
