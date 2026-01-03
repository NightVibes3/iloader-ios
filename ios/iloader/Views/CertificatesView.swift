import SwiftUI

struct CertificatesView: View {
    @StateObject private var service = CertificateService()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "0f172a").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Manage Certificates")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                if service.isLoading && service.certificates.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Text("Loading certificates...")
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else if service.certificates.isEmpty {
                    VStack {
                        Spacer()
                        Text("No certificates found.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(service.certificates) { cert in
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
                                                Task { await service.revokeCertificate(serialNumber: cert.serialNumber) }
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
                                        
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("Machine Name")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(cert.machineName)
                                                    .font(.footnote)
                                                    .foregroundColor(.white)
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing) {
                                                Text("Machine ID")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(cert.machineId)
                                                    .font(.footnote)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Button(action: {
                    Task { await service.loadCertificates() }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
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
            await service.loadCertificates()
        }
    }
}

struct CertificatesView_Previews: PreviewProvider {
    static var previews: some View {
        CertificatesView()
    }
}
