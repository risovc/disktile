import Foundation
import SwiftUI

public enum Formatters {
    public static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    public static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    public static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    public static func formatPercentage(_ fraction: Double) -> String {
        let percent = fraction * 100.0
        if percent < 0.1 && percent > 0 {
            return "< 0.1%"
        }
        return String(format: "%.1f%%", percent)
    }
}
