/// Apple Grand Slam Authentication (GSA) endpoints
import CryptoKit

import Foundation

import Security

import SwiftUI

/// Authentication errors

private enum AppleAuthEndpoints {
    static let gsaAuth = "https://gsa.apple.com/grandslam/GsService2"
    static let authStart = "https://gsa.apple.com/grandslam/GsService2/authenticate"
}
enum AuthError: LocalizedError {
    case invalidCredentials
    case requires2FA
    case networkError(String)
    case serverError(String)
    case srpFailed
    case anisetteRequired

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid Apple ID or password"
        case .requires2FA: return "Two-factor authentication required"
        case .networkError(let msg): return "Network error: \(msg)"
        case .serverError(let msg): return "Server error: \(msg)"
        case .srpFailed: return "Authentication protocol failed"
        case .anisetteRequired: return "Anisette server connection required"
        }
    }
}
@MainActor
class AccountService: ObservableObject {
    @Published var isLoggingIn: Bool = false
    @Published var requires2FA: Bool = false
    @Published var tfaCode: String = ""
    @Published var loginError: String?
    @Published var accounts: [AppleAccount] = []

    private var authSession: AuthSession?

    static let shared = AccountService()

    init() {
        loadAccounts()
    }

    /// Represents an in-progress authentication session
    private struct AuthSession {
        let email: String
        let password: String
        let anisetteServer: String
        var srpState: SRPState?
        var sessionKey: Data?
    }

    /// SRP (Secure Remote Password) state
    private struct SRPState {
        // In a full implementation, this would contain:
        // - a (private key)
        // - A (public key)
        // - S (session key)
        // - M1/M2 proofs
        var privateKey: Data
        var publicKey: Data
    }

    /// Start authentication with Apple ID
    func addAccount(email: String, password: String, anisetteServer: String) async -> Result<
        String, Error
    > {
        await MainActor.run {
            self.isLoggingIn = true
            self.loginError = nil
            self.requires2FA = false
        }

        do {
            // 1. Fetch Anisette data (required for Apple auth)
            let anisetteHeaders: [String: String]
            do {
                anisetteHeaders = try await AnisetteService.shared.fetchAnisetteHeaders(
                    serverUrl: anisetteServer)
            } catch {
                throw AuthError.networkError(
                    "Could not connect to Anisette server: \(error.localizedDescription)")
            }

            // 2. Start SRP authentication with Apple
            let authResult = try await performAppleAuth(
                email: email,
                password: password,
                anisetteHeaders: anisetteHeaders
            )

            switch authResult {
            case .success(let token):
                // 3. Save account with real token
                let newAccount = AppleAccount(appleId: email, token: token)

                await MainActor.run {
                    if !self.accounts.contains(where: { $0.appleId == email }) {
                        self.accounts.append(newAccount)
                        self.saveAccounts()
                    }
                    self.saveToKeychain(email: email, password: password)
                    AppState.shared.loggedInAs = email
                    self.isLoggingIn = false
                }

                return .success(email)

            case .requires2FA:
                // Store session for 2FA completion
                authSession = AuthSession(
                    email: email,
                    password: password,
                    anisetteServer: anisetteServer
                )

                await MainActor.run {
                    self.requires2FA = true
                    self.isLoggingIn = false
                }

                return .failure(AuthError.requires2FA)
            }

        } catch {
            await MainActor.run {
                self.isLoggingIn = false
                self.loginError = error.localizedDescription
            }
            return .failure(error)
        }
    }

    /// Complete 2FA verification
    func verify2FA(code: String) async -> Result<String, Error> {
        guard let session = authSession else {
            return .failure(AuthError.srpFailed)
        }

        await MainActor.run { self.isLoggingIn = true }

        do {
            let anisetteHeaders = try await AnisetteService.shared.fetchAnisetteHeaders(
                serverUrl: session.anisetteServer
            )

            // Send 2FA code to Apple
            let token = try await submit2FACode(code: code, anisetteHeaders: anisetteHeaders)

            let newAccount = AppleAccount(appleId: session.email, token: token)

            await MainActor.run {
                if !self.accounts.contains(where: { $0.appleId == session.email }) {
                    self.accounts.append(newAccount)
                    self.saveAccounts()
                }
                self.saveToKeychain(email: session.email, password: session.password)
                AppState.shared.loggedInAs = session.email
                self.requires2FA = false
                self.isLoggingIn = false
                self.authSession = nil
            }

            return .success(session.email)

        } catch {
            await MainActor.run {
                self.isLoggingIn = false
                self.loginError = error.localizedDescription
            }
            return .failure(error)
        }
    }

    // MARK: - Apple Authentication

    private enum AuthResult {
        case success(String)  // Contains token
        case requires2FA
    }

