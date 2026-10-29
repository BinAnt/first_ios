import SwiftUI

@main
struct FirstIOSApp: App {
    @State private var store = AppointmentStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .tint(AppTheme.primary)
        }
    }
}
