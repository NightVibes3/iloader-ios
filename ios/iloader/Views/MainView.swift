import SwiftUI

import UniformTypeIdentifiers

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
                // Rich gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "0a0f1a"),
                        Color(hex: "0f172a"),
                        Color(hex: "1a1f3a"),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Ambient glow orbs
                ZStack {
                    // Purple orb top-left
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .blur(radius: 80)
                        .offset(x: -geometry.size.width * 0.3, y: -geometry.size.height * 0.1)

                    // Cyan orb bottom-right
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 180
                            )
                        )
                        .frame(width: 350, height: 350)
                        .blur(radius: 70)
                        .offset(x: geometry.size.width * 0.4, y: geometry.size.height * 0.3)

                    // Blue orb center
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.25), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: geometry.size.width * 0.1, y: geometry.size.height * 0.15)

                    // Accent streak
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .purple.opacity(0.2), .blue.opacity(0.15), .cyan.opacity(0.1),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 1.8, height: 120)
                        .rotationEffect(.degrees(-30))
                        .blur(radius: 40)
                        .offset(x: -geometry.size.width * 0.2, y: geometry.size.height * 0.2)
                }
                .ignoresSafeArea()

                // Main Content
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
                    } else {
                        ProfileSection(appState: appState, showingSettings: $showingSettings)
                            .transition(.opacity)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    // Floating Tab Bar
                    VStack {
                        HStack(spacing: 0) {
                            ForEach(0..<3) { index in
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
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCertificates) { CertificatesView() }
        .sheet(isPresented: $showingAppIds) { AppIdsView() }
        .sheet(isPresented: $showingPairing) { PairingView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingLogin) { AppleIDView() }
        .sheet(isPresented: $sideloadService.isRunning) {
            OperationView(service: sideloadService)
                .presentationDetents([.medium, .large])
                .background(Color(hex: "0f172a"))
        }
    }

    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "square.stack.3d.up.fill"
        case 2: return "person.circle.fill"
        default: return "questionmark"
        }
    }

    private func tabLabel(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "Manage"
        case 2: return "Profile"
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

    @State private var isImportingIPA = false

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
                SectionHeader(title: "Management")
                GlassCard {
                    VStack(spacing: 0) {
                        ManagementRow(title: "Certificates", icon: "certificate") {
                            showingCertificates = true
                        }
                        Divider().padding(.vertical, 8).background(.white.opacity(0.05))
                        ManagementRow(title: "App IDs", icon: "square.stack.3d.up") {
                            showingAppIds = true
                        }
                        Divider().padding(.vertical, 8).background(.white.opacity(0.05))
                        ManagementRow(title: "Devices", icon: "iphone") { showingPairing = true }
                    }
                    .padding(4)
                }

                // Installers Section (Bottom)
                SectionHeader(title: "Installers")
                GlassCard {
                    VStack(spacing: 16) {
                        Button(action: { sideloadService.startOperation(.installSideStore) }) {
                            Text("Install All")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.cyan, .blue], startPoint: .leading,
                                        endPoint: .trailing)
                                )
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                        }

                        Button(action: { isImportingIPA = true }) {
                            Text("Install Custom IPA")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16).stroke(
                                        .white.opacity(0.1), lineWidth: 1))
                        }

                        HStack(spacing: 12) {
                            InstallerSubButton(title: "Refresh") {}
                            InstallerSubButton(title: "History") {}
                        }
                    }
                    .padding(8)
                }
                .fileImporter(
                    isPresented: $isImportingIPA,
                    allowedContentTypes: [UTType(filenameExtension: "ipa") ?? .data],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        sideloadService.installIPA(url: url)
                    case .failure(let error):
                        print("IPA Import failed: \(error.localizedDescription)")
                    }
                }

                Spacer(minLength: 40)
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
                    ManagementRow(title: "Certificates", icon: "certificate") {
                        showingCertificates = true
                    }
                    Divider().padding(.vertical, 8).background(.white.opacity(0.05))
                    ManagementRow(title: "App IDs", icon: "square.stack.3d.up") {
                        showingAppIds = true
                    }
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
                            Text(
                                appState.loggedInAs != nil
                                    ? "Pro Account" : "Sign in to access features"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }

                    Divider().background(.white.opacity(0.1))

                    ManagementRow(title: "Preferences", icon: "gearshape.fill") {
                        showingSettings = true
                    }
                    ManagementRow(title: "Privacy & Security", icon: "lock.fill") {}

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
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
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
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255,
            opacity: Double(a) / 255)
    }
}
