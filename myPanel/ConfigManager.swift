import Foundation
#if canImport(os)
import os
#endif

#if canImport(os)
private let logSubsystem = "com.noone.MAC_Xcode_myPanel"
private let logCategory = "App"
private let logger = OSLog(subsystem: logSubsystem, category: logCategory)
private func logInfo(_ msg: String) { os_log("%@", log: logger, type: .info, msg) }
private func logDebug(_ msg: String) { os_log("%@", log: logger, type: .debug, msg) }
private func logError(_ msg: String) { os_log("%@", log: logger, type: .error, msg) }
#else
private func logInfo(_ msg: String) { print("INFO: \(msg)") }
private func logDebug(_ msg: String) { print("DEBUG: \(msg)") }
private func logError(_ msg: String) { print("ERROR: \(msg)") }
#endif

// Reuse locally defined models
// AppConfig and Preferences are defined in LocalConfigModels.swift

public final class ConfigManager {
    public static let shared = ConfigManager()
    private init() {}

private var configURL: URL {
        #if DEBUG
        let currentPath = FileManager.default.currentDirectoryPath
        return URL(fileURLWithPath: currentPath).appendingPathComponent("myPanel.json")
        #else
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("myPanel.json")
        #endif
    }

    public func loadConfig() -> AppConfig? {
        let url = configURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            logDebug("Config not found at \(url.path)")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            if let cfg = try? decoder.decode(AppConfig.self, from: data) {
                logInfo("Loaded new format config from \(url.path)")
                return cfg
            }
            if let old = try? decoder.decode([String].self, from: data) {
                logInfo("Loaded old format config from \(url.path); migrating to new format")
                // migrate to new format
                let times = old.map { path -> TimeInterval in
                    if path.isEmpty { return 0 }
                    if FileManager.default.fileExists(atPath: path) {
                        if let attrs = try? FileManager.default.attributesOfItem(atPath: path), let d = attrs[.modificationDate] as? Date {
                            return d.timeIntervalSince1970
                        }
                    }
                    return 0
                }
                let migrated = AppConfig(lastOpenedFiles: old, preferences: Preferences(theme: "default", language: "en"), lastModifiedTimes: times)
                saveConfig(migrated)
                return migrated
            }
        } catch {
            logError("Load failed: \(error.localizedDescription)")
        }
        return nil
    }

    public func saveConfig(_ config: AppConfig) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(config)
            try data.write(to: configURL)
            logInfo("Saved config to: \(configURL.path)")
        } catch {
            logError("Save failed: \(error.localizedDescription)")
        }
    }
}
