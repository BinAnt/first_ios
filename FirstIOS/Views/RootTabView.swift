import SwiftUI

struct RootTabView: View {
    @Environment(AppointmentStore.self) private var store

    var body: some View {
        @Bindable var store = store

        TabView(selection: $store.selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "cross.case.fill")
                }
                .tag(AppTab.home)

            MyAppointmentsView()
                .modifier(UpcomingBadge(count: store.upcoming.count))
                .tabItem {
                    Label("我的预约", systemImage: "list.clipboard.fill")
                }
                .tag(AppTab.appointments)
        }
        .tint(AppTheme.primary)
    }
}

#Preview("空数据") {
    RootTabView()
        .environment(PreviewSupport.emptyStore())
}

#Preview("已有预约") {
    RootTabView()
        .environment(PreviewSupport.storeWithSamples())
}
