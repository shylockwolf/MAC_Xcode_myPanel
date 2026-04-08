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
    private init() {
        migrateFromSandboxIfNeeded()
    }

    private var configURL: URL {
        // 统一使用 Documents 目录，确保配置持久化
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("myPanel.json")
    }
    
    private func migrateFromSandboxIfNeeded() {
        let userDocsURL = configURL
        
        // 如果已经存在配置文件，不需要迁移
        if FileManager.default.fileExists(atPath: userDocsURL.path) {
            return
        }
        
        // 获取用户主目录
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        
        // 尝试从多个可能的位置迁移配置
        let possiblePaths = [
            // 沙盒Data目录下的配置文件
            homeDir.appendingPathComponent("Library/Containers/shylockwolf.myPanel/Data/myPanel.json"),
            // 沙盒Documents目录
            homeDir.appendingPathComponent("Library/Containers/shylockwolf.myPanel/Data/Documents/myPanel.json"),
            // 项目目录（旧DEBUG模式位置）
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("myPanel.json"),
            // 旧版应用支持目录
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("myPanel/myPanel.json")
        ].compactMap { $0 }
        
        for sourceURL in possiblePaths {
            let path = sourceURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    // 确保目标目录存在
                    let targetDir = userDocsURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
                    
                    // 复制文件
                    try FileManager.default.copyItem(at: sourceURL, to: userDocsURL)
                    logInfo("成功迁移配置: \(path) -> \(userDocsURL.path)")
                    return
                } catch {
                    logError("从 \(path) 迁移失败: \(error.localizedDescription)")
                }
            }
        }
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
                let times = old.map { path -> TimeInterval in
                    if path.isEmpty { return 0 }
                    if FileManager.default.fileExists(atPath: path) {
                        if let attrs = try? FileManager.default.attributesOfItem(atPath: path), let d = attrs[.modificationDate] as? Date {
                            return d.timeIntervalSince1970
                        }
                    }
                    return 0
                }
                let migrated = AppConfig(lastOpenedFiles: old, preferences: Preferences(theme: "default", language: "en"), lastModifiedTimes: times, itemCount: old.count)
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
    
    public func deleteConfig() -> Bool {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return true
        }
        do {
            try FileManager.default.removeItem(at: configURL)
            logInfo("Deleted config at: \(configURL.path)")
            return true
        } catch {
            logError("Delete failed: \(error.localizedDescription)")
            return false
        }
    }
    
    public var currentConfigPath: String {
        return configURL.path
    }
}
