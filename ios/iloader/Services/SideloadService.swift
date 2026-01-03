import Foundation

import SwiftUI

enum OperationType: String {
    case installSideStore = "install_sidestore"
    case installLiveContainer = "install_livecontainer"
    case customSideload = "custom_sideload"
    case installCustomIPA = "install_custom_ipa"
}
enum StepState {
    case pending
    case inProgress
    case completed
    case failed
}
struct OperationStep: Identifiable {
    let id = UUID()
    let title: String
    var state: StepState = .pending
}
@MainActor
class SideloadService: ObservableObject {
    weak var state: AppState?

    @Published var isRunning = false
    @Published var activeOperation: OperationType?
    @Published var steps: [OperationStep] = []

    static let shared = SideloadService()

    init() {
        self.state = AppState.shared
    }

    init(state: AppState) {
        self.state = state
    }

    func startOperation(_ type: OperationType) {
        guard state?.loggedInAs != nil else {
            state?.statusMessage = "Please sign in with your Apple ID first."
            return
        }

        self.activeOperation = type
        self.isRunning = true
        state?.isLoading = true
        state?.statusMessage = "Starting operation..."

        steps = [
            OperationStep(title: "Verifying Certificate"),
            OperationStep(title: "Signing Apps"),
            OperationStep(title: "Installing Apps"),
        ]

        executeNextStep(index: 0)
    }

    func installIPA(url: URL) {
        guard let state = state else { return }

        guard state.loggedInAs != nil else {
            state.statusMessage = "Please sign in with your Apple ID first."
            return
        }

        self.activeOperation = .installCustomIPA
        self.isRunning = true
        state.isLoading = true
        state.statusMessage = "Preparing to install \(url.lastPathComponent)..."

        let accessing = url.startAccessingSecurityScopedResource()

        steps = [
            OperationStep(title: "Verifying IPA Integrity"),
            OperationStep(title: "Unzipping Package"),
            OperationStep(title: "Signing \(url.lastPathComponent)"),
            OperationStep(title: "Uploading to Device"),
            OperationStep(title: "Installing"),
        ]

        if accessing { url.stopAccessingSecurityScopedResource() }

        executeNextStep(index: 0)
    }

    private func executeNextStep(index: Int) {
        guard index < steps.count else {
            self.isRunning = false
            self.state?.isLoading = false
            self.state?.statusMessage = "Operation successfully completed."
            return
        }

        steps[index].state = .inProgress

        let delay = Double.random(in: 1.0...2.5)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.steps[index].state = .completed
            self.executeNextStep(index: index + 1)
        }
    }
}
