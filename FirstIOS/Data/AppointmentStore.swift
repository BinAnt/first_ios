import Foundation
import Observation

/// 本机演示用的预约记录。没有后端，变更会写入 UserDefaults。
@MainActor
@Observable
final class AppointmentStore {
    private static let storageKey = "com.binant.firstios.appointments.v1"

    var appointments: [Appointment]
    var selectedTab: AppTab = .home

    private let persists: Bool

    init() {
        persists = true
        appointments = Self.loadAppointments()
    }

    init(previewAppointments: [Appointment]) {
        persists = false
        appointments = previewAppointments
    }

    var upcoming: [Appointment] {
        appointments
            .filter { $0.status == .upcoming }
            .sorted { sortByVisitTime($0, $1) }
    }

    var cancelled: [Appointment] {
        appointments
            .filter { $0.status == .cancelled }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func remaining(for slot: TimeSlot) -> Int {
        if slot.isExpired {
            return 0
        }
        let taken = appointments.reduce(into: 0) { count, appointment in
            if appointment.slotID == slot.id, appointment.status == .upcoming {
                count += 1
            }
        }
        return max(0, slot.initialRemaining - taken)
    }

    func book(_ appointment: Appointment) {
        var updated = appointments
        updated.insert(appointment, at: 0)
        appointments = updated
        persist()
    }

    func cancel(_ appointment: Appointment) {
        guard let index = appointments.firstIndex(where: { $0.id == appointment.id }) else { return }
        var updated = appointments
        updated[index].status = .cancelled
        appointments = updated
        persist()
    }

    func removeAll() {
        appointments = []
        persist()
    }

    private func sortByVisitTime(_ lhs: Appointment, _ rhs: Appointment) -> Bool {
        if lhs.day != rhs.day {
            return lhs.day < rhs.day
        }
        if lhs.timeLabel != rhs.timeLabel {
            return lhs.timeLabel < rhs.timeLabel
        }
        return lhs.createdAt < rhs.createdAt
    }

    private func persist() {
        guard persists else { return }
        guard let data = try? JSONEncoder().encode(appointments) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private static func loadAppointments() -> [Appointment] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([Appointment].self, from: data)) ?? []
    }
}
