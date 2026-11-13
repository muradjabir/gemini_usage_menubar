import SwiftUI

public struct PopoverContentView: View {
    @ObservedObject var store: UsageStore
    @ObservedObject var updater = UpdateChecker.shared
    
    public init(store: UsageStore) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 11) {
            // Header
            headerView
            
            // Upgrade Banner if a new release is detected
            if let update = updater.availableUpdate {
                updateBanner(update: update)
            }
            
            Divider()
                .opacity(0.3)
            
            // Progress Bar Cards: Gemini Hydrogen, Gemini Argon, Gemini Flash, Claude Opus, and Antigravity
            VStack(spacing: 8) {
                // Gemini 4 Hydrogen (New Flagship Thinking / Reasoning)
                ModelProgressBarCardView(
                    title: "Gemini Hydrogen",
                    subtitle: "Google Flagship",
                    snapshot: store.geminiHydrogenSnapshot,
                    accentGradient: LinearGradient(colors: [Color(red: 0.1, green: 0.85, blue: 0.7), Color(red: 0.2, green: 0.5, blue: 1.0)], startPoint: .leading, endPoint: .trailing)
                )
                
                // Gemini 4 Argon (Pro Reasoning Tier)
                ModelProgressBarCardView(
                    title: "Gemini Argon",
                    subtitle: "Google Pro",
                    snapshot: store.geminiArgonSnapshot,
                    accentGradient: LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                )
                
                // Gemini 3.8 Flash (Speed Tier)
                ModelProgressBarCardView(
                    title: "Gemini Flash",
                    subtitle: "Fast Tier",
                    snapshot: store.geminiFlashSnapshot,
                    accentGradient: LinearGradient(colors: [Color(red: 0.1, green: 0.7, blue: 0.9), Color.blue], startPoint: .leading, endPoint: .trailing)
                )
                
                // Claude Opus (Anthropic Reasoning - shown if usage exists or as legacy fallback)
                if store.claudeOpusSnapshot.weeklyUsed > 0 || store.claudeOpusSnapshot.dailyUsed > 0 {
                    ModelProgressBarCardView(
                        title: "Claude Opus",
                        subtitle: "Anthropic",
                        snapshot: store.claudeOpusSnapshot,
                        accentGradient: LinearGradient(colors: [Color(red: 0.85, green: 0.45, blue: 0.3), Color(red: 0.75, green: 0.25, blue: 0.35)], startPoint: .leading, endPoint: .trailing)
                    )
                }
                
                // Antigravity (Total Agent / IDE Platform Usage)
                ModelProgressBarCardView(
                    title: "Antigravity",
                    subtitle: "All Agents",
                    snapshot: store.antigravitySnapshot,
                    accentGradient: LinearGradient(colors: [Color.cyan, Color.purple], startPoint: .leading, endPoint: .trailing)
                )
            }
            
            // Combined Weekly Mini Chart
            weeklyActivitySection
            
            Divider()
                .opacity(0.3)
            
            // Footer with clean Launch at Login toggle
            footerView
        }
        .padding(13)
        .frame(width: 380)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Update Notification Banner
    private func updateBanner(update: ReleaseInfo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .foregroundColor(.cyan)
                .font(.system(size: 15))
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Update Available: \(update.version)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                Text(updater.updateStatusMessage ?? "Click to upgrade seamlessly")
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if updater.isUpdating {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(action: {
                    Task {
                        await updater.performInAppUpdate(release: update)
                    }
                }) {
                    Text("Update Now")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Text("AI Usage Monitor")
                    .font(.system(size: 13, weight: .bold))
                Text("v\(UpdateChecker.currentVersion)")
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
                        Circle().fill(Color(red: 0.1, green: 0.85, blue: 0.7)).frame(width: 5, height: 5)
                        Text("Hydrogen").font(.system(size: 8)).foregroundColor(.secondary)
                    }
                    HStack(spacing: 3) {
                        Circle().fill(Color.blue).frame(width: 5, height: 5)
                        Text("Argon").font(.system(size: 8)).foregroundColor(.secondary)
                    }
                    HStack(spacing: 3) {
                        Circle().fill(Color.cyan).frame(width: 5, height: 5)
                        Text("Flash").font(.system(size: 8)).foregroundColor(.secondary)
                    }
                    if store.claudeOpusSnapshot.weeklyUsed > 0 {
                        HStack(spacing: 3) {
                            Circle().fill(Color(red: 0.85, green: 0.45, blue: 0.3)).frame(width: 5, height: 5)
                            Text("Claude").font(.system(size: 8)).foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<store.antigravitySnapshot.weeklyDays.count, id: \.self) { idx in
                    let hydrogenDay = store.geminiHydrogenSnapshot.weeklyDays[idx]
                    let argonDay = store.geminiArgonSnapshot.weeklyDays[idx]
                    let flashDay = store.geminiFlashSnapshot.weeklyDays[idx]
                    let claudeDay = store.claudeOpusSnapshot.weeklyDays[idx]
                    
                    VStack(spacing: 3) {
                        HStack(alignment: .bottom, spacing: 1.5) {
                            // Hydrogen Bar
                            RoundedRectangle(cornerRadius: 1)
                                .fill(LinearGradient(colors: [Color(red: 0.1, green: 0.85, blue: 0.7), Color.teal], startPoint: .top, endPoint: .bottom))
                                .frame(width: 4, height: max(2, CGFloat(hydrogenDay.fraction * 22)))
                            
                            // Argon Bar
                            RoundedRectangle(cornerRadius: 1)
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                                .frame(width: 4, height: max(2, CGFloat(argonDay.fraction * 22)))
                            
                            // Flash Bar
                            RoundedRectangle(cornerRadius: 1)
                                .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))
                                .frame(width: 4, height: max(2, CGFloat(flashDay.fraction * 22)))
                            
                            // Claude Bar (if present)
                            if store.claudeOpusSnapshot.weeklyUsed > 0 {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color(red: 0.85, green: 0.45, blue: 0.3))
                                    .frame(width: 4, height: max(2, CGFloat(claudeDay.fraction * 22)))
                            }
                        }
                        
                        Text(hydrogenDay.dayName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 34)
            .padding(.top, 2)
        }
        .padding(9)
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
            
            Text("Right-click icon for options")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
}
