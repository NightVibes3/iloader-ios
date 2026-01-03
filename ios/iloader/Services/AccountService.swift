import Foundation
import SwiftUI
import Security

@MainActor
class AccountService: ObservableObject {
    @Published var isLoggingIn: Bool = false
    @Published var requires2FA: Bool = false
    @Published var tfaCode: String = ""
    
    static let shared = AccountService()
    
    func login(email: String, password: String, anisetteServer: String, save: Bool) async -> Result<String, Error> {
        DispatchQueue.main.async { self.isLoggingIn = true }
        
        // Simulating Apple ID login flow with 2FA
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Mock 2FA trigger
        if email.contains("2fa") {
            DispatchQueue.main.async { 
                self.requires2FA = true 
                self.isLoggingIn = false
            }
            return .failure(NSError(domain: "iloader", code: 2, userInfo: [NSLocalizedDescriptionKey: "2FA Required"]))
        }
        
        if save {
            saveToKeychain(email: email, password: password)
        }
        
        DispatchQueue.main.async { 
            self.isLoggingIn = false
            AppState.shared.loggedInAs = email
        }
        
        return .success(email)
    }
    
    func logout() {
        AppState.shared.loggedInAs = nil
        // Optional: clear keychain
    }
    
    private func saveToKeychain(email: String, password: String) {
        let passwordData = password.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecValueData as String: passwordData
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
