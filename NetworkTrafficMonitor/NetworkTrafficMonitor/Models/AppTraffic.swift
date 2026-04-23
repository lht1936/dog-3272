import Foundation

struct AppTraffic: Identifiable, Codable {
    let id = UUID()
    let appName: String
    let processID: Int
    var bytesReceived: UInt64
    var bytesSent: UInt64
    var timestamp: Date
    
    var totalBytes: UInt64 {
        return bytesReceived + bytesSent
    }
    
    var formattedBytesReceived: String {
        return formatBytes(bytesReceived)
    }
    
    var formattedBytesSent: String {
        return formatBytes(bytesSent)
    }
    
    var formattedTotalBytes: String {
        return formatBytes(totalBytes)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct AppTrafficHistory: Codable {
    let appName: String
    let processID: Int
    var totalBytesReceived: UInt64
    var totalBytesSent: UInt64
    var firstSeen: Date
    var lastSeen: Date
    
    var totalBytes: UInt64 {
        return totalBytesReceived + totalBytesSent
    }
    
    var formattedTotalBytesReceived: String {
        return formatBytes(totalBytesReceived)
    }
    
    var formattedTotalBytesSent: String {
        return formatBytes(totalBytesSent)
    }
    
    var formattedTotalBytes: String {
        return formatBytes(totalBytes)
    }
    
    var duration: TimeInterval {
        return lastSeen.timeIntervalSince(firstSeen)
    }
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
