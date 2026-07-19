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
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupportDir.appendingPathComponent("shylockwolf.myPanel")
        return appDir.appendingPathComponent("myPanel.json")
    }
    
    private func migrateFromSandboxIfNeeded() {
        let userDocsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("myPanel.json")
        
        if FileManager.default.fileExists(atPath: configURL.path) {
            return
        }
        
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        
        let possiblePaths = [
            userDocsURL,
            homeDir.appendingPathComponent("Library/Containers/shylockwolf.myPanel/Data/myPanel.json"),
            homeDir.appendingPathComponent("Library/Containers/shylockwolf.myPanel/Data/Documents/myPanel.json"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("myPanel.json"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("myPanel/myPanel.json")
        ].compactMap { $0 }
        
        for sourceURL in possiblePaths {
            let path = sourceURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    let targetDir = configURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
                    
                    try FileManager.default.copyItem(at: sourceURL, to: configURL)
                    logInfo("成功迁移配置: \(path) -> \(configURL.path)")
                    
                    if sourceURL == userDocsURL {
                        try FileManager.default.removeItem(at: sourceURL)
                        logInfo("清理旧配置文件: \(sourceURL.path)")
                    }
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
            
            do {
                let cfg = try decoder.decode(AppConfig.self, from: data)
                logInfo("Loaded new format config from \(url.path)")
                return cfg
            } catch {
                print("DEBUG: JSON 解析新格式失败: \(error)")
                if let decodingError = error as? DecodingError {
                    print("DEBUG: DecodingError 详情: \(decodingError.localizedDescription)")
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("DEBUG: 类型不匹配 - 期望类型: \(type), 路径: \(context.codingPath), 详情: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("DEBUG: 值不存在 - 期望类型: \(type), 路径: \(context.codingPath), 详情: \(context.debugDescription)")
                    case .keyNotFound(let key, let context):
                        print("DEBUG: 键不存在 - 键: \(key.stringValue), 路径: \(context.codingPath), 详情: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("DEBUG: 数据损坏 - 路径: \(context.codingPath), 详情: \(context.debugDescription)")
                    @unknown default:
                        print("DEBUG: 未知解码错误")
                    }
                }
            }
            
            do {
                let old = try decoder.decode([String].self, from: data)
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
            } catch {
                print("DEBUG: JSON 解析旧格式失败: \(error)")
            }
            
        } catch {
            logError("Load failed: \(error.localizedDescription)")
            print("DEBUG: 读取文件失败: \(error)")
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
