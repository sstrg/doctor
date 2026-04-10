import SwiftUI

@main
struct DoctorWorkstationApp: App {
    var body: some Scene {
        WindowGroup {
            LoginView()
                .frame(minWidth: 450, minHeight: 350)
        }
        .windowResizability(.contentSize)
    }
}
