import SwiftUI

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(minWidth: 64, alignment: .leading)
            Text(value)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}

struct StatusCapsule: View {
    let status: AppointmentStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(status == .upcoming ? AppTheme.primary : Color.secondary)
            .background(
                status == .upcoming ? AppTheme.softFill : Color.secondary.opacity(0.15),
                in: Capsule()
            )
            .accessibilityLabel("状态 \(status.rawValue)")
    }
}

struct UpcomingBadge: ViewModifier {
    let count: Int

    @ViewBuilder
    func body(content: Content) -> some View {
        if count > 0 {
            content.badge(count)
        } else {
            content
        }
    }
}

extension View {
    func cardStyle() -> some View {
        background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
    }

    func primaryButtonLabel() -> some View {
        font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(.vertical, 16)
            .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func secondaryButtonLabel() -> some View {
        font(.headline)
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(.vertical, 16)
            .background(AppTheme.softFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func readableColumn() -> some View {
        frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
    }
}

enum PreviewSupport {
    @MainActor
    static func emptyStore() -> AppointmentStore {
        AppointmentStore(previewAppointments: [])
    }

    @MainActor
    static func storeWithSamples() -> AppointmentStore {
        let store = AppointmentStore(previewAppointments: [])
        if let upcoming = sampleAppointment(serial: 9_001, status: .upcoming, dayOffset: 1) {
            store.book(upcoming)
        }
        if let cancelled = sampleAppointment(serial: 9_002, status: .cancelled, dayOffset: 3) {
            store.book(cancelled)
        }
        return store
    }

    private static func sampleAppointment(
        serial: UInt64,
        status: AppointmentStatus,
        dayOffset: Int
    ) -> Appointment? {
        let hospital = MockCatalog.hospitals[0]
        guard let department = MockCatalog.departments(for: hospital).first,
              let doctor = MockCatalog.doctors(for: department).first,
              let day = BookingCalendar.upcomingDays().dropFirst(dayOffset).first,
              let slot = MockCatalog.slots(for: doctor, on: day).first
        else {
            return nil
        }
        return Appointment(
            id: StableID.make(serial),
            slotID: slot.id,
            hospitalName: hospital.name,
            departmentName: department.name,
            doctorName: doctor.name,
            doctorTitle: doctor.title,
            day: slot.day,
            period: slot.period,
            timeLabel: slot.timeLabel,
            patientName: "李小安",
            phone: "13800138000",
            fee: doctor.fee,
            note: status == .upcoming ? "晨起头晕两周" : "",
            createdAt: Date(timeIntervalSinceNow: -3_600),
            status: status
        )
    }
}
