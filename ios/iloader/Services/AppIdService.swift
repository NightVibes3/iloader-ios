import Foundation

@MainActor
class AppIdService: ObservableObject {
    weak var state: AppState?
    
    init(state: AppState) {
        self.state = state
    }
    
    func loadAppIds() async {
        guard let state = state else { return }
        state.isLoading = true
        state.statusMessage = "Loading App IDs from Apple..."
        
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        
        state.appIds = [
            AppId(id: "COM.APPLE.TEST", name: "iloader App", identifier: "com.apple.test", type: "iOS App")
        ]
        
        state.isLoading = false
        state.statusMessage = ""
    }
}
