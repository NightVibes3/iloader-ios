// MARK: - App Data Models

import Foundation

// MARK: - Auth Models

struct Certificate: Identifiable, Codable {
    let id: String  // serialNumber or cert ID
    let name: String
    let serialNumber: String
    let machineName: String?
    let expirationDate: Date?
}
struct AppId: Identifiable, Codable {
    let id: String  // identifier
    let name: String
    let identifier: String
    let type: String  // e.g., "iOS App"
}
struct Device: Identifiable, Codable {
    let id: String  // UDID
    let name: String
    let model: String?
    let isPaired: Bool
}
struct AppIdsResponse: Codable {
    let app_ids: [AppId]
    let max_quantity: Int
    let available_quantity: Int
}
struct AppleAccount: Codable, Identifiable {
    var id: String { appleId }
    let appleId: String
    let token: String?  // DSID or similar token if needed
}
struct AnisetteData: Codable {
    let machineId: String
    let oneTimePassword: String
    let localUserId: String
    let deviceId: String
    let signature: String
    // Add other fields as per Anisette v3/v4 specs if needed
}
struct LoginResponse: Codable {
    let account: AppleAccount
    // Add other session data
}
