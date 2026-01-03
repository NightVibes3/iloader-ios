/// MobileGestalt Service - Access Apple's MobileGestalt data
/// for device information (UDID, Serial Number, etc.)
///
/// Supports multiple access methods:
/// 1. Private framework (TrollStore/Jailbreak)
/// 2. Shared cache plist (SideStore accessible!)

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
        case all = "AllGestaltInfo"
    }

    // MARK: - Private API Types

    private typealias MGCopyAnswerFunc = @convention(c) (CFString) -> CFTypeRef?
    private typealias MGGetBoolAnswerFunc = @convention(c) (CFString) -> Bool

    private var mgCopyAnswer: MGCopyAnswerFunc?
    private var mgGetBoolAnswer: MGGetBoolAnswerFunc?
    private var gestaltHandle: UnsafeMutableRawPointer?

    // MARK: - Cache Plist Fallback

    /// Path to MobileGestalt cache plist (accessible on SideStore!)
    private let gestaltCachePath =
        "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"

    /// Cached data from plist
    private var cachedGestaltData: [String: Any]?

    // MARK: - Initialization

    private init() {
        loadMobileGestalt()
    }

    /// Load MobileGestalt - tries private framework first, then cache plist
    private func loadMobileGestalt() {
        // Method 1: Try private framework (TrollStore/Jailbreak)
        if tryLoadPrivateFramework() {
            print("[MobileGestalt] Loaded via private framework (elevated permissions)")
            return
        }

        // Method 2: Try cache plist (SideStore compatible!)
        if tryLoadCachePlist() {
            print("[MobileGestalt] Loaded via cache plist (SideStore compatible)")
            return
        }

        print("[MobileGestalt] No access method available")
    }

    /// Try to load via private framework
    private func tryLoadPrivateFramework() -> Bool {
        let paths = [
            "/System/Library/PrivateFrameworks/MobileGestalt.framework/MobileGestalt",
            "/usr/lib/libMobileGestalt.dylib",
        ]

        for path in paths {
            if let handle = dlopen(path, RTLD_LAZY) {
                gestaltHandle = handle

                if let copyAnswerSym = dlsym(handle, "MGCopyAnswer") {
                    mgCopyAnswer = unsafeBitCast(copyAnswerSym, to: MGCopyAnswerFunc.self)
                }

                if let getBoolSym = dlsym(handle, "MGGetBoolAnswer") {
                    mgGetBoolAnswer = unsafeBitCast(getBoolSym, to: MGGetBoolAnswerFunc.self)
                }

                if mgCopyAnswer != nil {
                    return true
                }
            }
        }
        return false
    }

    /// Try to load from cache plist (SideStore accessible!)
    private func tryLoadCachePlist() -> Bool {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: gestaltCachePath),
            fileManager.isReadableFile(atPath: gestaltCachePath),
            let data = fileManager.contents(atPath: gestaltCachePath)
        else {
            return false
        }

        do {
            if let plist = try PropertyListSerialization.propertyList(
                from: data, options: [], format: nil) as? [String: Any]
            {
                // The plist structure varies - look for CacheData or CacheExtra
                if let cacheData = plist["CacheData"] as? [String: Any] {
                    cachedGestaltData = cacheData
                } else if let cacheExtra = plist["CacheExtra"] as? [String: Any] {
                    cachedGestaltData = cacheExtra
                } else {
                    // Use the plist directly
                    cachedGestaltData = plist
                }
                return cachedGestaltData != nil && !cachedGestaltData!.isEmpty
            }
        } catch {
            print("[MobileGestalt] Failed to parse cache plist: \(error)")
        }

        return false
    }

    // MARK: - Public API

    /// Check if MobileGestalt data is available (either method)
    var isAvailable: Bool {
        return mgCopyAnswer != nil || cachedGestaltData != nil
    }

    /// Check if using cache plist (SideStore mode)
    var isUsingCachePlist: Bool {
        return mgCopyAnswer == nil && cachedGestaltData != nil
    }

    /// Get a string value from MobileGestalt
    func getString(_ key: GestaltKey) -> String? {
        // Try private framework first
        if let copyAnswer = mgCopyAnswer {
            let cfKey = key.rawValue as CFString
            if let result = copyAnswer(cfKey), CFGetTypeID(result) == CFStringGetTypeID() {
                return result as? String
            }
        }

        // Fall back to cache plist
        if let cache = cachedGestaltData {
            return cache[key.rawValue] as? String
        }

        return nil
    }

    /// Get a boolean value from MobileGestalt
    func getBool(_ key: GestaltKey) -> Bool? {
        if let getBoolAnswer = mgGetBoolAnswer {
            return getBoolAnswer(key.rawValue as CFString)
        }

        if let cache = cachedGestaltData {
            return cache[key.rawValue] as? Bool
        }

        return nil
    }

    /// Get any value from MobileGestalt
    func getValue(_ key: GestaltKey) -> Any? {
        // Try private framework
        if let copyAnswer = mgCopyAnswer {
            let cfKey = key.rawValue as CFString
            if let result = copyAnswer(cfKey) {
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
            }
        }

        // Fall back to cache
        return cachedGestaltData?[key.rawValue]
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

    /// Get product type (e.g., "iPhone16,1")
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
        // If using cache, return it all
        if let cache = cachedGestaltData {
            return cache
        }

        // Otherwise query each key
        var info: [String: Any] = [:]
        let keys: [GestaltKey] = [
            .uniqueDeviceID, .serialNumber, .deviceName, .deviceClass,
            .productType, .productVersion, .buildVersion, .modelNumber,
            .wifiAddress, .bluetoothAddress, .cpuArchitecture,
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
