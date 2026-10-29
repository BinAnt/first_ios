import SwiftUI

struct DepartmentListView: View {
    let hospital: Hospital

    private let columns = [GridItem(.adaptive(minimum: 156), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hospitalHeader
                SectionTitle(text: "选择科室")
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(departments) { department in
                        NavigationLink(value: BookingRoute.doctors(hospital, department)) {
                            DepartmentTile(
                                department: department,
                                doctorCount: MockCatalog.doctors(for: department).count
                            )
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel("\(department.name)，\(department.summary)")
                        .accessibilityHint("查看医生")
                    }
                }
            }
            .padding(16)
            .readableColumn()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("选择科室")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var departments: [Department] {
        MockCatalog.departments(for: hospital)
    }

    private var hospitalHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(hospital.name)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text("\(hospital.level) · \(hospital.category.displayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Label(hospital.address, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Label(hospital.openHours, systemImage: "clock")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Label("咨询电话 \(hospital.phone)", systemImage: "phone")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(hospital.summary)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

private struct DepartmentTile: View {
    let department: Department
    let doctorCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: department.symbol)
                .font(.title3)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 44, height: 44)
                .background(AppTheme.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)

            Text(department.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Text(department.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text("\(doctorCount) 位医生")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
        .cardStyle()
        .accessibilityElement(children: .ignore)
    }
}

#Preview {
    NavigationStack {
        DepartmentListView(hospital: MockCatalog.hospitals[0])
    }
    .environment(PreviewSupport.emptyStore())
}
