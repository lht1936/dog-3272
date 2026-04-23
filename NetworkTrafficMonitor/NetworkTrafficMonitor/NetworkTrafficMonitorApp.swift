import SwiftUI

@main
struct NetworkTrafficMonitorApp: App {
    @StateObject private var trafficMonitor = TrafficMonitor()
    @State private var selectedTab = 0
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                RealTimeView(trafficMonitor: trafficMonitor)
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("实时流量")
                    }
                    .tag(0)
                
                HistoryView(trafficMonitor: trafficMonitor)
                    .tabItem {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("历史统计")
                    }
                    .tag(1)
            }
            .frame(minWidth: 800, minHeight: 600)
            .onAppear {
                trafficMonitor.startMonitoring()
            }
        }
        .commands {
            CommandMenu("监控") {
                Button("开始监控") {
                    trafficMonitor.startMonitoring()
                }
                .keyboardShortcut("S", modifiers: [.command])
                
                Button("停止监控") {
                    trafficMonitor.stopMonitoring()
                }
                .keyboardShortcut("P", modifiers: [.command])
                
                Divider()
                
                Button("清除历史数据") {
                    trafficMonitor.clearHistory()
                }
                .keyboardShortcut("K", modifiers: [.command])
            }
        }
    }
}
