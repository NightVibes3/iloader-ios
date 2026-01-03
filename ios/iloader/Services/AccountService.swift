import Foundation

import Security

import SwiftUI

@MainActor
class AccountService: ObservableObject {
    @Published var isLoggingIn: Bool = false
    @Published var requires2FA: Bool = false
    @Published var tfaCode: String = ""
    @Published var accounts: [AppleAccount] = []

    static let shared = AccountService()

    override init() {
        super.init()
        loadAccounts()
    }

    func addAccount(email: String, password: String, anisetteServer: String) async -> Result<
        String, Error
    > {
        DispatchQueue.main.async { self.isLoggingIn = true }

        do {
            // 1. Verify Anisette Server
            let _ = try await AnisetteService.shared.fetchAnisetteHeaders(serverUrl: anisetteServer)

            // 2. Perform Apple ID Login (Simulated SRP)
            try await Task.sleep(nanoseconds: 1_000_000_000)

            // 3. Save
            // In prod, token would come from Apple auth result
            let newAccount = AppleAccount(appleId: email, token: UUID().uuidString)

            DispatchQueue.main.async {
                if !self.accounts.contains(where: { $0.appleId == email }) {
                    self.accounts.append(newAccount)
                    self.saveAccounts()
                }
                self.saveToKeychain(email: email, password: password)

                // Automatically switch to new account
                AppState.shared.loggedInAs = email
                self.isLoggingIn = false
            }

            return .success(email)

        } catch {
            DispatchQueue.main.async { self.isLoggingIn = false }
            return .failure(error)
        }
    }

    func login(email: String, password: String, anisetteServer: String, save: Bool) async -> Result<
        String, Error
    > {
        // Redirect legacy call to addAccount
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

        // Remove from Keychain
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
