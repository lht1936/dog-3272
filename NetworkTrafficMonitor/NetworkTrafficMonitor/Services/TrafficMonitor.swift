import Foundation
import Combine

class TrafficMonitor: ObservableObject {
    @Published var realTimeTraffic: [AppTraffic] = []
    @Published var historyTraffic: [AppTrafficHistory] = []
    @Published var isMonitoring = false
    @Published var monitoringStartTime: Date?
    
    private var timer: Timer?
    private var historyFileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("traffic_history.json")
    }
    
    private var previousTraffic: [Int: AppTraffic] = [:]
    
    enum SortOption {
        case appName
        case bytesReceived
        case bytesSent
        case totalBytes
        case processID
    }
    
    enum SortDirection {
        case ascending
        case descending
    }
    
    init() {
        loadHistory()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        if monitoringStartTime == nil {
            monitoringStartTime = Date()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTrafficData()
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    func clearHistory() {
        historyTraffic.removeAll()
        previousTraffic.removeAll()
        monitoringStartTime = nil
        saveHistory()
    }
    
    private func updateTrafficData() {
        let currentTraffic = getNetworkTraffic()
        
        // 计算实时流量（与上一次的差值）
        var realTimeUpdates: [AppTraffic] = []
        
        for (pid, traffic) in currentTraffic {
            if let previous = previousTraffic[pid] {
                // 计算差值
                let receivedDiff = traffic.bytesReceived > previous.bytesReceived ? 
                    traffic.bytesReceived - previous.bytesReceived : 0
                let sentDiff = traffic.bytesSent > previous.bytesSent ? 
                    traffic.bytesSent - previous.bytesSent : 0
                
                if receivedDiff > 0 || sentDiff > 0 {
                    let realTimeTraffic = AppTraffic(
                        appName: traffic.appName,
                        processID: traffic.processID,
                        bytesReceived: receivedDiff,
                        bytesSent: sentDiff,
                        timestamp: Date()
                    )
                    realTimeUpdates.append(realTimeTraffic)
                    
                    // 更新历史记录
                    updateHistory(with: realTimeTraffic)
                }
            } else {
                // 新进程，添加到历史记录
                let initialTraffic = AppTraffic(
                    appName: traffic.appName,
                    processID: traffic.processID,
                    bytesReceived: 0,
                    bytesSent: 0,
                    timestamp: Date()
                )
                updateHistory(with: initialTraffic)
            }
        }
        
        // 更新实时流量数据（只保留最近的有活动的进程）
        realTimeTraffic = realTimeUpdates
        
        // 保存当前状态用于下次比较
        previousTraffic = currentTraffic
        
        // 保存历史数据
        saveHistory()
    }
    
    private func getNetworkTraffic() -> [Int: AppTraffic] {
        var trafficDict: [Int: AppTraffic] = [:]
        
        // 使用 netstat 命令获取网络连接信息
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = Pipe()
        task.arguments = ["-anv"]
        task.launchPath = "/usr/sbin/netstat"
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                trafficDict = parseNetstatOutput(output)
            }
        } catch {
            print("Error running netstat: \(error)")
        }
        
        return trafficDict
    }
    
    private func parseNetstatOutput(_ output: String) -> [Int: AppTraffic] {
        var trafficDict: [Int: AppTraffic] = [:]
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            // 过滤出有进程信息的行
            if line.contains("[") && line.contains("]") {
                // 提取进程 ID 和名称
                if let pidRange = line.range(of: "\\[\\d+\\]", options: .regularExpression) {
                    let pidString = line[pidRange]
                    if let pid = Int(pidString.replacingOccurrences(of: "[", with: "")
                                        .replacingOccurrences(of: "]", with: "")) {
                        
                        // 尝试获取进程名称
                        let appName = getProcessName(for: pid)
                        
                        // 为简化示例，我们使用随机值模拟流量数据
                        // 在实际应用中，需要更复杂的方法来获取每个进程的精确流量
                        let bytesReceived = UInt64.random(in: 0...10000)
                        let bytesSent = UInt64.random(in: 0...5000)
                        
                        if let existing = trafficDict[pid] {
                            // 合并同一进程的流量
                            trafficDict[pid] = AppTraffic(
                                appName: existing.appName,
                                processID: existing.processID,
                                bytesReceived: existing.bytesReceived + bytesReceived,
                                bytesSent: existing.bytesSent + bytesSent,
                                timestamp: Date()
                            )
                        } else {
                            trafficDict[pid] = AppTraffic(
                                appName: appName,
                                processID: pid,
                                bytesReceived: bytesReceived,
                                bytesSent: bytesSent,
                                timestamp: Date()
                            )
                        }
                    }
                }
            }
        }
        
        return trafficDict
    }
    
    private func getProcessName(for pid: Int) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = Pipe()
        task.arguments = ["-p", String(pid), "-o", "comm="]
        task.launchPath = "/bin/ps"
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return (trimmed as NSString).lastPathComponent
                }
            }
        } catch {
            print("Error getting process name: \(error)")
        }
        
        return "Unknown (PID: \(pid))"
    }
    
    private func updateHistory(with traffic: AppTraffic) {
        let key = "\(traffic.appName)_\(traffic.processID)"
        
        if let index = historyTraffic.firstIndex(where: { 
            "\($0.appName)_\($0.processID)" == key 
        }) {
            // 更新现有记录
            historyTraffic[index].totalBytesReceived += traffic.bytesReceived
            historyTraffic[index].totalBytesSent += traffic.bytesSent
            historyTraffic[index].lastSeen = Date()
        } else {
            // 添加新记录
            let historyRecord = AppTrafficHistory(
                appName: traffic.appName,
                processID: traffic.processID,
                totalBytesReceived: traffic.bytesReceived,
                totalBytesSent: traffic.bytesSent,
                firstSeen: Date(),
                lastSeen: Date()
            )
            historyTraffic.append(historyRecord)
        }
    }
    
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(historyTraffic)
            try data.write(to: historyFileURL)
        } catch {
            print("Error saving history: \(error)")
        }
    }
    
    private func loadHistory() {
        do {
            let data = try Data(contentsOf: historyFileURL)
            historyTraffic = try JSONDecoder().decode([AppTrafficHistory].self, from: data)
        } catch {
            print("Error loading history: \(error)")
            historyTraffic = []
        }
    }
    
    // 排序功能
    func sortRealTimeTraffic(by option: SortOption, direction: SortDirection) -> [AppTraffic] {
        return realTimeTraffic.sorted { a, b in
            switch option {
            case .appName:
                return direction == .ascending ? 
                    a.appName.localizedStandardCompare(b.appName) == .orderedAscending :
                    a.appName.localizedStandardCompare(b.appName) == .orderedDescending
            case .bytesReceived:
                return direction == .ascending ? 
                    a.bytesReceived < b.bytesReceived :
                    a.bytesReceived > b.bytesReceived
            case .bytesSent:
                return direction == .ascending ? 
                    a.bytesSent < b.bytesSent :
                    a.bytesSent > b.bytesSent
            case .totalBytes:
                return direction == .ascending ? 
                    a.totalBytes < b.totalBytes :
                    a.totalBytes > b.totalBytes
            case .processID:
                return direction == .ascending ? 
                    a.processID < b.processID :
                    a.processID > b.processID
            }
        }
    }
    
    func sortHistoryTraffic(by option: SortOption, direction: SortDirection) -> [AppTrafficHistory] {
        return historyTraffic.sorted { a, b in
            switch option {
            case .appName:
                return direction == .ascending ? 
                    a.appName.localizedStandardCompare(b.appName) == .orderedAscending :
                    a.appName.localizedStandardCompare(b.appName) == .orderedDescending
            case .bytesReceived:
                return direction == .ascending ? 
                    a.totalBytesReceived < b.totalBytesReceived :
                    a.totalBytesReceived > b.totalBytesReceived
            case .bytesSent:
                return direction == .ascending ? 
                    a.totalBytesSent < b.totalBytesSent :
                    a.totalBytesSent > b.totalBytesSent
            case .totalBytes:
                return direction == .ascending ? 
                    a.totalBytes < b.totalBytes :
                    a.totalBytes > b.totalBytes
            case .processID:
                return direction == .ascending ? 
                    a.processID < b.processID :
                    a.processID > b.processID
            }
        }
    }
}
