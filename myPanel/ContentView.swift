import SwiftUI
import UniformTypeIdentifiers

#if canImport(os)
import os
#endif

func L(_ key: String) -> String { NSLocalizedString(key, comment: "") }

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

struct ContentView: View {
    @State private var selectedFiles: [String] = Array(repeating: "", count: 9)
    @State private var buttonLabels: [String] = Array(repeating: "select", count: 9)
    @State private var prefs = Preferences(theme: "default", language: "en")
    @State private var disabledButtons: [Bool] = Array(repeating: false, count: 9)
    @State private var itemCount: Int = 9

    private let configFileURL: URL = {
        #if DEBUG
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return currentDirectory.appendingPathComponent("myPanel.json")
        #else
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("myPanel.json")
        #endif
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                HStack {
                    HStack(spacing: 5) {
                        Text("数量")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button(action: {
                            print("DEBUG: 点击 - 按钮, 当前 itemCount=\(itemCount)")
                            if itemCount > 1 {
                                updateItemCount(itemCount - 1)
                            } else {
                                print("DEBUG: itemCount <= 1, 不能减少")
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Text("\(itemCount)")
                            .font(.system(size: 14, weight: .medium))
                            .frame(minWidth: 25)
                        Button(action: {
                            print("DEBUG: 点击 + 按钮, 当前 itemCount=\(itemCount)")
                            if itemCount < 50 {
                                updateItemCount(itemCount + 1)
                            } else {
                                print("DEBUG: itemCount >= 50, 不能增加")
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    Spacer()

                    Text("myPanel")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Shylock Wolf")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("ver 2.1.1")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("2026-03")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)

                ForEach(0..<itemCount, id: \.self) { idx in
                    HStack(spacing: 10) {
                        Button(action: {
                            handleButtonClick(index: idx)
                        }) {
                            Image(systemName: selectedFiles[idx].isEmpty ? "paperclip.circle" : "play.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 32))
                        }
                        .buttonStyle(PlainButtonStyle())

                        if let icon = getFileIcon(for: idx) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "rectangle.dashed")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                        }

                        Text(getFileName(for: idx))
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                            .padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        Button(action: {
                            clearItem(index: idx)
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Clear Item")
                    }
                    .padding(.horizontal, 20)
                }
                Spacer().frame(height: 20)
            }
        }
        .frame(minWidth: 350, idealWidth: 350, maxWidth: .infinity,
               minHeight: 450, idealHeight: calculateWindowHeight(), maxHeight: .infinity)
        .onAppear {
            loadConfig()
        }
    }
    
    private func calculateWindowHeight() -> CGFloat {
        let headerHeight: CGFloat = 100
        let itemHeight: CGFloat = 55
        let bottomSpacing: CGFloat = 20
        let totalHeight = headerHeight + (CGFloat(itemCount) * itemHeight) + bottomSpacing
        return max(totalHeight, 450)
    }

    private func handleButtonClick(index: Int) {
        if selectedFiles[index].isEmpty {
            selectFile(index: index)
        } else {
            openFile(index: index)
        }
    }

    private func clearItem(index: Int) {
        selectedFiles[index] = ""
        buttonLabels[index] = "select"
        saveConfig()
    }

    private func selectFile(index: Int) {
        let panel = NSOpenPanel()
        panel.title = "选择文件 \(index + 1)"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.item]
        if panel.runModal() == .OK {
            if let url = panel.url {
                logInfo("用户选择了文件: \(url.path)")
                let isFile = FileManager.default.fileExists(atPath: url.path)
                let isAppBundle = url.pathExtension == "app" && FileManager.default.fileExists(atPath: url.path)
                logDebug("文件存在: \(isFile), 是应用包: \(isAppBundle)")
                if isFile || isAppBundle {
                    selectedFiles[index] = url.path
                    saveConfig()
                    logInfo("成功选择文件 \(index + 1): \(url.path)")
                } else {
                    logError("错误: 选择的路径不是有效的文件或应用")
                }
            }
        }
    }

    private func openFile(index: Int) {
        let filePath = selectedFiles[index]
        guard !filePath.isEmpty else {
            showAlert(title: L("warning"), message: L("not_selected_file"))
            return
        }
        let fileURL = URL(fileURLWithPath: filePath)
        let isFile = FileManager.default.fileExists(atPath: filePath)
        let isAppBundle = fileURL.pathExtension == "app" && FileManager.default.fileExists(atPath: filePath)
        guard isFile || isAppBundle else {
            showAlert(title: L("warning"), message: L("open_failed"))
            return
        }
        if isAppBundle {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: fileURL, configuration: config) { (app, error) in
                if let error = error {
                    showAlert(title: L("warning"), message: error.localizedDescription)
                    logError("打开失败: \(error.localizedDescription)")
                } else {
                    logInfo("已打开 \(index + 1): \(filePath)")
                }
            }
        } else {
            if NSWorkspace.shared.open(fileURL) {
                logInfo("已打开 \(index + 1): \(filePath)")
            } else {
                showAlert(title: L("warning"), message: L("open_failed"))
                logError("打开失败: 无法打开文件")
            }
        }
    }

    private func getFileName(for index: Int) -> String {
        let filePath = selectedFiles[index]
        if filePath.isEmpty {
            return L("not_selected_file")
        } else {
            return URL(fileURLWithPath: filePath).lastPathComponent
        }
    }

    private func getFileIcon(for index: Int) -> NSImage? {
        let filePath = selectedFiles[index]
        guard !filePath.isEmpty else { return nil }
        return NSWorkspace.shared.icon(forFile: filePath)
    }

    private func saveConfig() {
        var lastModifiedTimes: [TimeInterval] = []
        for filePath in selectedFiles {
            if !filePath.isEmpty {
                do {
                    let attrs = try FileManager.default.attributesOfItem(atPath: filePath)
                    if let mod = attrs[.modificationDate] as? Date {
                        lastModifiedTimes.append(mod.timeIntervalSince1970)
                    } else {
                        lastModifiedTimes.append(0)
                    }
                } catch {
                    logError("获取文件修改时间失败: \(filePath), 错误: \(error.localizedDescription)")
                    lastModifiedTimes.append(0)
                }
            } else {
                lastModifiedTimes.append(0)
            }
        }
        let cfg = AppConfig(lastOpenedFiles: selectedFiles, preferences: prefs, lastModifiedTimes: lastModifiedTimes, itemCount: itemCount)
        ConfigManager.shared.saveConfig(cfg)
    }

    private func loadConfig() {
        print("DEBUG: 开始加载配置")
        if let cfg = ConfigManager.shared.loadConfig() {
            print("DEBUG: 配置加载成功, itemCount=\(cfg.itemCount), lastOpenedFiles.count=\(cfg.lastOpenedFiles.count)")
            selectedFiles = cfg.lastOpenedFiles
            prefs = cfg.preferences
            
            let newCount = cfg.itemCount
            let currentCount = selectedFiles.count
            
            if currentCount < newCount {
                let additionalCount = newCount - currentCount
                selectedFiles.append(contentsOf: Array(repeating: "", count: additionalCount))
                buttonLabels.append(contentsOf: Array(repeating: "select", count: additionalCount))
                disabledButtons.append(contentsOf: Array(repeating: false, count: additionalCount))
            } else if currentCount > newCount {
                selectedFiles = Array(selectedFiles.prefix(newCount))
                buttonLabels = Array(buttonLabels.prefix(newCount))
                disabledButtons = Array(disabledButtons.prefix(newCount))
            }
            
            itemCount = newCount
            
            for i in 0..<min(itemCount, cfg.lastOpenedFiles.count) {
                if !cfg.lastOpenedFiles[i].isEmpty {
                    buttonLabels[i] = "open"
                    disabledButtons[i] = true
                }
            }
            print("DEBUG: 配置应用完成, itemCount=\(itemCount), selectedFiles.count=\(selectedFiles.count)")
            logInfo("Config loaded via ConfigManager, applying to UI")
        } else {
            print("DEBUG: 没有找到配置文件，使用默认值")
            logDebug("No config found; using defaults")
            selectedFiles = Array(repeating: "", count: itemCount)
            buttonLabels = Array(repeating: "select", count: itemCount)
            disabledButtons = Array(repeating: false, count: itemCount)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: L("ok"))
        alert.runModal()
    }

    private func showResetConfirmation() {
        let alert = NSAlert()
        alert.messageText = "设置项目数量"
        alert.informativeText = "请输入您想要的项目数量 (1-50):"
        alert.alertStyle = .informational
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = "\(itemCount)"
        alert.accessoryView = textField
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let newValue = Int(textField.stringValue), newValue >= 1 && newValue <= 50 {
                updateItemCount(newValue)
            } else {
                showAlert(title: "错误", message: "请输入 1 到 50 之间的数字")
            }
        }
    }

    private func updateItemCount(_ newCount: Int) {
        let oldCount = itemCount
        
        if newCount > oldCount {
            let additionalCount = newCount - oldCount
            selectedFiles.append(contentsOf: Array(repeating: "", count: additionalCount))
            buttonLabels.append(contentsOf: Array(repeating: "select", count: additionalCount))
            disabledButtons.append(contentsOf: Array(repeating: false, count: additionalCount))
        } else if newCount < oldCount {
            selectedFiles = Array(selectedFiles.prefix(newCount))
            buttonLabels = Array(buttonLabels.prefix(newCount))
            disabledButtons = Array(disabledButtons.prefix(newCount))
        }
        
        itemCount = newCount
        saveConfig()
        logInfo("项目数量已从 \(oldCount) 更新为 \(newCount)")
        print("DEBUG: itemCount=\(itemCount), selectedFiles.count=\(selectedFiles.count)")
        
        adjustWindowSize()
    }
    
    private func adjustWindowSize() {
        if let window = NSApp.keyWindow {
            let headerHeight: CGFloat = 100
            let itemHeight: CGFloat = 55
            let bottomSpacing: CGFloat = 20
            let totalHeight = headerHeight + (CGFloat(itemCount) * itemHeight) + bottomSpacing
            let newHeight = max(totalHeight, 450)
            
            let currentFrame = window.frame
            let newFrame = NSRect(x: currentFrame.origin.x, 
                                  y: currentFrame.origin.y + currentFrame.height - newHeight,
                                  width: currentFrame.width, 
                                  height: newHeight)
            window.setFrame(newFrame, display: true, animate: true)
        }
    }

    private func resetApp() {
        do {
            if FileManager.default.fileExists(atPath: configFileURL.path) {
                try FileManager.default.removeItem(at: configFileURL)
                logInfo("已删除配置文件: \(configFileURL.path)")
            }
            selectedFiles = Array(repeating: "", count: itemCount)
            buttonLabels = Array(repeating: "select", count: itemCount)
            disabledButtons = Array(repeating: false, count: itemCount)
            showAlert(title: L("reset_app"), message: L("reset_success"))
        } catch {
            logError("重置应用失败: \(error.localizedDescription)")
            showAlert(title: L("reset_app"), message: error.localizedDescription)
        }
    }
}

// #Preview {
//     ContentView()
// }
