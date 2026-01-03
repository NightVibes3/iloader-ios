import Foundation
import SwiftUI

struct PairingAppInfo: Identifiable, Codable {
    var id: String { bundleId }
    let name: String
    let bundleId: String
    let path: String
}

@MainActor
class PairingService: ObservableObject {
    @Published var apps: [PairingAppInfo] = []
    @Published var isLoading: Bool = false
    
    func loadApps() async {
        DispatchQueue.main.async { self.isLoading = true }
        
        // Mock data matching Pairing.tsx logic
        try? await Task.sleep(nanoseconds: 800_000_000)
        let mockApps = [
            PairingAppInfo(name: "SideStore", bundleId: "io.sidestore.SideStore", path: "/var/mobile/Containers/Data/Application/..."),
            PairingAppInfo(name: "StikDebug", bundleId: "com.nab138.StikDebug", path: "/var/mobile/Containers/Data/Application/...")
        ]
        
        DispatchQueue.main.async {
            self.apps = mockApps
            self.isLoading = false
        }
    }
    
    func placePairing(app: PairingAppInfo) async {
        // Simulating pairing file placement
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

struct PairingView: View {
    @StateObject private var service = PairingService()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "0f172a").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Manage Pairing File")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                if service.isLoading && service.apps.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView().tint(.white)
                        Text("Loading Apps...").foregroundColor(.secondary).padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else if service.apps.isEmpty {
                    VStack {
                        Spacer()
                        Text("No Supported Apps found.").foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(service.apps) { app in
                                GlassCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(app.name)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text(app.bundleId)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button(action: {
                                            Task { await service.placePairing(app: app) }
                                        }) {
                                            Text("Place")
                                                .font(.caption).bold()
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.2))
                                                .cornerRadius(8)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Button(action: {
                    Task { await service.loadApps() }
                }) {
                    Text("Refresh")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
                .padding()
                .disabled(service.isLoading)
            }
            .padding(.top)
        }
        .task {
            await service.loadApps()
        }
    }
}
