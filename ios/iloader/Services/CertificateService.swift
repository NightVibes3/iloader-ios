import Foundation

/// Apple Developer Services endpoints
import SwiftUI

private enum AppleDeveloperEndpoints {
    static let listCertificates = "https://developer.apple.com/services-account/v1/certificates"
    static let revokeCertificate = "https://developer.apple.com/services-account/v1/certificates"
    static let listAppIds = "https://developer.apple.com/services-account/v1/bundleIds"
    static let deleteAppId = "https://developer.apple.com/services-account/v1/bundleIds"

    // Alternative: Apple's internal APIs (used by tools like isideload)
    static let developerServices = "https://developerservices2.apple.com/services/v1"
}
@MainActor
class AppState: ObservableObject {
    @Published var loggedInAs: String? = nil
    @Published var selectedDeviceName: String? = nil

    // Detailed State for Features
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

    private let developerServicesURL = "https://developerservices2.apple.com/services/v1"

    init(state: AppState) {
        self.state = state
    }

    /// Fetch real certificates from Apple Developer Services
    func loadCertificates() async {
        guard let state = state else { return }

        guard let user = state.loggedInAs else {
            state.certificates = []
            return
        }

        state.isLoading = true
        state.statusMessage = "Fetching certificates from Apple..."

        do {
            // Get account token
            guard let account = state.accountService.accounts.first(where: { $0.appleId == user })
            else {
                throw NSError(
                    domain: "CertificateService", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No account session found"])
            }

            // Fetch Anisette headers
            let anisetteHeaders = try await AnisetteService.shared.fetchAnisetteHeaders(
                serverUrl: state.anisetteServer
            )

            // Build request
            var request = URLRequest(
                url: URL(string: "\(developerServicesURL)/ios/listAllDevelopmentCerts")!)
            request.httpMethod = "POST"
            request.timeoutInterval = 30

            // Add auth headers
            for (key, value) in anisetteHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            request.setValue(
                "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("Xcode", forHTTPHeaderField: "User-Agent")

            // Build request body
            let bodyParams: [String: Any] = [
                "clientId": "XABBG36SBA",
                "myacinfo": account.token,
                "protocolVersion": "A1234",
                "requestId": UUID().uuidString,
            ]

            let plistData = try PropertyListSerialization.data(
                fromPropertyList: bodyParams,
                format: .xml,
                options: 0
            )
            request.httpBody = plistData

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(
                    domain: "CertificateService", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            if httpResponse.statusCode == 200 {
                // Parse plist response
                if let plistResponse = try? PropertyListSerialization.propertyList(
                    from: data, options: [], format: nil) as? [String: Any],
                    let certsData = plistResponse["developerCertificates"] as? [[String: Any]]
                {

                    let certs = certsData.compactMap { cert -> Certificate? in
                        guard let id = cert["certificateId"] as? String,
                            let name = cert["name"] as? String,
                            let serialNumber = cert["serialNumber"] as? String
                        else {
                            return nil
                        }

                        let machineName = cert["machineName"] as? String ?? "Unknown"
                        let expirationTimestamp =
                            cert["expirationDate"] as? TimeInterval ?? Date().timeIntervalSince1970
                            + 604800

                        return Certificate(
                            id: id,
                            name: name,
                            serialNumber: serialNumber,
                            machineName: machineName,
                            expirationDate: Date(timeIntervalSince1970: expirationTimestamp)
                        )
                    }

                    state.certificates = certs
                    state.isLoading = false
                    state.statusMessage = certs.isEmpty ? "No certificates found" : ""
                    return
                }
            }

            // If we couldn't parse real data, show meaningful error
            throw NSError(
                domain: "CertificateService", code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey: "Apple returned status \(httpResponse.statusCode)"
                ])

        } catch {
            // Show error but don't crash
            state.isLoading = false
            state.statusMessage = "Error: \(error.localizedDescription)"
            state.certificates = []
        }
    }

    /// Revoke a certificate
    func revokeCertificate(serialNumber: String) async {
        guard let state = state else { return }
        guard let user = state.loggedInAs,
            let account = state.accountService.accounts.first(where: { $0.appleId == user })
        else {
            state.statusMessage = "Please sign in first"
            return
        }

        state.isLoading = true
        state.statusMessage = "Revoking certificate \(serialNumber)..."

        do {
            let anisetteHeaders = try await AnisetteService.shared.fetchAnisetteHeaders(
                serverUrl: state.anisetteServer
            )

            var request = URLRequest(
                url: URL(string: "\(developerServicesURL)/ios/revokeDevelopmentCert")!)
            request.httpMethod = "POST"
            request.timeoutInterval = 30

            for (key, value) in anisetteHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            request.setValue(
                "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let bodyParams: [String: Any] = [
                "serialNumber": serialNumber,
                "myacinfo": account.token,
                "clientId": "XABBG36SBA",
            ]

            request.httpBody = try PropertyListSerialization.data(
                fromPropertyList: bodyParams,
                format: .xml,
                options: 0
            )

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                state.certificates.removeAll { $0.serialNumber == serialNumber }
                state.statusMessage = "Certificate revoked successfully"
            } else {
                state.statusMessage = "Failed to revoke certificate"
            }

        } catch {
            state.statusMessage = "Error: \(error.localizedDescription)"
        }

        state.isLoading = false
    }
}
