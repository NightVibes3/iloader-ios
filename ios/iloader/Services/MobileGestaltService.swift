/// MobileGestalt Service - Access Apple's private MobileGestalt framework
/// for device information (UDID, Serial Number, etc.)
///
/// Note: Requires TrollStore or jailbreak for private API access
import Foundation

class MobileGestaltService {
    static let shared = MobileGestaltService()

    // MARK: - MobileGestalt Keys

    enum GestaltKey: String {
        case uniqueDeviceID = "UniqueDeviceID"
        case serialNumber = "SerialNumber"
        case deviceName = "DeviceName"
        case deviceClass = "DeviceClass"
        case productType = "ProductType"
        case productVersion = "ProductVersion"
        case buildVersion = "BuildVersion"
        case modelNumber = "ModelNumber"
        case regionInfo = "RegionInfo"
        case wifiAddress = "WifiAddress"
        case bluetoothAddress = "BluetoothAddress"
        case boardId = "HardwarePlatform"
        case chipID = "ChipID"
        case deviceColor = "DeviceColor"
        case internationalMobileEquipmentIdentity = "InternationalMobileEquipmentIdentity"
        case mobileEquipmentIdentifier = "MobileEquipmentIdentifier"
        case cpuArchitecture = "CPUArchitecture"
        case kernelBootArgs = "firmware-version"
        case activationState = "ActivationState"

        // Custom composite key for all info
        case all = "AllGestaltInfo"
    }

    // MARK: - Private API Types

    private typealias MGCopyAnswerFunc = @convention(c) (CFString) -> CFTypeRef?
    private typealias MGGetBoolAnswerFunc = @convention(c) (CFString) -> Bool

    private var mgCopyAnswer: MGCopyAnswerFunc?
    private var mgGetBoolAnswer: MGGetBoolAnswerFunc?
    private var gestaltHandle: UnsafeMutableRawPointer?

    // MARK: - Initialization

    private init() {
        loadMobileGestalt()
    }

    /// Load MobileGestalt framework dynamically
    private func loadMobileGestalt() {
        // Try to load MobileGestalt framework
        let paths = [
            "/System/Library/PrivateFrameworks/MobileGestalt.framework/MobileGestalt",
            "/usr/lib/libMobileGestalt.dylib",
        ]

        for path in paths {
            if let handle = dlopen(path, RTLD_LAZY) {
                gestaltHandle = handle

                // Get function pointers
                if let copyAnswerSym = dlsym(handle, "MGCopyAnswer") {
                    mgCopyAnswer = unsafeBitCast(copyAnswerSym, to: MGCopyAnswerFunc.self)
                }

                if let getBoolSym = dlsym(handle, "MGGetBoolAnswer") {
                    mgGetBoolAnswer = unsafeBitCast(getBoolSym, to: MGGetBoolAnswerFunc.self)
                }

                if mgCopyAnswer != nil {
                    return  // Successfully loaded
                }
            }
        }
    }

    // MARK: - Public API

    /// Check if MobileGestalt is available
    var isAvailable: Bool {
        return mgCopyAnswer != nil
    }

    /// Get a string value from MobileGestalt
    func getString(_ key: GestaltKey) -> String? {
        guard let copyAnswer = mgCopyAnswer else { return nil }

        let cfKey = key.rawValue as CFString
        guard let result = copyAnswer(cfKey) else { return nil }

        if CFGetTypeID(result) == CFStringGetTypeID() {
            return result as? String
        }

        return nil
    }

    /// Get a boolean value from MobileGestalt
    func getBool(_ key: GestaltKey) -> Bool? {
        guard let getBoolAnswer = mgGetBoolAnswer else { return nil }
        return getBoolAnswer(key.rawValue as CFString)
    }

    /// Get any value from MobileGestalt
    func getValue(_ key: GestaltKey) -> Any? {
        guard let copyAnswer = mgCopyAnswer else { return nil }

        let cfKey = key.rawValue as CFString
        guard let result = copyAnswer(cfKey) else { return nil }

        // Convert CFTypeRef to Swift type
        if CFGetTypeID(result) == CFStringGetTypeID() {
            return result as? String
        } else if CFGetTypeID(result) == CFNumberGetTypeID() {
            return result as? NSNumber
        } else if CFGetTypeID(result) == CFBooleanGetTypeID() {
            return CFBooleanGetValue(result as! CFBoolean)
        } else if CFGetTypeID(result) == CFDataGetTypeID() {
            return result as? Data
        } else if CFGetTypeID(result) == CFDictionaryGetTypeID() {
            return result as? [String: Any]
        }

        return nil
    }

    /// Get device UDID
    var udid: String? {
        return getString(.uniqueDeviceID)
    }

    /// Get device serial number
    var serialNumber: String? {
        return getString(.serialNumber)
    }

    /// Get device name
    var deviceName: String? {
        return getString(.deviceName)
    }

    /// Get product type (e.g., "iPhone14,2")
    var productType: String? {
        return getString(.productType)
    }

    /// Get iOS version
    var productVersion: String? {
        return getString(.productVersion)
    }

    /// Get build version
    var buildVersion: String? {
        return getString(.buildVersion)
    }

    /// Get all available device info as dictionary
    func getAllDeviceInfo() -> [String: Any] {
        var info: [String: Any] = [:]

        let keys: [GestaltKey] = [
            .uniqueDeviceID,
            .serialNumber,
            .deviceName,
            .deviceClass,
            .productType,
            .productVersion,
            .buildVersion,
            .modelNumber,
            .wifiAddress,
            .bluetoothAddress,
            .cpuArchitecture,
        ]

        for key in keys {
            if let value = getValue(key) {
                info[key.rawValue] = value
            }
        }

        return info
    }

    /// Export device info to JSON data
    func exportDeviceInfoAsJSON() -> Data? {
        let info = getAllDeviceInfo()
        return try? JSONSerialization.data(withJSONObject: info, options: .prettyPrinted)
    }

    // MARK: - Cleanup

    deinit {
        if let handle = gestaltHandle {
            dlclose(handle)
        }
    }
}
