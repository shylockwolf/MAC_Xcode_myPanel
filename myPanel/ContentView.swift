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
    @State private var externalDrives: [URL] = []
    @State private var showExternalDrives: Bool = false

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
                VStack(spacing: 0) {
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
                            Text("ver 3.0.1")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("2026-04")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 5)

                // 外接磁盘显示区域
                HStack(spacing: 10) {
                    Button(action: {
                        ejectAllDrives()
                    }) {
                        Image(systemName: "eject.fill")
                            .font(.system(size: 20))
                            .foregroundColor(externalDrives.isEmpty ? .gray : .blue)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(externalDrives.isEmpty)
                    .help(externalDrives.isEmpty ? "无外接设备" : "点击弹出所有外接设备")

                    if externalDrives.isEmpty {
                        Text("无外接设备")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                            .padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    } else {
                        HStack(spacing: 6) {
                            ForEach(externalDrives, id: \.self) { driveURL in
                                Button(action: {
                                    ejectDrive(driveURL)
                                }) {
                                    VStack(spacing: 1) {
                                        Image(nsImage: NSWorkspace.shared.icon(forFile: driveURL.path))
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                        Text(driveURL.lastPathComponent)
                                            .font(.system(size: 8))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("弹出 \(driveURL.lastPathComponent)")
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                        .padding(.horizontal, 10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }

                    Spacer().frame(width: 16)
                }
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
            refreshExternalDrives()
        }
    }
    
    private func calculateWindowHeight() -> CGFloat {
        let headerHeight: CGFloat = 100
        let externalDriveHeight: CGFloat = 55
        let itemHeight: CGFloat = 55
        let bottomSpacing: CGFloat = 20
        let totalHeight = headerHeight + externalDriveHeight + (CGFloat(itemCount) * itemHeight) + bottomSpacing
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
            
            // 调整数组大小以匹配新的 itemCount
            if selectedFiles.count < newCount {
                selectedFiles.append(contentsOf: Array(repeating: "", count: newCount - selectedFiles.count))
            } else if selectedFiles.count > newCount {
                selectedFiles = Array(selectedFiles.prefix(newCount))
            }
            
            if buttonLabels.count < newCount {
                buttonLabels.append(contentsOf: Array(repeating: "select", count: newCount - buttonLabels.count))
            } else if buttonLabels.count > newCount {
                buttonLabels = Array(buttonLabels.prefix(newCount))
            }
            
            if disabledButtons.count < newCount {
                disabledButtons.append(contentsOf: Array(repeating: false, count: newCount - disabledButtons.count))
            } else if disabledButtons.count > newCount {
                disabledButtons = Array(disabledButtons.prefix(newCount))
            }
            
            itemCount = newCount
            
            for i in 0..<min(itemCount, cfg.lastOpenedFiles.count) {
                if !cfg.lastOpenedFiles[i].isEmpty {
                    buttonLabels[i] = "open"
                    disabledButtons[i] = true
                }
            }
            print("DEBUG: 配置应用完成, itemCount=\(itemCount), selectedFiles.count=\(selectedFiles.count), buttonLabels.count=\(buttonLabels.count), disabledButtons.count=\(disabledButtons.count)")
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
    
    private func refreshExternalDrives() {
        var drives: [URL] = []
        
        // 获取所有挂载的卷
        guard let mountedVolumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: []) else {
            externalDrives = []
            return
        }
        
        for volumeURL in mountedVolumes {
            let path = volumeURL.path
            
            // 外接设备通常挂载在 /Volumes/ 下
            // 排除根目录和系统目录
            if path.hasPrefix("/Volumes/") && path != "/" {
                drives.append(volumeURL)
                logInfo("检测到外接设备: \(path)")
            }
        }
        
        externalDrives = drives
        logInfo("共检测到 \(drives.count) 个外接设备")
    }
    
    private func ejectDrive(_ driveURL: URL) {
        Task {
            do {
                try await NSWorkspace.shared.unmountAndEjectDevice(at: driveURL)
                logInfo("已弹出设备: \(driveURL.path)")
                await MainActor.run {
                    self.refreshExternalDrives()
                }
            } catch {
                // 检查是否是 OSStatus error -35 (nsvErr - No Such Volume)
                // 这个错误表示卷已经不存在，意味着磁盘已经弹出或被卸载
                let nsError = error as NSError
                if nsError.domain == "NSOSStatusErrorDomain" && nsError.code == -35 {
                    logInfo("磁盘已不存在（可能已被系统卸载）: \(driveURL.path)")
                    await MainActor.run {
                        self.refreshExternalDrives()
                    }
                    return // 视为成功，不显示错误
                }
                
                logError("弹出设备失败（初始）: \(error.localizedDescription)")
                
                // 每2秒检查一次，最多检查5次（共10秒）
                var ejected = false
                for attempt in 1...5 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 等待 2 秒
                    logInfo("检查磁盘状态（第\(attempt)次，共5次）: \(driveURL.path)")
                    
                    await MainActor.run {
                        self.refreshExternalDrives()
                    }
                    
                    // 检查磁盘是否还在
                    if !self.externalDrives.contains(driveURL) {
                        ejected = true
                        logInfo("磁盘实际已成功弹出: \(driveURL.path)")
                        break
                    }
                }
                
                // 如果10秒后磁盘还在，显示错误
                if !ejected {
                    await MainActor.run {
                        logError("磁盘弹出超时（10秒）: \(driveURL.path)")
                        self.showAlert(title: "弹出失败", message: "磁盘弹出超时（等待10秒）: \(driveURL.lastPathComponent)")
                    }
                }
            }
        }
    }
    
    private func ejectAllDrives() {
        let drivesToEject = externalDrives
        Task {
            var failedDrives: [(URL, String)] = []
            
            for driveURL in drivesToEject {
                do {
                    try await NSWorkspace.shared.unmountAndEjectDevice(at: driveURL)
                    logInfo("已弹出设备: \(driveURL.path)")
                } catch {
                    // 检查是否是 OSStatus error -35 (nsvErr - No Such Volume)
                    let nsError = error as NSError
                    if nsError.domain == "NSOSStatusErrorDomain" && nsError.code == -35 {
                        logInfo("磁盘已不存在（可能已被系统卸载）: \(driveURL.path)")
                        continue // 跳过，视为成功
                    }
                    
                    logError("弹出设备失败（初始）: \(driveURL.path) - \(error.localizedDescription)")
                    // 记录失败的驱动器，稍后会再次检查
                    failedDrives.append((driveURL, error.localizedDescription))
                }
            }
            
            // 每2秒检查一次失败的驱动器，最多检查5次（共10秒）
            var stillFailed: [(URL, String)] = failedDrives
            
            for attempt in 1...5 {
                if stillFailed.isEmpty {
                    break // 所有磁盘都已成功弹出
                }
                
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 等待 2 秒
                logInfo("批量检查磁盘状态（第\(attempt)次，共5次）")
                
                // 刷新驱动器列表
                await MainActor.run {
                    self.refreshExternalDrives()
                }
                
                // 检查失败的驱动器是否已弹出
                var newStillFailed: [(URL, String)] = []
                for (driveURL, errorMsg) in stillFailed {
                    if self.externalDrives.contains(driveURL) {
                        // 驱动器还在列表中，继续等待
                        newStillFailed.append((driveURL, errorMsg))
                    } else {
                        // 驱动器已不在列表中，实际成功
                        logInfo("磁盘实际已成功弹出: \(driveURL.path)")
                    }
                }
                stillFailed = newStillFailed
            }
            
            // 如果10秒后还有磁盘未弹出，显示错误
            await MainActor.run {
                if !stillFailed.isEmpty {
                    for (driveURL, _) in stillFailed {
                        logError("磁盘弹出超时（10秒）: \(driveURL.path)")
                    }
                    let messages = stillFailed.map { "\($0.0.lastPathComponent): 弹出超时（等待10秒）" }.joined(separator: "\n")
                    self.showAlert(title: "部分设备弹出失败", message: messages)
                }
            }
        }
    }
}

// #Preview {
//     ContentView()
// }