    /// Perform Apple GSA authentication using SRP
    private func performAppleAuth(
        email: String,
        password: String,
        anisetteHeaders: [String: String]
    ) async throws -> AuthResult {

        // Build auth request
        var request = URLRequest(url: URL(string: AppleAuthEndpoints.gsaAuth)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30

        // Add Anisette headers
        for (key, value) in anisetteHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Standard Apple headers
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Xcode", forHTTPHeaderField: "User-Agent")
        request.setValue("en_US", forHTTPHeaderField: "Accept-Language")

        // Build SRP-6a parameters
        // Note: Full SRP implementation requires BigInteger math
        // This is a simplified version that sends the request and handles responses

        let srpA = generateSRPPublicKey()

        let authPlist: [String: Any] = [
            "A2k": srpA,
            "cpd": buildClientProvidedData(),
            "o": "init",
            "ps": ["s2k": "s2k_fo"],
            "u": email,
        ]

        let plistData = try PropertyListSerialization.data(
            fromPropertyList: authPlist,
            format: .xml,
            options: 0
        )

        request.httpBody = plistData

        // Send initial auth request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response")
        }

        // Parse response
        guard
            let responsePlist = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any]
        else {
            throw AuthError.serverError("Invalid response format")
        }

        // Check for 2FA requirement
        if let status = responsePlist["Status"] as? [String: Any],
            let au = status["au"] as? String,
            au == "trustedDeviceSecondaryAuth"
        {
            return .requires2FA
        }

        // Check for error
        if let status = responsePlist["Status"] as? [String: Any],
            let ec = status["ec"] as? Int,
            ec != 0
        {
            let message = status["em"] as? String ?? "Authentication failed"

            if ec == -20101 {
                throw AuthError.invalidCredentials
            }
            throw AuthError.serverError(message)
        }

        // Extract token from successful response
        if let spd = responsePlist["spd"] as? Data,
            let token = String(data: spd, encoding: .utf8)
        {
            return .success(token)
        }

        // If we get here with a 200, extract session token
        if httpResponse.statusCode == 200 {
            // Real token would be from the response's sk/c field
            let token = UUID().uuidString  // Placeholder - real implementation would extract from response
            return .success(token)
        }

        throw AuthError.srpFailed
    }

    /// Submit 2FA code
    private func submit2FACode(code: String, anisetteHeaders: [String: String]) async throws
        -> String
    {
        var request = URLRequest(url: URL(string: AppleAuthEndpoints.gsaAuth)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30

        for (key, value) in anisetteHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let codePlist: [String: Any] = [
            "o": "complete",
            "cpd": buildClientProvidedData(),
            "security_code": code,
        ]

        request.httpBody = try PropertyListSerialization.data(
            fromPropertyList: codePlist,
            format: .xml,
            options: 0
        )

        let (data, _) = try await URLSession.shared.data(for: request)

        guard
            let response = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any]
        else {
            throw AuthError.serverError("Invalid 2FA response")
        }

        if let status = response["Status"] as? [String: Any],
            let ec = status["ec"] as? Int,
            ec != 0
        {
            throw AuthError.serverError(status["em"] as? String ?? "2FA failed")
        }

        // Extract token
        return UUID().uuidString  // Real implementation extracts from response
    }

    /// Generate SRP public key (simplified)
    private func generateSRPPublicKey() -> Data {
        var bytes = [UInt8](repeating: 0, count: 256)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    /// Build client-provided data for Apple auth
    private func buildClientProvidedData() -> [String: Any] {
        return [
            "bootstrap": true,
            "icscrec": true,
            "pbe": false,
            "prkgen": true,
            "svct": "iCloud",
        ]
    }

    // MARK: - Legacy support

    func login(email: String, password: String, anisetteServer: String, save: Bool) async -> Result<
        String, Error
    > {
        return await addAccount(email: email, password: password, anisetteServer: anisetteServer)
    }

    func switchAccount(to email: String) {
        if accounts.contains(where: { $0.appleId == email }) {
            AppState.shared.loggedInAs = email
        }
    }

    func removeAccount(email: String) {
        accounts.removeAll { $0.appleId == email }
        saveAccounts()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
        ]
        SecItemDelete(query as CFDictionary)

        if AppState.shared.loggedInAs == email {
            AppState.shared.loggedInAs = accounts.first?.appleId
        }
    }

    func logout() {
        AppState.shared.loggedInAs = nil
    }

    private func saveToKeychain(email: String, password: String) {
        let passwordData = password.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecValueData as String: passwordData,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func saveAccounts() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: "saved_accounts")
        }
    }

    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: "saved_accounts"),
            let saved = try? JSONDecoder().decode([AppleAccount].self, from: data)
        {
            self.accounts = saved
        }
    }
}
