import SwiftUI

public struct ModelProgressBarCardView: View {
    let title: String
    let subtitle: String
    let snapshot: UsageSnapshot
    let accentGradient: LinearGradient
    
    public init(
        title: String,
        subtitle: String,
        snapshot: UsageSnapshot,
        accentGradient: LinearGradient
    ) {
        self.title = title
        self.subtitle = subtitle
        self.snapshot = snapshot
        self.accentGradient = accentGradient
    }
    
    private func barGradient(for percent: Double) -> LinearGradient {
        if percent >= 90 {
            return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        } else if percent >= 75 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else {
            return accentGradient
        }
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Header Row: Model Title & Badge
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .fill(Color.primary.opacity(0.06))
                        )
                }
                
                Spacer()
                
                // Show if currently near limit / exhausted
                if snapshot.maxExhaustionPercent >= 88 {
                    Text("LIMIT REACHED")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.12))
                        )
                }
            }
            
            // Dual Progress Section: Daily & Weekly simultaneously visible
            VStack(spacing: 6) {
                // 1. Daily Usage Row
                metricRow(
                    label: "Today",
                    used: snapshot.dailyUsed,
                    limit: snapshot.dailyLimit,
                    percent: snapshot.dailyPercent
                )
                
                // 2. Weekly Usage Row
                metricRow(
                    label: "Weekly",
                    used: snapshot.weeklyUsed,
                    limit: snapshot.weeklyLimit,
                    percent: snapshot.weeklyPercent
                )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.45))
        )
    }
    
    @ViewBuilder
    private func metricRow(label: String, used: Double, limit: Double, percent: Double) -> some View {
        VStack(spacing: 3) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.0f / %.0f reqs", used, limit))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.0f%%", min(percent, 100.0)))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(percent >= 90 ? .red : (percent >= 75 ? .orange : .primary))
                    .frame(width: 38, alignment: .trailing)
            }
            
            // Linear Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.07))
                        .frame(height: 5.5)
                    
                    Capsule()
                        .fill(barGradient(for: percent))
                        .frame(
                            width: max(5.5, geo.size.width * CGFloat(min(max(percent / 100.0, 0.0), 1.0))),
                            height: 5.5
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: percent)
                }
            }
            .frame(height: 5.5)
        }
    }
}
