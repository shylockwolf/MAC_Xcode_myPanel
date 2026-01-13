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
                    Button(action: {
                        showResetConfirmation()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Reset App")

                    Spacer()

                    Text("myPanel")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Shylock Wolf")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("ver 2.0.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("2026-01-13")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)

                ForEach(0..<9) { idx in
                    HStack(spacing: 10) {
                        Button(action: {
                            handleButtonClick(index: idx)
                        }) {
                            Image(systemName: "doc.circle.fill")
                                .foregroundColor(disabledButtons[idx] ? .gray : .blue)
                                .font(.system(size: 32))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(disabledButtons[idx])
                        .disabled(disabledButtons[idx])

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
               minHeight: 450, idealHeight: 450, maxHeight: .infinity)
        .onAppear {
            loadConfig()
        }
    }

    private func handleButtonClick(index: Int) {
        if buttonLabels[index] == "select" {
            if selectedFiles[index].isEmpty {
                selectFile(index: index)
            } else {
                openFile(index: index)
            }
        } else {
            openFile(index: index)
        }
    }

    private func clearItem(index: Int) {
        selectedFiles[index] = ""
        buttonLabels[index] = "select"
        disabledButtons[index] = false
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
                    // keep label as "select" and disable
                    disabledButtons[index] = true
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
            do {
                _ = try NSWorkspace.shared.launchApplication(at: fileURL, options: [], configuration: [:])
                logInfo("已打开 \(index + 1): \(filePath)")
            } catch {
                showAlert(title: L("warning"), message: error.localizedDescription)
                logError("打开失败: \(error.localizedDescription)")
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
        let cfg = AppConfig(lastOpenedFiles: selectedFiles, preferences: prefs, lastModifiedTimes: lastModifiedTimes)
        ConfigManager.shared.saveConfig(cfg)
    }

    private func loadConfig() {
        if let cfg = ConfigManager.shared.loadConfig() {
            selectedFiles = cfg.lastOpenedFiles
            prefs = cfg.preferences
            for i in 0..<min(9, cfg.lastOpenedFiles.count) {
                if !cfg.lastOpenedFiles[i].isEmpty {
                    buttonLabels[i] = "open"
                    disabledButtons[i] = true
                }
            }
            logInfo("Config loaded via ConfigManager, applying to UI")
        } else {
            logDebug("No config found; using defaults")
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
        alert.messageText = L("reset_app")
        alert.informativeText = L("reset_confirm")
        alert.alertStyle = .warning
        alert.addButton(withTitle: L("reset_app"))
        alert.addButton(withTitle: L("cancel"))
        if alert.runModal() == .alertFirstButtonReturn {
            resetApp()
        }
    }

    private func resetApp() {
        do {
            if FileManager.default.fileExists(atPath: configFileURL.path) {
                try FileManager.default.removeItem(at: configFileURL)
                logInfo("已删除配置文件: \(configFileURL.path)")
            }
            selectedFiles = Array(repeating: "", count: 9)
            buttonLabels = Array(repeating: "select", count: 9)
            disabledButtons = Array(repeating: false, count: 9)
            showAlert(title: L("reset_app"), message: L("reset_success"))
        } catch {
            logError("重置应用失败: \(error.localizedDescription)")
            showAlert(title: L("reset_app"), message: error.localizedDescription)
        }
    }
}

#Preview {
    ContentView()
}
