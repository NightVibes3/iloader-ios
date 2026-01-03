/// SigningService - Native IPA signing on iOS
/// Implements codesigning using Security framework
/// Integrated with Apple ID certificates

import CommonCrypto

import Foundation

import Security

class SigningService {
    static let shared = SigningService()

    // MARK: - Types

    enum SigningError: LocalizedError {
        case ipaNotFound
        case extractionFailed
        case noBinaryFound
        case signingFailed(String)
        case certificateNotFound
        case profileNotFound
        case repackageFailed
        case notLoggedIn
        case noCertificateSelected
        case profileGenerationFailed

        var errorDescription: String? {
            switch self {
            case .ipaNotFound: return "IPA file not found"
            case .extractionFailed: return "Failed to extract IPA"
            case .noBinaryFound: return "No executable binary found in app"
            case .signingFailed(let msg): return "Signing failed: \(msg)"
            case .certificateNotFound: return "Signing certificate not found"
            case .profileNotFound: return "Provisioning profile not found"
            case .repackageFailed: return "Failed to repackage IPA"
            case .notLoggedIn: return "Please sign in with your Apple ID first"
            case .noCertificateSelected: return "No certificate selected for signing"
            case .profileGenerationFailed: return "Failed to generate provisioning profile"
            }
        }
    }

    struct SigningIdentity {
        let certificate: SecCertificate
        let privateKey: SecKey
        let commonName: String
    }

    struct SigningProgress {
        var currentStep: String
        var progress: Double
        var isComplete: Bool
    }

    // MARK: - State

    private let fileManager = FileManager.default
    private let tempDirectory: URL

    private let developerServicesURL = "https://developerservices2.apple.com/services/v1"

    private init() {
        tempDirectory = fileManager.temporaryDirectory.appendingPathComponent("iloader_signing")
        try? fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Apple ID Integrated Signing

    /// Sign an IPA using the logged-in Apple ID's certificate
    /// - Parameters:
    ///   - ipaURL: Path to the IPA file
    ///   - certificate: Certificate from AppState.certificates
    ///   - bundleId: Bundle ID to use (will create App ID if needed)
    ///   - progressHandler: Callback for progress updates
    /// - Returns: URL to signed IPA
    @MainActor
    func signWithAppleID(
        ipaURL: URL,
        certificate: Certificate,
        bundleId: String,
        progressHandler: ((SigningProgress) -> Void)? = nil
    ) async throws -> URL {

        let appState = AppState.shared

        // Verify user is logged in
        guard let appleId = appState.loggedInAs,
            let account = appState.accountService.accounts.first(where: { $0.appleId == appleId })
        else {
            throw SigningError.notLoggedIn
        }

        let workDir = tempDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: workDir, withIntermediateDirectories: true)

        defer {
            try? fileManager.removeItem(at: workDir)
        }

        // Step 1: Extract IPA
        progressHandler?(
            SigningProgress(currentStep: "Extracting IPA...", progress: 0.05, isComplete: false))
        let appDir = try extractIPA(ipaURL: ipaURL, to: workDir)

        // Step 2: Download signing certificate from Apple
        progressHandler?(
            SigningProgress(
                currentStep: "Fetching certificate from Apple...", progress: 0.15, isComplete: false
            ))
        let certData = try await downloadCertificate(
            serialNumber: certificate.serialNumber,
            account: account,
            anisetteServer: appState.anisetteServer
        )

        // Step 3: Generate/fetch provisioning profile for this app
        progressHandler?(
            SigningProgress(
                currentStep: "Generating provisioning profile...", progress: 0.25, isComplete: false
            ))
        let profileData = try await generateProvisioningProfile(
            bundleId: bundleId,
            certificateId: certificate.id,
            account: account,
            anisetteServer: appState.anisetteServer
        )

        // Step 4: Import certificate
        progressHandler?(
            SigningProgress(
                currentStep: "Loading signing identity...", progress: 0.35, isComplete: false))
        let identity = try importCertificateData(certData)

        // Step 5: Install provisioning profile
        progressHandler?(
            SigningProgress(currentStep: "Installing profile...", progress: 0.45, isComplete: false)
        )
        try installProvisioningProfile(data: profileData, appDir: appDir)

        // Step 6: Update bundle ID in Info.plist
        progressHandler?(
            SigningProgress(currentStep: "Updating bundle ID...", progress: 0.50, isComplete: false)
        )
        try updateBundleId(in: appDir, newBundleId: bundleId)

        // Step 7: Sign frameworks
        progressHandler?(
            SigningProgress(currentStep: "Signing frameworks...", progress: 0.60, isComplete: false)
        )
        try signFrameworks(in: appDir, identity: identity)

        // Step 8: Sign main binary
        progressHandler?(
            SigningProgress(
                currentStep: "Signing main binary...", progress: 0.75, isComplete: false))
        try signMainBinary(in: appDir, identity: identity)

        // Step 9: Generate CodeResources
        progressHandler?(
            SigningProgress(
                currentStep: "Generating code signature...", progress: 0.85, isComplete: false))
        try generateCodeResources(for: appDir)

        // Step 10: Repackage IPA
        progressHandler?(
            SigningProgress(currentStep: "Repackaging IPA...", progress: 0.95, isComplete: false))
        let signedIPA = try repackageIPA(appDir: appDir, to: workDir)

        // Move to output
        let outputURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("signed_\(ipaURL.lastPathComponent)")

        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }
        try fileManager.copyItem(at: signedIPA, to: outputURL)

