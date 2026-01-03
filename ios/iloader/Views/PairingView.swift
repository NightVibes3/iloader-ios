import Foundation

import SwiftUI

struct PairingView: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0f172a").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Devices")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)

                if appState.isLoading && appState.devices.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView().tint(.white)
                        Text(appState.statusMessage).foregroundColor(.secondary).padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else if appState.devices.isEmpty {
                    VStack {
                        Spacer()
                        Text("No devices found.").foregroundColor(.secondary)
                        Text("Ensure your device is connected via USB or WiFi.").font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(appState.devices) { device in
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
                                                Task {
                                                    await appState.pairingService.pairDevice(
                                                        device.id)
                                                }
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
                        .padding()
                    }
                }

                Button(action: {
                    Task { await appState.pairingService.scanForDevices() }
                }) {
                    Text("Scan for Devices")
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
