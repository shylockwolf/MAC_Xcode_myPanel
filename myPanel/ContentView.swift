import SwiftUI
import UniformTypeIdentifiers
import Combine

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
    /// 默认每列项数
    private static let defaultItemCount: Int = 9
    /// 最大列数（大面板模式），数组始终按此列数存储，保证切换模式不丢数据
    private static let maxColumns: Int = 4

    @State private var selectedFiles: [String] = Array(repeating: "", count: defaultItemCount * maxColumns)
    @State private var buttonLabels: [String] = Array(repeating: "select", count: defaultItemCount * maxColumns)
    @State private var prefs = Preferences(theme: "default", language: "en")
    @State private var disabledButtons: [Bool] = Array(repeating: false, count: defaultItemCount * maxColumns)
    @State private var itemCount: Int = defaultItemCount
    @State private var isLargePanel: Bool = false
    @State private var externalDrives: [URL] = []

    private var maxColumns: Int { Self.maxColumns }

    private var columnCount: Int {
        isLargePanel ? maxColumns : 1
    }

    /// 存储总数：始终按最大列数保存，切换模式只改显示不改存储
    private var totalItems: Int {
        itemCount * maxColumns
    }

    /// 当前需要显示的索引：单列模式只显示第 1 列（0, 4, 8, ...），大面板显示全部
    private var displayIndices: [Int] {
        if isLargePanel {
            return Array(0..<totalItems)
        } else {
            return (0..<itemCount).map { $0 * maxColumns }
        }
    }
    @State private var showExternalDrives: Bool = false
    @State private var isEjecting: Bool = false
    @StateObject private var ejectionWindowController = EjectionProgressWindowController()

    var body: some View {
        GeometryReader { geometry in
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

                    VStack(spacing: 2) {
                        Text("大面板")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Toggle("", isOn: $isLargePanel)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .onChange(of: isLargePanel) { _, _ in
                                adjustWindowSize()
                                saveConfig()
                            }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(isLargePanel ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .help(isLargePanel ? "当前：四列模式（点击关闭）" : "当前：单列模式（点击开启）")

                    Spacer()

                        Text("myPanel")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Shylock Wolf")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("ver 3.1.2")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("2026-07")
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
                            .foregroundColor(externalDrives.isEmpty ? .gray : (isEjecting ? .yellow : .blue))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(externalDrives.isEmpty || isEjecting)
                    .help(externalDrives.isEmpty ? "无外接设备" : (isEjecting ? "正在弹出..." : "点击弹出所有外接设备"))

                    if externalDrives.isEmpty {
                        HStack {
                            Text("无外接设备")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                refreshExternalDrives()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
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
                            
                            Spacer()
                            
                            Button(action: {
                                refreshExternalDrives()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("刷新")
                        }
                        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                        .padding(.horizontal, 10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 20)

                let columns: [GridItem] = isLargePanel ?
                    Array(repeating: GridItem(.flexible(minimum: 250), spacing: 10), count: 4) :
                    [GridItem(.flexible())]

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(displayIndices, id: \.self) { idx in
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
                    }
                }
                .padding(.horizontal, 20)
                Spacer().frame(height: 20)
            }
        }
        }
        .frame(minWidth: calculateWindowWidth(), idealWidth: calculateWindowWidth(), maxWidth: .infinity,
               minHeight: 450, idealHeight: calculateWindowHeight(), maxHeight: .infinity)
        .onAppear {
            loadConfig()
            refreshExternalDrives()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didMountNotification)) { notification in
            logInfo("收到挂载通知: \(notification.userInfo ?? [:])")
            refreshExternalDrives()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didUnmountNotification)) { notification in
            logInfo("收到卸载通知: \(notification.userInfo ?? [:])")
            refreshExternalDrives()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didRenameVolumeNotification)) { notification in
            logInfo("收到卷重命名通知: \(notification.userInfo ?? [:])")
            refreshExternalDrives()
        }
    }
    
    private func calculateWindowHeight() -> CGFloat {
        let headerHeight: CGFloat = 100
        let externalDriveHeight: CGFloat = 55
        let itemHeight: CGFloat = 55
        let bottomSpacing: CGFloat = 20
        let rows = CGFloat(itemCount)

        let totalHeight = headerHeight + externalDriveHeight + (rows * itemHeight) + bottomSpacing
        return max(totalHeight, 450)
    }

    private func calculateWindowWidth() -> CGFloat {
        return isLargePanel ? 1200 : 350
    }

    private func adjustWindowSize() {
        if let window = NSApp.keyWindow {
            let newWidth = calculateWindowWidth()
            let newHeight = calculateWindowHeight()

            window.minSize = NSSize(width: newWidth, height: 450)

            let currentFrame = window.frame
            let newFrame = NSRect(x: currentFrame.origin.x,
                                  y: currentFrame.origin.y + currentFrame.height - newHeight,
                                  width: newWidth,
                                  height: newHeight)
            window.setFrame(newFrame, display: true, animate: true)
        }
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
        let cfg = AppConfig(lastOpenedFiles: selectedFiles, preferences: prefs, lastModifiedTimes: lastModifiedTimes, itemCount: itemCount, isLargePanel: isLargePanel)
        ConfigManager.shared.saveConfig(cfg)
    }
    
    private func loadConfig() {
        print("DEBUG: 开始加载配置")
        if let cfg = ConfigManager.shared.loadConfig() {
            print("DEBUG: 配置加载成功, itemCount=\(cfg.itemCount), lastOpenedFiles.count=\(cfg.lastOpenedFiles.count)")

            itemCount = cfg.itemCount
            isLargePanel = cfg.isLargePanel
            prefs = cfg.preferences

            // 向后兼容：旧配置只有 itemCount 项（单列顺序存储），需重新分布到第 1 列
            let expectedTotal = itemCount * maxColumns
            if cfg.lastOpenedFiles.count == expectedTotal {
                selectedFiles = cfg.lastOpenedFiles
                // 同步其他数组大小
                resizeArraysToTotal()
            } else {
                selectedFiles = Array(repeating: "", count: expectedTotal)
                for i in 0..<min(cfg.lastOpenedFiles.count, itemCount) {
                    selectedFiles[i * maxColumns] = cfg.lastOpenedFiles[i]
                }
                // 同步其他数组大小
                resizeArraysToTotal()
            }

            for i in 0..<selectedFiles.count {
                if !selectedFiles[i].isEmpty {
                    buttonLabels[i] = "open"
                    disabledButtons[i] = true
                }
            }
            print("DEBUG: 配置应用完成, itemCount=\(itemCount), totalItems=\(totalItems), selectedFiles.count=\(selectedFiles.count), isLargePanel=\(isLargePanel)")
            logInfo("Config loaded via ConfigManager, applying to UI")
            adjustWindowSize()
        } else {
            print("DEBUG: 没有找到配置文件，使用默认值")
            logDebug("No config found; using defaults")
            selectedFiles = Array(repeating: "", count: totalItems)
            buttonLabels = Array(repeating: "select", count: totalItems)
            disabledButtons = Array(repeating: false, count: totalItems)
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
        itemCount = newCount
        resizeArraysToTotal()
        saveConfig()
        adjustWindowSize()
        logInfo("项目数量已从 \(oldCount) 更新为 \(newCount) (每列)")
        print("DEBUG: itemCount=\(itemCount), totalItems=\(totalItems), selectedFiles.count=\(selectedFiles.count)")
    }

    private func resizeArraysToTotal() {
        let target = totalItems

        if selectedFiles.count < target {
            selectedFiles.append(contentsOf: Array(repeating: "", count: target - selectedFiles.count))
        } else if selectedFiles.count > target {
            selectedFiles = Array(selectedFiles.prefix(target))
        }

        if buttonLabels.count < target {
            buttonLabels.append(contentsOf: Array(repeating: "select", count: target - buttonLabels.count))
        } else if buttonLabels.count > target {
            buttonLabels = Array(buttonLabels.prefix(target))
        }

        if disabledButtons.count < target {
            disabledButtons.append(contentsOf: Array(repeating: false, count: target - disabledButtons.count))
        } else if disabledButtons.count > target {
            disabledButtons = Array(disabledButtons.prefix(target))
        }
    }

    private func resetApp() {
        let success = ConfigManager.shared.deleteConfig()
        if success {
            selectedFiles = Array(repeating: "", count: totalItems)
            buttonLabels = Array(repeating: "select", count: totalItems)
            disabledButtons = Array(repeating: false, count: totalItems)
            showAlert(title: L("reset_app"), message: L("reset_success"))
        } else {
            showAlert(title: L("reset_app"), message: "删除配置文件失败")
        }
    }
    
    private func refreshExternalDrives() {
        var drives: [URL] = []
        
        // 获取所有挂载的卷
        guard let mountedVolumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: []) else {
            logError("无法获取挂载卷列表")
            externalDrives = []
            return
        }
        
        logInfo("检测到 \(mountedVolumes.count) 个挂载卷")
        
        for volumeURL in mountedVolumes {
            let path = volumeURL.path
            // 解析符号链接获取真实路径
            let resolvedPath = volumeURL.resolvingSymlinksInPath().path
            
            logInfo("检查卷: \(path), 解析后: \(resolvedPath)")
            
            // 检查是否是外接设备
            // 1. 路径以 /Volumes/ 开头（符号链接路径）
            // 2. 或解析后的路径以 /Volumes/ 开头
            // 3. 排除根目录
            let isExternal = (path.hasPrefix("/Volumes/") || resolvedPath.hasPrefix("/Volumes/")) 
                             && path != "/" 
                             && resolvedPath != "/"
            
            if isExternal {
                drives.append(volumeURL)
                logInfo("添加外接设备: \(volumeURL.lastPathComponent)")
            }
        }
        
        externalDrives = drives
        logInfo("共检测到 \(drives.count) 个外接设备")
    }
    
    private func ejectDrive(_ driveURL: URL) {
        Task {
            do {
                try NSWorkspace.shared.unmountAndEjectDevice(at: driveURL)
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
        isEjecting = true
        var logs: [String] = ["开始弹出所有外接设备..."]
        ejectionWindowController.updateLogs(logs)
        ejectionWindowController.showWindow()
        
        Task {
            let drivesToEject = externalDrives
            var failedDrives: [(URL, String)] = []
            
            for driveURL in drivesToEject {
                logs.append("正在弹出: \(driveURL.lastPathComponent)")
                await MainActor.run {
                    ejectionWindowController.updateLogs(logs)
                }
                
                do {
                    try NSWorkspace.shared.unmountAndEjectDevice(at: driveURL)
                    logInfo("已弹出设备: \(driveURL.path)")
                    logs.append("✓ 成功弹出: \(driveURL.lastPathComponent)")
                    await MainActor.run {
                        ejectionWindowController.updateLogs(logs)
                    }
                } catch {
                    let nsError = error as NSError
                    if nsError.domain == "NSOSStatusErrorDomain" && nsError.code == -35 {
                        logInfo("磁盘已不存在（可能已被系统卸载）: \(driveURL.path)")
                        logs.append("⚠ 磁盘已不存在: \(driveURL.lastPathComponent)")
                        await MainActor.run {
                            ejectionWindowController.updateLogs(logs)
                        }
                        continue
                    }
                    
                    logError("弹出设备失败（初始）: \(driveURL.path) - \(error.localizedDescription)")
                    // 不在窗口显示，只记录到失败列表
                    failedDrives.append((driveURL, error.localizedDescription))
                }
            }
            
            var stillFailed: [(URL, String)] = failedDrives
            
            if !stillFailed.isEmpty {
                for attempt in 1...5 {
                    if stillFailed.isEmpty {
                        break
                    }
                    
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    logInfo("批量检查磁盘状态（第\(attempt)次，共5次）")
                    
                    await MainActor.run {
                        self.refreshExternalDrives()
                    }
                    
                    var newStillFailed: [(URL, String)] = []
                    for (driveURL, errorMsg) in stillFailed {
                        if self.externalDrives.contains(driveURL) {
                            newStillFailed.append((driveURL, errorMsg))
                        } else {
                            logInfo("磁盘实际已成功弹出: \(driveURL.path)")
                            logs.append("✓ 成功弹出: \(driveURL.lastPathComponent)")
                            await MainActor.run {
                                ejectionWindowController.updateLogs(logs)
                            }
                        }
                    }
                    stillFailed = newStillFailed
                }
            }
            
            await MainActor.run {
                if !stillFailed.isEmpty {
                    for (driveURL, _) in stillFailed {
                        logError("磁盘弹出超时（10秒）: \(driveURL.path)")
                        logs.append("✗ 弹出失败: \(driveURL.lastPathComponent)")
                    }
                    logs.append("\n部分设备弹出失败")
                    let messages = stillFailed.map { "\($0.0.lastPathComponent)" }.joined(separator: "\n")
                    self.showAlert(title: "部分设备弹出失败", message: messages)
                    // 刷新外接设备列表（仅在有失败时刷新以显示剩余设备）
                    self.refreshExternalDrives()
                } else {
                    logs.append("\n所有设备已成功弹出")
                    // 直接清空列表，恢复到初始状态
                    self.externalDrives = []
                }
                
                ejectionWindowController.updateLogs(logs)
                
                // 延迟关闭窗口
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.ejectionWindowController.closeWindow()
                    self.isEjecting = false
                }
            }
        }
    }
    
    // 根据日志内容返回不同的颜色
    private func getLogTextColor(_ log: String) -> Color {
        if log.contains("✓") {
            return .green
        } else if log.contains("✗") {
            return .red
        } else if log.contains("⚠") {
            return .orange
        } else {
            return .primary
        }
    }
}