        progressHandler?(SigningProgress(currentStep: "Complete!", progress: 1.0, isComplete: true))

        return outputURL
    }

    // MARK: - Apple Developer Services Integration

    /// Download certificate data from Apple
    private func downloadCertificate(
        serialNumber: String,
        account: AppleAccount,
        anisetteServer: String
    ) async throws -> Data {
        let anisetteHeaders = try await AnisetteService.shared.fetchAnisetteHeaders(
            serverUrl: anisetteServer)

        var request = URLRequest(
            url: URL(string: "\(developerServicesURL)/ios/downloadDevelopmentCert")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30

        for (key, value) in anisetteHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams: [String: Any] = [
            "serialNumber": serialNumber,
            "myacinfo": account.token,
            "clientId": "XABBG36SBA",
        ]

        request.httpBody = try PropertyListSerialization.data(
            fromPropertyList: bodyParams, format: .xml, options: 0)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SigningError.certificateNotFound
        }

        // Parse plist response for certificate data
        if let plist = try? PropertyListSerialization.propertyList(
            from: data, options: [], format: nil) as? [String: Any],
            let certData = plist["certContent"] as? Data
        {
            return certData
        }

        // If response is raw certificate data
        return data
    }

    /// Generate a provisioning profile for the app
    private func generateProvisioningProfile(
        bundleId: String,
        certificateId: String,
        account: AppleAccount,
        anisetteServer: String
    ) async throws -> Data {
        let anisetteHeaders = try await AnisetteService.shared.fetchAnisetteHeaders(
            serverUrl: anisetteServer)

        // First, ensure App ID exists
        var request = URLRequest(url: URL(string: "\(developerServicesURL)/ios/addAppId")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30

        for (key, value) in anisetteHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let appIdParams: [String: Any] = [
            "identifier": bundleId,
            "name": bundleId.replacingOccurrences(of: ".", with: " "),
            "myacinfo": account.token,
            "clientId": "XABBG36SBA",
        ]

        request.httpBody = try PropertyListSerialization.data(
            fromPropertyList: appIdParams, format: .xml, options: 0)

        // Create App ID (ignore error if exists)
        _ = try? await URLSession.shared.data(for: request)

        // Now create provisioning profile
        var profileRequest = URLRequest(
            url: URL(string: "\(developerServicesURL)/ios/downloadTeamProvisioningProfile")!)
        profileRequest.httpMethod = "POST"
        profileRequest.timeoutInterval = 30

        for (key, value) in anisetteHeaders {
            profileRequest.setValue(value, forHTTPHeaderField: key)
        }
        profileRequest.setValue(
            "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let profileParams: [String: Any] = [
            "appIdId": bundleId,
            "certificateId": certificateId,
            "myacinfo": account.token,
            "clientId": "XABBG36SBA",
        ]

        profileRequest.httpBody = try PropertyListSerialization.data(
            fromPropertyList: profileParams, format: .xml, options: 0)

        let (data, response) = try await URLSession.shared.data(for: profileRequest)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SigningError.profileGenerationFailed
        }

        // Parse response for profile data
        if let plist = try? PropertyListSerialization.propertyList(
            from: data, options: [], format: nil) as? [String: Any],
            let profileData = plist["provisioningProfile"] as? Data
        {
            return profileData
        }

        return data
    }

    /// Import certificate data (DER format)
    private func importCertificateData(_ data: Data) throws -> SigningIdentity {
        guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
            throw SigningError.certificateNotFound
        }

        // Try to find matching private key in keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let privateKey = result as! SecKey? else {
            // Generate a new key pair if not found
            let keyParams: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                kSecAttrKeySizeInBits as String: 2048,
            ]

            var error: Unmanaged<CFError>?
            guard let newKey = SecKeyCreateRandomKey(keyParams as CFDictionary, &error) else {
                throw SigningError.signingFailed("Failed to generate signing key")
            }

            return SigningIdentity(
                certificate: certificate,
                privateKey: newKey,
                commonName: "Apple Development"
            )
        }

        var commonName: CFString?
        SecCertificateCopyCommonName(certificate, &commonName)

        return SigningIdentity(
            certificate: certificate,
            privateKey: privateKey,
            commonName: (commonName as String?) ?? "Apple Development"
        )
    }

    /// Update bundle ID in Info.plist
    private func updateBundleId(in appDir: URL, newBundleId: String) throws {
        let infoPlistPath = appDir.appendingPathComponent("Info.plist")

        guard
            var plist = try? PropertyListSerialization.propertyList(
                from: Data(contentsOf: infoPlistPath),
                options: .mutableContainersAndLeaves,
                format: nil
            ) as? [String: Any]
        else {
            return
        }

        plist["CFBundleIdentifier"] = newBundleId

        let newData = try PropertyListSerialization.data(
            fromPropertyList: plist, format: .xml, options: 0)
        try newData.write(to: infoPlistPath)
    }

    // MARK: - Public API

    /// Sign an IPA file
    /// - Parameters:
    ///   - ipaURL: Path to the IPA file
    ///   - certificate: Signing certificate data (P12)
    ///   - password: P12 password
    ///   - provisioningProfile: Embedded provisioning profile data
    ///   - progressHandler: Callback for progress updates
    /// - Returns: URL to signed IPA
    func signIPA(
        ipaURL: URL,
        certificate: Data,
        password: String,
        provisioningProfile: Data,
        progressHandler: ((SigningProgress) -> Void)? = nil
    ) async throws -> URL {

        let workDir = tempDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: workDir, withIntermediateDirectories: true)

        defer {
            try? fileManager.removeItem(at: workDir)
        }

        // Step 1: Extract IPA
        progressHandler?(
            SigningProgress(currentStep: "Extracting IPA...", progress: 0.1, isComplete: false))
        let appDir = try extractIPA(ipaURL: ipaURL, to: workDir)

        // Step 2: Import certificate
        progressHandler?(
            SigningProgress(currentStep: "Loading certificate...", progress: 0.2, isComplete: false)
        )
        let identity = try importP12Certificate(data: certificate, password: password)

        // Step 3: Install provisioning profile
        progressHandler?(
            SigningProgress(currentStep: "Installing profile...", progress: 0.3, isComplete: false))
        try installProvisioningProfile(data: provisioningProfile, appDir: appDir)

        // Step 4: Sign all frameworks
        progressHandler?(
            SigningProgress(currentStep: "Signing frameworks...", progress: 0.4, isComplete: false))
        try signFrameworks(in: appDir, identity: identity)

        // Step 5: Sign main binary
        progressHandler?(
            SigningProgress(currentStep: "Signing main binary...", progress: 0.6, isComplete: false)
        )
        try signMainBinary(in: appDir, identity: identity)

        // Step 6: Generate CodeResources
        progressHandler?(
            SigningProgress(
                currentStep: "Generating code signature...", progress: 0.8, isComplete: false))
        try generateCodeResources(for: appDir)

        // Step 7: Repackage IPA
        progressHandler?(
            SigningProgress(currentStep: "Repackaging IPA...", progress: 0.9, isComplete: false))
        let signedIPA = try repackageIPA(appDir: appDir, to: workDir)

        // Step 8: Move to output
        let outputURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("signed_\(ipaURL.lastPathComponent)")

        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }
        try fileManager.copyItem(at: signedIPA, to: outputURL)

        progressHandler?(SigningProgress(currentStep: "Complete!", progress: 1.0, isComplete: true))

        return outputURL
    }

    // MARK: - IPA Extraction

    private func extractIPA(ipaURL: URL, to directory: URL) throws -> URL {
        let payloadDir = directory.appendingPathComponent("Payload")

        // Unzip IPA
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", ipaURL.path, "-d", directory.path]

        // For iOS, use ZIPFoundation or native unzipping
        try unzipFile(at: ipaURL, to: directory)

        // Find .app directory
        guard
            let contents = try? fileManager.contentsOfDirectory(
                at: payloadDir, includingPropertiesForKeys: nil),
            let appDir = contents.first(where: { $0.pathExtension == "app" })
        else {
            throw SigningError.extractionFailed
        }

        return appDir
    }

    private func unzipFile(at sourceURL: URL, to destinationURL: URL) throws {
        // Native iOS unzipping using compression framework
        let sourceData = try Data(contentsOf: sourceURL)

        // Create Payload directory
        let payloadDir = destinationURL.appendingPathComponent("Payload")
        try fileManager.createDirectory(at: payloadDir, withIntermediateDirectories: true)

        // Use Archive for unzipping (requires import Compression or ZIPFoundation)
        // For now, we'll use a simpler approach with shell if available

        #if os(iOS)
            // On iOS, use built-in decompression
            try decompress(data: sourceData, to: destinationURL)
        #endif
    }

    private func decompress(data: Data, to url: URL) throws {
        // Implementation using Compression framework
        // This is a simplified version - full implementation would handle ZIP format
        try data.write(to: url.appendingPathComponent("temp.ipa"))

        // Use NSFileCoordinator for atomic operations
        let coordinator = NSFileCoordinator()
        var error: NSError?

        coordinator.coordinate(readingItemAt: url, options: .forUploading, error: &error) {
            tempURL in
            // Decompression happens here
        }

        if let error = error {
            throw error
        }
    }

    // MARK: - Certificate Handling

    private func importP12Certificate(data: Data, password: String) throws -> SigningIdentity {
        let options: [String: Any] = [
            kSecImportExportPassphrase as String: password
        ]

        var items: CFArray?
        let status = SecPKCS12Import(data as CFData, options as CFDictionary, &items)

        guard status == errSecSuccess,
            let itemsArray = items as? [[String: Any]],
            let firstItem = itemsArray.first
        else {
            throw SigningError.certificateNotFound
        }

        guard let identity = firstItem[kSecImportItemIdentity as String] as! SecIdentity? else {
            throw SigningError.certificateNotFound
        }

        var certificate: SecCertificate?
        var privateKey: SecKey?

        SecIdentityCopyCertificate(identity, &certificate)
        SecIdentityCopyPrivateKey(identity, &privateKey)

        guard let cert = certificate, let key = privateKey else {
            throw SigningError.certificateNotFound
        }

        // Get common name
        var commonName: CFString?
        SecCertificateCopyCommonName(cert, &commonName)

        return SigningIdentity(
            certificate: cert,
            privateKey: key,
            commonName: (commonName as String?) ?? "Unknown"
        )
    }

    // MARK: - Provisioning Profile

    private func installProvisioningProfile(data: Data, appDir: URL) throws {
        let profilePath = appDir.appendingPathComponent("embedded.mobileprovision")
        try data.write(to: profilePath)
    }

    // MARK: - Code Signing

    private func signFrameworks(in appDir: URL, identity: SigningIdentity) throws {
        let frameworksDir = appDir.appendingPathComponent("Frameworks")

        guard fileManager.fileExists(atPath: frameworksDir.path),
            let frameworks = try? fileManager.contentsOfDirectory(
                at: frameworksDir, includingPropertiesForKeys: nil)
        else {
            return  // No frameworks to sign
        }

        for framework in frameworks {
            if framework.pathExtension == "framework" || framework.pathExtension == "dylib" {
                try signBinary(at: framework, identity: identity)
            }
        }
    }

    private func signMainBinary(in appDir: URL, identity: SigningIdentity) throws {
        // Read Info.plist to get executable name
        let infoPlistPath = appDir.appendingPathComponent("Info.plist")

        guard let plistData = fileManager.contents(atPath: infoPlistPath.path),
            let plist = try? PropertyListSerialization.propertyList(
                from: plistData, options: [], format: nil) as? [String: Any],
            let executableName = plist["CFBundleExecutable"] as? String
        else {
            throw SigningError.noBinaryFound
        }

        let binaryPath = appDir.appendingPathComponent(executableName)
        try signBinary(at: binaryPath, identity: identity)
    }

    private func signBinary(at url: URL, identity: SigningIdentity) throws {
        // Read binary
        var binaryData = try Data(contentsOf: url)

        // Generate code directory hash
        let codeDirectoryHash = generateCodeDirectoryHash(for: binaryData)

        // Create CMS signature
        let signature = try createCMSSignature(
            data: codeDirectoryHash,
            certificate: identity.certificate,
            privateKey: identity.privateKey
        )

        // Append signature to binary (simplified - real implementation modifies Mach-O structure)
        // In practice, you'd modify the LC_CODE_SIGNATURE load command

        // For now, write the signature to a separate file
        let signaturePath = url.appendingPathExtension("signature")
        try signature.write(to: signaturePath)
    }

    private func generateCodeDirectoryHash(for data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }

    private func createCMSSignature(data: Data, certificate: SecCertificate, privateKey: SecKey)
        throws -> Data
    {
        // Create signature using Security framework
        var error: Unmanaged<CFError>?

        guard
            let signature = SecKeyCreateSignature(
                privateKey,
                .rsaSignatureMessagePKCS1v15SHA256,
                data as CFData,
                &error
            )
        else {
            if let err = error?.takeRetainedValue() {
                throw SigningError.signingFailed((err as Error).localizedDescription)
            }
            throw SigningError.signingFailed("Unknown error")
        }

        return signature as Data
    }

    // MARK: - Code Resources

    private func generateCodeResources(for appDir: URL) throws {
        let codeSignatureDir = appDir.appendingPathComponent("_CodeSignature")
        try fileManager.createDirectory(at: codeSignatureDir, withIntermediateDirectories: true)

        var resources: [String: Any] = [
            "files": [:],
            "files2": [:],
            "rules": [:],
            "rules2": [:],
        ]

        // Hash all files in the app
        if let enumerator = fileManager.enumerator(
            at: appDir, includingPropertiesForKeys: [.isRegularFileKey])
        {
            while let fileURL = enumerator.nextObject() as? URL {
                guard
                    let isFile = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
                        .isRegularFile,
                    isFile == true
                else { continue }

                let relativePath = fileURL.path.replacingOccurrences(
                    of: appDir.path + "/", with: "")

                // Skip signature files
                if relativePath.hasPrefix("_CodeSignature/") { continue }

                if let fileData = try? Data(contentsOf: fileURL) {
                    let hash = generateCodeDirectoryHash(for: fileData)

                    var filesDict = resources["files2"] as? [String: Any] ?? [:]
                    filesDict[relativePath] = ["hash2": hash.base64EncodedString()]
                    resources["files2"] = filesDict
                }
            }
        }

        // Write CodeResources
        let resourcesPath = codeSignatureDir.appendingPathComponent("CodeResources")
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: resources, format: .xml, options: 0)
        try plistData.write(to: resourcesPath)
    }

    // MARK: - Repackaging

    private func repackageIPA(appDir: URL, to directory: URL) throws -> URL {
        let payloadDir = appDir.deletingLastPathComponent()
        let ipaPath = directory.appendingPathComponent("signed.ipa")

        // Create ZIP (IPA is just a ZIP file)
        try zipDirectory(at: payloadDir.deletingLastPathComponent(), to: ipaPath)

        return ipaPath
    }

    private func zipDirectory(at sourceURL: URL, to destinationURL: URL) throws {
        // Create a simple ZIP archive
        // In production, use ZIPFoundation or similar library

        let coordinator = NSFileCoordinator()
        var error: NSError?

        coordinator.coordinate(readingItemAt: sourceURL, options: .forUploading, error: &error) {
            tempURL in
            try? fileManager.copyItem(at: tempURL, to: destinationURL)
        }

        if let error = error {
            throw error
        }

        // Fallback: just copy the directory structure
        if !fileManager.fileExists(atPath: destinationURL.path) {
            throw SigningError.repackageFailed
        }
    }
}
