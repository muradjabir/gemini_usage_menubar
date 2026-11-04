import Foundation

public struct RealUsageResult {
    public let antigravity: UsageSnapshot
    public let gemini: UsageSnapshot
}

public struct RealUsageProvider {
    public static func fetchUsage() -> RealUsageResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let geminiDir = home.appendingPathComponent(".gemini")
        
        let now = Date()
        let fiveHoursAgo = now.addingTimeInterval(-5 * 3600)
        let sevenDaysAgo = now.addingTimeInterval(-7 * 86400)
        
        var agyFiveHourCount: Double = 0
        var agyWeeklyCount: Double = 0
        var agyTimestampsIn5h: [Date] = []
        var agyWeekdayCounts: [Int: Double] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
        
        var geminiFiveHourCount: Double = 0
        var geminiWeeklyCount: Double = 0
        var geminiTimestampsIn5h: [Date] = []
        var geminiWeekdayCounts: [Int: Double] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
        
        let calendar = Calendar.current
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackIsoFormatter = ISO8601DateFormatter()
        fallbackIsoFormatter.formatOptions = [.withInternetDateTime]
        
        let fileManager = FileManager.default
        if let subdirs = try? fileManager.contentsOfDirectory(at: geminiDir, includingPropertiesForKeys: nil) {
            for appDir in subdirs {
                let brainDir = appDir.appendingPathComponent("brain")
                guard let convos = try? fileManager.contentsOfDirectory(at: brainDir, includingPropertiesForKeys: nil) else { continue }
                
                for convo in convos {
                    let logFile = convo.appendingPathComponent(".system_generated/logs/transcript.jsonl")
                    guard fileManager.fileExists(atPath: logFile.path) else { continue }
                    
                    // Check file modification date to skip old logs
                    if let attrs = try? fileManager.attributesOfItem(atPath: logFile.path),
                       let modDate = attrs[.modificationDate] as? Date,
                       modDate < sevenDaysAgo {
                        continue
                    }
                    
                    guard let fileHandle = try? FileHandle(forReadingFrom: logFile) else { continue }
                    defer { try? fileHandle.close() }
                    
                    let data = fileHandle.readDataToEndOfFile()
                    guard let text = String(data: data, encoding: .utf8) else { continue }
                    
                    var isGeminiSession = true
                    
                    for line in text.split(separator: "\n") {
                        // Detect active model changes (e.g. Gemini 3.8 Flash, Gemini 4 Argon, Claude Opus, etc.)
                        if line.contains("USER_SETTINGS_CHANGE") || line.contains("Model Selection") {
                            let lowerLine = line.lowercased()
                            if lowerLine.contains("claude") {
                                isGeminiSession = false
                            } else if lowerLine.contains("gemini") {
                                isGeminiSession = true
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
                            
                            // Antigravity tracks all IDE and CLI agent requests
                            if date >= sevenDaysAgo {
                                agyWeeklyCount += 1
                                agyWeekdayCounts[monIndex, default: 0] += 1
                                
                                if isGeminiSession {
                                    geminiWeeklyCount += 1
                                    geminiWeekdayCounts[monIndex, default: 0] += 1
                                }
                            }
                            
                            if date >= fiveHoursAgo {
                                agyFiveHourCount += 1
                                agyTimestampsIn5h.append(date)
                                
                                if isGeminiSession {
                                    geminiFiveHourCount += 1
                                    geminiTimestampsIn5h.append(date)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Compute next reset slot countdowns
        agyTimestampsIn5h.sort()
        var agyNextSlotReset: TimeInterval = 0
        if let oldest = agyTimestampsIn5h.first {
            let target = oldest.addingTimeInterval(5 * 3600)
            agyNextSlotReset = max(0, target.timeIntervalSince(now))
        }
        
        geminiTimestampsIn5h.sort()
        var geminiNextSlotReset: TimeInterval = 0
        if let oldest = geminiTimestampsIn5h.first {
            let target = oldest.addingTimeInterval(5 * 3600)
            geminiNextSlotReset = max(0, target.timeIntervalSince(now))
        }
        
        let dayNames = ["M", "T", "W", "T", "F", "S", "S"]
        let agyMaxDaily = max(100.0, (agyWeekdayCounts.values.max() ?? 100.0) * 1.1)
        var agyDays: [DailyUsage] = []
        for i in 0..<7 {
            agyDays.append(DailyUsage(
                dayName: dayNames[i],
                count: agyWeekdayCounts[i] ?? 0,
                maxCap: agyMaxDaily
            ))
        }
        
        let geminiMaxDaily = max(100.0, (geminiWeekdayCounts.values.max() ?? 100.0) * 1.1)
        var geminiDays: [DailyUsage] = []
        for i in 0..<7 {
            geminiDays.append(DailyUsage(
                dayName: dayNames[i],
                count: geminiWeekdayCounts[i] ?? 0,
                maxCap: geminiMaxDaily
            ))
        }
        
        // Dynamic, responsive quota scaling
        let agyFiveHourCap: Double = max(1000.0, agyFiveHourCount * 1.1)
        let agyWeeklyCap: Double = max(3000.0, agyWeeklyCount * 1.1)
        
        let geminiFiveHourCap: Double = max(1000.0, geminiFiveHourCount * 1.1)
        let geminiWeeklyCap: Double = max(3000.0, geminiWeeklyCount * 1.1)
        
        let agySnapshot = UsageSnapshot(
            source: .antigravity,
            fiveHourUsed: agyFiveHourCount,
            fiveHourLimit: agyFiveHourCap,
            nextSlotResetSeconds: agyNextSlotReset,
            fullResetSeconds: max(0, 5 * 3600 - agyNextSlotReset),
            weeklyUsed: agyWeeklyCount,
            weeklyLimit: agyWeeklyCap,
            weeklyDays: agyDays
        )
        
        let geminiSnapshot = UsageSnapshot(
            source: .geminiApi,
            fiveHourUsed: geminiFiveHourCount,
            fiveHourLimit: geminiFiveHourCap,
            nextSlotResetSeconds: geminiNextSlotReset,
            fullResetSeconds: max(0, 5 * 3600 - geminiNextSlotReset),
            weeklyUsed: geminiWeeklyCount,
            weeklyLimit: geminiWeeklyCap,
            weeklyDays: geminiDays
        )
        
        return RealUsageResult(antigravity: agySnapshot, gemini: geminiSnapshot)
    }
}
