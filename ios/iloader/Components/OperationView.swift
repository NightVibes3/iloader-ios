import SwiftUI

struct OperationView: View {
    @ObservedObject var service: SideloadService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(service.activeOperation?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "Operation")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if !service.isRunning {
                    Button("Close") { service.isRunning = false }
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(service.steps) { step in
                    HStack(spacing: 12) {
                        stepIcon(for: step.state)
                        
                        Text(step.title)
                            .font(.subheadline)
                            .foregroundColor(stepColor(for: step.state))
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(4)
    }
    
    @ViewBuilder
    func stepIcon(for state: StepState) -> some View {
        switch state {
        case .pending:
            Circle().stroke(.secondary.opacity(0.3), lineWidth: 1.5).frame(width: 18, height: 18)
        case .inProgress:
            ProgressView().scaleEffect(0.7).frame(width: 18, height: 18)
        case .completed:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
        }
    }
    
    func stepColor(for state: StepState) -> Color {
        switch state {
        case .pending: return .secondary
        case .inProgress: return .white
        case .completed: return .white
        case .failed: return .red
        }
    }
}
