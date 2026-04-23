import SwiftUI

struct RealTimeView: View {
    @ObservedObject var trafficMonitor: TrafficMonitor
    @State private var sortOption: TrafficMonitor.SortOption = .totalBytes
    @State private var sortDirection: TrafficMonitor.SortDirection = .descending
    @State private var selectedSortColumn: String = "total"
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部控制栏
            HStack {
                Text("实时网络流量监控")
                    .font(.system(size: 28, weight: .bold))
                
                Spacer()
                
                HStack(spacing: 10) {
                    if trafficMonitor.isMonitoring {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                        Text("监控中")
                            .foregroundColor(.green)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        Text("已停止")
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                HStack {
                    Button(action: {
                        if trafficMonitor.isMonitoring {
                            trafficMonitor.stopMonitoring()
                        } else {
                            trafficMonitor.startMonitoring()
                        }
                    }) {
                        Text(trafficMonitor.isMonitoring ? "停止监控" : "开始监控")
                    }
                    
                    Button(action: {
                        trafficMonitor.clearHistory()
                    }) {
                        Text("清除数据")
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
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
            
            // 流量表格
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 表头
                    HStack(spacing: 0) {
                        Text("应用名称")
                            .font(.headline)
                            .frame(width: 250, alignment: .leading)
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
                        
                        Text("接收")
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
                        
                        Text("发送")
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
                    if sortedTraffic.isEmpty {
                        VStack {
                            Spacer()
                            Text("暂无实时流量数据")
                                .foregroundColor(.secondary)
                                .padding()
                            Spacer()
                        }
                        .frame(minHeight: 300)
                    } else {
                        ForEach(sortedTraffic) { traffic in
                            HStack(spacing: 0) {
                                Text(traffic.appName)
                                    .frame(width: 250, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Text(traffic.formattedBytesReceived)
                                    .frame(width: 120, alignment: .trailing)
                                    .padding(.horizontal, 8)
                                    .foregroundColor(.blue)
                                
                                Text(traffic.formattedBytesSent)
                                    .frame(width: 120, alignment: .trailing)
                                    .padding(.horizontal, 8)
                                    .foregroundColor(.green)
                                
                                Text(traffic.formattedTotalBytes)
                                    .frame(width: 120, alignment: .trailing)
                                    .padding(.horizontal, 8)
                                    .font(.system(size: 13, weight: .semibold))
                                
                                Text(String(traffic.processID))
                                    .frame(width: 80, alignment: .trailing)
                                    .padding(.horizontal, 8)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                            .background(
                                sortedTraffic.firstIndex(where: { $0.id == traffic.id })! % 2 == 0 ? 
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
    
    private var sortedTraffic: [AppTraffic] {
        return trafficMonitor.sortRealTimeTraffic(by: sortOption, direction: sortDirection)
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

struct RealTimeView_Previews: PreviewProvider {
    static var previews: some View {
        RealTimeView(trafficMonitor: TrafficMonitor())
    }
}
