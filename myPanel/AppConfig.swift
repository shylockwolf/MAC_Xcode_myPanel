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
    var itemCount: Int
    
    public enum CodingKeys: String, CodingKey {
        case lastOpenedFiles
        case preferences
        case lastModifiedTimes
        case itemCount
    }
    
    public init(lastOpenedFiles: [String], preferences: Preferences, lastModifiedTimes: [TimeInterval], itemCount: Int) {
        self.lastOpenedFiles = lastOpenedFiles
        self.preferences = preferences
        self.lastModifiedTimes = lastModifiedTimes
        self.itemCount = itemCount
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastOpenedFiles = try container.decode([String].self, forKey: .lastOpenedFiles)
        preferences = try container.decode(Preferences.self, forKey: .preferences)
        lastModifiedTimes = try container.decode([TimeInterval].self, forKey: .lastModifiedTimes)
        itemCount = try container.decodeIfPresent(Int.self, forKey: .itemCount) ?? lastOpenedFiles.count
    }
}

extension AppConfig {
    static var defaultConfig: AppConfig {
        AppConfig(
            lastOpenedFiles: Array(repeating: "", count: 9),
            preferences: Preferences(theme: "default", language: "en"),
            lastModifiedTimes: Array(repeating: 0.0, count: 9),
            itemCount: 9
        )
    }
}

