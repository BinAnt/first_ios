import SwiftUI

struct DoctorListView: View {
    let hospital: Hospital
    let department: Department

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(department.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(hospital.name)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 4)
                .accessibilityElement(children: .combine)

                if doctors.isEmpty {
                    ContentUnavailableView(
                        "暂无医生",
                        systemImage: "stethoscope",
                        description: Text("请返回选择其他科室。")
                    )
                } else {
                    ForEach(doctors) { doctor in
                        NavigationLink(value: BookingRoute.schedule(hospital, department, doctor)) {
                            DoctorCard(doctor: doctor)
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel(
                            "预约\(doctor.name)，\(doctor.title)，挂号费\(doctor.fee)元，擅长\(doctor.specialty)"
                        )
                        .accessibilityHint("选择就诊时间")
                    }
                }
            }
            .padding(16)
            .readableColumn()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle(department.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var doctors: [Doctor] {
        MockCatalog.doctors(for: department)
    }
}

private struct DoctorCard: View {
    let doctor: Doctor

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(doctor.avatarText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(avatarColor, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(doctor.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(doctor.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.softFill, in: Capsule())
                }
                Text("从业 \(doctor.years) 年")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("擅长：\(doctor.specialty)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Label(BookingFormat.rating(doctor.rating), systemImage: "star.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.warning)
                    Spacer(minLength: 8)
                    Text(BookingFormat.fee(doctor.fee))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("预约")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.primary, in: Capsule())
                }
            }
        }
        .padding(16)
        .cardStyle()
        .accessibilityElement(children: .ignore)
    }

    private var avatarColor: Color {
        let palette: [Color] = [
            AppTheme.primary,
            Color(red: 0.18, green: 0.42, blue: 0.58),
            Color(red: 0.33, green: 0.45, blue: 0.32),
            Color(red: 0.45, green: 0.34, blue: 0.52),
            AppTheme.warning,
        ]
        let index = doctor.name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % palette.count
        return palette[index]
    }
}

#Preview {
    let hospital = MockCatalog.hospitals[0]
    let department = MockCatalog.departments(for: hospital)[0]
    NavigationStack {
        DoctorListView(hospital: hospital, department: department)
    }
    .environment(PreviewSupport.emptyStore())
}