// 弹出进度窗口控制器
class EjectionProgressWindowController: ObservableObject {
    private var window: NSPanel?
    @Published var logs: [String] = []
    
    func showWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "弹出设备进度"
        panel.isFloatingPanel = true
        panel.level = .floating
        
        let contentView = EjectionProgressView(logs: logs)
        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
        
        window = panel
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
    
    func updateLogs(_ newLogs: [String]) {
        logs = newLogs
        if let hostingView = window?.contentView as? NSHostingView<EjectionProgressView> {
            hostingView.rootView = EjectionProgressView(logs: newLogs)
        }
    }
    
    func closeWindow() {
        window?.close()
        window = nil
    }
}

struct EjectionProgressView: View {
    let logs: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(logs, id: \.self) { log in
                        Text(log)
                            .font(.system(size: 12))
                            .foregroundColor(getLogTextColor(log))
                    }
                }
                .padding()
            }
            .frame(maxHeight: .infinity)
            
            HStack {
                Spacer()
                Text("正在处理...")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.bottom, 10)
        }
        .frame(width: 400, height: 280)
    }
    
    private func getLogTextColor(_ log: String) -> Color {
        if log.contains("✓") {
            return .green
        } else if log.contains("✗") {
            return .red
        } else if log.contains("⚠") {
            return .orange
        } else {
            return .primary
        }
    }
}

// #Preview {
//     ContentView()
// }
