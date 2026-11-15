import SwiftUI
import FirebaseCore

@main
struct SaveFoodApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
