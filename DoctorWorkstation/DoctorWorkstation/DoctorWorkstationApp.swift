import SwiftUI

@main
struct DoctorWorkstationApp: App {
    init() {
        // Настройка подключения к PostgreSQL
        DatabaseManager.shared.configure(
            host: "localhost",
            port: 5432,
            username: "postgrs",
            password: "",
            database: "med"
        )
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .frame(minWidth: 450, minHeight: 350)
        }
        .windowResizability(.contentSize)
    }
}
