import Foundation

import SwiftUI

struct PairingView: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) var dismiss
    @State private var isImportingPairing = false

    var body: some View {
        ZStack {
            Color(hex: "0f172a").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                headerView

                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                scanButton
                    .padding()
                    .disabled(appState.isLoading)
            }
            .padding(.top)
        }
    }

    var headerView: some View {
        HStack {
            Text("Devices")
                .font(.title2).bold()
                .foregroundColor(.white)
            Spacer()
            Button("Done") { dismiss() }
                .foregroundColor(.blue)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    var contentView: some View {
        if appState.isLoading && appState.devices.isEmpty {
            loadingView
        } else if appState.devices.isEmpty {
            emptyView
        } else {
            deviceListView
        }
    }

    var loadingView: some View {
        VStack {
            Spacer()
            ProgressView().tint(.white)
            Text(appState.statusMessage).foregroundColor(.secondary).padding()
            Spacer()
        }
    }

    var emptyView: some View {
        VStack {
            Spacer()
            Text("No devices found.").foregroundColor(.secondary)
            Text("Ensure your device is connected via USB or WiFi.").font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
            Spacer()
        }
    }

    var deviceListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(appState.devices) { device in
                    deviceCard(for: device)
                }
            }
            .padding()
        }
    }

    func deviceCard(for device: Device) -> some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(device.model ?? "Unknown Model")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                if device.isPaired {
                    Label("Paired", systemImage: "checkmark.circle.fill")
                        .font(.caption).bold()
                        .foregroundColor(.green)
                } else {
                    Button(action: {
                        Task { await appState.pairingService.pairDevice(device.id) }
                    }) {
                        Text("Pair")
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

            }
        }
        .fileImporter(isPresented: $isImportingPairing, allowedContentTypes: [.content], allowsMultipleSelection: false) { result in
             switch result {
             case .success(let urls):
                 guard let url = urls.first else { return }
                 Task {
                     try? await appState.pairingService.importPairingFile(url: url)
                 }
             case .failure(let error):
                 print("Import failed: \(error.localizedDescription)")
             }
        }
    }
}
