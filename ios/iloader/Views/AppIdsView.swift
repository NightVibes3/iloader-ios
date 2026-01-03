import SwiftUI

struct AppIdsView: View {
    @StateObject private var service = AppIdService()
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "0f172a").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Manage App IDs")
                            .font(.title2).bold()
                            .foregroundColor(.white)
                        Text("\(service.availableQuantity)/\(service.maxQuantity) IDs Available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                if service.isLoading && service.appIds.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView().tint(.white)
                        Text("Loading App IDs...").foregroundColor(.secondary).padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else if service.appIds.isEmpty {
                    VStack {
                        Spacer()
                        Text("No App IDs found.").foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(service.appIds) { appId in
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(appId.name)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Spacer()
                                            if appState.allowAppIdDeletion {
                                                Button(action: {
                                                    Task { await service.deleteAppId(id: appId.app_id_id) }
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
                                        
                                        HStack {
                                            Text("Expires: \(appId.expiration_date ?? "Never")")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("ID: \(appId.app_id_id)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Button(action: {
                    Task { await service.loadAppIds() }
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
            await service.loadAppIds()
        }
    }
}

struct AppIdsView_Previews: PreviewProvider {
    static var previews: some View {
        AppIdsView()
    }
}
