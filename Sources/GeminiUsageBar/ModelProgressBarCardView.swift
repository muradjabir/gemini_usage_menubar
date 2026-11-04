import SwiftUI

public enum UsageWindowMetric: String, CaseIterable, Identifiable {
    case fiveHour = "5h"
    case weekly = "Wk"
    
    public var id: String { rawValue }
}

public struct ModelProgressBarCardView: View {
    let title: String
    let subtitle: String
    let snapshot: UsageSnapshot
    let accentGradient: LinearGradient
    @Binding var selectedMetric: UsageWindowMetric
    
    public init(
        title: String,
        subtitle: String,
        snapshot: UsageSnapshot,
        accentGradient: LinearGradient,
        selectedMetric: Binding<UsageWindowMetric>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.snapshot = snapshot
        self.accentGradient = accentGradient
        self._selectedMetric = selectedMetric
    }
    
    private var usedCount: Double {
        selectedMetric == .fiveHour ? snapshot.fiveHourUsed : snapshot.weeklyUsed
    }
    
    private var limitCount: Double {
        selectedMetric == .fiveHour ? snapshot.fiveHourLimit : snapshot.weeklyLimit
    }
    
    private var percent: Double {
        selectedMetric == .fiveHour ? snapshot.fiveHourPercent : snapshot.weeklyPercent
    }
    
    private var progressColor: LinearGradient {
        if percent >= 90 {
            return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        } else if percent >= 75 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else {
            return accentGradient
        }
    }
    
    private func formatCountdown(_ seconds: TimeInterval) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hrs > 0 {
            return String(format: "%dh %02dm", hrs, mins)
        } else {
            return String(format: "%02dm %02ds", mins, secs)
        }
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Header Row: Model Title & Metric Picker
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                }
                
                Spacer()
                
                // 5h vs Wk toggle
                Picker("", selection: $selectedMetric) {
                    Text("5h").tag(UsageWindowMetric.fiveHour)
                    Text("Wk").tag(UsageWindowMetric.weekly)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
            }
            
            // Sleek Horizontal Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 7)
                    
                    // Fill Bar
                    Capsule()
                        .fill(progressColor)
                        .frame(
                            width: max(7, geo.size.width * CGFloat(min(max(percent / 100.0, 0.0), 1.0))),
                            height: 7
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: percent)
                }
            }
            .frame(height: 7)
            
            // Stat Numbers & Reset Timer Row
            HStack {
                // Requests Count
                Text(String(format: "%.0f / %.0f reqs", usedCount, limitCount))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Percentage & Countdown
                HStack(spacing: 8) {
                    if selectedMetric == .fiveHour && snapshot.nextSlotResetSeconds > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text(formatCountdown(snapshot.nextSlotResetSeconds))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Text(String(format: "%.1f%%", percent))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.45))
        )
    }
}
