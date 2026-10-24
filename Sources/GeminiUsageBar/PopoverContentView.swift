import SwiftUI

public struct PopoverContentView: View {
    @ObservedObject var store: UsageStore
    
    public init(store: UsageStore) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header
            headerView
            
            Divider()
                .opacity(0.3)
            
            // Side-by-side Circular Gauge Cards
            HStack(spacing: 12) {
                CircularGaugeCardView(
                    title: "Antigravity",
                    snapshot: store.antigravitySnapshot,
                    isAntigravity: true,
                    selectedMetric: $store.agyMetric
                )
                
                CircularGaugeCardView(
                    title: "Gemini",
                    snapshot: store.geminiSnapshot,
                    isAntigravity: false,
                    selectedMetric: $store.geminiMetric
                )
            }
            
            // Combined Weekly Mini Chart
            weeklyActivitySection
            
            Divider()
                .opacity(0.3)
            
            // Footer with clean Launch at Login toggle
            footerView
        }
        .padding(16)
        .frame(width: 390)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("AI Usage Monitor")
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
            
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                Text("Online")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Weekly Activity Bar Chart
    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("WEEKLY ACTIVITY (Antigravity vs Gemini)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Resets Mon 00:00")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(0..<store.antigravitySnapshot.weeklyDays.count, id: \.self) { idx in
                    let agyDay = store.antigravitySnapshot.weeklyDays[idx]
                    let gemDay = store.geminiSnapshot.weeklyDays[idx]
                    
                    VStack(spacing: 3) {
                        HStack(alignment: .bottom, spacing: 2) {
                            // Antigravity Bar
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom))
                                .frame(width: 6, height: max(3, CGFloat(agyDay.fraction * 24)))
                            
                            // Gemini Bar
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                                .frame(width: 6, height: max(3, CGFloat(gemDay.fraction * 24)))
                        }
                        
                        Text(agyDay.dayName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 38)
            .padding(.top, 2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.45))
        )
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack {
            // Native Launch at Login Toggle
            Button(action: {
                store.toggleLaunchAtLogin()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: store.launchAtLogin ? "checkmark.square.fill" : "square")
                        .font(.system(size: 11))
                        .foregroundColor(store.launchAtLogin ? .accentColor : .secondary)
                    Text("Launch at Login")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("Right-click menu bar icon for options")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
}
