import Foundation

struct Certificate: Identifiable, Codable {
    var id: String { certificateId }
    let name: String
    let certificateId: String
    let serialNumber: String
    let machineName: String
    let machineId: String
}

struct AppId: Identifiable, Codable {
    var id: String { app_id_id }
    let app_id_id: String
    let identifier: String
    let name: String
    let features: [String: String]?
    let expiration_date: String?
}

struct AppIdsResponse: Codable {
    let app_ids: [AppId]
    let max_quantity: Int
    let available_quantity: Int
}
