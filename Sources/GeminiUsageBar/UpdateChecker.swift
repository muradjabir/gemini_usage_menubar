import Foundation
import AppKit

public struct ReleaseInfo {
    public let version: String
    public let htmlUrl: URL
    public let downloadUrl: URL?
    public let releaseNotes: String
}

@MainActor
public final class UpdateChecker: ObservableObject {
    public static let shared = UpdateChecker()
    
    public static let currentVersion = "1.0.5"
    private static let repo = "muradjabir/gemini_usage_menubar"
    
    @Published public var availableUpdate: ReleaseInfo? = nil
    @Published public var isUpdating: Bool = false
    @Published public var updateStatusMessage: String? = nil
    
    private init() {
        // Automatically check for updates on startup in background
        Task {
            await checkForUpdates()
        }
    }
    
    public func checkForUpdates(manual: Bool = false) async {
        guard let url = URL(string: "https://api.github.com/repos/\(Self.repo)/releases/latest") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("GeminiUsageBar-App", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if manual {
                    showNotice(title: "Check for Updates", message: "Unable to reach update server. Please check your internet connection.")
                }
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlUrlStr = json["html_url"] as? String,
                  let htmlUrl = URL(string: htmlUrlStr) else {
                return
            }
            
            let cleanRemoteVersion = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let notes = json["body"] as? String ?? ""
            
            // Find .zip asset download url
            var downloadUrl: URL? = nil
            if let assets = json["assets"] as? [[String: Any]] {
                for asset in assets {
                    if let name = asset["name"] as? String, name.hasSuffix(".zip"),
                       let downloadStr = asset["browser_download_url"] as? String {
                        downloadUrl = URL(string: downloadStr)
                        break
                    }
                }
            }
            
            if isVersion(cleanRemoteVersion, newerThan: Self.currentVersion) {
                let release = ReleaseInfo(
                    version: tagName,
                    htmlUrl: htmlUrl,
                    downloadUrl: downloadUrl,
                    releaseNotes: notes
                )
                self.availableUpdate = release
                
                if manual {
                    promptUpdateModal(release: release)
                }
            } else if manual {
                showNotice(title: "Up to Date", message: "You are running the latest version of Gemini & Antigravity Usage Bar (v\(Self.currentVersion)).")
            }
        } catch {
            if manual {
                showNotice(title: "Check for Updates", message: "Failed to check for updates: \(error.localizedDescription)")
            }
        }
    }
    
    public func performInAppUpdate(release: ReleaseInfo) async {
        guard let downloadUrl = release.downloadUrl else {
            NSWorkspace.shared.open(release.htmlUrl)
            return
        }
        
        self.isUpdating = true
        self.updateStatusMessage = "Downloading \(release.version)..."
        
        let tempZip = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("GeminiUsageBar-update.zip")
        let tempExtractDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("GeminiUsageBar-extract-\(UUID().uuidString)")
        
        do {
            try? FileManager.default.removeItem(at: tempZip)
            try? FileManager.default.removeItem(at: tempExtractDir)
            
            // Download update zip
            let (downloadedFileUrl, _) = try await URLSession.shared.download(from: downloadUrl)
            try FileManager.default.moveItem(at: downloadedFileUrl, to: tempZip)
            
            self.updateStatusMessage = "Extracting update..."
            try FileManager.default.createDirectory(at: tempExtractDir, withIntermediateDirectories: true)
            
            // Unzip using system ditto or unzip
            let unzipProcess = Process()
            unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            unzipProcess.arguments = ["-x", "-k", tempZip.path, tempExtractDir.path]
            try unzipProcess.run()
            unzipProcess.waitUntilExit()
            
            let extractedApp = tempExtractDir.appendingPathComponent("GeminiUsageBar.app")
            guard FileManager.default.fileExists(atPath: extractedApp.path) else {
                throw NSError(domain: "Updater", code: 1, userInfo: [NSLocalizedDescriptionKey: "Extracted update is missing GeminiUsageBar.app"])
            }
            
            self.updateStatusMessage = "Installing..."
            
            // Clear quarantine attribute
            let xattrProcess = Process()
            xattrProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            xattrProcess.arguments = ["-cr", extractedApp.path]
            try? xattrProcess.run()
            xattrProcess.waitUntilExit()
            
            // Destination path
            let destinationApp = URL(fileURLWithPath: "/Applications/GeminiUsageBar.app")
            
            // Spawn detached relaunch script that replaces app and relaunches it cleanly
            let script = """
            sleep 0.8
            rm -rf "\(destinationApp.path)"
            cp -R "\(extractedApp.path)" "\(destinationApp.path)"
            xattr -cr "\(destinationApp.path)" 2>/dev/null || true
            open "\(destinationApp.path)"
            rm -rf "\(tempExtractDir.path)"
            rm -f "\(tempZip.path)"
            """
            
            let relauncher = Process()
            relauncher.executableURL = URL(fileURLWithPath: "/bin/bash")
            relauncher.arguments = ["-c", script]
            try relauncher.run()
            
            // Terminate current process so the replacement can complete
            NSApplication.shared.terminate(nil)
        } catch {
            self.isUpdating = false
            self.updateStatusMessage = nil
            showNotice(title: "Update Failed", message: "Failed to apply update: \(error.localizedDescription)\n\nOpening release page in your browser instead.")
            NSWorkspace.shared.open(release.htmlUrl)
        }
    }
    
    private func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(parts1.count, parts2.count)
        for i in 0..<maxCount {
            let num1 = i < parts1.count ? parts1[i] : 0
            let num2 = i < parts2.count ? parts2[i] : 0
            if num1 > num2 { return true }
            if num1 < num2 { return false }
        }
        return false
    }
    
    private func promptUpdateModal(release: ReleaseInfo) {
        let alert = NSAlert()
        alert.messageText = "Update Available: \(release.version)"
        alert.informativeText = "A new version of Gemini & Antigravity Usage Bar is available (you have v\(Self.currentVersion)).\n\nWould you like to install it now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install Update")
        alert.addButton(withTitle: "View Release Notes")
        alert.addButton(withTitle: "Later")
        
        let resp = alert.runModal()
        if resp == .alertFirstButtonReturn {
            Task {
                await performInAppUpdate(release: release)
            }
        } else if resp == .alertSecondButtonReturn {
            NSWorkspace.shared.open(release.htmlUrl)
        }
    }
    
    private func showNotice(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

