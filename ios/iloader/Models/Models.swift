import Foundation

// MARK: - App Data Models

struct Certificate: Identifiable, Codable {
    let id: String // serialNumber or cert ID
    let name: String
    let serialNumber: String
    let machineName: String?
    let expirationDate: Date?
}

struct AppId: Identifiable, Codable {
    let id: String // identifier
    let name: String
    let identifier: String
    let type: String // e.g., "iOS App"
}

struct Device: Identifiable, Codable {
    let id: String // UDID
    let name: String
    let model: String?
    let isPaired: Bool
}

struct AppIdsResponse: Codable {
    let app_ids: [AppId]
    let max_quantity: Int
    let available_quantity: Int
}
