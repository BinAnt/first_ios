import SwiftUI

struct ScheduleView: View {
    @Environment(AppointmentStore.self) private var store

    let hospital: Hospital
    let department: Department
    let doctor: Doctor
    let onContinue: (TimeSlot) -> Void

    @State private var selectedDay = BookingCalendar.startOfDay(.now)
    @State private var selectedSlotID: UUID?

    private let slotColumns = [GridItem(.adaptive(minimum: 108), spacing: 8)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                doctorHeader
                dateSection
                slotSection
            }
            .padding(16)
            .padding(.bottom, 12)
            .readableColumn()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("选择时间")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .onChange(of: selectedDay) { _, _ in
            selectedSlotID = nil
        }
        .sensoryFeedback(.selection, trigger: selectedSlotID)
    }

    private var days: [Date] {
        MockCatalog.upcomingDays()
    }

    private var slots: [TimeSlot] {
        MockCatalog.slots(for: doctor, on: selectedDay)
    }

    private var selectedSlot: TimeSlot? {
        guard let selectedSlotID else { return nil }
        return slots.first { $0.id == selectedSlotID }
    }

    private var doctorHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(doctor.name)
                    .font(.title3.weight(.semibold))
                Text(doctor.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("\(hospital.name) · \(department.name)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(doctor.bio)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Label(BookingFormat.rating(doctor.rating), systemImage: "star.fill")
                    .foregroundStyle(AppTheme.warning)
                Spacer()
                Text("挂号费 \(BookingFormat.fee(doctor.fee))")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "就诊日期")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(days, id: \.self) { day in
                        dateChip(day)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func dateChip(_ day: Date) -> some View {
        let isSelected = BookingCalendar.startOfDay(day) == selectedDay
        return Button {
            selectedDay = BookingCalendar.startOfDay(day)
        } label: {
            VStack(spacing: 4) {
                Text(BookingCalendar.relativeLabel(day))
                    .font(.caption.weight(.semibold))
                Text(BookingCalendar.monthSlashDay(day))
                    .font(.subheadline.weight(.bold))
            }
            .frame(minWidth: 72, minHeight: 64)
            .padding(.horizontal, 8)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                isSelected ? AppTheme.primary : AppTheme.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(isSelected ? 0 : 0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(BookingCalendar.relativeLabel(day)) \(BookingFormat.fullDate(day))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var slotSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "门诊时段")
            ForEach(DayPeriod.allCases) { period in
                VStack(alignment: .leading, spacing: 8) {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: slotColumns, spacing: 8) {
                        ForEach(slots.filter { $0.period == period }) { slot in
                            slotCell(slot)
                        }
                    }
                }
            }

            if !slots.contains(where: { store.remaining(for: $0) > 0 }) {
                Text("这一天没有可预约号源，请换一天。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func slotCell(_ slot: TimeSlot) -> some View {
        let remaining = store.remaining(for: slot)
        let isAvailable = remaining > 0
        let isSelected = selectedSlotID == slot.id && isAvailable
        let statusText = slotStatusText(slot: slot, remaining: remaining)

        return Button {
            guard isAvailable else { return }
            selectedSlotID = slot.id
        } label: {
            VStack(spacing: 4) {
                Text(slot.timeLabel)
                    .font(.subheadline.weight(.semibold))
                Text(statusText)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(slotForeground(isSelected: isSelected, isAvailable: isAvailable))
            .background(
                slotBackground(isSelected: isSelected, isAvailable: isAvailable),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .accessibilityLabel("\(slot.period.rawValue) \(slot.timeLabel)")
        .accessibilityValue(statusText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func slotStatusText(slot: TimeSlot, remaining: Int) -> String {
        if slot.isExpired {
            return "已过时"
        }
        if remaining <= 0 {
            return "已约满"
        }
        return "余 \(remaining)"
    }

    private func slotForeground(isSelected: Bool, isAvailable: Bool) -> Color {
        if isSelected { return .white }
        if isAvailable { return .primary }
        return .secondary
    }

    private func slotBackground(isSelected: Bool, isAvailable: Bool) -> Color {
        if isSelected { return AppTheme.primary }
        if isAvailable { return AppTheme.cardBackground }
        return Color.secondary.opacity(0.12)
    }

    @ViewBuilder
    private var bottomBar: some View {
        Group {
            if let selectedSlot, store.remaining(for: selectedSlot) > 0 {
                Button {
                    onContinue(selectedSlot)
                } label: {
                    Text("下一步 · \(selectedSlot.period.rawValue) \(selectedSlot.timeLabel)")
                        .primaryButtonLabel()
                }
                .buttonStyle(PressableStyle())
                .accessibilityHint("填写就诊人并确认预约")
            } else {
                Text(selectedSlot == nil ? "请选择就诊时段" : "该时段已不可预约")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 24)
                    .padding(.vertical, 16)
                    .background(
                        Color.secondary.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    let hospital = MockCatalog.hospitals[0]
    let department = MockCatalog.departments(for: hospital)[0]
    let doctor = MockCatalog.doctors(for: department)[0]
    NavigationStack {
        ScheduleView(hospital: hospital, department: department, doctor: doctor) { _ in }
    }
    .environment(PreviewSupport.emptyStore())
}
