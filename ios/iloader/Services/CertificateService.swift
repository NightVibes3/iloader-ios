import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var loggedInAs: String? = nil
    @Published var selectedDeviceName: String? = "My iPhone"
    
    // Settings
    @AppStorage("anisetteServer") var anisetteServer: String = "ani.sidestore.io"
    @AppStorage("allowAppIdDeletion") var allowAppIdDeletion: Bool = false
    
    // Services
    let certificateService = CertificateService()
    let appIdService = AppIdService()
    let pairingService = PairingService()
    let accountService = AccountService.shared
    
    static let shared = AppState()
}



class CertificateService: ObservableObject {
    @Published var certificates: [Certificate] = []
    @Published var isLoading: Bool = false
    
    func loadCertificates() async {
        DispatchQueue.main.async { self.isLoading = true }
        
        // Simulating network/rust invoke
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let mockCerts = [
            Certificate(name: "iPhone Developer: nab138", certificateId: "CERT123", serialNumber: "SN12345", machineName: "MacBook Pro", machineId: "MAC1"),
            Certificate(name: "iPhone Developer: nab138", certificateId: "CERT456", serialNumber: "SN67890", machineName: "Windows PC", machineId: "WIN1")
        ]
        
        DispatchQueue.main.async {
            self.certificates = mockCerts
            self.isLoading = false
        }
    }
    
    func revokeCertificate(serialNumber: String) async {
        // Simulating revoke logic
        try? await Task.sleep(nanoseconds: 500_000_000)
        await loadCertificates()
    }
}
