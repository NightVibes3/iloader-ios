import SwiftUI

struct CertificatesView: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "0f172a").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Certificates")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                if appState.isLoading && appState.certificates.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView().tint(.white)
                        Text(appState.statusMessage).foregroundColor(.secondary).padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else if appState.certificates.isEmpty {
                    VStack {
                        Spacer()
                        Text("No certificates found.").foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(appState.certificates) { cert in
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(cert.name)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Text("Serial: \(cert.serialNumber)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Button(action: {
                                                Task { await appState.certificateService.revokeCertificate(serialNumber: cert.serialNumber) }
                                            }) {
                                                Text("Revoke")
                                                    .font(.caption).bold()
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(Color.red.opacity(0.2))
                                                    .cornerRadius(6)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        
                                        Divider().background(.white.opacity(0.1))
                                        
                                        if let machine = cert.machineName {
                                            Text("Recorded on: \(machine)")
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
                    Task { await appState.certificateService.loadCertificates() }
                }) {
                    Text("Refresh Certificates")
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

struct CertificatesView_Previews: PreviewProvider {
    static var previews: some View {
        CertificatesView()
    }
}
