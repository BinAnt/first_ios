import Foundation

enum BookingCalendar {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        return calendar
    }()

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func upcomingDays(count: Int = 7, from now: Date = .now) -> [Date] {
        let start = startOfDay(now)
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    static func datePart(_ date: Date) -> Int {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }

    static func endDate(day: Date, timeLabel: String) -> Date? {
        guard let end = timeLabel.split(separator: "-").last else { return nil }
        let pieces = end.split(separator: ":")
        guard pieces.count == 2, let hour = Int(pieces[0]), let minute = Int(pieces[1]) else {
            return nil
        }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay(day))
    }

    static func isExpired(day: Date, timeLabel: String, now: Date = .now) -> Bool {
        guard let end = endDate(day: day, timeLabel: timeLabel) else { return false }
        return end <= now
    }

    static func dayOffset(from start: Date, to date: Date) -> Int {
        calendar.dateComponents([.day], from: startOfDay(start), to: startOfDay(date)).day ?? 0
    }

    static func relativeLabel(_ date: Date, now: Date = .now) -> String {
        switch dayOffset(from: now, to: date) {
        case 0: "今天"
        case 1: "明天"
        case 2: "后天"
        default: weekdayText(date)
        }
    }

    static func weekdayText(_ date: Date) -> String {
        let symbols = calendar.shortWeekdaySymbols
        let index = calendar.component(.weekday, from: date) - 1
        guard symbols.indices.contains(index) else { return "" }
        return symbols[index]
    }

    static func monthSlashDay(_ date: Date) -> String {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return "\(month)/\(day)"
    }
}

extension TimeSlot {
    var isExpired: Bool {
        BookingCalendar.isExpired(day: day, timeLabel: timeLabel)
    }
}

enum BookingFormat {
    static func fee(_ value: Int) -> String {
        "¥\(value)"
    }

    static func rating(_ value: Double) -> String {
        let tenths = Int((value * 10).rounded())
        return "\(tenths / 10).\(abs(tenths % 10))"
    }

    static func fullDate(_ date: Date) -> String {
        let parts = BookingCalendar.calendar.dateComponents([.year, .month, .day], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return "\(year)年\(month)月\(day)日 \(BookingCalendar.weekdayText(date))"
    }

    static func scheduleText(day: Date, period: DayPeriod, timeLabel: String) -> String {
        let offset = BookingCalendar.dayOffset(from: .now, to: day)
        if (0...2).contains(offset) {
            return "\(BookingCalendar.relativeLabel(day)) \(period.rawValue) \(timeLabel)"
        }
        return "\(fullDate(day)) \(period.rawValue) \(timeLabel)"
    }

    static func createdAt(_ date: Date) -> String {
        createdAtFormatter.string(from: date)
    }

    static func maskedPhone(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)
        guard digits.count == 11 else { return phone }
        let start = digits.prefix(3)
        let end = digits.suffix(4)
        return "\(start)****\(end)"
    }

    static func confirmationCode(for appointment: Appointment) -> String {
        let compact = appointment.id.uuidString.replacingOccurrences(of: "-", with: "")
        return "BA-\(compact.prefix(6))"
    }

    private static let createdAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
}
