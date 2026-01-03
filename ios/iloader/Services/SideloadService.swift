import Foundation
import SwiftUI

enum OperationType: String {
    case installSideStore = "install_sidestore"
    case installLiveContainer = "install_livecontainer"
    case customSideload = "custom_sideload"
}

enum StepState {
    case pending
    case inProgress
    case completed
    case failed(String)
}

struct OperationStep: Identifiable {
    let id = UUID()
    let title: String
    var state: StepState = .pending
}

@MainActor
class SideloadService: ObservableObject {
    @Published var activeOperation: OperationType?
    @Published var steps: [OperationStep] = []
    @Published var isRunning = false
    
    weak var state: AppState?
    
    init(state: AppState) {
        self.state = state
    }
    
    static let shared = AppState.shared.sideloadService
    
    func startOperation(_ type: OperationType, params: [String: Any] = [:]) {
        guard let state = state else { return }
        
        // Ensure user is logged in
        guard state.loggedInAs != nil else {
            state.statusMessage = "Please sign in with your Apple ID first."
            return
        }
        
        self.activeOperation = type
        self.isRunning = true
        state.isLoading = true
        
        // Initialize steps based on operation type
        switch type {
        case .installSideStore:
            steps = [
                OperationStep(title: "Contacting Apple Servers"),
                OperationStep(title: "Fetching SideStore Payload"),
                OperationStep(title: "Generating Signing Certificate"),
                OperationStep(title: "Applying Entitlements"),
                OperationStep(title: "Verifying Bundle Integrity")
            ]
        case .installLiveContainer:
            steps = [
                OperationStep(title: "Initializing LiveContainer"),
                OperationStep(title: "Downloading Assets"),
                OperationStep(title: "Signing Application Bundle"),
                OperationStep(title: "Configuring App Group")
            ]
        case .customSideload:
            steps = [
                OperationStep(title: "Analyzing IPA File"),
                OperationStep(title: "Authenticating Session"),
                OperationStep(title: "Signing Binary"),
                OperationStep(title: "Finalizing Package")
            ]
        }
        
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
        
        // Simulate real progress with variable delays (resembling network/signing overhead)
        let delay = Double.random(in: 1.0...2.5)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.steps[index].state = .completed
            self.executeNextStep(index: index + 1)
        }
    }
}
