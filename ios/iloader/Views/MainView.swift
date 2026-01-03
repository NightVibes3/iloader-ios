import SwiftUI

struct MainView: View {
    @ObservedObject var appState = AppState.shared
    @StateObject var sideloadService = SideloadService.shared
    
    @State private var showingCertificates = false
    @State private var showingAppIds = false
    @State private var showingPairing = false
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            // Background with "Liquid" refractions
            Color(hex: "0f172a").ignoresSafeArea()
            
            // Refraction Streaks (Simulated with Ellipses)
            VStack {
                Capsule()
                    .fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 600, height: 100)
                    .rotationEffect(.degrees(-35))
                    .blur(radius: 50)
                    .offset(x: -100, y: 100)
                Spacer()
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack(alignment: .top) {
                            Text("iloader")
                                .font(.system(size: 64, weight: .extrabold))
                                .foregroundColor(.white)
                            Spacer()
                            // Profile Bubble
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 80, height: 80)
                                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                                Text("🫵") // Placeholder for Memoji
                                    .font(.system(size: 50))
                            }
                            .shadow(color: .black.opacity(0.3), radius: 20)
                        }
                        .padding(.top, 20)
                        
                        // Account Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Account")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.4))
                                .textCase(.uppercase)
                            
                            GlassCard {
                                VStack(spacing: 16) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Kamon Whoite")
                                                .font(.headline)
                                            Text("user@mkmitangmail.com")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                            Text("Premium Member")
                                                .font(.caption2.bold())
                                                .foregroundColor(.green)
                                        }
                                        Spacer()
                                        Text("👩‍💻") // Placeholder for Memoji
                                            .font(.system(size: 40))
                                            .padding(8)
                                            .background(Circle().fill(.blue.opacity(0.2)))
                                    }
                                    
                                    Divider().background(.white.opacity(0.1))
                                    
                                    Button(action: { showingSettings = true }) {
                                        HStack {
                                            Text("Settings")
                                                .font(.subheadline.bold())
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.white)
                                    }
                                }
                                .padding(4)
                            }
                        }
                        
                        // Management Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Management")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.4))
                                .textCase(.uppercase)
                            
                            GlassCard {
                                VStack(spacing: 0) {
                                    ManagementRow(title: "Certificates", icon: "certificate") { showingCertificates = true }
                                    Divider().padding(.vertical, 8).background(.white.opacity(0.05))
                                    ManagementRow(title: "App IDs", icon: "square.stack.3d.up") { showingAppIds = true }
                                    Divider().padding(.vertical, 8).background(.white.opacity(0.05))
                                    ManagementRow(title: "Devices", icon: "iphone") { showingPairing = true }
                                }
                                .padding(4)
                            }
                        }
                        
                        // Installers Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Installers")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.4))
                                .textCase(.uppercase)
                                
                            GlassCard {
                                VStack(spacing: 12) {
                                    Button(action: { }) {
                                        Text("Install All")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(
                                                LinearGradient(colors: [Color(hex: "3b82f6"), Color(hex: "6366f1")], startPoint: .leading, endPoint: .trailing)
                                            )
                                            .cornerRadius(16)
                                            .shadow(color: Color(hex: "3b82f6").opacity(0.3), radius: 10, y: 5)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        InstallerSubButton(title: "Refresh") { }
                                        InstallerSubButton(title: "History") { }
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Floating Tab Bar
            VStack {
                Spacer()
                HStack(spacing: 30) {
                    TabItem(icon: "house.fill", label: "Home", isActive: true)
                    TabItem(icon: "gearshape", label: "Manage", isActive: false)
                    TabItem(icon: "arrow.down.circle", label: "Install", isActive: false)
                    TabItem(icon: "person.circle", label: "Profile", isActive: false)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingCertificates) { CertificatesView() }
        .sheet(isPresented: $showingAppIds) { AppIdsView() }
        .sheet(isPresented: $showingPairing) { PairingView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }
}

struct ManagementRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                }
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .foregroundColor(.white)
        }
    }
}

struct InstallerSubButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
        }
    }
}

struct TabItem: View {
    let icon: String
    let label: String
    let isActive: Bool
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(isActive ? .blue : .white.opacity(0.4))
    }
}

// Helper for Hex Colors (Copied from SectionView)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
