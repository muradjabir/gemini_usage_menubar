import SwiftUI

public enum CircularGaugeMetric: String, CaseIterable, Identifiable {
    case fiveHour = "5h"
    case weekly = "Wk"
    
    public var id: String { rawValue }
}

public struct CircularGaugeCardView: View {
    let title: String
    let snapshot: UsageSnapshot
    let isAntigravity: Bool
    @Binding var selectedMetric: CircularGaugeMetric
    
    public init(title: String, snapshot: UsageSnapshot, isAntigravity: Bool, selectedMetric: Binding<CircularGaugeMetric>) {
        self.title = title
        self.snapshot = snapshot
        self.isAntigravity = isAntigravity
        self._selectedMetric = selectedMetric
    }
    
    private var currentPercent: Double {
        switch selectedMetric {
        case .fiveHour: return snapshot.fiveHourPercent
        case .weekly: return snapshot.weeklyPercent
        }
    }
    
    private var gaugeColor: LinearGradient {
        if currentPercent >= 90 {
            return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if currentPercent >= 75 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if isAntigravity {
            return LinearGradient(colors: [Color.cyan, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.blue, Color(red: 0.8, green: 0.3, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Card Title & Metric Toggle
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Picker("", selection: $selectedMetric) {
                    Text("5h").tag(CircularGaugeMetric.fiveHour)
                    Text("Wk").tag(CircularGaugeMetric.weekly)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
            }
            
            // Concentric Circular Gauge with Centered Brand Logo
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 110, height: 110)
                
                // Progress Arc
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(currentPercent / 100.0, 0.0), 1.0)))
                    .stroke(
                        gaugeColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPercent)
                
                // Center Brand Logo & Percentage Overlay
                VStack(spacing: 2) {
                    if isAntigravity {
                        AntigravityIconView(size: 34)
                    } else {
                        GeminiLogoView(size: 34)
                    }
                    
                    Text("\(Int(currentPercent))%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 6)
            
            // Metric Details (5h slot countdown & weekly usage)
            VStack(spacing: 4) {
                if selectedMetric == .fiveHour {
                    Text("\(Int(snapshot.fiveHourUsed)) / \(Int(snapshot.fiveHourLimit)) reqs (5h)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary.opacity(0.85))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 9))
                        Text("Reset: \(UsageStore.formatDuration(snapshot.nextSlotResetSeconds))")
                            .font(.system(size: 10))
                            .monospacedDigit()
                    }
                    .foregroundColor(.secondary)
                } else {
                    Text("\(Int(snapshot.weeklyUsed)) / \(Int(snapshot.weeklyLimit)) reqs (Weekly)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary.opacity(0.85))
                    
                    Text("Resets Mon 00:00")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}
