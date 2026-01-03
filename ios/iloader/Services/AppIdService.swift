import Foundation

@MainActor
class AppIdService: ObservableObject {
    weak var state: AppState?

    private let developerServicesURL = "https://developerservices2.apple.com/services/v1"

    init(state: AppState) {
        self.state = state
    }

    /// Fetch real App IDs from Apple Developer Services
    func loadAppIds() async {
        guard let state = state else { return }

        guard let user = state.loggedInAs else {
            state.appIds = []
            return
        }

        state.isLoading = true
        state.statusMessage = "Loading App IDs from Apple..."

        do {
            guard let account = state.accountService.accounts.first(where: { $0.appleId == user })
            else {
                throw NSError(
                    domain: "AppIdService", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No account session found"])
            }

            let anisetteHeaders = try await AnisetteService.shared.fetchAnisetteHeaders(
                serverUrl: state.anisetteServer
            )

            var request = URLRequest(url: URL(string: "\(developerServicesURL)/ios/listAppIds")!)
            request.httpMethod = "POST"
            request.timeoutInterval = 30

            for (key, value) in anisetteHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            request.setValue(
                "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("Xcode", forHTTPHeaderField: "User-Agent")

            let bodyParams: [String: Any] = [
                "clientId": "XABBG36SBA",
                "myacinfo": account.token,
                "protocolVersion": "A1234",
                "requestId": UUID().uuidString,
            ]

            request.httpBody = try PropertyListSerialization.data(
                fromPropertyList: bodyParams,
                format: .xml,
                options: 0
            )

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(
                    domain: "AppIdService", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            if httpResponse.statusCode == 200 {
                if let plistResponse = try? PropertyListSerialization.propertyList(
                    from: data, options: [], format: nil) as? [String: Any],
                    let appIdsData = plistResponse["appIds"] as? [[String: Any]]
                {

                    let appIds = appIdsData.compactMap { appId -> AppId? in
                        guard let id = appId["appIdId"] as? String,
                            let name = appId["name"] as? String,
                            let identifier = appId["identifier"] as? String
                        else {
                            return nil
                        }

                        let type = appId["appIdPlatform"] as? String ?? "iOS App"

                        return AppId(id: id, name: name, identifier: identifier, type: type)
                    }

                    state.appIds = appIds
                    state.isLoading = false
                    state.statusMessage = appIds.isEmpty ? "No App IDs found" : ""
                    return
                }
            }

            throw NSError(
                domain: "AppIdService", code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey: "Apple returned status \(httpResponse.statusCode)"
                ])

        } catch {
            state.isLoading = false
            state.statusMessage = "Error: \(error.localizedDescription)"
            state.appIds = []
        }
    }

    /// Delete an App ID
    func deleteAppId(_ id: String) async {
        guard let state = state else { return }
        guard state.allowAppIdDeletion else {
            state.statusMessage = "App ID deletion is disabled in settings"
            return
        }
        guard let user = state.loggedInAs,
            let account = state.accountService.accounts.first(where: { $0.appleId == user })
        else {
            state.statusMessage = "Please sign in first"
            return
        }

        state.isLoading = true
        state.statusMessage = "Deleting App ID..."

        do {
            let anisetteHeaders = try await AnisetteService.shared.fetchAnisetteHeaders(
                serverUrl: state.anisetteServer
            )

            var request = URLRequest(url: URL(string: "\(developerServicesURL)/ios/deleteAppId")!)
            request.httpMethod = "POST"
            request.timeoutInterval = 30

            for (key, value) in anisetteHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            request.setValue(
                "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let bodyParams: [String: Any] = [
                "appIdId": id,
                "myacinfo": account.token,
                "clientId": "XABBG36SBA",
            ]

            request.httpBody = try PropertyListSerialization.data(
                fromPropertyList: bodyParams,
                format: .xml,
                options: 0
            )

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                state.appIds.removeAll { $0.id == id }
                state.statusMessage = "App ID deleted successfully"
            } else {
                state.statusMessage = "Failed to delete App ID"
            }

        } catch {
            state.statusMessage = "Error: \(error.localizedDescription)"
        }

        state.isLoading = false
    }
}
