import SwiftUI

struct BookingSuccessView: View {
    let appointment: Appointment
    let onGoHome: () -> Void
    let onViewAppointments: () -> Void

    @State private var didAppear = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(AppTheme.primary)
                        .symbolRenderingMode(.hierarchical)
                        .symbolEffect(.bounce, value: didAppear)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("预约成功")
                            .font(.largeTitle.weight(.bold))
                        Text("请按预约时间提前到院取号。本次为演示预约，不会同步到真实医院。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityElement(children: .combine)

                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(title: "预约号", value: BookingFormat.confirmationCode(for: appointment))
                        InfoRow(title: "医院", value: appointment.hospitalName)
                        InfoRow(title: "科室", value: appointment.departmentName)
                        InfoRow(title: "医生", value: "\(appointment.doctorName) · \(appointment.doctorTitle)")
                        InfoRow(
                            title: "时间",
                            value: BookingFormat.scheduleText(
                                day: appointment.day,
                                period: appointment.period,
                                timeLabel: appointment.timeLabel
                            )
                        )
                        InfoRow(title: "就诊人", value: appointment.patientName)
                        InfoRow(title: "手机号", value: appointment.phone)
                        InfoRow(title: "挂号费", value: BookingFormat.fee(appointment.fee))
                        if !appointment.note.isEmpty {
                            InfoRow(title: "备注", value: appointment.note)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }
                .padding(20)
                .readableColumn()
            }

            VStack(spacing: 10) {
                Button(action: onViewAppointments) {
                    Text("查看我的预约")
                        .primaryButtonLabel()
                }
                .buttonStyle(PressableStyle())

                Button(action: onGoHome) {
                    Text("返回首页")
                        .secondaryButtonLabel()
                }
                .buttonStyle(PressableStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .readableColumn()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("预约结果")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .sensoryFeedback(.success, trigger: didAppear)
        .onAppear {
            didAppear = true
        }
    }
}

#Preview {
    NavigationStack {
        if let appointment = PreviewSupport.storeWithSamples().upcoming.first {
            BookingSuccessView(appointment: appointment, onGoHome: {}, onViewAppointments: {})
        }
    }
}
