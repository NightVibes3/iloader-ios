import Foundation

@MainActor
class PairingService: ObservableObject {
    weak var state: AppState?
    
    init(state: AppState) {
        self.state = state
    }
    
    func scanForDevices() async {
        guard let state = state else { return }
        state.isLoading = true
        state.statusMessage = "Scanning for USB/WiFi devices..."
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Simulating the discovery process from pairing.rs
        let foundDevices = [
            Device(id: UUID().uuidString.prefix(8).description, name: "iPhone 16 Pro", model: "iPhone17,1", isPaired: false)
        ]
        
        state.devices = foundDevices
        state.isLoading = false
        state.statusMessage = foundDevices.isEmpty ? "No devices found." : "Found \(foundDevices.count) device(s)."
    }
    
    func pairDevice(_ deviceId: String) async {
        guard let state = state else { return }
        state.isLoading = true
        state.statusMessage = "Establishing secure connection..."
        
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        if let index = state.devices.firstIndex(where: { $0.id == deviceId }) {
            state.devices[index] = Device(
                id: state.devices[index].id,
                name: state.devices[index].name,
                model: state.devices[index].model,
                isPaired: true
            )
            state.selectedDeviceName = state.devices[index].name
        }
        
        state.isLoading = false
        state.statusMessage = "Device paired successfully."
    }
}
