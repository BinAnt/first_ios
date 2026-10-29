import SwiftUI

struct ConfirmAppointmentView: View {
    @Environment(AppointmentStore.self) private var store

    let hospital: Hospital
    let department: Department
    let doctor: Doctor
    let slot: TimeSlot
    let onBooked: (Appointment) -> Void

    @State private var patientName = ""
    @State private var phone = ""
    @State private var note = ""
    @State private var didAttemptSubmit = false
    @State private var isSubmitting = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var submitTask: Task<Void, Never>?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name
        case phone
        case note
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard
                patientCard
                hintCard
            }
            .padding(16)
            .readableColumn()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("确认预约")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            submitBar
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    focusedField = nil
                }
            }
        }
        .alert("无法完成预约", isPresented: $showAlert) {
            Button("我知道了", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onDisappear {
            submitTask?.cancel()
        }
        .onChange(of: phone) { _, newValue in
            let filtered = String(newValue.filter(\.isNumber).prefix(11))
            if filtered != newValue {
                phone = filtered
            }
        }
        .onChange(of: note) { _, newValue in
            if newValue.count > 80 {
                note = String(newValue.prefix(80))
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "预约信息")
            InfoRow(title: "医院", value: hospital.name)
            InfoRow(title: "科室", value: department.name)
            InfoRow(title: "医生", value: "\(doctor.name) · \(doctor.title)")
            InfoRow(
                title: "时间",
                value: BookingFormat.scheduleText(
                    day: slot.day,
                    period: slot.period,
                    timeLabel: slot.timeLabel
                )
            )
            InfoRow(title: "挂号费", value: BookingFormat.fee(doctor.fee))
            InfoRow(title: "剩余", value: "\(store.remaining(for: slot)) 个号")
        }
        .padding(16)
        .cardStyle()
    }

    private var patientCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "就诊人")
                Spacer()
                Button("填入示例") {
                    handleFillSample()
                }
                .font(.subheadline.weight(.semibold))
                .disabled(isSubmitting)
                .accessibilityHint("填入演示用的姓名和手机号")
            }

            field(
                title: "姓名",
                error: visibleNameError,
                content: {
                    TextField("请输入就诊人姓名", text: $patientName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .name)
                        .onSubmit { focusedField = .phone }
                }
            )

            field(
                title: "手机号",
                error: visiblePhoneError,
                content: {
                    TextField("请输入 11 位手机号", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .phone)
                }
            )

            field(
                title: "备注",
                error: nil,
                content: {
                    TextField("选填，例如症状或需求", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                        .focused($focusedField, equals: .note)
                }
            )
        }
        .padding(16)
        .cardStyle()
        .disabled(isSubmitting)
    }

    private var hintCard: some View {
        Label {
            Text("当前为演示挂号，不会连接医院系统，也不会产生真实就诊记录。请按预约时间携带有效证件到院。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppTheme.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    private var submitBar: some View {
        Button {
            handleSubmit()
        } label: {
            if isSubmitting {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                    Text("正在提交")
                }
                .primaryButtonLabel()
            } else {
                Text("确认预约")
                    .primaryButtonLabel()
            }
        }
        .buttonStyle(PressableStyle())
        .disabled(isSubmitting)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .accessibilityLabel(isSubmitting ? "正在提交预约" : "确认预约")
    }

    private var visibleNameError: String? {
        didAttemptSubmit ? PatientValidator.nameError(patientName) : nil
    }

    private var visiblePhoneError: String? {
        didAttemptSubmit ? PatientValidator.phoneError(phone) : nil
    }

    private func field<Content: View>(
        title: String,
        error: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            content()
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(AppTheme.pageBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel("错误：\(error)")
            }
        }
    }

    private func handleFillSample() {
        patientName = "李小安"
        phone = "13800138000"
        didAttemptSubmit = false
    }

    private func handleSubmit() {
        guard !isSubmitting else { return }
        didAttemptSubmit = true
        focusedField = nil

        if PatientValidator.nameError(patientName) != nil {
            focusedField = .name
            return
        }
        if PatientValidator.phoneError(phone) != nil {
            focusedField = .phone
            return
        }
        guard store.remaining(for: slot) > 0 else {
            alertMessage = "该时段号源已满或已过时，请返回重新选择。"
            showAlert = true
            return
        }

        let draftName = patientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let draftPhone = phone
        let draftNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        isSubmitting = true
        submitTask?.cancel()
        submitTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            if Task.isCancelled {
                isSubmitting = false
                return
            }
            guard store.remaining(for: slot) > 0 else {
                isSubmitting = false
                alertMessage = "该时段号源已满或已过时，请返回重新选择。"
                showAlert = true
                return
            }
            let appointment = Appointment(
                id: UUID(),
                slotID: slot.id,
                hospitalName: hospital.name,
                departmentName: department.name,
                doctorName: doctor.name,
                doctorTitle: doctor.title,
                day: slot.day,
                period: slot.period,
                timeLabel: slot.timeLabel,
                patientName: draftName,
                phone: draftPhone,
                fee: doctor.fee,
                note: draftNote,
                createdAt: .now,
                status: .upcoming
            )
            store.book(appointment)
            isSubmitting = false
            onBooked(appointment)
        }
    }
}

#Preview {
    let hospital = MockCatalog.hospitals[0]
    let department = MockCatalog.departments(for: hospital)[0]
    let doctor = MockCatalog.doctors(for: department)[0]
    let slot = MockCatalog.slots(for: doctor, on: BookingCalendar.upcomingDays()[1])[0]
    NavigationStack {
        ConfirmAppointmentView(
            hospital: hospital,
            department: department,
            doctor: doctor,
            slot: slot,
            onBooked: { _ in }
        )
    }
    .environment(PreviewSupport.emptyStore())
}
