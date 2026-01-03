import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) var dismiss
    @State private var isCustomAnisette = false
    
    let anisetteServers = [
        ("ani.sidestore.io", "SideStore (.io)"),
        ("ani.sidestore.app", "SideStore (.app)"),
        ("ani.sidestore.zip", "SideStore (.zip)"),
        ("ani.846969.xyz", "SideStore (.xyz)"),
        ("ani.neoarz.xyz", "neoarz"),
        ("ani.xu30.top", "SteX"),
        ("anisette.wedotstud.io", "WE. Studio")
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "0f172a").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Settings")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Anisette Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ANISETTE SERVER")
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                            
                            GlassCard {
                                VStack(spacing: 0) {
                                    Picker("Server", selection: $appState.anisetteServer) {
                                        ForEach(anisetteServers, id: \.0) { server in
                                            Text(server.1).tag(server.0)
                                        }
                                        Text("Custom").tag("custom")
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.white)
                                    
                                    if appState.anisetteServer == "custom" || isCustomAnisette {
                                        Divider().background(.white.opacity(0.1)).padding(.vertical, 8)
                                        TextField("Server URL", text: $appState.anisetteServer)
                                            .textFieldStyle(.plain)
                                            .foregroundColor(.white)
                                            .padding(10)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // App ID Deletion
                        VStack(alignment: .leading, spacing: 12) {
                            Text("MANAGEMENT")
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                            
                            GlassCard {
                                Toggle(isOn: $appState.allowAppIdDeletion) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Allow App ID deletion")
                                            .foregroundColor(.white)
                                        Text("Not recommended for free accounts. This just hides them until they expire.")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tint(.blue)
                            }
                        }
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ABOUT")
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                            
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Version")
                                        Spacer()
                                        Text("1.1.6").foregroundColor(.secondary)
                                    }
                                    Divider().background(.white.opacity(0.1))
                                    HStack {
                                        Text("Developer")
                                        Spacer()
                                        Text("nab138").foregroundColor(.secondary)
                                    }
                                }
                                .foregroundColor(.white)
                                .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                }
            }
            .padding(.top)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
