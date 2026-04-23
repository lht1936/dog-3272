import SwiftUI

struct HistoryView: View {
    @ObservedObject var trafficMonitor: TrafficMonitor
    @State private var sortOption: TrafficMonitor.SortOption = .totalBytes
    @State private var sortDirection: TrafficMonitor.SortDirection = .descending
    @State private var selectedSortColumn: String = "total"
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部控制栏
            HStack {
                Text("历史流量统计")
                    .font(.system(size: 28, weight: .bold))
                
                Spacer()
                
                HStack {
                    Image(systemName: "clock.fill")
                    Text("累计统计")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    trafficMonitor.clearHistory()
                }) {
                    Text("清除历史数据")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // 统计摘要
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("监控应用总数")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(trafficMonitor.historyTraffic.count)")
                        .font(.system(size: 28, weight: .bold))
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("总接收流量")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedTotalReceived)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("总发送流量")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedTotalSent)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            // 排序控制
            HStack {
                Text("排序方式:")
                    .font(.subheadline)
                
                Menu {
                    Button("应用名称") {
                        sortOption = .appName
                        selectedSortColumn = "name"
                    }
                    Button("接收字节数") {
                        sortOption = .bytesReceived
                        selectedSortColumn = "received"
                    }
                    Button("发送字节数") {
                        sortOption = .bytesSent
                        selectedSortColumn = "sent"
                    }
                    Button("总字节数") {
                        sortOption = .totalBytes
                        selectedSortColumn = "total"
                    }
                    Button("进程ID") {
                        sortOption = .processID
                        selectedSortColumn = "pid"
                    }
                } label: {
                    Text(getSortOptionLabel())
                        .frame(width: 120)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                
                Button(action: {
                    sortDirection = sortDirection == .ascending ? .descending : .ascending
                }) {
                    Image(systemName: sortDirection == .ascending ? "arrow.up" : "arrow.down")
                }
                
                Spacer()
                
                if let startTime = trafficMonitor.monitoringStartTime {
                    Text("监控开始时间: \(formatDate(startTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding([.leading, .trailing, .top])
            .padding(.bottom, 5)
            
            // 历史流量表格
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 表头
                    HStack(spacing: 0) {
                        Text("应用名称")
                            .font(.headline)
                            .frame(width: 200, alignment: .leading)
                            .padding(.horizontal, 8)
                            .background(sortIndicatorBackground(for: "name"))
                            .onTapGesture {
                                if sortOption == .appName {
                                    sortDirection = sortDirection == .ascending ? .descending : .ascending
                                } else {
                                    sortOption = .appName
                                    sortDirection = .ascending
                                }
                                selectedSortColumn = "name"
                            }
                        
                        Text("总接收")
                            .font(.headline)
                            .frame(width: 120, alignment: .trailing)
                            .padding(.horizontal, 8)
                            .background(sortIndicatorBackground(for: "received"))
                            .onTapGesture {
                                if sortOption == .bytesReceived {
                                    sortDirection = sortDirection == .ascending ? .descending : .ascending
                                } else {
                                    sortOption = .bytesReceived
                                    sortDirection = .descending
                                }
                                selectedSortColumn = "received"
                            }
                        
                        Text("总发送")
                            .font(.headline)
                            .frame(width: 120, alignment: .trailing)
                            .padding(.horizontal, 8)
                            .background(sortIndicatorBackground(for: "sent"))
                            .onTapGesture {
                                if sortOption == .bytesSent {
                                    sortDirection = sortDirection == .ascending ? .descending : .ascending
                                } else {
                                    sortOption = .bytesSent
                                    sortDirection = .descending
                                }
                                selectedSortColumn = "sent"
                            }
                        
                        Text("总计")
                            .font(.headline)
                            .frame(width: 120, alignment: .trailing)
                            .padding(.horizontal, 8)
                            .background(sortIndicatorBackground(for: "total"))
                            .onTapGesture {
                                if sortOption == .totalBytes {
                                    sortDirection = sortDirection == .ascending ? .descending : .ascending
                                } else {
                                    sortOption = .totalBytes
                                    sortDirection = .descending
                                }
                                selectedSortColumn = "total"
                            }
                        
                        Text("持续时间")
                            .font(.headline)
                            .frame(width: 100, alignment: .trailing)
                            .padding(.horizontal, 8)
                        
                        Text("PID")
                            .font(.headline)
                            .frame(width: 80, alignment: .trailing)
                            .padding(.horizontal, 8)
                            .background(sortIndicatorBackground(for: "pid"))
                            .onTapGesture {
                                if sortOption == .processID {
                                    sortDirection = sortDirection == .ascending ? .descending : .ascending
                                } else {
                                    sortOption = .processID
                                    sortDirection = .ascending
                                }
                                selectedSortColumn = "pid"
                            }
                    }
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    // 数据行
                    if sortedHistory.isEmpty {
                        VStack {
                            Spacer()
                            Text("暂无历史流量数据")
                                .foregroundColor(.secondary)
                                .padding()
                            Text("开始监控后，数据将自动记录")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(minHeight: 300)
                    } else {
                        ForEach(sortedHistory, id: \.appName) { history in
                            HStack(spacing: 0) {
                                Text(history.appName)
                                    .frame(width: 200, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Text(history.formattedTotalBytesReceived)
                                    .frame(width: 120, alignment: .trailing)
                                    .padding(.horizontal, 8)
                                    .foregroundColor(.blue)
                                
                                Text(history.formattedTotalBytesSent)
                                    .frame(width: 120, alignment: .trailing)
                                    .padding(.horizontal, 8)
                                    .foregroundColor(.green)
                                
                                Text(history.formattedTotalBytes)
                                    .frame(width: 120, alignment: .trailing)
                                    .padding(.horizontal, 8)
                                    .font(.system(size: 13, weight: .semibold))
                                
                                Text(history.formattedDuration)
                                    .frame(width: 100, alignment: .trailing)
                                    .padding(.horizontal, 8)
                                    .foregroundColor(.secondary)
                                
                                Text(String(history.processID))
                                    .frame(width: 80, alignment: .trailing)
                                    .padding(.horizontal, 8)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                            .background(
                                sortedHistory.firstIndex(where: { $0.appName == history.appName })! % 2 == 0 ? 
                                    Color.clear : Color(NSColor.controlBackgroundColor).opacity(0.3)
                            )
                            
                            Divider()
                        }
                    }
                }
            }
            .background(Color(NSColor.textBackgroundColor))
        }
    }
    
    private var sortedHistory: [AppTrafficHistory] {
        return trafficMonitor.sortHistoryTraffic(by: sortOption, direction: sortDirection)
    }
    
    private var totalReceived: UInt64 {
        return trafficMonitor.historyTraffic.reduce(0) { $0 + $1.totalBytesReceived }
    }
    
    private var totalSent: UInt64 {
        return trafficMonitor.historyTraffic.reduce(0) { $0 + $1.totalBytesSent }
    }
    
    private var formattedTotalReceived: String {
        return formatBytes(totalReceived)
    }
    
    private var formattedTotalSent: String {
        return formatBytes(totalSent)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func getSortOptionLabel() -> String {
        switch sortOption {
        case .appName:
            return "应用名称"
        case .bytesReceived:
            return "接收字节数"
        case .bytesSent:
            return "发送字节数"
        case .totalBytes:
            return "总字节数"
        case .processID:
            return "进程ID"
        }
    }
    
    private func sortIndicatorBackground(for column: String) -> Color {
        if selectedSortColumn == column {
            return Color.blue.opacity(0.1)
        }
        return Color.clear
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(trafficMonitor: TrafficMonitor())
    }
}
