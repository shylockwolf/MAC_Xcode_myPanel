import Foundation

public struct Preferences: Codable {
    var theme: String
    var language: String
}

public struct AppConfig: Codable {
    var lastOpenedFiles: [String]
    var preferences: Preferences
    var lastModifiedTimes: [TimeInterval]
    var itemCount: Int
    var isLargePanel: Bool
    
    public enum CodingKeys: String, CodingKey {
        case lastOpenedFiles
        case preferences
        case lastModifiedTimes
        case itemCount
        case isLargePanel
    }
    
    public init(lastOpenedFiles: [String], preferences: Preferences, lastModifiedTimes: [TimeInterval], itemCount: Int, isLargePanel: Bool = false) {
        self.lastOpenedFiles = lastOpenedFiles
        self.preferences = preferences
        self.lastModifiedTimes = lastModifiedTimes
        self.itemCount = itemCount
        self.isLargePanel = isLargePanel
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastOpenedFiles = try container.decode([String].self, forKey: .lastOpenedFiles)
        preferences = try container.decode(Preferences.self, forKey: .preferences)
        lastModifiedTimes = try container.decode([TimeInterval].self, forKey: .lastModifiedTimes)
        itemCount = try container.decodeIfPresent(Int.self, forKey: .itemCount) ?? lastOpenedFiles.count
        isLargePanel = try container.decodeIfPresent(Bool.self, forKey: .isLargePanel) ?? false
    }
}

extension AppConfig {
    static var defaultConfig: AppConfig {
        AppConfig(
            lastOpenedFiles: Array(repeating: "", count: 9),
            preferences: Preferences(theme: "default", language: "en"),
            lastModifiedTimes: Array(repeating: 0.0, count: 9),
            itemCount: 9,
            isLargePanel: false
        )
    }
}
