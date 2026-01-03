import SwiftUI

struct MainView: View {
    @ObservedObject var appState = AppState.shared
    @StateObject var sideloadService = SideloadService.shared
    
    @State private var selectedTab = 0
    @State private var showingCertificates = false
    @State private var showingAppIds = false
    @State private var showingPairing = false
    @State private var showingSettings = false
    @State private var showingLogin = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with "Liquid" refractions
                Color(hex: "0f172a").ignoresSafeArea()
                
                // Refraction Streaks (Dynamic scaling for iPhone 16)
                ZStack {
                    Capsule()
                        .fill(LinearGradient(colors: [.blue.opacity(0.12), .purple.opacity(0.08), .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * 1.5, height: geometry.size.height * 0.15)
                        .rotationEffect(.degrees(-35))
                        .blur(radius: 50)
                        .offset(x: -geometry.size.width * 0.2, y: geometry.size.height * 0.1)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.05))
                        .frame(width: geometry.size.width * 0.8)
                        .blur(radius: 100)
                        .offset(x: geometry.size.width * 0.3, y: -geometry.size.height * 0.2)
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if selectedTab == 0 {
                        HomeView(
                            appState: appState,
                            sideloadService: sideloadService,
                            showingCertificates: $showingCertificates,
                            showingAppIds: $showingAppIds,
                            showingPairing: $showingPairing,
                            showingSettings: $showingSettings,
                            showingLogin: $showingLogin
                        )
                        .transition(.opacity)
                    } else if selectedTab == 1 {
                        ManagementSection(
                            showingCertificates: $showingCertificates,
                            showingAppIds: $showingAppIds,
                            showingPairing: $showingPairing
                        )
                        .transition(.opacity)
                    } else if selectedTab == 2 {
                        InstallerSection(sideloadService: sideloadService)
                            .transition(.opacity)
                    } else {
                        ProfileSection(appState: appState, showingSettings: $showingSettings)
                            .transition(.opacity)
                    }
                    
                    Spacer(minLength: 120) // Space for floating tab bar
                }
                
                // Floating Tab Bar
                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        ForEach(0..<4) { index in
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedTab = index
                                }
                            }) {
                                TabItem(
                                    icon: tabIcon(for: index),
                                    label: tabLabel(for: index),
                                    isActive: selectedTab == index
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
                    .padding(.horizontal, 24)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 20)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingCertificates) { CertificatesView() }
        .sheet(isPresented: $showingAppIds) { AppIdsView() }
        .sheet(isPresented: $showingPairing) { PairingView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingLogin) { AppleIDView() }
        .sheet(isPresented: $sideloadService.isRunning) { OperationView() }
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "square.stack.3d.up.fill"
        case 2: return "arrow.down.circle.fill"
        case 3: return "person.circle.fill"
        default: return "questionmark"
        }
    }
    
    private func tabLabel(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "Manage"
        case 2: return "Install"
        case 3: return "Profile"
        default: return ""
        }
    }
}

