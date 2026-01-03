import Foundation

import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var loggedInAs: String? = nil
    @Published var selectedDeviceName: String? = nil

    // Detailed State for "Real" Features
    @Published var certificates: [Certificate] = []
    @Published var appIds: [AppId] = []
    @Published var devices: [Device] = []

    @Published var isLoading = false
    @Published var statusMessage = ""

    // Settings
    @AppStorage("anisetteServer") var anisetteServer: String = "ani.sidestore.io"
    @AppStorage("allowAppIdDeletion") var allowAppIdDeletion: Bool = false

    // Services
    lazy var certificateService = CertificateService(state: self)
    lazy var appIdService = AppIdService(state: self)
    lazy var pairingService = PairingService(state: self)
    lazy var sideloadService = SideloadService(state: self)
    let accountService = AccountService.shared

    static let shared = AppState()
}
@MainActor
class CertificateService: ObservableObject {
    weak var state: AppState?

    init(state: AppState) {
        self.state = state
    }

    func loadCertificates() async {
        guard let state = state else { return }
        state.isLoading = true
        state.statusMessage = "Fetching certificates from Apple..."

        // Simulating the real "isideload" response
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        let mockCerts = [
            Certificate(
                id: "L8A2B3C4D5", name: "iPhone Developer: User", serialNumber: "57B6C8D9E0",
                machineName: "MacBook Pro", expirationDate: Date().addingTimeInterval(7 * 24 * 3600)
            )
        ]

        state.certificates = mockCerts
        state.isLoading = false
        state.statusMessage = ""
    }

    func revokeCertificate(serialNumber: String) async {
        guard let state = state else { return }
        state.isLoading = true
        state.statusMessage = "Revoking certificate \(serialNumber)..."

        try? await Task.sleep(nanoseconds: 1_500_000_000)
        state.certificates.removeAll { $0.serialNumber == serialNumber }

        state.isLoading = false
        state.statusMessage = "Certificate successfully revoked."
    }
}
