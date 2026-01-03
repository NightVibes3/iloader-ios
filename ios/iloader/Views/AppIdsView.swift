import SwiftUI

struct AppIdsView: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "0f172a").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("App IDs")
                            .font(.title2).bold()
                            .foregroundColor(.white)
                        Text("\(10 - appState.appIds.count) IDs Available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                if appState.isLoading && appState.appIds.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView().tint(.white)
                        Text(appState.statusMessage).foregroundColor(.secondary).padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else if appState.appIds.isEmpty {
                    VStack {
                        Spacer()
                        Text("No App IDs found.").foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(appState.appIds) { appId in
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(appId.name)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Spacer()
                                            if appState.allowAppIdDeletion {
                                                Button(action: {
                                                    // State manipulation simulation
                                                    appState.appIds.removeAll { $0.id == appId.id }
                                                }) {
                                                    Image(systemName: "trash")
                                                        .foregroundColor(.red)
                                                        .font(.footnote)
                                                }
                                            }
                                        }
                                        
                                        Text(appId.identifier)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        
                                        Text("Type: \(appId.type)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Button(action: {
                    Task { await appState.appIdService.loadAppIds() }
                }) {
                    Text("Refresh App IDs")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
                .padding()
                .disabled(appState.isLoading)
            }
            .padding(.top)
        }
    }
}

struct AppIdsView_Previews: PreviewProvider {
    static var previews: some View {
        AppIdsView()
    }
}
