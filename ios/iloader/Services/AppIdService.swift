import Foundation

@MainActor
class AppIdService: ObservableObject {
    weak var state: AppState?

    init(state: AppState) {
        self.state = state
    }

    func loadAppIds() async {
        guard let state = state else { return }

        guard let user = state.loggedInAs else {
            state.appIds = []
            return
        }

        state.isLoading = true
        state.statusMessage = "Loading App IDs from Apple..."

        try? await Task.sleep(nanoseconds: 1_200_000_000)

        state.appIds = [
            AppId(
                id: "COM.APPLE.TEST", name: "iloader App",
                identifier: "com.\(user.split(separator: "@")[0]).iloader", type: "iOS App")
        ]

        state.isLoading = false
        state.statusMessage = ""
    }

    func deleteAppId(_ id: String) async {
        guard let state = state else { return }
        state.isLoading = true
        state.statusMessage = "Deleting App ID..."

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        state.appIds.removeAll { $0.id == id }

        state.isLoading = false
        state.statusMessage = "App ID deleted successfully."
    }
}
