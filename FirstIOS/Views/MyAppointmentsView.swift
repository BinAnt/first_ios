import SwiftUI

private enum AppointmentFilter: String, CaseIterable, Identifiable {
    case upcoming = "待就诊"
    case cancelled = "已取消"

    var id: String { rawValue }
}

struct MyAppointmentsView: View {
    @Environment(AppointmentStore.self) private var store
    @State private var filter: AppointmentFilter = .upcoming
    @State private var pendingCancel: Appointment?
    @State private var showCancelConfirm = false
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("预约状态", selection: $filter) {
                    ForEach(AppointmentFilter.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .accessibilityLabel("预约状态")

                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                if visibleAppointments.isEmpty {
                    ContentUnavailableView {
                        Label(emptyTitle, systemImage: emptySymbol)
                    } description: {
                        Text(emptyDescription)
                    } actions: {
                        if filter == .upcoming {
                            Button("去挂号") {
                                store.selectedTab = .home
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(visibleAppointments) { appointment in
                            AppointmentRow(appointment: appointment) {
                                handleAskCancel(appointment)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if appointment.status == .upcoming {
                                    Button("取消", role: .destructive) {
                                        handleAskCancel(appointment)
                                    }
                                    .accessibilityLabel("取消这场预约")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("我的预约")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("清空", role: .destructive) {
                        showClearConfirm = true
                    }
                    .disabled(store.appointments.isEmpty)
                    .accessibilityLabel("清空全部预约记录")
                }
            }
            .confirmationDialog(
                "取消这场预约？",
                isPresented: $showCancelConfirm,
                titleVisibility: .visible
            ) {
                Button("取消预约", role: .destructive) {
                    guard let pendingCancel else { return }
                    withAnimation {
                        store.cancel(pendingCancel)
                    }
                    self.pendingCancel = nil
                }
                Button("保留预约", role: .cancel) {
                    pendingCancel = nil
                }
            } message: {
                Text("取消后号源会回到可预约列表，只影响本机演示数据。")
            }
            .confirmationDialog(
                "清空全部预约记录？",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("清空", role: .destructive) {
                    withAnimation {
                        store.removeAll()
                    }
                }
                Button("保留", role: .cancel) {}
            } message: {
                Text("演示记录会从本机删除，且无法恢复。")
            }
        }
    }

    private var visibleAppointments: [Appointment] {
        switch filter {
        case .upcoming:
            store.upcoming
        case .cancelled:
            store.cancelled
        }
    }

    private var summaryText: String {
        switch filter {
        case .upcoming:
            "共 \(store.upcoming.count) 条待就诊"
        case .cancelled:
            "共 \(store.cancelled.count) 条已取消"
        }
    }

    private var emptyTitle: String {
        filter == .upcoming ? "还没有预约" : "没有已取消的预约"
    }

    private var emptySymbol: String {
        filter == .upcoming ? "calendar.badge.plus" : "calendar"
    }

    private var emptyDescription: String {
        filter == .upcoming
            ? "选好医院、医生和就诊时间后，预约会出现在这里。"
            : "取消过的演示预约会列在这里。"
    }

    private func handleAskCancel(_ appointment: Appointment) {
        pendingCancel = appointment
        showCancelConfirm = true
    }
}

private struct AppointmentRow: View {
    let appointment: Appointment
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(BookingFormat.confirmationCode(for: appointment))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                StatusCapsule(status: appointment.status)
            }

            Text(appointment.hospitalName)
                .font(.headline)
                .foregroundStyle(.primary)
            Text("\(appointment.departmentName) · \(appointment.doctorName) \(appointment.doctorTitle)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Label(
                BookingFormat.scheduleText(
                    day: appointment.day,
                    period: appointment.period,
                    timeLabel: appointment.timeLabel
                ),
                systemImage: "clock"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.primary)

            HStack {
                Text("\(appointment.patientName) · \(BookingFormat.maskedPhone(appointment.phone))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(BookingFormat.fee(appointment.fee))
                    .font(.subheadline.weight(.semibold))
            }

            if !appointment.note.isEmpty {
                Text("备注：\(appointment.note)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("预约于 \(BookingFormat.createdAt(appointment.createdAt))")
                .font(.caption)
                .foregroundStyle(.tertiary)

            if appointment.status == .upcoming {
                Button("取消预约", action: onCancel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(minHeight: 44)
                    .accessibilityHint("取消后号源会退回")
            }
        }
        .padding(16)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

#Preview("空列表") {
    MyAppointmentsView()
        .environment(PreviewSupport.emptyStore())
}

#Preview("有记录") {
    MyAppointmentsView()
        .environment(PreviewSupport.storeWithSamples())
}
