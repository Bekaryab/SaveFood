import SwiftUI
import FirebaseCore

@main
struct SaveFoodApp: App {

    private let dependencies: AppDependencies
    @State private var session: AppSession

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        let deps = AppDependencies()
        self.dependencies = deps
        _session = State(
            initialValue: AppSession(
                authRepository: deps.authRepository,
                profileRepository: deps.profileRepository
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies, session: session)
        }
    }
}
