import SwiftUI

struct InstallerView: View {
    var body: some View {
        VStack(spacing: 12) {
            InstallerButton(title: "SideStore (Stable)", subtitle: "Standard build", icon: "arrow.down.circle.fill", color: .blue)
            InstallerButton(title: "SideStore (Nightly)", subtitle: "Latest features", icon: "moon.stars.fill", color: .purple)
            InstallerButton(title: "LiveContainer + SideStore", subtitle: "Multi-app support", icon: "package.fill", color: .orange)
            
            Divider().background(.white.opacity(0.1)).padding(.vertical, 4)
            
            Button(action: {
                // Logic to open file picker for IPA
            }) {
                HStack {
                    Image(systemName: "plus.app.fill")
                    Text("Import IPA")
                    Spacer()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

struct InstallerButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "icloud.and.arrow.down")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

struct InstallerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GlassCard {
                InstallerView()
            }
            .padding()
        }
    }
}
