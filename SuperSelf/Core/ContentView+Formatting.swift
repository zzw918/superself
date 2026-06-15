import SwiftUI

extension ContentView {
    func chineseDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "M月d日 HH:mm"
            : "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }

    func chineseMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    func chineseMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月"
        return formatter.string(from: date)
    }

    func chineseDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "d日"
        return formatter.string(from: date)
    }

    func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    func chineseYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年"
        return formatter.string(from: date)
    }

    func chineseYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }

    func anniversaryDateText(for item: AnniversaryItem) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        if item.calendarKind == .lunar {
            formatter.calendar = Calendar(identifier: .chinese)
            formatter.setLocalizedDateFormatFromTemplate("MMMd")
            return "农历\(formatter.string(from: item.date))"
        } else {
            formatter.dateFormat = "M月d日"
            return "阳历\(formatter.string(from: item.date))"
        }
    }

    func anniversarySolarText(for item: AnniversaryItem) -> String? {
        guard item.calendarKind == .lunar,
              let nextDate = nextAnniversaryDate(for: item) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return "阳历 \(formatter.string(from: nextDate))"
    }

    func elapsedDaysText(for item: AnniversaryItem) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: item.date),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0

        if days < 0 {
            return "还没开始"
        }
        return "已 \(days) 天"
    }

    func daysUntilAnniversary(for item: AnniversaryItem) -> Int? {
        guard let nextDate = nextAnniversaryDate(for: item) else { return nil }
        return Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: nextDate)
        ).day
    }

    func nextAnniversaryDate(for item: AnniversaryItem) -> Date? {
        nextAnniversaryDate(date: item.date, calendarKind: item.calendarKind)
    }

    func nextAnniversaryDate(date: Date, calendarKind: AnniversaryCalendarKind) -> Date? {
        let sourceCalendar = calendarKind == .lunar ? Calendar(identifier: .chinese) : Calendar.current
        let targetComponents = sourceCalendar.dateComponents([.month, .day], from: date)
        let today = Date()

        for yearOffset in 0...3 {
            let candidateBaseDate = Calendar.current.date(byAdding: .year, value: yearOffset, to: today) ?? today
            let candidateYear = sourceCalendar.component(.year, from: candidateBaseDate)
            var components = DateComponents()
            components.calendar = sourceCalendar
            components.year = candidateYear
            components.month = targetComponents.month
            components.day = targetComponents.day

            if let candidateDate = sourceCalendar.date(from: components),
               Calendar.current.startOfDay(for: candidateDate) >= Calendar.current.startOfDay(for: today) {
                return candidateDate
            }
        }

        return nil
    }

    func anniversarySolarPreviewText(date: Date, calendarKind: AnniversaryCalendarKind) -> String? {
        guard calendarKind == .lunar,
              let nextDate = nextAnniversaryDate(date: date, calendarKind: calendarKind) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        return formatter.string(from: nextDate)
    }

    func relativeTimeText(for date: Date) -> String {
        let calendar = Calendar.current
        let dayText: String

        if calendar.isDateInToday(date) {
            dayText = "今天"
        } else if calendar.isDateInYesterday(date) {
            dayText = "昨天"
        } else if calendar.isDateInTomorrow(date) {
            dayText = "明天"
        } else {
            dayText = date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits))
        }

        return "\(dayText) \(date.formatted(date: .omitted, time: .shortened))"
    }

    func durationText(from startDate: Date, to endDate: Date) -> String {
        let totalMinutes = max(0, Int(endDate.timeIntervalSince(startDate) / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 {
            return "\(hours) 小时"
        }

        return "\(hours) 小时 \(minutes) 分钟"
    }

    func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    func compactDurationText(from interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(interval / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return "\(minutes) 分钟"
        }
        if minutes == 0 {
            return "\(hours) 小时"
        }
        return "\(hours) 小时 \(minutes) 分钟"
    }

    func weightText(_ weight: Double) -> String {
        String(format: "%.1f", weight)
    }

    func currencyText(_ amount: Double) -> String {
        if abs(amount) >= 10_000 {
            let value = amount / 10_000
            let text = value == value.rounded() ? String(format: "%.0f", value) : String(format: "%.1f", value)
            return "¥\(text)万"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 0
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "¥%.0f", amount)
    }

    func financeDistributionColor(at index: Int) -> Color {
        let colors: [Color] = [
            .blue,
            .teal,
            .indigo,
            .orange,
            .green,
            .purple
        ]
        return colors[index % colors.count]
    }
}
