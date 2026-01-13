import Foundation

// 可编码的应用配置模型
public struct Preferences: Codable {
    var theme: String
    var language: String
}

public struct AppConfig: Codable {
    var lastOpenedFiles: [String]
    var preferences: Preferences
    var lastModifiedTimes: [TimeInterval]
}

extension AppConfig {
    static var defaultConfig: AppConfig {
        AppConfig(
            lastOpenedFiles: Array(repeating: "", count: 9),
            preferences: Preferences(theme: "default", language: "en"),
            lastModifiedTimes: Array(repeating: 0.0, count: 9)
        )
    }
}

