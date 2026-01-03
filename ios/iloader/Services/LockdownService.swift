/// LockdownService - Access iOS lockdown pairing data
/// Allows extraction of device pairing files for sideloading tools
///
/// Note: Requires TrollStore or jailbreak to access /var/root/Library/Lockdown/
import Foundation

class LockdownService {
    static let shared = LockdownService()

    // MARK: - Paths

    private let lockdownPath = "/var/root/Library/Lockdown"
    private let pairRecordsPath = "/var/root/Library/Lockdown/pair_records"
    private let systemPairingPath = "/var/Keychains/SystemKeychain"

    // MARK: - Error Types

    enum LockdownError: LocalizedError {
        case accessDenied
        case fileNotFound
        case invalidPairingData
        case exportFailed

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Access denied. App requires elevated permissions (TrollStore/Jailbreak)"
            case .fileNotFound: return "Pairing file not found"
            case .invalidPairingData: return "Invalid pairing data format"
            case .exportFailed: return "Failed to export pairing file"
            }
        }
    }

    // MARK: - Pairing Data Structure

    struct PairingData {
        let deviceCertificate: Data
        let hostCertificate: Data
        let hostPrivateKey: Data
        let rootCertificate: Data
        let systemBUID: String
        let hostID: String
        let udid: String

        /// Convert to plist dictionary for export
        func toDictionary() -> [String: Any] {
            return [
                "DeviceCertificate": deviceCertificate,
                "HostCertificate": hostCertificate,
                "HostPrivateKey": hostPrivateKey,
                "RootCertificate": rootCertificate,
                "SystemBUID": systemBUID,
                "HostID": hostID,
                "UDID": udid,
            ]
        }

        /// Export to .mobiledevicepairing file format
        func exportData() throws -> Data {
            let dict = toDictionary()
            return try PropertyListSerialization.data(
                fromPropertyList: dict,
                format: .xml,
                options: 0
            )
        }
    }

    // MARK: - Public API

    /// Check if we have access to lockdown data
    var hasAccess: Bool {
        return FileManager.default.isReadableFile(atPath: lockdownPath)
    }

    /// Get the device's own UDID from MobileGestalt
    var deviceUDID: String? {
        return MobileGestaltService.shared.udid
    }

    /// Get list of paired device UDIDs
    func getPairedDevices() -> [String] {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: pairRecordsPath)
        else {
            return []
        }

        return files.compactMap { file -> String? in
            if file.hasSuffix(".plist") {
                return String(file.dropLast(6))  // Remove .plist
            }
            return nil
        }
    }

    /// Read pairing data for the current device
    func getOwnPairingData() throws -> PairingData {
        // Get device UDID
        guard let udid = deviceUDID else {
            throw LockdownError.accessDenied
        }

        return try getPairingData(forUDID: udid)
    }

    /// Read pairing data for a specific UDID
    func getPairingData(forUDID udid: String) throws -> PairingData {
        let pairingFilePath = "\(pairRecordsPath)/\(udid).plist"

        guard FileManager.default.fileExists(atPath: pairingFilePath) else {
            // Try reading from main lockdown plist
            return try readFromLockdownPlist(udid: udid)
        }

        guard let plistData = FileManager.default.contents(atPath: pairingFilePath) else {
            throw LockdownError.fileNotFound
        }

        return try parsePairingPlist(plistData, udid: udid)
    }

    /// Read system BUID from device
    func getSystemBUID() -> String? {
        let buidPath = "\(lockdownPath)/data_ark.plist"

        guard let data = FileManager.default.contents(atPath: buidPath),
            let plist = try? PropertyListSerialization.propertyList(
                from: data, options: [], format: nil) as? [String: Any],
            let buid = plist["-SystemBUID"] as? String
        else {
            return nil
        }

        return buid
    }

    /// Export pairing file to Documents directory
    func exportPairingFile() throws -> URL {
        let pairingData = try getOwnPairingData()
        let exportData = try pairingData.exportData()

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "device_pairing_\(pairingData.udid).mobiledevicepairing"
        let fileURL = documentsURL.appendingPathComponent(fileName)

        try exportData.write(to: fileURL)

        return fileURL
    }

    /// Generate a share-able pairing file URL
    func getShareablePairingURL() throws -> URL {
        return try exportPairingFile()
    }

    // MARK: - Private Helpers

    private func readFromLockdownPlist(udid: String) throws -> PairingData {
        let lockdownPlist = "\(lockdownPath)/data_ark.plist"

        guard FileManager.default.isReadableFile(atPath: lockdownPlist) else {
            throw LockdownError.accessDenied
        }

        guard let data = FileManager.default.contents(atPath: lockdownPlist) else {
            throw LockdownError.fileNotFound
        }

        guard
            let plist = try? PropertyListSerialization.propertyList(
                from: data, options: [], format: nil) as? [String: Any]
        else {
            throw LockdownError.invalidPairingData
        }

        // Extract pairing info from lockdown plist
        guard let deviceCert = plist["DeviceCertificate"] as? Data,
            let hostCert = plist["HostCertificate"] as? Data,
            let hostKey = plist["HostPrivateKey"] as? Data,
            let rootCert = plist["RootCertificate"] as? Data
        else {
            throw LockdownError.invalidPairingData
        }

        let systemBUID = plist["-SystemBUID"] as? String ?? UUID().uuidString
        let hostID = plist["-HostID"] as? String ?? UUID().uuidString

        return PairingData(
            deviceCertificate: deviceCert,
            hostCertificate: hostCert,
            hostPrivateKey: hostKey,
            rootCertificate: rootCert,
            systemBUID: systemBUID,
            hostID: hostID,
            udid: udid
        )
    }

    private func parsePairingPlist(_ data: Data, udid: String) throws -> PairingData {
        guard
            let plist = try? PropertyListSerialization.propertyList(
                from: data, options: [], format: nil) as? [String: Any]
        else {
            throw LockdownError.invalidPairingData
        }

        guard let deviceCert = plist["DeviceCertificate"] as? Data,
            let hostCert = plist["HostCertificate"] as? Data,
            let hostKey = plist["HostPrivateKey"] as? Data,
            let rootCert = plist["RootCertificate"] as? Data
        else {
            throw LockdownError.invalidPairingData
        }

        return PairingData(
            deviceCertificate: deviceCert,
            hostCertificate: hostCert,
            hostPrivateKey: hostKey,
            rootCertificate: rootCert,
            systemBUID: plist["SystemBUID"] as? String ?? "",
            hostID: plist["HostID"] as? String ?? "",
            udid: udid
        )
    }
}
