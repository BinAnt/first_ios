import Foundation

enum HospitalCategory: String, Codable, Hashable, CaseIterable, Identifiable {
    case general = "综合"
    case tcm = "中医"
    case maternal = "妇幼"
    case specialty = "专科"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .general: "综合医院"
        case .tcm: "中医医院"
        case .maternal: "妇幼保健"
        case .specialty: "专科医院"
        }
    }
}

enum HospitalFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case general = "综合"
    case tcm = "中医"
    case maternal = "妇幼"
    case specialty = "专科"

    var id: String { rawValue }

    var category: HospitalCategory? {
        HospitalCategory(rawValue: rawValue)
    }
}

struct Hospital: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let level: String
    let category: HospitalCategory
    let district: String
    let address: String
    let phone: String
    let openHours: String
    let summary: String
    let symbol: String
}

struct Department: Identifiable, Hashable, Codable {
    let id: UUID
    let hospitalID: UUID
    let name: String
    let symbol: String
    let summary: String
}

struct Doctor: Identifiable, Hashable, Codable {
    let id: UUID
    let departmentID: UUID
    let serial: Int
    let name: String
    let title: String
    let years: Int
    let rating: Double
    let fee: Int
    let specialty: String
    let bio: String

    var avatarText: String {
        String(name.prefix(1))
    }
}

enum DayPeriod: String, Codable, Hashable, CaseIterable, Identifiable {
    case morning = "上午"
    case afternoon = "下午"

    var id: String { rawValue }
}

struct TimeSlot: Identifiable, Hashable, Codable {
    let id: UUID
    let doctorID: UUID
    let day: Date
    let period: DayPeriod
    let timeLabel: String
    let initialRemaining: Int
}

enum AppointmentStatus: String, Codable, Hashable, CaseIterable, Identifiable {
    case upcoming = "待就诊"
    case cancelled = "已取消"

    var id: String { rawValue }
}

struct Appointment: Identifiable, Hashable, Codable {
    let id: UUID
    let slotID: UUID
    let hospitalName: String
    let departmentName: String
    let doctorName: String
    let doctorTitle: String
    let day: Date
    let period: DayPeriod
    let timeLabel: String
    let patientName: String
    let phone: String
    let fee: Int
    let note: String
    let createdAt: Date
    var status: AppointmentStatus
}

enum AppTab: Hashable {
    case home
    case appointments
}

enum StableID {
    static func make(_ value: UInt64) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        bytes[6] = 0x40
        bytes[8] = 0x80
        var remaining = value
        for index in stride(from: 15, through: 10, by: -1) {
            bytes[index] = UInt8(truncatingIfNeeded: remaining)
            remaining >>= 8
        }
        precondition(remaining == 0, "标识超出 48 位：\(value)")
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    /// 号源 ID 按医生序号、公历日期和时段下标生成，同一天重复打开 App 时保持不变。
    static func slotID(doctorSerial: Int, datePart: Int, slotIndex: Int) -> UUID {
        precondition(doctorSerial > 0)
        precondition(datePart > 0)
        precondition(slotIndex >= 0 && slotIndex < 100)
        let value = UInt64(doctorSerial) * 10_000_000_000
            + UInt64(datePart) * 100
            + UInt64(slotIndex)
        return make(value)
    }
}
