import Foundation

@MainActor
class AppIdService: ObservableObject {
    @Published var appIds: [AppId] = []
    @Published var maxQuantity: Int = 10
    @Published var availableQuantity: Int = 10
    @Published var isLoading: Bool = false
    
    func loadAppIds() async {
        DispatchQueue.main.async { self.isLoading = true }
        
        // Simulating network/rust invoke
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let mockIds = [
            AppId(app_id_id: "ID1", identifier: "com.nab138.iloader", name: "iloader", features: [:], expiration_date: "2026-01-03T03:04:45Z"),
            AppId(app_id_id: "ID2", identifier: "io.sidestore.SideStore", name: "SideStore", features: [:], expiration_date: nil)
        ]
        
        DispatchQueue.main.async {
            self.appIds = mockIds
            self.maxQuantity = 10
            self.availableQuantity = 8
            self.isLoading = false
        }
    }
    
    func deleteAppId(id: String) async {
        // Simulating delete logic
        try? await Task.sleep(nanoseconds: 500_000_000)
        await loadAppIds()
    }
}
