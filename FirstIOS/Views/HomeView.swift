import SwiftUI

struct HomeView: View {
    @Environment(AppointmentStore.self) private var store
    @State private var path = NavigationPath()
    @State private var query = ""
    @State private var selectedFilter: HospitalFilter = .all

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    filterBar
                    hospitalSection
                    Text("医院、医生与号源均为演示数据，预约结果只保存在本机。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
                .readableColumn()
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("预约挂号")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "搜索医院、科室或地区"
            )
            .navigationDestination(for: BookingRoute.self) { route in
                destination(for: route)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label("滨安健康", systemImage: "cross.case.fill")
                    .font(.subheadline.weight(.semibold))
                Text("演示版")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.18), in: Capsule())
            }
            .foregroundStyle(.white.opacity(0.92))

            Text("选择医院，开始挂号")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            Text("覆盖综合、中医、妇幼和专科门诊，可预约未来 7 天号源。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HospitalFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .foregroundStyle(selectedFilter == filter ? Color.white : Color.primary)
                            .background(
                                selectedFilter == filter ? AppTheme.primary : AppTheme.cardBackground,
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .stroke(
                                        Color.primary.opacity(selectedFilter == filter ? 0 : 0.08),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedFilter == filter ? .isSelected : [])
                    .accessibilityLabel("筛选\(filter.rawValue)")
                }
            }
            .padding(.vertical, 2)
        }
        .sensoryFeedback(.selection, trigger: selectedFilter)
    }

    @ViewBuilder
    private var hospitalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "医院")
                Spacer()
                Text("共 \(filteredHospitals.count) 家")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if filteredHospitals.isEmpty {
                ContentUnavailableView {
                    Label("没有找到医院", systemImage: "building.2")
                } description: {
                    Text("试试其他关键词，或切换上方筛选。")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(filteredHospitals) { hospital in
                    hospitalButton(hospital)
                }
            }
        }
        .animation(.snappy, value: filteredHospitals.map(\.id))
    }

    private func hospitalButton(_ hospital: Hospital) -> some View {
        let matched = MockCatalog.matchingDepartments(hospital: hospital, query: trimmedQuery)
        let departmentCount = MockCatalog.departments(for: hospital).count
        let today = BookingCalendar.startOfDay(.now)
        let hasSlotToday = MockCatalog.hasOpenSlot(on: today, hospital: hospital) { slot in
            store.remaining(for: slot)
        }

        return Button {
            path.append(BookingRoute.departments(hospital))
        } label: {
            HospitalCard(
                hospital: hospital,
                departmentCount: departmentCount,
                hasSlotToday: hasSlotToday,
                matchedDepartmentNames: matched.map(\.name)
            )
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(accessibilityText(hospital: hospital, hasSlotToday: hasSlotToday))
        .accessibilityHint("查看可预约科室")
    }

    private func accessibilityText(hospital: Hospital, hasSlotToday: Bool) -> String {
        let availability = hasSlotToday ? "今日有号" : "今日已满"
        return "\(hospital.name)，\(hospital.level)，\(hospital.district)，\(availability)"
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredHospitals: [Hospital] {
        MockCatalog.hospitals.filter { hospital in
            if let category = selectedFilter.category, hospital.category != category {
                return false
            }
            guard !trimmedQuery.isEmpty else { return true }
            if hospital.name.localizedStandardContains(trimmedQuery) { return true }
            if hospital.district.localizedStandardContains(trimmedQuery) { return true }
            if hospital.address.localizedStandardContains(trimmedQuery) { return true }
            if hospital.level.localizedStandardContains(trimmedQuery) { return true }
            if hospital.category.rawValue.localizedStandardContains(trimmedQuery) { return true }
            if hospital.category.displayName.localizedStandardContains(trimmedQuery) { return true }
            return !MockCatalog.matchingDepartments(hospital: hospital, query: trimmedQuery).isEmpty
        }
    }

    @ViewBuilder
    private func destination(for route: BookingRoute) -> some View {
        switch route {
        case .departments(let hospital):
            DepartmentListView(hospital: hospital)
        case .doctors(let hospital, let department):
            DoctorListView(hospital: hospital, department: department)
        case .schedule(let hospital, let department, let doctor):
            ScheduleView(hospital: hospital, department: department, doctor: doctor) { slot in
                path.append(BookingRoute.confirm(hospital, department, doctor, slot))
            }
        case .confirm(let hospital, let department, let doctor, let slot):
            ConfirmAppointmentView(
                hospital: hospital,
                department: department,
                doctor: doctor,
                slot: slot,
                onBooked: { appointment in
                    path.append(BookingRoute.success(appointment))
                }
            )
        case .success(let appointment):
            BookingSuccessView(
                appointment: appointment,
                onGoHome: {
                    path = NavigationPath()
                },
                onViewAppointments: {
                    path = NavigationPath()
                    store.selectedTab = .appointments
                }
            )
        }
    }
}

private struct HospitalCard: View {
    let hospital: Hospital
    let departmentCount: Int
    let hasSlotToday: Bool
    let matchedDepartmentNames: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: hospital.symbol)
                    .font(.title3)
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 52, height: 52)
                    .background(AppTheme.softFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(hospital.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Text(hospital.level)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.softFill, in: Capsule())
                    }
                    Text("\(hospital.category.displayName) · \(hospital.district)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Label(hospital.address, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                }
            }

            if !matchedDepartmentNames.isEmpty {
                Text("匹配科室：\(matchedDepartmentNames.prefix(3).joined(separator: "、"))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.primary)
                    .lineLimit(2)
            }

            Divider()

            HStack(spacing: 8) {
                Text("\(departmentCount) 个科室")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(hasSlotToday ? "今日有号" : "今日已满")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(hasSlotToday ? AppTheme.primary : Color.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        hasSlotToday ? AppTheme.softFill : Color.secondary.opacity(0.12),
                        in: Capsule()
                    )
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .cardStyle()
        .accessibilityElement(children: .ignore)
    }
}

#Preview {
    HomeView()
        .environment(PreviewSupport.emptyStore())
}