struct HomeView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var sideloadService: SideloadService
    @Binding var showingCertificates: Bool
    @Binding var showingAppIds: Bool
    @Binding var showingPairing: Bool
    @Binding var showingSettings: Bool
    @Binding var showingLogin: Bool
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(alignment: .top) {
                    Text("iloader")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.white)
                    Spacer()
                    // Profile Bubble
                    Button(action: { showingSettings = true }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 64, height: 64)
                                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                            Text(appState.loggedInAs != nil ? "👨‍💻" : "👤")
                                .font(.system(size: 32))
                        }
                    }
                    .shadow(color: .black.opacity(0.3), radius: 15)
                }
                .padding(.top, 20)
                
                // Account Section
                SectionHeader(title: "Account")
                GlassCard {
                    if let user = appState.loggedInAs {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Apple ID")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(user)
                                        .font(.headline)
                                    Text("Active Session")
                                        .font(.caption2.bold())
                                        .foregroundColor(.green)
                                }
                                Spacer()
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                    .font(.title)
                            }
                            
                            Divider().background(.white.opacity(0.1))
                            
                            Button(action: { showingSettings = true }) {
                                HStack {
                                    Text("Manage Account")
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Text("No Apple ID Found")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                            Text("Login to start sideloading apps to your device.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { showingLogin = true }) {
                                Text("Sign In with Apple ID")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Quick Actions
                SectionHeader(title: "Quick Actions")
                GlassCard {
                    VStack(spacing: 0) {
                        ManagementRow(title: "Import IPA", icon: "arrow.down.doc") {
                            sideloadService.startOperation(.customSideload)
                        }
                        Divider().padding(.vertical, 8).background(.white.opacity(0.05))
                        ManagementRow(title: "Pair Device", icon: "iphone.badge.plus") {
                            showingPairing = true
                        }
                    }
                    .padding(4)
                }
                
                // Featured
                SectionHeader(title: "Featured Installers")
                HStack(spacing: 16) {
                    FeaturedCard(title: "SideStore", icon: "s.circle.fill", color: .blue) {
                        sideloadService.startOperation(.installSideStore)
                    }
                    FeaturedCard(title: "LiveContainer", icon: "l.circle.fill", color: .purple) {
                        sideloadService.startOperation(.installLiveContainer)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct ManagementSection: View {
    @Binding var showingCertificates: Bool
    @Binding var showingAppIds: Bool
    @Binding var showingPairing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Management")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(.top, 40)
            
            GlassCard {
                VStack(spacing: 0) {
                    ManagementRow(title: "Certificates", icon: "certificate") { showingCertificates = true }
                    Divider().padding(.vertical, 8).background(.white.opacity(0.05))
                    ManagementRow(title: "App IDs", icon: "square.stack.3d.up") { showingAppIds = true }
                    Divider().padding(.vertical, 8).background(.white.opacity(0.05))
                    ManagementRow(title: "Paired Devices", icon: "iphone") { showingPairing = true }
                }
                .padding(4)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct InstallerSection: View {
    @ObservedObject var sideloadService: SideloadService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Installers")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(.top, 40)
            
            GlassCard {
                VStack(spacing: 16) {
                    Button(action: { sideloadService.startOperation(.installSideStore) }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("Refresh All Apps")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16)
                    }
                    
                    HStack(spacing: 12) {
                        InstallerSubButton(title: "Update Store") { }
                        InstallerSubButton(title: "View History") { }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct ProfileSection: View {
    @ObservedObject var appState: AppState
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Profile")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(.top, 40)
            
            GlassCard {
                VStack(spacing: 20) {
                    HStack(spacing: 15) {
                        ZStack {
                            Circle().fill(.white.opacity(0.1)).frame(width: 80, height: 80)
                            Text("👤").font(.system(size: 40))
                        }
                        VStack(alignment: .leading) {
                            Text(appState.loggedInAs ?? "Guest User")
                                .font(.title3.bold())
                            Text(appState.loggedInAs != nil ? "Pro Account" : "Sign in to access features")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider().background(.white.opacity(0.1))
                    
                    ManagementRow(title: "Preferences", icon: "gearshape.fill") { showingSettings = true }
                    ManagementRow(title: "Privacy & Security", icon: "lock.fill") { }
                    
                    if appState.loggedInAs != nil {
                        Button(action: { appState.loggedInAs = nil }) {
                            Text("Log Out")
                                .foregroundColor(.red)
                                .font(.subheadline.bold())
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct FeaturedCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Tap to install")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 1))
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption.bold())
            .foregroundColor(.white.opacity(0.4))
            .textCase(.uppercase)
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
        .padding(.vertical, 4)
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
                .scaleEffect(isActive ? 1.1 : 1.0)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(isActive ? .blue : .white.opacity(0.4))
    }
}

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
