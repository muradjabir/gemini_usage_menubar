import Foundation

public struct RealUsageProvider {
    public static func fetchAntigravityUsage() -> UsageSnapshot {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let geminiDir = home.appendingPathComponent(".gemini")
        
        let now = Date()
        let fiveHoursAgo = now.addingTimeInterval(-5 * 3600)
        let sevenDaysAgo = now.addingTimeInterval(-7 * 86400)
        
        var fiveHourCount: Double = 0
        var weeklyCount: Double = 0
        var timestampsIn5h: [Date] = []
        var weekdayCounts: [Int: Double] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
        
        let calendar = Calendar.current
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackIsoFormatter = ISO8601DateFormatter()
        fallbackIsoFormatter.formatOptions = [.withInternetDateTime]
        
        // Scan all conversation brain transcripts in ~/.gemini/*/brain/*/.system_generated/logs/transcript.jsonl
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
                    
                    for line in text.split(separator: "\n") {
                        if line.contains("\"type\":\"PLANNER_RESPONSE\"") || line.contains("\"type\":\"USER_INPUT\"") {
                            guard let lineData = line.data(using: .utf8),
                                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                                  let createdAtStr = json["created_at"] as? String else {
                                continue
                            }
                            
                            guard let date = isoFormatter.date(from: createdAtStr) ?? fallbackIsoFormatter.date(from: createdAtStr) else {
                                continue
                            }
                            
                            if date >= sevenDaysAgo {
                                weeklyCount += 1
                                // Calendar weekday: 1 = Sun, 2 = Mon ... 7 = Sat
                                // Convert to Mon=0 .. Sun=6
                                let rawWeekday = calendar.component(.weekday, from: date)
                                let monIndex = (rawWeekday + 5) % 7
                                weekdayCounts[monIndex, default: 0] += 1
                            }
                            
                            if date >= fiveHoursAgo {
                                fiveHourCount += 1
                                timestampsIn5h.append(date)
                            }
                        }
                    }
                }
            }
        }
        
        // Compute next reset slot countdown
        timestampsIn5h.sort()
        var nextSlotReset: TimeInterval = 0
        if let oldest = timestampsIn5h.first {
            let target = oldest.addingTimeInterval(5 * 3600)
            nextSlotReset = max(0, target.timeIntervalSince(now))
        }
        
        let dayNames = ["M", "T", "W", "T", "F", "S", "S"]
        let maxDaily = max(100.0, (weekdayCounts.values.max() ?? 100.0) * 1.1)
        var days: [DailyUsage] = []
        for i in 0..<7 {
            days.append(DailyUsage(
                dayName: dayNames[i],
                count: weekdayCounts[i] ?? 0,
                maxCap: maxDaily
            ))
        }
        
        // Quota caps: defaults to 1,000 for 5h window and 3,000 for weekly allocation if not set
        let fiveHourCap: Double = max(1000.0, fiveHourCount * 1.1)
        let weeklyCap: Double = max(3000.0, weeklyCount * 1.1)
        
        return UsageSnapshot(
            source: .antigravity,
            fiveHourUsed: fiveHourCount,
            fiveHourLimit: fiveHourCap,
            nextSlotResetSeconds: nextSlotReset,
            fullResetSeconds: max(0, 5 * 3600 - (nextSlotReset)),
            weeklyUsed: weeklyCount,
            weeklyLimit: weeklyCap,
            weeklyDays: days
        )
    }
}
