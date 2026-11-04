import SwiftUI

public struct PopoverContentView: View {
    @ObservedObject var store: UsageStore
    
    public init(store: UsageStore) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header
            headerView
            
            Divider()
                .opacity(0.3)
            
            // Progress Bar Cards for Antigravity, Gemini Argon, and Gemini Flash
            VStack(spacing: 9) {
                // Antigravity (Agent / IDE)
                ModelProgressBarCardView(
                    title: "Antigravity",
                    subtitle: "Agent",
                    snapshot: store.antigravitySnapshot,
                    accentGradient: LinearGradient(colors: [Color.cyan, Color.purple], startPoint: .leading, endPoint: .trailing),
                    selectedMetric: $store.agyMetric
                )
                
                // Gemini 4 Argon (Reasoning Tier)
                ModelProgressBarCardView(
                    title: "Gemini Argon",
                    subtitle: "Pro Tier",
                    snapshot: store.geminiArgonSnapshot,
                    accentGradient: LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing),
                    selectedMetric: $store.argonMetric
                )
                
                // Gemini 3.8 Flash (Speed Tier)
                ModelProgressBarCardView(
                    title: "Gemini Flash",
                    subtitle: "Fast Tier",
                    snapshot: store.geminiFlashSnapshot,
                    accentGradient: LinearGradient(colors: [Color(red: 0.1, green: 0.7, blue: 0.9), Color.blue], startPoint: .leading, endPoint: .trailing),
                    selectedMetric: $store.flashMetric
                )
            }
            
            // Combined Weekly Mini Chart
            weeklyActivitySection
            
            Divider()
                .opacity(0.3)
            
            // Footer with clean Launch at Login toggle
            footerView
        }
        .padding(14)
        .frame(width: 380)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Text("AI Usage Monitor")
                    .font(.system(size: 13, weight: .bold))
                Text("v1.0.3")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
            }
            
            Spacer()
            
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Weekly Activity Bar Chart
    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("WEEKLY ACTIVITY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Circle().fill(Color.purple).frame(width: 5, height: 5)
                        Text("AGY").font(.system(size: 8)).foregroundColor(.secondary)
                    }
                    HStack(spacing: 3) {
                        Circle().fill(Color.blue).frame(width: 5, height: 5)
                        Text("Argon").font(.system(size: 8)).foregroundColor(.secondary)
                    }
                    HStack(spacing: 3) {
                        Circle().fill(Color.cyan).frame(width: 5, height: 5)
                        Text("Flash").font(.system(size: 8)).foregroundColor(.secondary)
                    }
                }
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<store.antigravitySnapshot.weeklyDays.count, id: \.self) { idx in
                    let agyDay = store.antigravitySnapshot.weeklyDays[idx]
                    let argonDay = store.geminiArgonSnapshot.weeklyDays[idx]
                    let flashDay = store.geminiFlashSnapshot.weeklyDays[idx]
                    
                    VStack(spacing: 3) {
                        HStack(alignment: .bottom, spacing: 1.5) {
                            // AGY Bar
                            RoundedRectangle(cornerRadius: 1)
                                .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom))
                                .frame(width: 5, height: max(2, CGFloat(agyDay.fraction * 22)))
                            
                            // Argon Bar
                            RoundedRectangle(cornerRadius: 1)
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                                .frame(width: 5, height: max(2, CGFloat(argonDay.fraction * 22)))
                            
                            // Flash Bar
                            RoundedRectangle(cornerRadius: 1)
                                .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))
                                .frame(width: 5, height: max(2, CGFloat(flashDay.fraction * 22)))
                        }
                        
                        Text(agyDay.dayName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 34)
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
